const std = @import("std");
const config = @import("config");
const hal = @import("hal");
const ch32 = @import("ch32");

pub const ch32_options: ch32.Options = .{
    .log_level = .debug,
    // When a logger function other than nopFn is set,
    // it will be used to output the panic message.
    .logFn = hal.log.logFn,
    // Also we can set the panic options with a LED pin to blink on panic.
    .panic_options = .{
        .led = switch (config.chip.series) {
            .ch32v003 => hal.Pin.init(.GPIOC, 0),
            .ch32v103 => hal.Pin.init(.GPIOC, 0),
            .ch32v20x => hal.Pin.init(.GPIOA, 15), // nanoCH32V203 board
            .ch32v30x => hal.Pin.init(.GPIOA, 3), // nanoCH32V305 board
            // else => @compileError("Unsupported chip series"),
        },
    },
};

// Connect and reset:
// zig build minichlink -- -T
// Connect and resume:
// zig build minichlink -- -e -T
pub fn main() !void {
    hal.delay.init(.default);

    // Enable SDI print for logging.
    hal.debug.sdi_print.init();
    hal.log.setWriter(&hal.debug.sdi_print.writer);

    std.log.info("Hello, World!", .{});

    var counter: u32 = 0;
    while (true) {
        counter += 1;

        // Print counter to UART.
        std.log.info("Counter: {}", .{counter});

        if (counter == 10) {
            // Trigger a panic.
            @panic("Counter reached 10");
        }

        hal.delay.ms(1000);
    }
}
