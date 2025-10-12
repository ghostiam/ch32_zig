const std = @import("std");
const app = @import("app");
const builtin = @import("builtin");

pub const svd = @import("svd");
pub const hal = @import("hal");
const startup = @import("startup.zig");

comptime {
    if (!builtin.is_test) {
        asm (
            \\.section .init
            \\j _start
        );

        @export(&startup.start, .{
            .name = "_start",
        });

        @export(&vector_table, .{
            .name = "vector_table",
            .section = ".init",
        });

        // Execute comptime code.
        _ = app;

        if (@hasDecl(app, "std_options")) {
            @compileError("std_options is not supported, use ch32_options instead");
        }
    }
}

pub const Options = struct {
    /// The current log level.
    log_level: std.log.Level = std.log.default_level,
    log_scope_levels: []const std.log.ScopeLevel = &.{},
    /// Logger function to use for std.log.
    /// When a logger function other than nopFn is set,
    /// it will be used to output the panic message.
    logFn: fn (
        comptime message_level: std.log.Level,
        comptime scope: @TypeOf(.enum_literal),
        comptime format: []const u8,
        args: anytype,
    ) void = hal.log.nopFn,
    fmt_max_depth: usize = std.fmt.default_max_depth,
    unhandledInterruptFn: fn () callconv(hal.interrupts.call_conv) void = hal.interrupts.unhandled,
    panic_options: hal.panic.Options = .{},
};

pub const ch32_options: Options = if (@hasDecl(app, "ch32_options")) app.ch32_options else .{};

pub const std_options: std.Options = .{
    .log_level = ch32_options.log_level,
    .log_scope_levels = ch32_options.log_scope_levels,
    .logFn = ch32_options.logFn,
    .fmt_max_depth = ch32_options.fmt_max_depth,
};

const defaultPanic = if (ch32_options.logFn == hal.log.nopFn) hal.panic.InitSilent(ch32_options.panic_options) else hal.panic.InitLog(ch32_options.panic_options);
pub const panic = if (@hasDecl(app, "panic")) app.panic else defaultPanic;

pub const interrupts: hal.interrupts.VectorTable = if (@hasDecl(app, "interrupts")) app.interrupts else .{};
pub const InterruptHandler = *const fn () callconv(hal.interrupts.call_conv) void;

// Vector table

const vector_table_offset = 1; // First entry is reserved for the _reset_vector.

fn vectorTableSize() usize {
    const type_info = @typeInfo(svd.interrupts);

    const interrupts_list = type_info.@"enum".fields;
    const last_interrupt = interrupts_list[interrupts_list.len - 1];
    const last_interrupt_idx = last_interrupt.value;

    return last_interrupt_idx + 1 - vector_table_offset;
}

pub fn generateVectorTable(handlers: hal.interrupts.VectorTable, unhandled: InterruptHandler) [vectorTableSize()]InterruptHandler {
    @setEvalBranchQuota(100_000);

    const type_info = @typeInfo(svd.interrupts);
    const interrupts_list = type_info.@"enum".fields;

    var temp: [vectorTableSize()]InterruptHandler = @splat(unhandled);
    for (&temp, vector_table_offset..) |_, idx| {
        // Find name of the interrupt by its number.
        var name: ?[:0]const u8 = null;
        for (interrupts_list) |decl| {
            if (decl.value == idx) {
                name = decl.name;
                break;
            }
        }

        if (name) |n| {
            if (@field(handlers, n)) |h| {
                temp[idx - vector_table_offset] = h;
            }
        }
    }

    return temp;
}

const vector_table = generateVectorTable(interrupts, ch32_options.unhandledInterruptFn);

test generateVectorTable {
    const v = comptime generateVectorTable(.{
        .SysTick = testSysTickHandler,
    }, hal.interrupts.unhandled);
    try std.testing.expectEqual(hal.interrupts.unhandled, v[@intFromEnum(svd.interrupts.NMI) - vector_table_offset]);
    try std.testing.expectEqual(hal.interrupts.unhandled, v[@intFromEnum(svd.interrupts.HardFault) - vector_table_offset]);
    try std.testing.expectEqual(testSysTickHandler, v[@intFromEnum(svd.interrupts.SysTick) - vector_table_offset]);
}

fn testSysTickHandler() callconv(hal.interrupts.call_conv) void {}
