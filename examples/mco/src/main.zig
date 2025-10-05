const std = @import("std");
const config = @import("config");
const hal = @import("hal");

pub fn main() !void {
    // Set up the system clock to use HSI at max frequency for MCU.
    _ = hal.clock.setOrGet(.hsi_max);

    // MCO pin:
    // For CH32V003: PC4
    // For CH32V103, CH32V20x and CH32V30x: PA8
    hal.clock.mco(.sys);

    while (true) {
        asm volatile ("" ::: .{ .memory = true });
    }
}
