const std = @import("std");
const config = @import("config");
const hal = @import("hal");
const svd = @import("svd");

pub const interrupts: hal.interrupts.VectorTable = .{
    .DMA1_Channel4 = dma1Channel4Handler,
};

fn dma1Channel4Handler() callconv(hal.interrupts.call_conv) void {
    // Toggle the LED pin.
    led.toggle();

    // Clear the state for the next interrupt.
    hal.dma.Interrupt.clear(usart1_tx_dma_channel, .transfer_complete);
}

// Select LED pin based on chip series.
const led: hal.Pin = switch (config.chip.series) {
    .ch32v003 => hal.Pin.init(.GPIOC, 0),
    .ch32v103 => hal.Pin.init(.GPIOC, 0),
    .ch32v20x => hal.Pin.init(.GPIOA, 15), // nanoCH32V203 board
    .ch32v30x => hal.Pin.init(.GPIOA, 3), // nanoCH32V305 board
    // else => @compileError("Unsupported chip series"),
};

const usart1_tx_dma_channel = hal.dma.Channel{ .dma1 = .channel4 };

fn dmaWrite(msg: []const u8) void {
    // Disable DMA before set new message.
    hal.dma.Channel.disable(usart1_tx_dma_channel);
    // Set source and transfer length.
    hal.dma.Channel.setMemoryPtr(usart1_tx_dma_channel, msg.ptr, msg.len);
    // Enable DMA.
    hal.dma.Channel.enable(usart1_tx_dma_channel);
}

pub fn main() !void {
    const clock = hal.clock.setOrGet(.hsi_max);
    hal.delay.init(clock);

    // Enable the clock for the Led GPIO port and configure the pin.
    hal.port.enable(led.port);
    led.asOutput(.{ .speed = .max_50mhz, .mode = .push_pull });

    // Configure UART.
    // The default pins are:
    // For CH32V003: TX: PD5, RX: PD6.
    // For CH32V103, CH32V20x and CH32V30x: TX: PA9, RX: PA10.
    const USART1 = hal.Uart.init(.USART1, .{
        .mode = .tx,
        .dma = .tx,
    });
    // Runtime baud rate configuration.
    USART1.configureBaudRate(.{
        .peripheral_clock = switch (config.chip.series) {
            .ch32v003 => clock.hb,
            else => clock.pb2,
        },
        .baud_rate = 115_200,
    });

    // Configure DMA for USART1 TX.
    hal.dma.Channel.configure(usart1_tx_dma_channel, .{
        // Set USART1 TX peripheral address.
        .periph_ptr = @volatileCast(&svd.peripherals.USART1.DATAR),
        // Memory address will be set in dmaWrite.
        .mem_ptr = null,
        .direction = .mem_to_periphh,
        // Transfer length will be set in dmaWrite.
        .data_length = 0,
        .periph_inc = false,
        .mem_inc = true,
        .periph_data_size = .byte,
        .mem_data_size = .byte,
        .mode = .normal,
        .priority = .low,
        .mem_to_mem = false,
    });
    // Enable DMA interrupt when transfer is complete.
    hal.dma.Interrupt.enable(usart1_tx_dma_channel, .transfer_complete);

    // Counter is 32 bits, so we need 10 bytes to store it,
    // because max value is 4294967295.
    var buf: [10]u8 = undefined;
    var msg_buf: [32]u8 = undefined;
    var w = std.Io.fixedBufferStream(&msg_buf);
    const prefix = "Counter: ";
    const suffix = "\r\n";

    var counter: u32 = 0;
    while (true) {
        counter += 1;

        w.reset();

        // Convert counter to string.
        const counter_str = intToStr(&buf, counter);
        // Build message.
        _ = try w.write(prefix);
        _ = try w.write(counter_str);
        _ = try w.write(suffix);

        // Print counter to UART using DMA.
        dmaWrite(w.getWritten());

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
