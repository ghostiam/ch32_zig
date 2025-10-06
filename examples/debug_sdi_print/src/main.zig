const std = @import("std");
const config = @import("config");
const hal = @import("hal");

// Connect and reset:
// zig build minichlink -- -T
// Connect and resume:
// zig build minichlink -- -e -T
pub fn main() !void {
    hal.delay.init(.default);

    // Enable SDI print for logging.
    hal.debug.sdi_print.init();

    _ = try hal.debug.sdi_print.write("Hello, World!\r\n");

    // Counter is 32 bits, so we need 10 bytes to store it,
    // because max value is 4294967295.
    var buf: [10]u8 = undefined;
    var counter: u32 = 0;
    while (true) {
        counter += 1;

        _ = try hal.debug.sdi_print.writeVec(&.{ "Counter: ", intToStr(&buf, counter), "\r\n" });

        hal.delay.ms(1000);
    }
}

fn intToStr(buf: []u8, value: u32) []u8 {
    var i: u32 = buf.len;
    var v: u32 = value;
    if (v == 0) {
        buf[0] = '0';
        return buf[0..1];
    }

    while (v > 0) : (v /= 10) {
        i -= 1;
        buf[i] = @as(u8, @truncate(v % 10)) + '0';
    }

    return buf[i..];
}
