const std = @import("std");
const config = @import("config");
const hal = @import("hal");
const svd = @import("svd");

pub fn main() !void {
    const clock = hal.clock.setOrGet(.hsi_max);
    hal.delay.init(clock);

    hal.debug.sdi_print.init();
    const console_writer = hal.debug.sdi_print.writer();
    // If you want to use the UART for logging, you can replace SDI print with:
    // const USART1 = hal.Uart.init(.USART1, .{ .mode = .tx });
    // USART1.configureBaudRate(.{
    //     .peripheral_clock = switch (config.chip.series) {
    //         .ch32v003 => clock.hb,
    //         else => clock.pb2,
    //     },
    //     .baud_rate = 115_200,
    // });
    // const console_writer = USART1.writer();

    // ADC.
    const RCC = svd.peripherals.RCC;
    const ADC1 = svd.peripherals.ADC1;

    RCC.CFGR0.modify(.{ .ADCPRE = 0 });
    RCC.APB2PCENR.modify(.{ .ADC1EN = 1 });

    // ADC pin. A7 - PD4.
    const adc_pin = hal.Pin.init(.GPIOD, 4);
    hal.port.enable(adc_pin.port);
    adc_pin.asInput(.analog);

    // Reset ADC.
    RCC.APB2PRSTR.write(.{ .ADC1RST = 1 });
    RCC.APB2PRSTR.write(.{ .ADC1RST = 0 });

    // ADC1 regular sequence length.
    // 0000-1111: 1-16 conversions.
    ADC1.RSQR1.write(.{ .L = 0 });
    ADC1.RSQR2.write(.{});
    // ADC1 regular sequence: 0-9.
    // Set channel 7 as the first channel to be converted.
    ADC1.RSQR3.write(.{ .SQ1 = 7 });

    // Sample time configuration for channels:
    // 000: 3 cycles; 001: 9 cycles.
    // 010: 15 cycles; 011: 30 cycles.
    // 100: 43 cycles; 101:57 cycles.
    // 110: 73 cycles; 111: 241 cycles.
    ADC1.SAMPTR2.write(.{ .SMP7 = 0b111 });

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

    // Set SWSTART software trigger.
    ADC1.CTLR2.modify(.{ .EXTSEL = 0b111 });

    var buf: [10]u8 = undefined;
    while (true) {
        // Start.
        ADC1.CTLR2.modify(.{ .SWSTART = 1 });

        // Wait.
        while (ADC1.STATR.read().EOC == 0) {
            asm volatile ("" ::: .{ .memory = true });
        }

        // Result.
        const v: u16 = @truncate(ADC1.RDATAR.raw);

        const fmt = [_][]const u8{ "ADC: ", intToStr(&buf, v), "\n" };
        for (fmt) |s| {
            _ = try console_writer.write(s);
        }

        hal.delay.ms(200);
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
