const std = @import("std");
const config = @import("config");
const hal = @import("hal");
const svd = @import("svd");

// const AdcResults = packed struct {
//     a0_pa2: u16 = 0,
//     a1_pa1: u16 = 0,
//     a2_pc4: u16 = 0,
//     a3_pd2: u16 = 0,
//     a4_pd3: u16 = 0,
//     a5_pd5: u16 = 0,
//     a6_pd6: u16 = 0,
//     a7_pd4: u16 = 0,
// };
// var adc_results: AdcResults = .{};
var adc_results = [_]u16{0} ** 8;

pub fn main() !void {
    const clock = hal.clock.setOrGet(.hsi_max);
    hal.delay.init(clock);

    hal.debug.sdi_print.init();
    const console_writer = hal.debug.sdi_print;
    // If you want to use the UART for logging, you can replace SDI print with:
    // WARNING: TX pin was remapped to PD0 because PD5 is used as ADC A5 channel.
    // var USART1 = hal.Uart.init(.USART1, .{
    //     .mode = .tx,
    //     .pins = hal.Uart.Pins.usart1.tx_pd0_rx_pd1,
    // });
    // USART1.configureBaudRate(.{
    //     .peripheral_clock = switch (config.chip.series) {
    //         .ch32v003 => clock.hb,
    //         else => clock.pb2,
    //     },
    //     .baud_rate = 115_200,
    // });
    // var usart1_writer = USART1.writer(.{ .ms = 1 });
    // const console_writer = &usart1_writer.interface;

    // ADC.
    const RCC = svd.peripherals.RCC;
    const ADC1 = svd.peripherals.ADC1;

    RCC.CFGR0.modify(.{ .ADCPRE = 0 });
    RCC.APB2PCENR.modify(.{ .ADC1EN = 1 });

    // ADC pins for CH32V003.
    const pins = [_]hal.Pin{
        // A0 - PA2
        hal.Pin.init(.GPIOA, 2),
        // A1 - PA1
        hal.Pin.init(.GPIOA, 1),
        // A2 - PC4
        hal.Pin.init(.GPIOC, 4),
        // A3 - PD2
        hal.Pin.init(.GPIOD, 2),
        // A4 - PD3
        hal.Pin.init(.GPIOD, 3),
        // A5 - PD5
        hal.Pin.init(.GPIOD, 5),
        // A6 - PD6
        hal.Pin.init(.GPIOD, 6),
        // A7 - PD4
        hal.Pin.init(.GPIOD, 4),
    };
    for (pins) |adc_pin| {
        hal.port.enable(adc_pin.port);
        adc_pin.asInput(.analog);
    }

    // Reset ADC.
    RCC.APB2PRSTR.write(.{ .ADC1RST = 1 });
    RCC.APB2PRSTR.write(.{ .ADC1RST = 0 });

    // ADC1 regular sequence length.
    // 0000-1111: 1-16 conversions.
    ADC1.RSQR1.write(.{ .L = @truncate(pins.len - 1) });
    // ADC1 regular sequence: 0-9.
    ADC1.RSQR3.write(.{ .SQ1 = 0, .SQ2 = 1, .SQ3 = 2, .SQ4 = 3, .SQ5 = 4, .SQ6 = 5 });
    ADC1.RSQR2.write(.{ .SQ7 = 6, .SQ8 = 7 });

    // Sample time configuration for channels:
    // 000: 3 cycles; 001: 9 cycles.
    // 010: 15 cycles; 011: 30 cycles.
    // 100: 43 cycles; 101: 57 cycles.
    // 110: 73 cycles; 111: 241 cycles.
    const adc_cycles: u4 = 0b111;
    ADC1.SAMPTR2.write(.{
        .SMP0 = adc_cycles,
        .SMP1 = adc_cycles,
        .SMP2 = adc_cycles,
        .SMP3 = adc_cycles,
        .SMP4 = adc_cycles,
        .SMP5 = adc_cycles,
        .SMP6 = adc_cycles,
        .SMP7 = adc_cycles,
    });

    // Enable ADC.
    ADC1.CTLR2.modify(.{ .ADON = 1 });

    // Reset calibration
    ADC1.CTLR2.modify(.{ .RSTCAL = 1 });
    while (ADC1.CTLR2.read().RSTCAL == 1) {
        asm volatile ("" ::: .{ .memory = true });
    }

    // Start calibration
    ADC1.CTLR2.modify(.{ .CAL = 1 });
    while (ADC1.CTLR2.read().CAL == 1) {
        asm volatile ("" ::: .{ .memory = true });
    }

    _ = try console_writer.write("ADC calibration done\n");

    // Enable DMA
    const dma_adc_ch = hal.dma.Channel{ .dma1 = .channel1 };
    dma_adc_ch.configure(.{
        .periph_ptr = @volatileCast(&ADC1.RDATAR),
        .mem_ptr = @constCast(&adc_results),
        .direction = .periph_to_mem,
        .data_length = pins.len,
        .periph_inc = false,
        .mem_inc = true,
        .mem_data_size = .half_word,
        .periph_data_size = .half_word,
        .mode = .circular,
        .priority = .very_high,
        .mem_to_mem = false,
    });
    dma_adc_ch.enable();

    ADC1.CTLR1.modify(.{ .SCAN = 1 });
    ADC1.CTLR2.modify(.{
        .CONT = 1,
        .DMA = 1,
        // Set SWSTART software trigger.
        .EXTSEL = 0b111,
    });

    // Start.
    ADC1.CTLR2.modify(.{ .SWSTART = 1 });

    while (true) {
        // Print ADC results.
        _ = try console_writer.write("ADC:\n");
        for (adc_results, 0..) |v, i| {
            var buf_id: [1]u8 = undefined; // 0-7
            var buf_value: [4]u8 = undefined; // 0-1023

            const fmt = [_][]const u8{ "A", intToStr(&buf_id, i), ": ", intToStr(&buf_value, v), "\n" };
            for (fmt) |s| {
                _ = try console_writer.write(s);
            }
        }
        _ = try console_writer.write("\n");

        hal.delay.ms(250);
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
