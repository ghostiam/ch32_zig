const std = @import("std");
const config = @import("config");
const hal = @import("hal");
const ch32 = @import("ch32");

const bmi160 = @import("bmi160.zig");

pub const ch32_options: ch32.Options = .{
    .log_level = .debug,
    .logFn = hal.log.logFn,
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

    hal.debug.sdi_print.init();
    const console_writer = &hal.debug.sdi_print.writer;
    // If you want to use the UART for logging, you can replace SDI print with:
    // var USART1 = hal.Uart.init(.USART1, .{ .mode = .tx });
    // USART1.configureBaudRate(.{
    //     .peripheral_clock = switch (config.chip.series) {
    //         .ch32v003 => clock.hb,
    //         else => clock.pb2,
    //     },
    //     .baud_rate = 115_200,
    // });
    // var usart1_writer = USART1.writer(.{ .ms = 1 });
    // const console_writer = &usart1_writer.interface;

    hal.log.setWriter(console_writer);

    // Configure I2C.
    // The default pins are:
    // For CH32V003: SCL: PC2, SDA: PC1.
    // For CH32V103, CH32V20x and CH32V30x: SCL: PB6, SDA: PB7.
    const I2C1 = hal.I2c.init(.I2C1, .{
        // You can use the default pins for the selected I2C by leaving the field null or remap it to other pins.
        // For example, to use the remapped pins for I2C1 on CH32V003:
        // .pins = hal.I2c.Pins.i2c1.scl_pd1_sda_pd0,
    });
    // You can deinitialize the I2C peripheral if you don't need it anymore.
    defer I2C1.deinit();

    // Runtime baud rate configuration.
    try I2C1.configureBaudRate(.{
        .peripheral_clock = switch (config.chip.series) {
            .ch32v003 => clock.hb,
            else => clock.pb2,
        },
        .speed = 400_000,
        .duty_cycle = .@"16/9",
    });

    // Can be 0x68 or 0x69.
    const BMI160_I2C_ADDR = 0x69;

    const timeout = hal.time.Duration{ .ms = 1000 };
    bmi160.setup(I2C1, BMI160_I2C_ADDR, .init(timeout)) catch |err| switch (err) {
        error.I2CDeviceNotFound => {
            std.log.err("Device on address 0x{X:0>2} not found", .{BMI160_I2C_ADDR});
            return err;
        },
        error.I2CDeviceNotBMI160 => {
            std.log.err("Device on address 0x{X:0>2} is not BMI160", .{BMI160_I2C_ADDR});
            return err;
        },
        else => return err,
    };

    var imu_data: bmi160.ImuData = undefined;
    while (true) {
        try bmi160.readImuData(I2C1, BMI160_I2C_ADDR, &imu_data, .init(timeout));

        std.log.info("{f}", .{imu_data});

        hal.delay.ms(50);
    }
}
