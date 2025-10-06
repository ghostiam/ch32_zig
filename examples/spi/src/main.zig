const std = @import("std");
const config = @import("config");
const hal = @import("hal");
const sdi_print = hal.debug.sdi_print;

pub const interrupts: hal.interrupts.VectorTable = .{
    .SysTick = hal.time.sysTickHandler,
};

pub fn main() !void {
    // Enable SDI print for logging.
    sdi_print.init();

    const clock = hal.clock.setOrGet(.hsi_max);
    hal.time.init(clock);

    // Configure SPI.
    // The default pins are:
    // For CH32V003: SCK: PC5, MISO: PC7, MOSI: PC6, NSS: PC1.
    // For CH32V103, CH32V20x and CH32V30x: SCK: PA5, MISO: PA6, MOSI: PA7, NSS: PA4.
    const SPI1 = try hal.Spi.init(.SPI1, .{
        .mode = if (config.spi_mode == .master) .master else .slave,
        .cpol = .high,
        .cpha = .second_edge,
        // You can use the default pins for the selected SPI by leaving the field null or remap it to other pins.
        // For example, to use the remapped pins for SPI1 on CH32V003:
        // .pins = hal.Spi.Pins.spi1.sck_pc5_miso_pc7_mosi_pc6_nss_pc0,
        // or to use the default pins with software NSS on any pin:
        // .pins = hal.Spi.Pins.softwareNss(hal.Spi.Pins.spi1.default, hal.Pin.init(.GPIOC, 1)),
    });
    // You can deinitialize the SPI peripheral if you don't need it anymore.
    defer SPI1.deinit();

    // Runtime baud rate configuration.
    SPI1.configureBaudRate(.{
        .peripheral_clock = switch (config.chip.series) {
            .ch32v003 => clock.hb,
            else => clock.pb2,
        },
        .baud_rate = 750_000,
    });

    const spi_master_data = "Hello";
    const spi_slave_data = "World";
    const spi_send = if (config.spi_mode == .master) spi_master_data else spi_slave_data;
    const spi_recv_expected = if (config.spi_mode == .master) spi_slave_data else spi_master_data;

    var buf: [spi_recv_expected.len]u8 = undefined;
    while (true) {
        _ = try sdi_print.writeVec(&.{ "SPI send: ", spi_send, "\r\n" });

        SPI1.transferBlocking(u8, spi_send, &buf, hal.time.Deadline.init(null)) catch {};

        _ = try sdi_print.writeVec(&.{ "SPI recv: ", &buf, "\r\n" });

        hal.delay.ms(100);
    }
}
