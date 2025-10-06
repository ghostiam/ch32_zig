const std = @import("std");
const config = @import("config");

pub fn nop() void {
    asm volatile ("nop");
}

// Wait for interrupt.
// This will put the processor into a low power state until an interrupt occurs.
pub inline fn wfi() void {
    asm volatile ("wfi");
}

// Wait for event.
// This will put the processor into a low power state until an event occurs.
pub inline fn wfe() void {
    // 6.5.2.22 PFIC System Control Register (PFIC_SCTLR)
    const PFIC_SCTLR: *volatile u32 = @ptrFromInt(0xE000ED10);
    // WFITOWFE. Execute the WFI command as if it were a WFE.
    PFIC_SCTLR.* |= @as(u32, 1 << 3);
    asm volatile ("wfi");
}

pub const csr = struct {
    /// Architecture Number Register
    /// Examples:
    /// - 0xDC68D841 - WCH-V2A
    /// - 0xDC68D886 - WCH-V4F
    pub const marchid = Csr(0xF12, u32);
    pub const mimpid = Csr(0xF13, u32);

    /// Machine Mode Status Register
    pub const mstatus = Csr(0x300, packed struct(u32) {
        pub const Fs = enum(u2) {
            /// Floating-point unit status
            off = 0b00,
            initial = 0b01,
            clean = 0b10,
            dirty = 0b11,
        };

        /// [2:0] Reserved
        reserved4: u3 = 0,
        /// [3] Machine mode interrupt enable
        mie: u1 = 0,
        /// [6:4] Reserved
        reserved3: u3 = 0,
        /// [7] Interrupt enable state before entering interrupt
        mpie: u1 = 0,
        /// [10:8] Reserved
        reserved2: u3 = 0,
        /// [12:11] Privileged mode before entering break
        mpp: u2 = 0,
        /// [14:13] Reserved
        reserved1: u2 = 0,
        /// [14:13] Floating-point unit status
        /// Valid only for WCH-V4F
        fs: Fs = .off,
        /// [31:15] Reserved
        reserved0: u15 = 0,
    });
    pub const misa = Csr(0x301, u32);
    /// Machine Mode Exception Base Address Register
    pub const mtvec = Csr(0x305, packed struct(u32) {
        /// [0] Mode 0
        /// Interrupt or exception entry address mode selection.
        /// 0: Use of the uniform entry address.
        /// 1: Address offset based on interrupt number *4.
        mode0: u1,
        /// [1] Mode 1
        /// Interrupt vector table identifies patterns.
        /// 0: Identification by jump instruction,
        /// limited range, support for non-jump 0 instructions.
        /// 1: Identify by absolute address, support
        /// full range, but must jump.
        mode1: u1,
        /// [31:2] Base address of the interrupt vector table
        base: u30,
    });

    pub const mscratch = Csr(0x340, u32);
    pub const mepc = Csr(0x341, u32);
    pub const mcause = Csr(0x342, packed struct {
        code: u31,
        is_interrupt: u1,
    });
    pub const mtval = Csr(0x343, u32);

    pub const pmpcfg0 = Csr(0x3A0, u32);
    pub const pmpaddr0 = Csr(0x3B0, u32);
    pub const pmpaddr1 = Csr(0x3B1, u32);
    pub const pmpaddr2 = Csr(0x3B2, u32);
    pub const pmpaddr3 = Csr(0x3B3, u32);

    pub const fflags = Csr(0x001, u32);
    pub const fcsr = Csr(0x003, u32);
    pub const frm = Csr(0x002, u32);

    pub const dcsr = Csr(0x7B0, u32);
    pub const dpc = Csr(0x7B1, u32);
    pub const dscratch0 = Csr(0x7B2, u32);
    pub const dscratch1 = Csr(0x7B3, u32);

    const intsyscr_v2 = packed struct(u32) {
        /// [0] HPE enable
        hwstken: u1,
        /// [1] Interrupt nesting enable
        inesten: u1,
        /// [2] EABI enable
        eabien: u1,
        /// [31:3] Reserved
        reserved0: u29 = 0,
    };
    const intsyscr_v3 = packed struct(u32) {
        /// [0] Hardware stack enable
        hwstken: u1,
        /// [1] Interrupt nesting enable
        inesten: u1,
        /// [3:2] Priority preemption configuration
        pmtcfg: u2,
        /// [4] Reserved
        reserved0: u1 = 0,
        /// [5] Global interrupt and hardware stack shutdown enable
        gihwstknen: u1 = 0,
        /// [30:6] Reserved
        reserved1: u25 = 0x380,
        /// [31] Lock
        lock: u1 = 0,
    };
    const intsyscr_v4 = packed struct(u32) {
        /// [0] HPE enable
        hwstken: u1,
        /// [1] Interrupt nesting enable
        inesten: u1,
        /// [3:2] Interrupt nesting depth configuration
        pmtcfg: u2,
        /// [4] Interrupt enable after HPE overflow
        hwstkoven: u1 = 0,
        /// [5] Global interrupt and HPE off enable
        gihwstknen: u1 = 0,
        /// [7:6] Reserved
        reserved1: u2 = 0,
        /// [15:8] Preemption status indication
        pmtsta: u8 = 0,
        /// [31:16] Reserved
        reserved0: u16 = 0,
    };
    const intsyscr_impl = switch (config.chip.series) {
        .ch32v003 => intsyscr_v2,
        .ch32v103 => intsyscr_v3,
        .ch32v20x, .ch32v30x => intsyscr_v4,
    };

    pub const gintenr = Csr(0x800, u32);
    pub const intsyscr = Csr(0x804, intsyscr_impl);
    pub const corecfgr = Csr(0xBC0, u32);
    pub const cstrcr = Csr(0xBC2, u32);
    pub const cpmpocr = Csr(0xBC3, u32);
    pub const cmcr = Csr(0xBD0, u32);
    pub const cinfor = Csr(0xFC0, u32);

    pub fn Csr(addr: u24, T: type) type {
        const size = @bitSizeOf(T);
        if (size != 32)
            @compileError("size must be 32!");
        const ident = std.fmt.comptimePrint("{}", .{addr});

        return struct {
            const Self = @This();

            pub inline fn readRaw() u32 {
                return asm volatile ("csrr %[value], " ++ ident
                    : [value] "=r" (-> u32),
                );
            }

            pub inline fn read() T {
                return @bitCast(readRaw());
            }

            pub inline fn writeRaw(value: u32) void {
                asm volatile ("csrw " ++ ident ++ ", %[value]"
                    :
                    : [value] "r" (value),
                );
            }

            pub inline fn write(value: T) void {
                writeRaw(@bitCast(value));
            }

            pub inline fn modify(modifier: anytype) void {
                switch (@typeInfo(T)) {
                    .@"struct" => {
                        var value = read();
                        inline for (@typeInfo(@TypeOf(modifier)).Struct.fields) |field| {
                            @field(value, field.name) = @field(modifier, field.name);
                        }
                        write(value);
                    },
                    .int => write(modifier),
                    else => @compileError("unsupported type"),
                }
            }

            pub inline fn setRaw(bits: u32) void {
                asm volatile ("csrs " ++ ident ++ ", %[bits]"
                    :
                    : [bits] "r" (bits),
                );
            }

            pub inline fn set(fields: T) void {
                setRaw(getBits(fields));
            }

            pub inline fn clearRaw(bits: u32) void {
                asm volatile ("csrc " ++ ident ++ ", %[bits]"
                    :
                    : [bits] "r" (bits),
                );
            }

            pub inline fn clear(fields: T) void {
                clearRaw(getBits(fields));
            }

            pub inline fn readSetRaw(bits: u32) u32 {
                return asm volatile ("csrrs %[value], " ++ ident ++ ", %[bits]"
                    : [value] "=r" (-> u32),
                    : [bits] "r" (bits),
                );
            }

            pub inline fn readSet(fields: anytype) T {
                return @bitCast(readSetRaw(getBits(fields)));
            }

            pub inline fn readClearRaw(bits: u32) u32 {
                return asm volatile ("csrrc %[value], " ++ ident ++ ", %[bits]"
                    : [value] "=r" (-> u32),
                    : [bits] "r" (bits),
                );
            }

            pub inline fn readClear(fields: anytype) T {
                return @bitCast(readClearRaw(getBits(fields)));
            }

            inline fn getBits(fields: anytype) u32 {
                return switch (@typeInfo(T)) {
                    .@"struct" => blk: {
                        var bits: T = @bitCast(@as(u32, 0));
                        inline for (@typeInfo(@TypeOf(fields)).@"struct".fields) |field| {
                            @field(bits, field.name) = @field(fields, field.name);
                        }
                        break :blk @bitCast(bits);
                    },
                    .int => fields,
                    else => @compileError("unsupported type"),
                };
            }
        };
    }
};
