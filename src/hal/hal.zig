const config = @import("config");

pub const Pin = @import("Pin.zig");
pub const port = @import("port.zig");
pub const Uart = @import("Uart.zig");
pub const Spi = @import("Spi.zig");
pub const I2c = @import("I2c.zig");
pub const debug = @import("debug.zig");
pub const log = @import("log.zig");
pub const panic = @import("panic.zig");
pub const cpu = @import("cpu.zig");
pub const interrupts = @import("interrupts.zig");
pub const time = @import("time.zig");
pub const delay = if (time.isEnabledInterrupt()) time.delay else @import("delay.zig");
pub const dma = @import("dma.zig");

pub const clock = switch (config.chip.series) {
    .ch32v003 => @import("clock/ch32v003.zig"),
    .ch32v20x, .ch32v30x => @import("clock/ch32v30x.zig"),
    // TODO: implement other chips
    else => @compileError("Unsupported chip series"),
};

comptime {
    @import("std").testing.refAllDecls(@This());
}
