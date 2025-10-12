const std = @import("std");
const config = @import("config");

const cpu = @import("cpu.zig");
const interrupts = @import("interrupts.zig");
const Pin = @import("Pin.zig");

pub const Options = struct {
    /// The LED pin to use for panic indication.
    /// If not set, the panic handler will just hang.
    led: ?Pin = null,
};

/// Returns a panic handler that will print the registers and hang.
/// If configured, the LED will blink with a pattern of 3 long and 3 short.
pub fn InitLog(comptime o: Options) type {
    return std.debug.FullPanic(struct {
        fn panic(message: []const u8, _: ?usize) noreturn {
            printRegisters(message, @returnAddress());

            if (o.led) |led| {
                hangWithLed(led);
            } else {
                hang();
            }
        }
    }.panic);
}

/// Returns a silent panic handler.
/// If configured, the LED will blink with a pattern of 3 long and 3 short.
pub fn InitSilent(comptime o: Options) type {
    return std.debug.FullPanic(struct {
        fn panic(_: []const u8, _: ?usize) noreturn {
            if (o.led) |led| {
                hangWithLed(led);
            } else {
                hang();
            }
        }
    }.panic);
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

inline fn printRegisters(message: []const u8, return_address: ?usize) void {
    std.log.err(
        \\PANIC: {s}
        \\Registers dump:
        \\    MSTATUS: 0x{X:0>8}
        \\    MEPC: 0x{X:0>8}
        \\    MCAUSE: 0x{X:0>8}
        \\    MTVAL: 0x{X:0>8}
        \\    MSCRATCH: 0x{X:0>8}
    , .{
        message,
        cpu.csr.mstatus.readRaw(),
        cpu.csr.mepc.readRaw(),
        cpu.csr.mcause.readRaw(),
        cpu.csr.mtval.readRaw(),
        cpu.csr.mscratch.readRaw(),
    });

    // Max 10 hex addresses.
    // 10 * (addr_len + 0x + space).
    var buf: [10 * (8 + 2 + 1)]u8 = undefined;
    var w: SimpleBufWriter = .init(&buf);
    var index: usize = 0;
    var iter = std.debug.StackIterator.init( return_address, null);
    while (iter.next()) |address| : (index += 1) {
        w.printAddress(address);
        // Avoid infinite loop.
        if (index >= 10) break;
    }

    if (w.end > 0) {
        std.log.err("Run for stack trace:", .{});
        std.log.err("addr2line {s}-e <elf>", .{w.buffered()});
    }
}

inline fn dummyLoop(count: u32) void {
    var i: u32 = 0;
    while (i < count) : (i += 1) {
        asm volatile ("" ::: .{ .memory = true });
    }
}

const SimpleBufWriter = struct {
    buffer: []u8,
    end: usize = 0,

    fn init(buffer: []u8) SimpleBufWriter {
        return .{ .buffer = buffer };
    }

    fn write(w: *SimpleBufWriter, data: []const u8) void {
        const dest = w.buffer[w.end..];
        const len = @min(data.len, dest.len);
        @memcpy(dest[0..len], data[0..len]);
        w.end += len;
    }

    fn printAddress(w: *SimpleBufWriter, address: usize) void {
        w.write("0x");

        const charset = "0123456789ABCDEF";
        const len = @sizeOf(@TypeOf(address));
        var i: usize = len - 1;
        while (true) : (i -= 1) {
            const byte: u8 = @truncate(address >> @intCast(8 * i));

            w.write(&.{ charset[byte >> 4], charset[byte & 15] });

            if (i == 0) break;
        }

        w.write(" ");
    }

    pub fn buffered(w: *const SimpleBufWriter) []u8 {
        return w.buffer[0..w.end];
    }
};
