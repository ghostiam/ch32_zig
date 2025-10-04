const std = @import("std");
const mem = std.mem;
const ascii = std.ascii;
const fmt = std.fmt;
const warn = std.log.warn;

const svd = @import("svd.zig");

const register_def =
    \\const std = @import("std");
    \\
    \\pub fn RegisterRW(comptime Register: type, comptime Nullable: type) type {
    \\    const size = @bitSizeOf(Register);
    \\    const IntSize = std.meta.Int(.unsigned, size);
    \\
    \\    return extern struct {
    \\        raw: IntSize,
    \\
    \\        const Self = @This();
    \\
    \\        pub inline fn read(self: *volatile Self) Register {
    \\            return @bitCast(self.raw);
    \\        }
    \\
    \\        pub inline fn write(self: *volatile Self, value: Register) void {
    \\            self.writeRaw(@bitCast(value));
    \\        }
    \\
    \\        pub inline fn modify(self: *volatile Self, new_value: Nullable) void {
    \\            var old_value = self.read();
    \\            inline for (@typeInfo(@TypeOf(new_value)).@"struct".fields) |field| {
    \\                if (@field(new_value, field.name)) |v| {
    \\                    @field(old_value, field.name) = v;
    \\                }
    \\            }
    \\            self.write(old_value);
    \\        }
    \\
    \\        /// Write any type to the register. Any unassigned fields will be set to default.
    \\        pub inline fn writeAny(self: *volatile Self, value: anytype) void {
    \\            var reg = self.default();
    \\
    \\            const reg_fields = @typeInfo(@TypeOf(value)).@"struct".fields;
    \\            inline for (reg_fields) |field| {
    \\                @field(reg, field.name) = @field(value, field.name);
    \\            }
    \\
    \\            self.write(reg);
    \\        }
    \\
    \\        /// Modify register with any type.
    \\        /// Fields can have types different from the register fields, such as optional or bool.
    \\        pub inline fn modifyAny(self: *volatile Self, new_value: anytype) void {
    \\            var old_value = self.read();
    \\
    \\            inline for (@typeInfo(@TypeOf(new_value)).@"struct".fields) |field| {
    \\                const old_field_value = @field(old_value, field.name);
    \\                const old_field_value_type_info = @typeInfo(@TypeOf(old_field_value));
    \\
    \\                const new_field_value = @field(new_value, field.name);
    \\                const new_field_value_type_info = @typeInfo(@TypeOf(new_field_value));
    \\                const is_new_value_optional = new_field_value_type_info == .optional;
    \\
    \\                // Unwrap optional type.
    \\                const new_field_value_unwrapped_type_info = if (is_new_value_optional)
    \\                    @typeInfo(new_field_value_type_info.optional.child)
    \\                else
    \\                    new_field_value_type_info;
    \\
    \\                // Null fields don't modify the value.
    \\                if (new_field_value_unwrapped_type_info == .null) {
    \\                    continue;
    \\                }
    \\
    \\                // Unwrap optional value.
    \\                const new_field_value_unwrapped: @Type(new_field_value_unwrapped_type_info) = if (is_new_value_optional)
    \\                    // Null values don't modify the field.
    \\                    if (new_field_value) |v| v else continue
    \\                else
    \\                    new_field_value;
    \\
    \\                // Allow set boolean values.
    \\                const is_u1_type = old_field_value_type_info.int.signedness == .unsigned and old_field_value_type_info.int.bits == 1;
    \\                if (is_u1_type and new_field_value_unwrapped_type_info == .bool) {
    \\                    @field(old_value, field.name) = if (new_field_value_unwrapped) 1 else 0;
    \\                    continue;
    \\                }
    \\
    \\                @field(old_value, field.name) = new_field_value_unwrapped;
    \\            }
    \\
    \\            self.write(old_value);
    \\        }
    \\
    \\        pub inline fn writeRaw(self: *volatile Self, value: IntSize) void {
    \\            self.raw = value;
    \\        }
    \\
    \\        pub inline fn setBits(self: *volatile Self, pos: u5, width: u6, value: IntSize) void {
    \\            if (pos + width > size) {
    \\                return;
    \\            }
    \\
    \\            const IntSizePlus1 = std.meta.Int(.unsigned, size + 1);
    \\            const mask: IntSize = @as(IntSize, (@as(IntSizePlus1, 1) << width) - 1) << pos;
    \\            self.raw = (self.raw & ~mask) | ((value << pos) & mask);
    \\        }
    \\
    \\        pub inline fn setBit(self: *volatile Self, pos: u5, value: u1) void {
    \\            if (pos >= size) {
    \\                return;
    \\            }
    \\
    \\            if (value == 1) {
    \\                self.raw |= @as(IntSize, 1) << pos;
    \\            } else {
    \\                self.raw &= ~(@as(IntSize, 1) << pos);
    \\            }
    \\        }
    \\
    \\        pub inline fn getBit(self: *volatile Self, pos: u5) u1 {
    \\            if (pos >= size) {
    \\                return 0;
    \\            }
    \\
    \\            return @truncate(self.raw >> pos);
    \\        }
    \\
    \\        pub inline fn default(_: *volatile Self) Register {
    \\            return Register{};
    \\        }
    \\    };
    \\}
    \\
