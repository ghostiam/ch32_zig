const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const exe = b.addExecutable(.{
        .name = "svd4zig",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    b.installArtifact(exe);

    const test_step = b.step("test", "Run tests");
    const unit_tests = b.addTest(.{
        .name = "svd4zig",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
        .test_runner = .{ .path = b.path("test_runner.zig"), .mode = .simple },
    });
    const unit_tests_run = b.addRunArtifact(unit_tests);
    test_step.dependOn(&unit_tests_run.step);
}
