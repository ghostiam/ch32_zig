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

pub fn unhandled() callconv(call_conv) void {
    switch (builtin.mode) {
        .Debug, .ReleaseSafe => {
            @panic("unhandled interrupt: see mcause.");
        },
        .ReleaseFast, .ReleaseSmall => @panic("UH IRQ"),
    }
}

pub fn generateExportedVectorTable(list: VectorTable, unhandledFn: Handler) ExportedVectorTableType {
    var vector_table: ExportedVectorTableType = undefined;
    for (@typeInfo(ExportedVectorTableType).@"struct".fields) |field| {
        if (std.mem.startsWith(u8, field.name, "_")) {
            @field(vector_table, field.name) = 0;
            continue;
        }
        const handler: Handler = @field(list, field.name) orelse unhandledFn;
        @field(vector_table, field.name) = handler;
    }

    return vector_table;
}

const ExportedVectorTableType = CreateExportedVectorTableType();

fn CreateExportedVectorTableType() type {
    @setEvalBranchQuota(100_000);

    const offset = 1;
    const interrupts_list = @typeInfo(svd.interrupts).@"enum".fields;
    const last_interrupt = interrupts_list[interrupts_list.len - 1];
    const last_interrupt_idx = last_interrupt.value;

    var fields: [last_interrupt_idx + 1 - offset]std.builtin.Type.StructField = undefined;
    for (&fields, offset..) |*field, idx| {
        // Find name of the interrupt by its number.
        var name: ?[:0]const u8 = null;
        for (interrupts_list) |decl| {
            if (decl.value == idx) {
                name = decl.name;
                break;
            }
        }

        const idx_str = std.fmt.comptimePrint("{}", .{idx});
        const FieldType = if (name != null) Handler else std.meta.Int(.unsigned, @alignOf(Handler) * 8);
        field.* = .{
            .name = name orelse "_reserved" ++ idx_str,
            .type = FieldType,
            .default_value_ptr = null,
            .is_comptime = false,
            .alignment = @alignOf(FieldType),
        };
    }

    return @Type(.{
        .@"struct" = .{
            .layout = .@"extern",
            .fields = &fields,
            .decls = &.{},
            .is_tuple = false,
        },
    });
}

test generateExportedVectorTable {
    const v = comptime generateExportedVectorTable(.{
        .SysTick = testSysTickHandler,
    }, unhandled);
    try std.testing.expectEqual(0, v._reserved4);
    try std.testing.expectEqual(unhandled, v.NMI);
    try std.testing.expectEqual(testSysTickHandler, v.SysTick);
}

fn testSysTickHandler() callconv(call_conv) void {}