;

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var args = try std.process.argsWithAllocator(allocator);

    _ = args.next(); // skip application name
    // Note memory will be freed on exit since using arena

    const svd_file_name = args.next() orelse return error.MandatoryFilenameArgumentNotGiven;
    const file = try std.fs.cwd().openFile(svd_file_name, .{});
    defer file.close();

    var svd_stream_buffer: [1024 * 1024]u8 = undefined;
    var file_reader = file.reader(&svd_stream_buffer);
    var svd_stream = &file_reader.interface;

    var output_buffer: [1024 * 1024]u8 = undefined;
    var out_stream: *std.Io.Writer = undefined;
    const out_file_name = args.next();
    if (out_file_name) |file_name| {
        const out_file = try std.fs.cwd().createFile(file_name, .{});
        var out_file_writer = out_file.writer(&output_buffer);
        out_stream = &out_file_writer.interface;
    } else {
        const out_file = std.fs.File.stdout();
        var out_file_writer = out_file.writer(&output_buffer);
        out_stream = &out_file_writer.interface;
    }
    defer out_stream.flush() catch @panic("flush");

    var state = SvdParseState.Device;
    var dev = try svd.Device.init(allocator);
    defer dev.deinit(allocator);
    var cur_interrupt: svd.Interrupt = undefined;

    var eof = false;
    while (!eof) {
        const line = svd_stream.takeDelimiterInclusive('<') catch |err| sw: switch (err) {
            error.EndOfStream => {
                eof = true;
                break :sw svd_stream.buffered();
            },
            else => |e| return e,
        };

        const chunk = getChunk(line) orelse continue;
        switch (state) {
            .Device => {
                if (ascii.eqlIgnoreCase(chunk.tag, "/device")) {
                    state = .Finished;
                } else if (ascii.eqlIgnoreCase(chunk.tag, "name")) {
                    if (chunk.data) |data| {
                        try appendSliceWithFixes(&dev.name, allocator, data);
                    }
                } else if (ascii.eqlIgnoreCase(chunk.tag, "version")) {
                    if (chunk.data) |data| {
                        try appendSliceWithFixes(&dev.version, allocator, data);
                    }
                } else if (ascii.eqlIgnoreCase(chunk.tag, "description")) {
                    if (chunk.data) |data| {
                        try appendSliceWithFixes(&dev.description, allocator, data);
                    }
                } else if (ascii.eqlIgnoreCase(chunk.tag, "cpu")) {
                    const cpu = try svd.Cpu.init(allocator);
                    dev.cpu = cpu;
                    state = .Cpu;
                } else if (ascii.eqlIgnoreCase(chunk.tag, "addressUnitBits")) {
                    if (chunk.data) |data| {
                        dev.address_unit_bits = fmt.parseInt(u32, data, 10) catch null;
                    }
                } else if (ascii.eqlIgnoreCase(chunk.tag, "width")) {
                    if (chunk.data) |data| {
                        dev.max_bit_width = fmt.parseInt(u32, data, 10) catch null;
                    }
                } else if (ascii.eqlIgnoreCase(chunk.tag, "size")) {
                    if (chunk.data) |data| {
                        dev.reg_default_size = fmt.parseInt(u32, data, 10) catch null;
                    }
                } else if (ascii.eqlIgnoreCase(chunk.tag, "resetValue")) {
                    if (chunk.data) |data| {
                        dev.reg_default_reset_value = fmt.parseInt(u32, data, 10) catch null;
                    }
                } else if (ascii.eqlIgnoreCase(chunk.tag, "resetMask")) {
                    if (chunk.data) |data| {
                        dev.reg_default_reset_mask = fmt.parseInt(u32, data, 10) catch null;
                    }
                } else if (ascii.eqlIgnoreCase(chunk.tag, "peripherals")) {
                    state = .Peripherals;
                }
            },
            .Cpu => {
                if (ascii.eqlIgnoreCase(chunk.tag, "/cpu")) {
                    state = .Device;
                } else if (ascii.eqlIgnoreCase(chunk.tag, "name")) {
                    if (chunk.data) |data| {
                        try appendSliceWithFixes(&dev.cpu.?.name, allocator, data);
                    }
                } else if (ascii.eqlIgnoreCase(chunk.tag, "revision")) {
                    if (chunk.data) |data| {
                        try appendSliceWithFixes(&dev.cpu.?.revision, allocator, data);
                    }
                } else if (ascii.eqlIgnoreCase(chunk.tag, "endian")) {
                    if (chunk.data) |data| {
                        try appendSliceWithFixes(&dev.cpu.?.endian, allocator, data);
                    }
                } else if (ascii.eqlIgnoreCase(chunk.tag, "mpuPresent")) {
                    if (chunk.data) |data| {
                        dev.cpu.?.mpu_present = textToBool(data);
                    }
                } else if (ascii.eqlIgnoreCase(chunk.tag, "fpuPresent")) {
                    if (chunk.data) |data| {
                        dev.cpu.?.fpu_present = textToBool(data);
                    }
                } else if (ascii.eqlIgnoreCase(chunk.tag, "nvicPrioBits")) {
                    if (chunk.data) |data| {
                        dev.cpu.?.nvic_prio_bits = fmt.parseInt(u32, data, 10) catch null;
                    }
                } else if (ascii.eqlIgnoreCase(chunk.tag, "vendorSystickConfig")) {
                    if (chunk.data) |data| {
                        dev.cpu.?.vendor_systick_config = textToBool(data);
                    }
                }
            },
            .Peripherals => {
                if (ascii.eqlIgnoreCase(chunk.tag, "/peripherals")) {
                    state = .Device;
                } else if (ascii.eqlIgnoreCase(chunk.tag, "peripheral")) {
                    var periph = try svd.Peripheral.init(allocator);
                    if (chunk.derivedFrom) |derived_from| {
                        try periph.derived_from.appendSlice(allocator, derived_from);
                    }
                    try dev.peripherals.append(allocator, periph);
                    state = .Peripheral;
                }
            },
            .Peripheral => {
                var cur_periph = &dev.peripherals.items[dev.peripherals.items.len - 1];
                if (ascii.eqlIgnoreCase(chunk.tag, "/peripheral")) {
                    state = .Peripherals;

                    if (cur_periph.derived_from.items.len > 0) {
                        for (dev.peripherals.items) |*periph_being_checked| {
                            if (mem.eql(u8, periph_being_checked.name.items, cur_periph.derived_from.items)) {
                                try periph_being_checked.derived_peripherals.append(allocator, cur_periph.*);
                            }
                        }
                    }
                } else if (ascii.eqlIgnoreCase(chunk.tag, "name")) {
                    if (chunk.data) |data| {
                        try appendSliceWithFixes(&cur_periph.name, allocator, data);
                    }
                } else if (ascii.eqlIgnoreCase(chunk.tag, "description")) {
                    if (chunk.data) |data| {
                        try appendSliceWithFixes(&cur_periph.description, allocator, data);
                    }
                } else if (ascii.eqlIgnoreCase(chunk.tag, "groupName")) {
                    if (chunk.data) |data| {
                        try appendSliceWithFixes(&cur_periph.group_name, allocator, data);
                    }
                } else if (ascii.eqlIgnoreCase(chunk.tag, "baseAddress")) {
                    if (chunk.data) |data| {
                        cur_periph.base_address = parseIntLiteral(data);
                    }
                } else if (ascii.eqlIgnoreCase(chunk.tag, "addressBlock")) {
                    if (cur_periph.address_block) |_| {
                        // do nothing
                    } else {
                        const block = try svd.AddressBlock.init(allocator);
                        cur_periph.address_block = block;
                    }
                    state = .AddressBlock;
                } else if (ascii.eqlIgnoreCase(chunk.tag, "interrupt")) {
                    cur_interrupt = try svd.Interrupt.init(allocator);
                    state = .Interrupt;
                } else if (ascii.eqlIgnoreCase(chunk.tag, "registers")) {
                    state = .Registers;
                }
            },
            .AddressBlock => {
                var cur_periph = &dev.peripherals.items[dev.peripherals.items.len - 1];
                var address_block = &cur_periph.address_block.?;
                if (ascii.eqlIgnoreCase(chunk.tag, "/addressBlock")) {
                    state = .Peripheral;
                } else if (ascii.eqlIgnoreCase(chunk.tag, "offset")) {
                    if (chunk.data) |data| {
                        address_block.offset = parseIntLiteral(data);
                    }
                } else if (ascii.eqlIgnoreCase(chunk.tag, "size")) {
                    if (chunk.data) |data| {
                        address_block.size = parseIntLiteral(data);
                    }
                } else if (ascii.eqlIgnoreCase(chunk.tag, "usage")) {
                    if (chunk.data) |data| {
                        try appendSliceWithFixes(&address_block.usage, allocator, data);
                    }
                }
            },
            .Interrupt => {
                if (ascii.eqlIgnoreCase(chunk.tag, "/interrupt")) {
                    if (cur_interrupt.value) |value| {
                        // If we find a duplicate interrupt, deinit the old one
                        if (try dev.interrupts.fetchPut(value, cur_interrupt)) |old_entry| {
                            var old_interrupt = old_entry.value;
                            const old_name = old_interrupt.name.items;
                            const cur_name = cur_interrupt.name.items;
                            if (!mem.eql(u8, old_name, cur_name)) {
                                warn(
                                    \\ Found duplicate interrupt values with different names: {s} and {s}
                                    \\ The latter will be discarded.
                                    \\
                                , .{
                                    cur_name,
                                    old_name,
                                });
                            }
                            old_interrupt.deinit(allocator);
                        }
                    }
                    state = .Peripheral;
                } else if (ascii.eqlIgnoreCase(chunk.tag, "name")) {
                    if (chunk.data) |data| {
                        try appendSliceWithFixes(&cur_interrupt.name, allocator, data);
                    }
                } else if (ascii.eqlIgnoreCase(chunk.tag, "description")) {
                    if (chunk.data) |data| {
                        try appendSliceWithFixes(&cur_interrupt.description, allocator, data);
                    }
                } else if (ascii.eqlIgnoreCase(chunk.tag, "value")) {
                    if (chunk.data) |data| {
                        cur_interrupt.value = fmt.parseInt(u32, data, 10) catch null;
                    }
                }
            },
            .Registers => {
                var cur_periph = &dev.peripherals.items[dev.peripherals.items.len - 1];
                if (ascii.eqlIgnoreCase(chunk.tag, "/registers")) {
                    state = .Peripheral;
                } else if (ascii.eqlIgnoreCase(chunk.tag, "register")) {
                    const reset_value = dev.reg_default_reset_value orelse 0;
                    const size = dev.reg_default_size orelse 32;
                    const register = try svd.Register.init(allocator, cur_periph.name.items, reset_value, size);
                    try cur_periph.registers.append(allocator, register);
                    state = .Register;
                }
            },
            .Register => {
                var cur_periph = &dev.peripherals.items[dev.peripherals.items.len - 1];
                var cur_reg = &cur_periph.registers.items[cur_periph.registers.items.len - 1];
                if (ascii.eqlIgnoreCase(chunk.tag, "/register")) {
                    state = .Registers;
                } else if (ascii.eqlIgnoreCase(chunk.tag, "name")) {
                    if (chunk.data) |data| {
                        try appendSliceWithFixes(&cur_reg.name, allocator, data);
                    }
                } else if (ascii.eqlIgnoreCase(chunk.tag, "displayName")) {
                    if (chunk.data) |data| {
                        try appendSliceWithFixes(&cur_reg.display_name, allocator, data);
                    }
                } else if (ascii.eqlIgnoreCase(chunk.tag, "description")) {
                    if (chunk.data) |data| {
                        try appendSliceWithFixes(&cur_reg.description, allocator, data);
                    }
                } else if (ascii.eqlIgnoreCase(chunk.tag, "addressOffset")) {
                    if (chunk.data) |data| {
                        cur_reg.address_offset = parseIntLiteral(data);
                    }
                } else if (ascii.eqlIgnoreCase(chunk.tag, "size")) {
                    if (chunk.data) |data| {
                        cur_reg.size = parseIntLiteral(data) orelse cur_reg.size;
                    }
                } else if (ascii.eqlIgnoreCase(chunk.tag, "access")) {
                    if (chunk.data) |data| {
                        cur_reg.access = parseAccessValue(data) orelse cur_reg.access;
                    }
                } else if (ascii.eqlIgnoreCase(chunk.tag, "resetValue")) {
                    if (chunk.data) |data| {
                        cur_reg.reset_value = parseIntLiteral(data) orelse cur_reg.reset_value;
                    }
                } else if (ascii.eqlIgnoreCase(chunk.tag, "alternateRegister")) {
                    if (chunk.data) |data| {
                        try appendSliceWithFixes(&cur_reg.alternate_register, allocator, data);
                    }
                } else if (ascii.eqlIgnoreCase(chunk.tag, "fields")) {
                    state = .Fields;
                }
            },
            .Fields => {
                var cur_periph = &dev.peripherals.items[dev.peripherals.items.len - 1];
                var cur_reg = &cur_periph.registers.items[cur_periph.registers.items.len - 1];
                if (ascii.eqlIgnoreCase(chunk.tag, "/fields")) {
                    state = .Register;
                } else if (ascii.eqlIgnoreCase(chunk.tag, "field")) {
                    const field = try svd.Field.init(allocator, cur_periph.name.items, cur_reg.name.items, cur_reg.reset_value);
                    try cur_reg.fields.append(allocator, field);
                    state = .Field;
                }
            },
            .Field => {
                var cur_periph = &dev.peripherals.items[dev.peripherals.items.len - 1];
                var cur_reg = &cur_periph.registers.items[cur_periph.registers.items.len - 1];
                var cur_field = &cur_reg.fields.items[cur_reg.fields.items.len - 1];
                if (ascii.eqlIgnoreCase(chunk.tag, "/field")) {
                    state = .Fields;
                } else if (ascii.eqlIgnoreCase(chunk.tag, "name")) {
                    if (chunk.data) |data| {
                        try appendSliceWithFixes(&cur_field.name, allocator, data);
                    }
                } else if (ascii.eqlIgnoreCase(chunk.tag, "description")) {
                    if (chunk.data) |data| {
                        try appendSliceWithFixes(&cur_field.description, allocator, data);
                    }
                } else if (ascii.eqlIgnoreCase(chunk.tag, "bitOffset")) {
                    if (chunk.data) |data| {
                        cur_field.bit_offset = fmt.parseInt(u32, data, 10) catch null;
                    }
                } else if (ascii.eqlIgnoreCase(chunk.tag, "bitWidth")) {
                    if (chunk.data) |data| {
                        cur_field.bit_width = fmt.parseInt(u32, data, 10) catch null;
                    }
                } else if (ascii.eqlIgnoreCase(chunk.tag, "access")) {
                    if (chunk.data) |data| {
                        cur_field.access = parseAccessValue(data) orelse cur_field.access;
                    }
                } else if (ascii.eqlIgnoreCase(chunk.tag, "bitRange")) {
                    if (chunk.data) |data| {
                        const trimmed = mem.trim(u8, data, " []");
                        var token = mem.tokenizeAny(u8, trimmed, ":");
                        if (token.next()) |start| {
                            var start_val = fmt.parseInt(u32, start, 10) catch continue;
                            if (token.next()) |end| {
                                var end_val = fmt.parseInt(u32, end, 10) catch continue;

                                if (start_val > end_val) {
                                    const tmp = start_val;
                                    start_val = end_val;
                                    end_val = tmp;
                                }

                                cur_field.bit_offset = start_val;
                                cur_field.bit_width = 1 + end_val - start_val;
                            }
                        }
                    }
                }
            },
            .Finished => {
                // wait for EOF
            },
        }
    }
    if (state == .Finished) {
        try out_stream.print("{s}\n", .{register_def});
        try out_stream.print("{f}\n", .{dev});
    } else {
        return error.InvalidXML;
    }
}

