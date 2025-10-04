const std = @import("std");
const chip = @import("src/chip/chip.zig");

pub const Target = struct {
    chip: chip.Chip,
    // Override the default linker script for the chip.
    linker_script: ?std.Build.LazyPath = null,
};

pub const FirmwareOptions = struct {
    name: []const u8,
    root_source_file: std.Build.LazyPath,
    target: Target,
    optimize: std.builtin.OptimizeMode = .ReleaseSmall,
    /// Override the default config options.
    /// Use `createConfigOptions(b, name, target.chip)` for default and add options to it.
    config_options: ?*std.Build.Step.Options = null,
};

pub fn addFirmwareTest(app_builder: *std.Build, dep_maybe: ?*std.Build.Dependency, native_target: std.Build.ResolvedTarget, options: FirmwareOptions) *std.Build.Step.Compile {
    const ch32_builder = if (dep_maybe) |dep| dep.builder else app_builder;

    const root_mod = createModules(ch32_builder, native_target, options);

    const firmware = ch32_builder.addTest(.{
        .name = options.name,
        .root_module = root_mod.import_table.get("app").?,
        .test_runner = .{ .path = ch32_builder.path("test_runner.zig"), .mode = .simple },
    });

    return firmware;
}

pub fn addFirmware(app_builder: *std.Build, dep_maybe: ?*std.Build.Dependency, options: FirmwareOptions) *std.Build.Step.Compile {
    const ch32_builder = if (dep_maybe) |dep| dep.builder else app_builder;

    const target = ch32_builder.resolveTargetQuery(options.target.chip.target());

    const root_mod = createModules(ch32_builder, target, options);

    const firmware = ch32_builder.addExecutable(.{
        .name = options.name,
        .linkage = .static,
        .root_module = root_mod,
    });
    firmware.bundle_compiler_rt = true;
    firmware.link_gc_sections = true;
    firmware.link_function_sections = true;
    firmware.link_data_sections = true;

    firmware.linker_script = options.target.linker_script orelse ch32_builder.path("src/ld").join(ch32_builder.allocator, options.target.chip.linkScript(ch32_builder)) catch @panic("OOM");

    // For emit elf with debug info.
    firmware.root_module.strip = false;

    return firmware;
}

pub fn createModules(b: *std.Build, target: std.Build.ResolvedTarget, options: FirmwareOptions) *std.Build.Module {
    const config_options = options.config_options orelse createConfigOptions(b, options.name, options.target.chip);
    const config_mod = config_options.createModule();

    const svd_mod = svdModule(b, target, options.target.chip.asSeries().svdName());

    const hal_mod = halModule(b, target);
    hal_mod.addImport("config", config_mod);
    hal_mod.addImport("svd", svd_mod);

    const app_mod = b.createModule(.{
        .root_source_file = options.root_source_file,
        .target = target,
        .optimize = options.optimize,
        .single_threaded = true,
        .imports = &.{
            .{ .name = "config", .module = config_mod },
            .{ .name = "svd", .module = svd_mod },
            .{ .name = "hal", .module = hal_mod },
        },
    });

    const root_mod = b.createModule(.{
        .root_source_file = b.path("src/ch32.zig"),
        .target = target,
        .optimize = options.optimize,
        .single_threaded = true,
        .imports = &.{
            .{ .name = "config", .module = config_mod },
            .{ .name = "svd", .module = svd_mod },
            .{ .name = "hal", .module = hal_mod },
            .{ .name = "app", .module = app_mod },
        },
    });
    app_mod.addImport("ch32", root_mod);

    return root_mod;
}

const ChipOption = struct {
    series: chip.Series,
    model: chip.Model,
    class: chip.Class,

    fn from(c: chip.Chip) ChipOption {
        return .{
            .series = c.asSeries(),
            .model = c.asModel(),
            .class = c.asClass(),
        };
    }
};

pub fn createConfigOptions(
    b: *std.Build,
    name: []const u8,
    c: chip.Chip,
) *std.Build.Step.Options {
    const config_options = b.addOptions();
    config_options.addOption([]const u8, "name", name);
    config_options.addOption(ChipOption, "chip", ChipOption.from(c));

    return config_options;
}

fn svdModule(b: *std.Build, target: std.Build.ResolvedTarget, svd_name: []const u8) *std.Build.Module {
    const svd_path = b.path("src/svd").join(b.allocator, b.fmt("{s}.zig", .{svd_name})) catch @panic("OOM");
    const module = b.createModule(.{
        .root_source_file = svd_path,
        .target = target,
        .single_threaded = true,
    });

    return module;
}

fn halModule(b: *std.Build, target: std.Build.ResolvedTarget) *std.Build.Module {
    const module = b.createModule(.{
        .root_source_file = b.path("src/hal/hal.zig"),
        .target = target,
        .single_threaded = true,
    });

    return module;
}

