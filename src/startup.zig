const std = @import("std");
const root = @import("app");
const config = @import("config");
const svd = @import("svd");
const csr = @import("hal").cpu.csr;

pub fn start() callconv(.naked) void {
    // Set global pointer.
    asm volatile (
        \\.option push
        \\.option norelax
        \\la gp, __global_pointer$
        \\.option pop
    );

    // Set stack pointer.
    asm volatile (
        \\la sp, __end_of_stack
    );

    // Clear whole RAM. Good for debugging.
    asm volatile (
        \\    li a0, 0
        \\    la a1, __start_of_ram
        \\    la a2, __end_of_stack
        \\    beq a1, a2, clear_ram_done
        \\clear_ram_loop:
        \\    sw a0, 0(a1)
        \\    addi a1, a1, 4
        \\    blt a1, a2, clear_ram_loop
        \\clear_ram_done:
    );

    // // Clear .bss section.
    // asm volatile (
    //     \\    li a0, 0
    //     \\    la a1, __bss_start
    //     \\    la a2, __bss_end
    //     \\    beq a1, a2, clear_bss_done
    //     \\clear_bss_loop:
    //     \\    sw a0, 0(a1)
    //     \\    addi a1, a1, 4
    //     \\    blt a1, a2, clear_bss_loop
    //     \\clear_bss_done:
    // );

    // Copy .data from flash to RAM.
    asm volatile (
        \\    la a0, __data_load_start
        \\    la a1, __data_start
        \\    la a2, __data_end
        \\copy_data_loop:
        \\    beq a1, a2, copy_done
        \\    lw a3, 0(a0)
        \\    sw a3, 0(a1)
        \\    addi a0, a0, 4
        \\    addi a1, a1, 4
        \\    bne a1, a2, copy_data_loop
        \\copy_done:
    );

    // Configure the CPU.
    switch (config.chip.series) {
        .ch32v003 => csr.intsyscr.write(.{ .hwstken = 1, .inesten = 1, .eabien = 1 }),
        .ch32v103 => {},
        .ch32v20x => {
            // Configure pipelining and instruction prediction.
            csr.corecfgr.writeRaw(0x1f);
            // Enable interrupt nesting and hardware stack.
            csr.intsyscr.write(.{ .hwstken = 1, .inesten = 1, .pmtcfg = 0 });
        },
        .ch32v30x => {
            // Configure pipelining and instruction prediction.
            csr.corecfgr.writeRaw(0x1f);
            // Enable interrupt nesting and hardware stack.
            csr.intsyscr.write(.{ .hwstken = 1, .inesten = 1, .pmtcfg = 0b10 });
        },
    }

    // Enable interrupts.
    csr.mtvec.write(.{ .mode0 = 1, .mode1 = 1, .base = 0 });
    csr.mstatus.write(.{
        .mie = 1,
        .mpie = 1,
        .fs = if (config.chip.series == .ch32v30x) .dirty else .off,
    });

    // Call systemInit for system initialization.
    @export(&systemInit, .{ .name = "systemInit" });
    asm volatile (
        \\jal systemInit
    );

    // Load the address of the `callMain` function into the `mepc` register
    // and transfer control to it using the `mret` instruction.
    // This is necessary to ensure proper MCU startup after a power-off.
    // Directly calling the function from an interrupt would prevent the MCU from starting correctly.
    @export(&callMain, .{ .name = "callMain" });
    asm volatile (
        \\la t0, callMain
        \\csrw mepc, t0
    );

    // Return from the interrupt.
    asm volatile ("mret");
}