const SvdParseState = enum {
    Device,
    Cpu,
    Peripherals,
    Peripheral,
    AddressBlock,
    Interrupt,
    Registers,
    Register,
    Fields,
    Field,
    Finished,
};

const XmlChunk = struct {
    tag: []const u8,
    data: ?[]const u8,
    derivedFrom: ?[]const u8,
};

fn getChunk(line: []const u8) ?XmlChunk {
    var chunk = XmlChunk{
        .tag = undefined,
        .data = null,
        .derivedFrom = null,
    };

    const trimmed = mem.trim(u8, line, " \r\n\t");
    var toker = mem.tokenizeAny(u8, trimmed, "<>"); //" =\n<>\"");

    if (toker.next()) |maybe_tag| {
        var tag_toker = mem.tokenizeAny(u8, maybe_tag, " =\"");
        chunk.tag = tag_toker.next() orelse return null;
        if (tag_toker.next()) |maybe_tag_property| {
            if (ascii.eqlIgnoreCase(maybe_tag_property, "derivedFrom")) {
                chunk.derivedFrom = tag_toker.next();
            }
        }
    } else {
        return null;
    }

    if (toker.next()) |chunk_data| {
        const chunk_data_trimmed = mem.trim(u8, chunk_data, " \r\n\t");
        chunk.data = chunk_data_trimmed;
    }

    return chunk;
}

