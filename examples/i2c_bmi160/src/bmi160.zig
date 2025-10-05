const std = @import("std");
const hal = @import("hal");

// https://github.com/LiquidCGS/FastIMU/blob/main/src/F_BMI160.cpp
pub fn setup(I2C1: hal.I2c, addr: u7, deadline: hal.time.Deadline) !void {
    const BMI160_CHIP_ID = 0x00;
    const BMI160_CHIP_ID_DEFAULT_VALUE = 0xD1;

    const BMI160_RA_CMD = 0x7E;

    const BMI160_GYR_RANGE = 0x43;
    const BMI160_GYR_CONF = 0x42;
    const BMI160_ACC_RANGE = 0x41;
    const BMI160_ACC_CONF = 0x40;

    // Ping device example.
    I2C1.masterTransferBlocking(.from7(addr), null, null, deadline) catch |err| switch (err) {
        error.AckFailure => return error.I2CDeviceNotFound,
        else => return err,
    };

    // Request CHIP_ID.
    var chip_id_buf = [_]u8{0x00};
    try I2C1.masterTransferBlocking(.from7(addr), &.{BMI160_CHIP_ID}, &chip_id_buf, deadline);
    // Check CHIP_ID.
    if (chip_id_buf[0] != BMI160_CHIP_ID_DEFAULT_VALUE) {
        return error.I2CDeviceNotBMI160;
    }

    // Soft-reset device.
    try I2C1.masterTransferBlocking(.from7(addr), &.{ BMI160_RA_CMD, 0xB6 }, null, deadline);
    hal.delay.ms(100);

    // Power up the accelerometer
    try I2C1.masterTransferBlocking(.from7(addr), &.{ BMI160_RA_CMD, 0x11 }, null, deadline);
    hal.delay.ms(100);

    // Power up the gyroscope
    try I2C1.masterTransferBlocking(.from7(addr), &.{ BMI160_RA_CMD, 0x15 }, null, deadline);
    hal.delay.ms(100);

    // Set up full-scale range for the accelerometer. 0x0C = 16g
    try I2C1.masterTransferBlocking(.from7(addr), &.{ BMI160_ACC_RANGE, 0x0C }, null, deadline);
    // Set up full-scale range for the gyroscope. 0x00 = 2000dps
    try I2C1.masterTransferBlocking(.from7(addr), &.{ BMI160_GYR_RANGE, 0x00 }, null, deadline);

    // Set Accel ODR to 400hz, BWP mode to Oversample 4, LPF of ~40.5hz
    try I2C1.masterTransferBlocking(.from7(addr), &.{ BMI160_ACC_CONF, 0x0A }, null, deadline);
    // Set Gyro ODR to 400hz, BWP mode to Oversample 4, LPF of ~34.15hz
    try I2C1.masterTransferBlocking(.from7(addr), &.{ BMI160_GYR_CONF, 0x0A }, null, deadline);
}

pub const ImuData = packed struct {
    gyr_x: i16,
    gyr_y: i16,
    gyr_z: i16,
    acc_x: i16,
    acc_y: i16,
    acc_z: i16,

    pub fn format(self: ImuData, out_stream: *std.Io.Writer) !void {
        _ = try out_stream.print("gyro: {d:>5} | {d:>5} | {d:>5} |     accel: {d:>5} | {d:>5} | {d:>5}", .{
            self.gyr_x,
            self.gyr_y,
            self.gyr_z,
            self.acc_x,
            self.acc_y,
            self.acc_z,
        });
    }
};

pub fn readImuData(I2C1: hal.I2c, addr: u7, imu_data_ret: *ImuData, deadline: hal.time.Deadline) !void {
    // const a_res = 16.0 / 32768.0; // value for full range (16g) readings
    // const g_res = 2000.0 / 32768.0; // value for full range (2000dps) readings

    // Read the 12 raw data registers into data array
    const BMI160_GYR_X_L = 0x0C;
    // Read directly to the structure, thanks `std.mem.asBytes`.
    try I2C1.masterTransferBlocking(.from7(addr), &.{BMI160_GYR_X_L}, std.mem.asBytes(imu_data_ret), deadline);
}
