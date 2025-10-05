const std = @import("std");
const config = @import("config");

const zasm = @import("asm.zig");
const interrupts = @import("interrupts.zig");
const Pin = @import("Pin.zig");

pub const Options = struct {
    /// The LED pin to use for panic indication.
    /// If not set, the panic handler will just hang.
    led: ?Pin = null,
};

/// Returns a panic handler that will print the registers and hang.
/// If configured, the LED will blink with a pattern of 3 long and 3 short.
pub fn initLog(comptime o: Options) fn (message: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) callconv(.@"inline") noreturn {
    return struct {
        inline fn panic(message: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) noreturn {
            printRegisters(message, @returnAddress());

            if (o.led) |led| {
                hangWithLed(led);
            } else {
                hang();
            }
        }
    }.panic;
}

/// Returns a silent panic handler.
/// If configured, the LED will blink with a pattern of 3 long and 3 short.
pub fn initSilent(comptime o: Options) fn (message: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) callconv(.@"inline") noreturn {
    return struct {
        inline fn panic(_: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) noreturn {
            if (o.led) |led| {
                hangWithLed(led);
            } else {
                hang();
            }
        }
    }.panic;
}

pub inline fn hang() noreturn {
    interrupts.globalDisable();
    while (true) {
        interrupts.wait();
    }
}

pub fn hangWithLed(pin: Pin) noreturn {
    interrupts.globalDisable();

    const short_delay: u32 = 500_000;
    const long_delay: u32 = 1_500_000;
    const blinks: u32 = 3;

    pin.enablePort();
    pin.asOutput(.{ .speed = .max_50mhz, .mode = .push_pull });

    // Fast blink for debugging.
    while (true) {
        // Short blinks.
        for (0..blinks * 2) |_| {
            pin.toggle();
            dummyLoop(short_delay);
        }

        // Long blinks.
        for (0..blinks * 2) |_| {
            pin.toggle();
            dummyLoop(long_delay);
        }
    }
}

inline fn printRegisters(message: []const u8, retAddr: usize) void {
    std.log.err(
        \\PANIC: {s}
        \\Registers dump:
        \\    MSTATUS: 0x{X:0>8}
        \\    MEPC: 0x{X:0>8}
        \\    MCAUSE: 0x{X:0>8}
        \\    MTVAL: 0x{X:0>8}
        \\    MSCRATCH: 0x{X:0>8}
    , .{ message, zasm.getMstatus(), zasm.getMepc(), zasm.getMcause(), zasm.getMtval(), zasm.getMscratch() });

    // Stack trace
    // Use `riscv-none-elf-addr2line -e zig-out/firmware/ch32v003_blink.elf 0x08000950` ---> main.zig:xxx
    var index: usize = 0;
    var iter = std.debug.StackIterator.init(retAddr, null);
    while (iter.next()) |address| : (index += 1) {
        if (index == 0) {
            std.log.err("Stack trace:", .{});
        }
        std.log.err("{d: >3}: 0x{X:0>8}", .{ index, address });

        // Avoid infinite loop.
        if (index >= 10) break;
    }
}

inline fn dummyLoop(count: u32) void {
    var i: u32 = 0;
    while (i < count) : (i += 1) {
        asm volatile ("" ::: .{ .memory = true });
    }
}