fn appendSliceWithFixes(s: anytype, allocator: std.mem.Allocator, data: []const u8) !void {
    var token = mem.tokenizeAny(u8, data, " \r\n\t");
    var i: usize = 0;
    while (token.next()) |v| {
        if (i > 0) try s.appendSlice(allocator, " ");
        try s.appendSlice(allocator, v);
        i += 1;
    }
}

test "getChunk" {
    const valid_xml = "  <name>STM32F7x7</name>  \n";
    const expected_chunk = XmlChunk{ .tag = "name", .data = "STM32F7x7", .derivedFrom = null };

    const chunk = getChunk(valid_xml).?;
    try std.testing.expectEqualStrings(expected_chunk.tag, chunk.tag);
    try std.testing.expectEqualStrings(expected_chunk.data.?, chunk.data.?);

    const no_data_xml = "  <name> \n";
    const expected_no_data_chunk = XmlChunk{ .tag = "name", .data = null, .derivedFrom = null };
    const no_data_chunk = getChunk(no_data_xml).?;
    try std.testing.expectEqualStrings(expected_no_data_chunk.tag, no_data_chunk.tag);
    try std.testing.expectEqual(expected_no_data_chunk.data, no_data_chunk.data);

    const comments_xml = "<description>Auxiliary Cache Control register</description>";
    const expected_comments_chunk = XmlChunk{ .tag = "description", .data = "Auxiliary Cache Control register", .derivedFrom = null };
    const comments_chunk = getChunk(comments_xml).?;
    try std.testing.expectEqualStrings(expected_comments_chunk.tag, comments_chunk.tag);
    try std.testing.expectEqualStrings(expected_comments_chunk.data.?, comments_chunk.data.?);

    const derived = "   <peripheral derivedFrom=\"TIM10\">";
    const expected_derived_chunk = XmlChunk{ .tag = "peripheral", .data = null, .derivedFrom = "TIM10" };
    const derived_chunk = getChunk(derived).?;
    try std.testing.expectEqualStrings(expected_derived_chunk.tag, derived_chunk.tag);
    try std.testing.expectEqualStrings(expected_derived_chunk.derivedFrom.?, derived_chunk.derivedFrom.?);
    try std.testing.expectEqual(expected_derived_chunk.data, derived_chunk.data);
}

fn textToBool(data: []const u8) ?bool {
    if (ascii.eqlIgnoreCase(data, "true")) {
        return true;
    } else if (ascii.eqlIgnoreCase(data, "false")) {
        return false;
    } else {
        return null;
    }
}

fn parseIntLiteral(data: []const u8) ?u32 {
    return fmt.parseInt(u32, data, 0) catch null;
}

fn parseAccessValue(data: []const u8) ?svd.Access {
    if (ascii.eqlIgnoreCase(data, "read-write")) {
        return .ReadWrite;
    } else if (ascii.eqlIgnoreCase(data, "read-only")) {
        return .ReadOnly;
    } else if (ascii.eqlIgnoreCase(data, "write-only")) {
        return .WriteOnly;
    }
    return null;
}

test {
    _ = svd;
    _ = @import("register.zig");
}
