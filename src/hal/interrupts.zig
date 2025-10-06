const std = @import("std");
const builtin = @import("builtin");
const config = @import("config");
const svd = @import("svd");

const PFIC = svd.peripherals.PFIC;

pub const call_conv: std.builtin.CallingConvention = if (builtin.cpu.arch != .riscv32) .c else .{ .riscv32_interrupt = .{ .mode = .machine } };
pub const Handler = *const fn () callconv(call_conv) void;

pub const VectorTable = svd.interrupts.VectorTable;

/// Enable Global Interrupt.
pub inline fn globalEnable() void {
    asm volatile ("csrsi mstatus, 0b1000");
}

/// Disable Global Interrupt.
pub inline fn globalDisable() void {
    asm volatile ("csrci mstatus, 0b1000");
}

/// Check if Global Interrupt is enabled.
pub inline fn isGlobalEnabled() bool {
    const mstatus = asm ("csrr %[out], mstatus"
        : [out] "=r" (-> u32),
    );
    return (mstatus & 0b1000) != 0;
}

/// Wait for interrupt.
pub inline fn wait() void {
    asm volatile ("wfi");
}

/// Enable interrupt.
pub inline fn enable(comptime irq: svd.interrupts) void {
    comptime {
        const root = @import("root");
        const irq_name = @tagName(irq);
        if (!@hasDecl(root, "interrupts") or @field(root.interrupts, irq_name) == null) {
            @compileError(
                irq_name ++ " interrupt handler should be defined.\n" ++
                    "Add to your main file:\n" ++
                    "    pub const interrupts: hal.interrupts.VectorTable = .{\n" ++
                    "        ." ++ irq_name ++ " = yourHandlerFor" ++ irq_name ++ ",\n" ++
                    "    };\n",
            );
        }
    }

    const irq_num = @intFromEnum(irq);
    const num = irq_num >> 5;
    const pos = irq_num & 0x1F;
    switch (num) {
        0 => PFIC.IENR1.setBit(pos, 1),
        1 => PFIC.IENR2.setBit(pos, 1),
        2 => PFIC.IENR3.setBit(pos, 1),
        3 => PFIC.IENR4.setBit(pos, 1),
        else => unreachable,
    }
}

/// Disable interrupt.
pub inline fn disable(irq: svd.interrupts) void {
    const irq_num = @intFromEnum(irq);
    const num = irq_num >> 5;
    const pos = irq_num & 0x1F;
    switch (num) {
        0 => PFIC.IRER1.setBit(pos, 1),
        1 => PFIC.IRER2.setBit(pos, 1),
        2 => PFIC.IRER3.setBit(pos, 1),
        3 => PFIC.IRER4.setBit(pos, 1),
        else => unreachable,
    }
}

/// Interrupt status.
pub inline fn status(irq: svd.interrupts) bool {
    const irq_num = @intFromEnum(irq);
    const num = irq_num >> 5;
    const pos = irq_num & 0x1F;
    const v = switch (num) {
        0 => PFIC.ISR1.getBit(pos),
        1 => PFIC.ISR2.getBit(pos),
        2 => PFIC.ISR3.getBit(pos),
        3 => PFIC.ISR4.getBit(pos),
        else => unreachable,
    };
    return v != 0;
}

/// Interrupt pending state.
pub inline fn isPending(irq: svd.interrupts) bool {
    const irq_num = @intFromEnum(irq);
    const num = irq_num >> 5;
    const pos = irq_num & 0x1F;
    const v = switch (num) {
        0 => PFIC.IPR1.getBit(pos),
        1 => PFIC.IPR2.getBit(pos),
        2 => PFIC.IPR3.getBit(pos),
        3 => PFIC.IPR4.getBit(pos),
        else => unreachable,
    };
    return v != 0;
}

/// Set interrupt pending.
pub inline fn setPending(irq: svd.interrupts) void {
    const irq_num = @intFromEnum(irq);
    const num = irq_num >> 5;
    const pos = irq_num & 0x1F;
    switch (num) {
        0 => PFIC.IPSR1.setBit(pos, 1),
        1 => PFIC.IPSR2.setBit(pos, 1),
        2 => PFIC.IPSR3.setBit(pos, 1),
        3 => PFIC.IPSR4.setBit(pos, 1),
        else => unreachable,
    }
}

/// Clear interrupt pending.
pub inline fn clearPending(irq: svd.interrupts) void {
    const irq_num = @intFromEnum(irq);
    const num = irq_num >> 5;
    const pos = irq_num & 0x1F;
    switch (num) {
        0 => PFIC.IPRR1.setBit(pos, 1),
        1 => PFIC.IPRR2.setBit(pos, 1),
        2 => PFIC.IPRR3.setBit(pos, 1),
        3 => PFIC.IPRR4.setBit(pos, 1),
        else => unreachable,
    }
}

/// Interrupt active state.
pub inline fn isActive(irq: svd.interrupts) bool {
    const irq_num = @intFromEnum(irq);
    const num = irq_num >> 5;
    const pos = irq_num & 0x1F;
    const v = switch (num) {
        0 => PFIC.IACTR1.getBit(pos),
        1 => PFIC.IACTR2.getBit(pos),
        2 => PFIC.IACTR3.getBit(pos),
        3 => PFIC.IACTR4.getBit(pos),
        else => unreachable,
    };
    return v != 0;
}

/// Interrupt priority configuration.
/// priority -
/// bit7 - pre-emption priority
/// bit6~bit4 - subpriority
/// bit3~bit0 - reserved (must be 0)
pub inline fn setPriority(comptime irq: svd.interrupts, priority: u8) void {
    const irq_num = @intFromEnum(irq);
    const irq_num_str = std.fmt.comptimePrint("{}", .{irq_num});
    @field(PFIC, "IPRIOR" ++ irq_num_str) = priority & 0b1111_0000;
}

pub inline fn getPriority(comptime irq: svd.interrupts) u8 {
    const irq_num = @intFromEnum(irq);
    const irq_num_str = std.fmt.comptimePrint("{}", .{irq_num});
    return @field(PFIC, "IPRIOR" ++ irq_num_str);
}

pub fn unhandled() callconv(call_conv) void {
    switch (builtin.mode) {
        .Debug, .ReleaseSafe => {
            @panic("unhandled interrupt: see mcause.");
        },
        .ReleaseFast, .ReleaseSmall => @panic("UH IRQ"),
    }
}
