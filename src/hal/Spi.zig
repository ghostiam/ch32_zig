const std = @import("std");
const config = @import("config");
const svd = @import("svd");

const time = @import("time.zig");
const Pin = @import("Pin.zig");

pub const Config = struct {
    /// SPI mode. Master or slave.
    mode: Mode = .master,
    /// Unidirectional or bidirectional data mode.
    direction: Direction = .two_lines_full_duplex,
    /// Clock polarity.
    cpol: CPOL = .low,
    /// Clock active edge for the bit capture.
    cpha: CPHA = .first_edge,
    /// Baud Rate prescaler value which will be
    /// used to configure the transmit and receive SCK clock.
    /// Can be set in runtime using configureBaudRate method.
    baud_rate: ?BaudRate = null,
    /// Whether data transfers start from MSB bit.
    first_bit: FirstBit = .msb,
    /// SPI data size.
    data_size: DataSize = .eight_bits,
    /// SPI pins. If not provided, default pins will be used.
    pins: ?Pins = null,
};

pub const Mode = enum(u1) {
    master,
    slave,
};

pub const DataSize = enum(u1) {
    eight_bits = 0, // 8
    sixteen_bits = 1, // 16
};

pub const Direction = enum {
    two_lines_full_duplex,
    two_lines_rx_only,
    one_line_rx,
    one_line_tx,
};

pub const CPOL = enum(u1) {
    low = 0,
    high = 1,
};

pub const CPHA = enum(u1) {
    first_edge = 0,
    second_edge = 1,
};

pub const BaudRate = struct {
    peripheral_clock: u32,
    baud_rate: u32,

    fn calculate(self: BaudRate) BaudRatePrescaler {
        if (self.peripheral_clock == 0 or self.baud_rate == 0) {
            return .div64;
        }

        const div = self.peripheral_clock / self.baud_rate;
        if (div <= 2) return .div2;
        if (div <= 4) return .div4;
        if (div <= 8) return .div8;
        if (div <= 16) return .div16;
        if (div <= 32) return .div32;
        if (div <= 64) return .div64;
        if (div <= 128) return .div128;
        if (div <= 256) return .div256;

        return .div256;
    }
};

pub const BaudRatePrescaler = enum(u3) {
    div2 = 0b000,
    div4 = 0b001,
    div8 = 0b010,
    div16 = 0b011,
    div32 = 0b100,
    div64 = 0b101,
    div128 = 0b110,
    div256 = 0b111,
};

pub const BiDirectionalMode = enum(u1) {
    rx = 0,
    tx = 1,
};

pub const FirstBit = enum(u1) {
    msb = 0,
    lsb = 1,
};

const chip = switch (config.chip.series) {
    .ch32v003 => @import("spi/ch32v003.zig"),
    .ch32v20x, .ch32v30x => @import("spi/ch32v20x_30x.zig"),
    // TODO: implement other chips
    else => @compileError("Unsupported chip series"),
};

pub const Pins = chip.Pins;

const rcc = chip.rcc;

pub const Timeout = error{
    Timeout,
};

pub const ConfigureError = error{
    ModeFault,
};

const SPI = @This();

reg: *volatile svd.registers.SPI,
sw_nss: ?Pin,
has_hardware_nss: bool,

pub fn init(comptime uart: svd.peripherals.SPI, comptime cfg: Config) ConfigureError!SPI {
    if (cfg.pins) |pins| {
        comptime checkPins(uart.get(), pins);
    }

    const pins = cfg.pins orelse Pins.defaultFor(uart.get());

    // Software NSS pin allowed only in master mode.
    const sw_nss: ?Pin = if (cfg.mode == .master and !pins.isHardwareNss()) blk: {
        break :blk if (pins.nss) |nss| nss.pin else null;
    } else null;

    const self = SPI{
        .reg = uart.get(),
        .sw_nss = sw_nss,
        .has_hardware_nss = pins.isHardwareNss(),
    };

    self.reset();
    self.enable();
    self.configurePins(cfg, pins);
    self.configureCtrl(cfg);
    if (cfg.baud_rate) |baud_rate| {
        self.configureBaudRate(baud_rate);
    }
    try self.configureCheck();

    return self;
}

