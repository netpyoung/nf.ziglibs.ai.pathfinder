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
        .name = "Sample_Raylib",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "nf_ziglibs_ai_pathfinder", .module = mod_pathfinder },
            },
        }),
    });

    {
        // setup raylib
        // ref: https://github.com/raylib-zig/raylib-zig

        const raylib_dep = b.dependency("raylib_zig", .{
            .target = target,
            .optimize = optimize,
        });

        const raylib = raylib_dep.module("raylib"); // main raylib module
        const raygui = raylib_dep.module("raygui"); // raygui module
        const raylib_artifact = raylib_dep.artifact("raylib"); // raylib C library
        exe.root_module.linkLibrary(raylib_artifact);
        exe.root_module.addImport("raylib", raylib);
        exe.root_module.addImport("raygui", raygui);
    }

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
}