fn systemInit() callconv(.c) void {
    if (config.chip.series == .ch32v003) {
        svd.peripherals.FLASH.ACTLR.modify(.{ .LATENCY = 0 });
    }

    const RCC = svd.peripherals.RCC;

    // RCC->CTLR |= (uint32_t)0x00000001;
    RCC.CTLR.modify(.{ .HSION = 1 });

    if (config.chip.series == .ch32v30x and config.chip.class == .d8c) {
        // RCC->CFGR0 &= (uint32_t)0xF0FF0000;
        RCC.CFGR0.modify(.{
            .SW = 0,
            .SWS = 0,
            .HPRE = 0,
            .PPRE1 = 0,
            .PPRE2 = 0,
            .ADCPRE = 0,
            .MCO = 0,
        });
    } else {
        // RCC->CFGR0 &= (uint32_t)0xF8FF0000;
        RCC.CFGR0.modify(.{
            .SW = 0,
            .SWS = 0,
            .HPRE = 0,
            .ADCPRE = 0,
            .MCO = 0,
        });
    }

    // RCC->CTLR &= (uint32_t)0xFEF6FFFF;
    RCC.CTLR.modify(.{ .HSEON = 0, .CSSON = 0, .PLLON = 0 });
    // RCC->CTLR &= (uint32_t)0xFFFBFFFF;
    RCC.CTLR.modify(.{ .HSEBYP = 0 });

    if (config.chip.series == .ch32v003) {
        // RCC->CFGR0 &= (uint32_t)0xFFFEFFFF;
        RCC.CFGR0.modify(.{ .PLLSRC = 0 });
    } else {
        // RCC->CFGR0 &= (uint32_t)0xFF00FFFF;
        RCC.CFGR0.modify(.{ .PLLSRC = 0, .PLLXTPRE = 0, .PLLMUL = 0, .USBPRE = 0 });
    }

    if (config.chip.class == .d8c) {
        // RCC->CTLR &= (uint32_t)0xEBFFFFFF;
        RCC.CTLR.modify(.{ .PLL2ON = 0 });
        // RCC->INTR = 0x00FF0000;
        RCC.INTR.write(.{
            // Read-only ready flags.
            .LSIRDYF = 0,
            .LSERDYF = 0,
            .HSIRDYF = 0,
            .HSERDYF = 0,
            .PLLRDYF = 0,
            .PLL2RDYF = 0,
            .PLL3RDYF = 0,
            .CSSF = 0,
            // Disable ready interrupts.
            .LSIRDYIE = 0,
            .LSERDYIE = 0,
            .HSIRDYIE = 0,
            .HSERDYIE = 0,
            .PLLRDYIE = 0,
            .PLL2RDYIE = 0,
            .PLL3RDYIE = 0,
            // Clear ready flags.
            .LSIRDYC = 1,
            .LSERDYC = 1,
            .HSIRDYC = 1,
            .HSERDYC = 1,
            .PLLRDYC = 1,
            .PLL2RDYC = 1,
            .PLL3RDYC = 1,
            .CSSC = 1,
        });
        RCC.CFGR2.raw = 0x00000000;
    } else {
        // RCC->INTR = 0x009F0000;
        RCC.INTR.write(.{
            // Read-only ready flags.
            .LSIRDYF = 0,
            .HSIRDYF = 0,
            .HSERDYF = 0,
            .PLLRDYF = 0,
            .CSSF = 0,
            // Disable ready interrupts.
            .LSIRDYIE = 0,
            .HSIRDYIE = 0,
            .HSERDYIE = 0,
            .PLLRDYIE = 0,
            // Clear ready flags.
            .LSIRDYC = 1,
            .HSIRDYC = 1,
            .HSERDYC = 1,
            .PLLRDYC = 1,
            .CSSC = 1,
        });
    }

    if (config.chip.series == .ch32v003) {
        // Adjusts the Internal High Speed oscillator (HSI) calibration value.
        RCC.CTLR.modify(.{ .HSITRIM = 0x10 });
    }
}

fn callMain() callconv(.c) noreturn {
    const main_invalid_msg = "main must be either \"pub fn main() void\" or \"pub fn main() !void\".";

    const main_type = @typeInfo(@TypeOf(root.main));
    if (main_type != .@"fn" or main_type.@"fn".params.len > 0) {
        @compileError(main_invalid_msg);
    }

    const return_type = @typeInfo(main_type.@"fn".return_type.?);
    if (return_type != .void and return_type != .noreturn and return_type != .error_union) {
        @compileError(main_invalid_msg);
    }

    if (return_type == .error_union) {
        root.main() catch |err| {
            var buf: [32]u8 = undefined;
            const msg = concat(&buf, "main(): ", @errorName(err));
            @panic(msg);
        };
    } else {
        root.main();
    }

    @panic("main() must not return");
}

fn concat(buf: []u8, a: []const u8, b: []const u8) []u8 {
    var i: usize = 0;
    while (i < a.len and i < buf.len) : (i += 1) {
        buf[i] = a[i];
    }

    var j: usize = 0;
    while (j < b.len and i + j < buf.len) : (j += 1) {
        buf[i + j] = b[j];
    }

    return buf[0 .. i + j];
}

test "concat" {
    const a = "Hello, ";
    const b = "World!";
    var buf: [20]u8 = undefined;
    const result = concat(&buf, a, b);
    const expected = "Hello, World!";
    try std.testing.expectEqualStrings(expected, result);
}

test "concat small buffer" {
    const a = "Hello, ";
    const b = "World!";
    var buf: [8]u8 = undefined;
    const result = concat(&buf, a, b);
    const expected = "Hello, W";
    try std.testing.expectEqualStrings(expected, result);
}

test "concat very small buffer" {
    const a = "Hello, ";
    const b = "World!";
    var buf: [4]u8 = undefined;
    const result = concat(&buf, a, b);
    const expected = "Hell";
    try std.testing.expectEqualStrings(expected, result);
}
