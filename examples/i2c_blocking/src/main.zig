const std = @import("std");
const config = @import("config");
const hal = @import("hal");

const address: hal.I2c.Address = .from7(0x42);

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

    // const console_writer = if (config.i2c_mode == .master) &usart1_writer.interface else &hal.debug.sdi_print.writer;

    // Configure I2C.
    // The default pins are:
    // For CH32V003: SCL: PC2, SDA: PC1.
    // For CH32V103, CH32V20x and CH32V30x: SCL: PB6, SDA: PB7.
    const I2C1 = hal.I2c.init(.I2C1, .{
        .mode = if (config.i2c_mode == .master)
            .master
        else
            .{ .slave = .{ .own_address1 = address } },

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

    const i2c_master_data = "Hello";
    const i2c_slave_data = "World";
    const i2c_send = if (config.i2c_mode == .master) i2c_master_data else i2c_slave_data;
    const i2c_recv_expected = if (config.i2c_mode == .master) i2c_slave_data else i2c_master_data;

    var buf: [32]u8 = undefined;
    while (true) {
        buf = [_]u8{0} ** buf.len;

        if (config.i2c_mode == .master) {
            hal.delay.ms(250);

            try console_writer.print("I2C master send: {s}\n", .{i2c_send});

            // Send and receive data from the slave.
            I2C1.masterTransferBlocking(address, i2c_send, buf[0..i2c_recv_expected.len], hal.time.Deadline.init(null)) catch |err| {
                try console_writer.print("I2C master transfer error: {s}\n", .{@errorName(err)});
            };

            const n = i2c_recv_expected.len;
            try console_writer.print("I2C master recv({d}): {s}\n", .{ n, buf[0..i2c_recv_expected.len] });
        } else {
            try console_writer.writeAll("I2C slave waiting for master...\n");

            // Wait for the master to send valid address and direction.
            const dir = I2C1.slaveAddressMatchingBlocking(hal.time.Deadline.init(null)) catch |err| {
                try console_writer.print("I2C slave address matching error: {s}\n", .{@errorName(err)});
                continue;
            };

            switch (dir) {
                .receive => {
                    try console_writer.writeAll("I2C slave receive request\n");

                    // Receive data from the master.
                    const n = I2C1.slaveReadBlocking(&buf, hal.time.Deadline.init(null)) catch |err| blk: {
                        try console_writer.print("I2C slave read error: {s}\n", .{@errorName(err)});
                        break :blk 0;
                    };

                    try console_writer.print("I2C slave recv({d}): {s}\n", .{ n, buf[0..n] });
                },
                .transmit => {
                    try console_writer.writeAll("I2C slave transmit request\n");

                    try console_writer.print("I2C slave send: {s}\n", .{i2c_slave_data});

                    // Send data to the master.
                    const n = I2C1.slaveWriteBlocking(i2c_slave_data, hal.time.Deadline.init(null)) catch |err| blk: {
                        try console_writer.print("I2C slave write error: {s}\n", .{@errorName(err)});
                        break :blk 0;
                    };

                    try console_writer.print("I2C slave send({d}): {s}\n", .{ n, i2c_slave_data[0..n] });
                },
            }
        }
    }
}
