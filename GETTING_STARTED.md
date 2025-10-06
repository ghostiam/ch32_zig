# Getting Started

> \[!NOTE\]
> If you are using `nix`, you can simply run `nix develop` in the root of the project, and it will automatically install
> `zig`, `zls`, `zigscient`, `minichlink` and `minichlink-ocd` in your environment.

### Install Zig

Currently, the examples are tested with `0.15.1`.\
Download the latest version from:
https://ziglang.org/download/

### Configure a project

Create a new project:

```shell
zig init -m
```

Import the hal:

```shell
zig fetch --save=ch32 https://github.com/ghostiam/ch32_zig/archive/refs/heads/master.zip
```

Replace `build.zig` with the following:

```zig
const std = @import("std");
const ch32 = @import("ch32");

pub fn build(b: *std.Build) void {
    const ch32_dep = b.dependency("ch32", .{});

    const name = "YOUR_PROJECT_NAME";
    const targets: []const ch32.Target = &.{
        // You can specify a series of the chip.
        // Enabling multiple options simultaneously may result in incorrect autocompletion.
        .{ .chip = .{ .series = .ch32v003 } },
        // .{ .chip = .{ .series = .ch32v103 } },
        // .{ .chip = .{ .series = .ch32v20x } },
        // .{ .chip = .{ .series = .ch32v30x } },
    };

    //      ┌──────────────────────────────────────────────────────────┐
    //      │                          Build                           │
    //      └──────────────────────────────────────────────────────────┘
    const optimize = b.option(
        std.builtin.OptimizeMode,
        "optimize",
        "Prioritize performance, safety, or binary size",
    ) orelse .ReleaseSmall;

    for (targets) |target| {
        const fw = ch32.addFirmware(b, ch32_dep, .{
            .name = b.fmt("{s}_{s}", .{ name, target.chip.string() }),
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        });

        // Emit the bin file for flashing.
        const fw_bin = ch32.installFirmware(b, fw, .{});
        ch32.printFirmwareSize(b, fw_bin);

        // Emit the elf file for debugging.
        _ = ch32.installFirmware(b, fw, .{ .format = .elf });
    }

    //      ┌──────────────────────────────────────────────────────────┐
    //      │                           Test                           │
    //      └──────────────────────────────────────────────────────────┘
    const native_target = b.standardTargetOptions(.{});
    const test_step = b.step("test", "Run platform-independent tests");
    for (targets) |target| {
        const fw_test = ch32.addFirmwareTest(b, ch32_dep, native_target, .{
            .name = b.fmt("{s}_{s}", .{ name, target.chip.string() }),
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = .Debug,
        });
        const unit_tests_run = b.addRunArtifact(fw_test);
        test_step.dependOn(&unit_tests_run.step);
    }

    //      ┌──────────────────────────────────────────────────────────┐
    //      │                          Clean                           │
    //      └──────────────────────────────────────────────────────────┘
    const clean_step = b.step("clean", "Clean up");
    clean_step.dependOn(&b.addRemoveDirTree(.{ .cwd_relative = b.install_path }).step);
    clean_step.dependOn(&b.addRemoveDirTree(.{ .cwd_relative = b.pathFromRoot(".zig-cache") }).step);

    //      ┌──────────────────────────────────────────────────────────┐
    //      │                        minichlink                        │
    //      └──────────────────────────────────────────────────────────┘
    const minichlink_step = b.step("minichlink", "minichlink");
    ch32.addMinichlink(b, ch32_dep, minichlink_step);
}
```

Create a file `src/main.zig` with the following:

```zig
const std = @import("std");
const config = @import("config");
const hal = @import("hal");

pub const interrupts: hal.interrupts.VectorTable = .{
    .SysTick = hal.time.sysTickHandler,
};

pub fn main() !void {
    const clock = hal.clock.setOrGet(.hsi_max);
    hal.time.init(clock);
    hal.delay.init(clock);

    const led = hal.Pin.init(.GPIOC, 0);
    led.enablePort();
    led.asOutput(.{ .speed = .max_50mhz, .mode = .push_pull });

    while (true) {
        led.toggle();
        hal.delay.ms(1_000);
    }
}
```

### Build the project

```shell
zig build
```

### Flashing

```shell
zig build minichlink -- -w zig-out/firmware/YOUR_PROJECT_NAME_ch32v003.bin flash -b
```

### Build the `minichlink` as standalone

[Minichlink](https://github.com/cnlohr/ch32v003fun/tree/master/minichlink) is a open-source flasher for WCH chips.
It is built with Zig and can be compiled using the following command:

```shell
zig build minichlink
```

Output will be in `zig-out/bin/minichlink`.
