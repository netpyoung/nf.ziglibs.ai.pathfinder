const std = @import("std");
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const dep_pathfinder = b.dependency("nf_ziglibs_ai_pathfinder", .{
        .target = target,
        .optimize = optimize,
    });

    const mod_pathfinder = dep_pathfinder.module("nf_ziglibs_ai_pathfinder");

    const exe = b.addExecutable(.{
        .name = "Sample_Benchmark",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "nf_ziglibs_ai_pathfinder", .module = mod_pathfinder },
            },
        }),
    });

    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