/// Deinitializes the SPI peripheral.
/// Disables and resets registers.
/// Note: GPIO pins will not be deinitialized when this function is called.
pub fn deinit(self: SPI) void {
    self.disable();
    self.reset();
}

fn configurePins(self: SPI, comptime cfg: Config, comptime pins: Pins) void {
    _ = self;
    if (pins.remap.has()) {
        // Alternate function I/O clock enable
        svd.peripherals.RCC.APB2PCENR.modify(.{ .AFIOEN = 1 });
        // Remap the pins.
        svd.peripherals.AFIO.PCFR1.modify(pins.remap.afio_pcfr1);
    }

    // TODO: add support bi-dir mode
    switch (cfg.mode) {
        .master => {
            if (pins.nss) |nss| {
                nss.pin.enablePort();
                nss.pin.asOutput(.{ .speed = .max_50mhz, .mode = if (nss.is_hardware) .alt_push_pull else .push_pull });
            }

            pins.sck.enablePort();
            pins.sck.asOutput(.{ .speed = .max_50mhz, .mode = .alt_push_pull });

            pins.miso.enablePort();
            pins.miso.asInput(.{ .pull = .up });

            pins.mosi.enablePort();
            pins.mosi.asOutput(.{ .speed = .max_50mhz, .mode = .alt_push_pull });
        },
        .slave => {
            if (pins.nss) |nss| {
                nss.pin.enablePort();
                nss.pin.asInput(.{ .pull = .up });
            }
            pins.sck.enablePort();
            pins.sck.asInput(.floating);

            pins.miso.enablePort();
            pins.miso.asOutput(.{ .speed = .max_50mhz, .mode = .alt_push_pull });

            pins.mosi.enablePort();
            pins.mosi.asInput(.{ .pull = .up });
        },
    }
}

fn configureCtrl(self: SPI, comptime cfg: Config) void {
    self.reg.CTLR1.write(.{
        // Clock phase.
        .CPHA = @intFromEnum(cfg.cpha),
        // Clock polarity.
        .CPOL = @intFromEnum(cfg.cpol),
        // Master selection.
        .MSTR = if (cfg.mode == .master) 1 else 0,
        // BR: Baud rate control.
        .BR = 0,
        // SPI enable.
        .SPE = 0,
        // Frame format.
        .LSBFIRST = @intFromEnum(cfg.first_bit),
        // Internal slave select. Required for master mode.
        .SSI = if (cfg.mode == .master) 1 else 0,
        // SSM: Software slave management.
        .SSM = if (!self.has_hardware_nss) 1 else 0,
        // Receive only.
        .RXONLY = if (cfg.direction == .two_lines_rx_only) 1 else 0,
        // Data frame format.
        .DFF = @intFromEnum(cfg.data_size),
        // CRC transfer next.
        .CRCNEXT = 0,
        // CRC enable.
        .CRCEN = 0,
        // Output enable in bidirectional mode.
        .BIDIOE = if (cfg.direction == .one_line_tx) 1 else 0,
        // Bidirectional data mode enable
        .BIDIMODE = if (cfg.direction == .one_line_rx or cfg.direction == .one_line_tx) 1 else 0,
    });
    self.reg.CTLR2.write(.{
        .SSOE = if (cfg.mode == .master and self.has_hardware_nss) 1 else 0,
    });

    // SPI enable.
    self.reg.CTLR1.modify(.{ .SPE = 1 });
}

/// Runtime baud rate configuration.
pub fn configureBaudRate(self: SPI, baud_rate: BaudRate) void {
    self.reg.CTLR1.modify(.{ .BR = @intFromEnum(baud_rate.calculate()) });
}

fn configureCheck(self: SPI) ConfigureError!void {
    if (self.reg.STATR.read().MODF == 1) {
        return ConfigureError.ModeFault;
    }
}

/// Selects the data transfer direction in bi-directional mode.
pub fn setBiDirectionalMode(self: SPI, dir: BiDirectionalMode) void {
    self.reg.CTLR1.modify(.{ .BIDIOE = @intFromEnum(dir) });
}

pub fn enable(self: SPI) void {
    rcc.enable(self.reg);
}

