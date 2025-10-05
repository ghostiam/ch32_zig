const std = @import("std");
const config = @import("config");
const hal = @import("hal");

pub fn main() !void {
    // Select LED pin based on chip series.
    const led = switch (config.chip.series) {
        .ch32v003 => hal.Pin.init(.GPIOC, 0),
        .ch32v103 => hal.Pin.init(.GPIOC, 0),
        .ch32v20x => hal.Pin.init(.GPIOA, 15), // nanoCH32V203 board
        .ch32v30x => hal.Pin.init(.GPIOA, 3), // nanoCH32V305 board
        // else => @compileError("Unsupported chip series"),
    };
    // hal.port.enable(led.port);
    // hal.port.disable(led.port);
    // or
    led.enablePort();

    led.asOutput(.{ .speed = .max_50mhz, .mode = .push_pull });

    while (true) {
        // const on = led.read();
        // led.write(!on);
        // or
        led.toggle();

        busyDelay(1000);
    }
}

inline fn busyDelay(comptime ms: u32) void {
    const cpu_frequency = hal.clock.Clocks.default.hb;
    const cycles_per_ms = cpu_frequency / 1_000;
    const loop_cycles = if (config.chip.series == .ch32v003) 4 else 3;
    const limit = cycles_per_ms * ms / loop_cycles;

    var i: u32 = 0;
    while (i < limit) : (i += 1) {
        asm volatile ("" ::: .{ .memory = true });
    }
}
