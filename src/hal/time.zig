const std = @import("std");
const builtin = @import("builtin");
const config = @import("config");
const svd = @import("svd");

const hal = @import("hal.zig");
const PFIC = svd.peripherals.PFIC;

const SysTicksPer = packed struct(u32) {
    us: u8 = 0, // 1 - 144
    ms: u24 = 0, // 1_000 - 144_000
};
var systicks_per = SysTicksPer{};
var systick_millis: u32 = 0;

/// Enable SysTick timer and initialize dividers for the given clock.
pub fn init(clock: hal.clock.Clocks) void {
    comptime {
        if (!isEnabledInterrupt()) {
            @compileError(
                \\SysTick interrupt handler should be defined to `hal.time.sysTickHandler`.
                \\Add to your main file:
                \\    pub const interrupts: hal.interrupts.VectorTable = .{
                \\        .SysTick = hal.time.sysTickHandler,
                \\    };
            );
        }
    }

    systicks_per.us = @truncate(divOptimized(clock.hb, 1_000_000));
    systicks_per.ms = @truncate(divOptimized(clock.hb, 1_000));

    PFIC.STK_CTLR.raw = 0;
    // Reset the Count Register.
    PFIC.STK_CNTL.raw = 0;
    // Set the compare register to trigger once per millisecond.
    PFIC.STK_CMPLR.raw = systicks_per.ms - 1;
    // Enable SysTick timer.
    PFIC.STK_CTLR.write(.{
        // Enable SysTick.
        .STE = 1,
        // Enable counter interrupt.
        .STIE = 1,
        // HCLK/1 for time base.
        .STCLK = 1,
    });

    // Enable SysTick interrupt.
    hal.interrupts.enable(.SysTick);
}

pub fn isEnabledInterrupt() bool {
    const root = @import("root");
    if (!@hasDecl(root, "interrupts")) {
        return false;
    }

    return root.interrupts.SysTick == sysTickHandler;
}

pub fn sysTickHandler() callconv(hal.interrupts.call_conv) void {
    PFIC.STK_CMPLR.raw +%= systicks_per.ms;

    // Clear the trigger state for the next interrupt.
    PFIC.STK_SR.modify(.{ .CNTIF = 0 });

    // Increment the milliseconds count
    systick_millis +%= 1;
}

pub inline fn ticks() u32 {
    return PFIC.STK_CNTL.raw;
}

// micros rolls over every ~89.5 seconds if cpu frequency is 48MHz.
pub inline fn micros() u32 {
    return ticks() / systicks_per.us;
}

pub inline fn millis() u32 {
    return systick_millis;
}

pub const delay = struct {
    pub inline fn init(_: hal.clock.Clocks) void {}

    /// Delay in SysTick clock cycles.
    pub inline fn ticks(n: u32) void {
        const end = PFIC.STK_CNTL.raw +% n;

        while (diffTime(PFIC.STK_CNTL.raw, end) < 0) {
            asm volatile ("" ::: .{ .memory = true });
        }
    }

    /// Delay in microseconds. Max value is 65_535.
    pub inline fn us(n: u16) void {
        const start = PFIC.STK_CNTL.raw;
        const ticks_count: u32 = n * @as(u32, @intCast(systicks_per.us));
        const end = start +% ticks_count;

        while (diffTime(PFIC.STK_CNTL.raw, end) < 0) {
            asm volatile ("" ::: .{ .memory = true });
        }
    }

    /// Delay in milliseconds.
    pub inline fn ms(n: u32) void {
        const end = millis() +% n;

        while (diffTime(millis(), end) < 0) {
            hal.interrupts.wait();
        }
    }
};

pub const Duration = union(enum) {
    ticks: u32,
    us: u16,
    ms: u32,
};

pub const Deadline = struct {
    deadline: ?Duration,

    pub fn init(timeout: ?Duration) Deadline {
        comptime {
            if (!isEnabledInterrupt()) {
                @compileError(
                    \\`hal.time` module should be initialized with `hal.time.init()` before using deadline.
                );
            }
        }

        const tm = timeout orelse return .{ .deadline = null };

        const time = switch (tm) {
            .ticks => |t| Duration{ .ticks = ticks() +% t },
            .us => |us| Duration{ .us = @as(u16, @truncate(micros())) +% us },
            .ms => |ms| Duration{ .ms = millis() +% ms },
        };

        return .{ .deadline = time };
    }

    pub fn isReached(self: Deadline) bool {
        const time = self.deadline orelse return false;
        const diff = switch (time) {
            .ticks => |t| diffTime(ticks(), t),
            .us => |us| diffTime(micros(), us),
            .ms => |ms| diffTime(millis(), ms),
        };

        return diff >= 0;
    }
};

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