pub fn disable(self: SPI) void {
    rcc.disable(self.reg);
}

fn reset(self: SPI) void {
    rcc.reset(self.reg);
}

/// Blocking bidirectional data transfer.
///
/// Transfers data of size `max(send.len, recv.len)` bytes.
/// If send.len > recv.len, the remaining bytes during reading will be ignored.
/// If recv.len > send.len, zeros will be sent for the remaining bytes.
///
/// This function blocks execution until all data is transferred or a timeout occurs.
/// The deadline parameter allows specifying a timeout check function to avoid infinite waiting.
pub fn transferBlocking(self: SPI, comptime u8_or_u16: type, send: ?[]const u8_or_u16, recv: ?[]u8_or_u16, deadline: time.Deadline) Timeout!void {
    const type_info = @typeInfo(u8_or_u16).int;
    if (type_info.bits != 8 and type_info.bits != 16 or @typeInfo(u8_or_u16).int.signedness != .unsigned) {
        @compileError("Unsupported type, only u8 and u16 are supported");
    }

    self.swNssWrite(false);
    defer self.swNssWrite(true);

    const send_len = if (send) |s| s.len else 0;
    const recv_len = if (recv) |r| r.len else 0;
    const len = @max(send_len, recv_len);

    for (0..len) |offset| {
        const word: u16 = if (send) |s| blk: {
            break :blk if (s.len > offset) s[offset] else 0;
        } else 0;

        const v = self.transferWordBlocking(word, deadline) catch |err| {
            return err;
        };

        if (recv) |r| {
            if (r.len > offset) {
                r[offset] = @truncate(v);
            }
        }
    }

    try self.wait(isNotBusy, deadline);
}

inline fn swNssWrite(self: SPI, v: bool) void {
    if (self.sw_nss) |nss| {
        nss.write(v);
    }
}

fn isReadable(self: SPI) bool {
    return self.reg.STATR.read().RXNE == 1;
}

fn isWriteable(self: SPI) bool {
    return self.reg.STATR.read().TXE == 1;
}

fn isNotBusy(self: SPI) bool {
    return self.reg.STATR.read().BSY == 0;
}

fn transferWordBlocking(self: SPI, word: u16, deadline: time.Deadline) Timeout!u16 {
    try self.wait(isWriteable, deadline);

    self.reg.DATAR.raw = word;

    try self.wait(isReadable, deadline);

    return @truncate(self.reg.DATAR.raw);
}

// Wait for a condition to be true.
fn wait(self: SPI, conditionFn: fn (self: SPI) bool, deadline: time.Deadline) Timeout!void {
    while (!conditionFn(self)) {
        if (deadline.isReached()) {
            return error.Timeout;
        }
        asm volatile ("" ::: .{ .memory = true });
    }
}

// Comptime pins checks.
fn checkPins(comptime reg: *volatile svd.registers.SPI, comptime pins: Pins) void {
    const pins_namespace = Pins.namespaceFor(reg);

    // Find pins from namespace.
    var periph_pins_maybe: ?Pins = null;
    for (@typeInfo(pins_namespace).@"struct".decls) |decl| {
        const p_pins: Pins = @field(pins_namespace, decl.name);
        if (p_pins.eqWithoutNss(pins)) {
            periph_pins_maybe = p_pins;
            break;
        }
    }
    const periph_pins = periph_pins_maybe orelse @compileError(
        \\Pins not found in namespace for selected SPI.
        \\This may be due to an incorrect pin configuration.
        \\For example, if you are using SPI1, the pins should be from Pins.spi1 namespace.
    );

    const nss = pins.nss orelse return;
    if (nss.is_hardware) {
        return;
    }

    // Software NSS pin must not be the same as any of the SPI pins.
    const pin_names = &.{ "sck", "miso", "mosi" };
    for (pin_names) |pin_name| {
        const periph_pin = @field(periph_pins, pin_name);
        if (periph_pin.eq(nss.pin)) {
            var buf = [_]u8{0} ** pin_name.len;
            const pin_name_upper = std.ascii.upperString(&buf, pin_name);
            @compileError("NSS pin must not be the same as " ++ pin_name_upper ++ " pins");
        }
    }
}
