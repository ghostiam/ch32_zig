const std = @import("std");
const config = @import("config");
const svd = @import("svd");

const hal = @import("hal.zig");
const PFIC = svd.peripherals.PFIC;

const SysTicksPer = packed struct(u32) {
    us: u8 = 0, // 1 - 144
    ms: u24 = 0, // 1_000 - 144_000
};
var systicks_per = SysTicksPer{};

/// Initialize delay dividers for the given clock and enable SysTick timer.
pub fn init(clock: hal.clock.Clocks) void {
    comptime {
        if (hal.time.isEnabledInterrupt()) {
            @compileError("Only one delay implementation can be used at same time");
        }
    }

    systicks_per.us = @truncate(divOptimized(clock.hb, 1_000_000));
    systicks_per.ms = @truncate(divOptimized(clock.hb, 1_000));

    // Enable SysTick timer.
    svd.peripherals.PFIC.STK_CTLR.modify(.{
        .STE = 1, // Enable SysTick.
        .STCLK = 1, // HCLK/1 for time base.
    });
}

/// Delay in SysTick clock cycles.
pub fn ticks(n: u32) void {
    const end = PFIC.STK_CNTL.raw +% n;

    while (diffTime(PFIC.STK_CNTL.raw, end) < 0) {
        asm volatile ("" ::: .{ .memory = true });
    }
}

/// Delay in microseconds. Max value is 65_535.
pub fn us(n: u16) void {
    const start = PFIC.STK_CNTL.raw;
    const ticks_count: u32 = n * @as(u32, @intCast(systicks_per.us));
    const end = start +% ticks_count;

    while (diffTime(PFIC.STK_CNTL.raw, end) < 0) {
        asm volatile ("" ::: .{ .memory = true });
    }
}

/// Delay in milliseconds.
pub fn ms(n: u32) void {
    const start = PFIC.STK_CNTL.raw;
    const ticks_count = n * @as(u32, @intCast(systicks_per.ms));
    const end = start +% ticks_count;

    while (diffTime(PFIC.STK_CNTL.raw, end) < 0) {
        asm volatile ("" ::: .{ .memory = true });
    }
}

inline fn diffTime(a: u32, b: u32) i32 {
    return @bitCast(a -% b);
}

fn divOptimized(n: u32, d: u32) u32 {
    var q: u32 = 0;
    var r: u32 = n;

    while (r >= d) {
        r -= d;
        q += 1;
    }

    return q;
}

test divOptimized {
    const Test = struct {
        n: u32,
        d: u32,
        expected: u32,
    };
    const tests = [_]Test{
        // Hz to MHz
        .{ .n = 1_000_000, .d = 1_000_000, .expected = 1 },
        .{ .n = 8_000_000, .d = 1_000_000, .expected = 8 },
        .{ .n = 16_000_000, .d = 1_000_000, .expected = 16 },
        .{ .n = 24_000_000, .d = 1_000_000, .expected = 24 },
        .{ .n = 48_000_000, .d = 1_000_000, .expected = 48 },
        .{ .n = 96_000_000, .d = 1_000_000, .expected = 96 },
        .{ .n = 144_000_000, .d = 1_000_000, .expected = 144 },
        // Hz to kHz
        .{ .n = 1_000_000, .d = 1_000, .expected = 1_000 },
        .{ .n = 8_000_000, .d = 1_000, .expected = 8_000 },
        .{ .n = 16_000_000, .d = 1_000, .expected = 16_000 },
        .{ .n = 24_000_000, .d = 1_000, .expected = 24_000 },
        .{ .n = 48_000_000, .d = 1_000, .expected = 48_000 },
        .{ .n = 96_000_000, .d = 1_000, .expected = 96_000 },
        .{ .n = 144_000_000, .d = 1_000, .expected = 144_000 },
    };

    for (tests) |t| {
        const actual = divOptimized(t.n, t.d);
        try std.testing.expectEqual(t.expected, actual);
    }
}