const FirmwareFormat = union(enum) {
    elf,
    bin,
    @"asm",

    fn ext(format: FirmwareFormat) []const u8 {
        return switch (format) {
            .elf => "elf",
            .bin => "bin",
            .@"asm" => "s",
        };
    }
};

pub const InstallFirmwareOptions = struct {
    format: FirmwareFormat = .bin,
    install_dir: std.Build.InstallDir = .{ .custom = "firmware" },
};

pub fn installFirmware(b: *std.Build, compile: *std.Build.Step.Compile, options: InstallFirmwareOptions) std.Build.LazyPath {
    const basename = b.fmt("{s}.{s}", .{ compile.name, options.format.ext() });

    const path = switch (options.format) {
        .elf => compile.getEmittedBin(),
        .bin => b.addObjCopy(compile.getEmittedBin(), .{
            .basename = basename,
            .format = .bin,
        }).getOutput(),
        .@"asm" => compile.getEmittedAsm(),
    };

    const install = b.addInstallFileWithDir(path, .{ .custom = "firmware" }, basename);
    b.getInstallStep().dependOn(&install.step);

    return path;
}

const FirmwareSize = struct {
    step: std.Build.Step,
    source: std.Build.LazyPath,
};

pub fn printFirmwareSize(b: *std.Build, file: std.Build.LazyPath) void {
    const size = b.allocator.create(FirmwareSize) catch @panic("OOM");
    size.* = .{
        .step = std.Build.Step.init(.{
            .id = .install_file,
            .name = b.fmt("print {s} size", .{file.getDisplayName()}),
            .owner = b,
            .makeFn = makeFirmwareSize,
        }),
        .source = file,
    };

    file.addStepDependencies(&size.step);
    b.getInstallStep().dependOn(&size.step);
}

fn makeFirmwareSize(step: *std.Build.Step, options: std.Build.Step.MakeOptions) !void {
    _ = options;
    const b = step.owner;

    const self: *FirmwareSize = @fieldParentPtr("step", step);

    const full_src_path = self.source.getPath2(b, step);
    const name = std.fs.path.basename(full_src_path);

    const file = std.fs.openFileAbsolute(full_src_path, .{ .mode = .read_only }) catch |err| {
        return step.fail("unable to open file from '{s}': {s}", .{
            full_src_path, @errorName(err),
        });
    };
    const stat = file.stat() catch |err| {
        return step.fail("unable to stat file from '{s}': {s}", .{
            full_src_path, @errorName(err),
        });
    };
    const size = stat.size;

    std.log.info("{s} size: {d} bytes", .{ name, size });
}

pub fn addMinichlink(b: *std.Build, dep_maybe: ?*std.Build.Dependency, step: *std.Build.Step) void {
    const ch32_builder = if (dep_maybe) |dep| dep.builder else b;

    const minichlink_dep = ch32_builder.dependency("minichlink", .{});
    const minichlink = minichlink_dep.artifact("minichlink");

    if (b.args) |args| {
        const minichlink_run = ch32_builder.addRunArtifact(minichlink);
        minichlink_run.setCwd(.{ .cwd_relative = "." });
        minichlink_run.addArgs(args);
        step.dependOn(&minichlink_run.step);
    } else {
        const minichlink_install = b.addInstallArtifact(minichlink, .{});
        step.dependOn(&minichlink_install.step);
    }
}

pub fn build(b: *std.Build) void {
    const native_target = b.standardTargetOptions(.{});
    const targets: []const Target = &.{
        .{ .chip = .{ .series = .ch32v003 } },
        // .{ .chip = .{ .series = .ch32v103 } },
        .{ .chip = .{ .series = .ch32v20x } },
        .{ .chip = .{ .series = .ch32v30x } },
    };

    //      ┌──────────────────────────────────────────────────────────┐
    //      │                          Build                           │
    //      └──────────────────────────────────────────────────────────┘
    const fw = addFirmware(b, null, .{
        .name = "build",
        .target = .{ .chip = .{ .series = .ch32v30x } },
        .root_source_file = b.path("src/main.zig"),
    });
    _ = installFirmware(b, fw, .{});

    //      ┌──────────────────────────────────────────────────────────┐
    //      │                           Test                           │
    //      └──────────────────────────────────────────────────────────┘
    const test_step = b.step("test", "Run platform-independent tests");
    for (targets) |target| {
        const hal_test = addFirmwareTest(b, null, native_target, .{
            .name = target.chip.string(),
            .root_source_file = b.path("src/hal/hal.zig"),
            .target = target,
            .optimize = .Debug,
        });
        const hal_unit_tests_run = b.addRunArtifact(hal_test);
        test_step.dependOn(&hal_unit_tests_run.step);

        const core_test = addFirmwareTest(b, null, native_target, .{
            .name = target.chip.string(),
            .root_source_file = b.path("src/ch32.zig"),
            .target = target,
            .optimize = .Debug,
        });
        const core_unit_tests_run = b.addRunArtifact(core_test);
        test_step.dependOn(&core_unit_tests_run.step);
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
    addMinichlink(b, null, minichlink_step);
}
