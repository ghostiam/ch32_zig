const std = @import("std");

var writer: ?*std.Io.Writer = null;

pub fn setWriter(w: ?*std.Io.Writer) void {
    comptime {
        const root = @import("root");
        if (!@hasDecl(root, "ch32_options") or root.ch32_options.logFn == nopFn) {
            @compileError(
                \\Writer is set but logFn is not defined.
                \\Add to your main file:
                \\    const ch32 = @import("ch32");
                \\    pub const ch32_options: ch32.Options = .{
                \\        .log_level = .debug,
                \\        .logFn = hal.log.logFn,
                \\    };
            );
        }
    }

    writer = w;
}

pub fn nopFn(
    comptime _: std.log.Level,
    comptime _: @Type(.enum_literal),
    comptime _: []const u8,
    _: anytype,
) void {}

pub fn logFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const prefix = comptime level.asText() ++ switch (scope) {
        .default => ": ",
        else => " (" ++ @tagName(scope) ++ "): ",
    };

    if (writer) |w| {
        w.print(prefix ++ format ++ "\n", args) catch {};
    }
}
