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

pub const interrupts: hal.interrupts.VectorTable = .{
    .SysTick = hal.time.sysTickHandler,
};

pub fn main() !void {
    const clock = hal.clock.setOrGet(.hsi_max);
    hal.time.init(clock);
    hal.delay.init(clock);

    // Configure UART.
    // The default pins are:
    // For CH32V003: TX: PD5, RX: PD6.
    // For CH32V103, CH32V20x and CH32V30x: TX: PA9, RX: PA10.
    var USART1 = hal.Uart.init(.USART1, .{
        // For this example we will use only transmit mode.
        // Default is .tx_rx.
        .mode = .tx,
        // You can use the default pins for the selected USART by leaving the field null or remap it to other pins.
        // For example, to use the remapped pins for USART1 on CH32V003:
        // .pins = hal.Uart.Pins.usart1.tx_pd0_rx_pd1,
    });
    // Runtime baud rate configuration.
    USART1.configureBaudRate(.{
        .peripheral_clock = switch (config.chip.series) {
            .ch32v003 => clock.hb,
            else => clock.pb2,
        },
        .baud_rate = 115_200,
    });
    var writer = USART1.writer(.{ .ms = 1 });
    hal.log.setWriter(&writer.interface);

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
