const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const root_module = b.addModule("nf_ziglibs_ai_pathfinder", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .strip = (optimize != .Debug),
    });

    const isDynamic = b.option(bool, "dynamic", "dynamic") orelse false;

    const lib = b.addLibrary(.{
        .name = "nf_ziglibs_ai_pathfinder",
        .linkage = if (isDynamic) .dynamic else .static,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src//exports.zig"),
            .target = target,
            .optimize = optimize,
            .strip = (optimize != .Debug),
        }),
    });

    lib.rdynamic = true;
    lib.entry = .disabled;
    
    b.installArtifact(lib);

    // _ = b.standardTargetOptions(.{});
    // _ = b.standardOptimizeOption(.{});
    //
    // const step = b.step("task", "do something");
    // step.makeFn = myTask;
    // b.default_step = step;

//    target.result.os.tag == .ios
//    if (target.result.cpu.arch == .aarch64)

//    const custom_path = b.fmt("a/b/{s}", .{lib.out_lib_filename});
//    const custom_install = b.addInstallFile(
//        lib.getEmittedBin(),
//        custom_path,
//    );
//    b.getInstallStep().dependOn(&custom_install.step);

    const mod_tests = b.addTest(.{
        .root_module = root_module,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
}

fn myTask(step: *std.Build.Step, options: std.Build.Step.MakeOptions) !void {
    std.debug.print("Hello!\n", .{});
    _ = options;
    _ = step;
}

// fn Hello(step: *std.Build.Step, options: std.Build.Step.MakeOptions) !void {
//     _ = options;
//
//     const target = b.standardTargetOptions(.{});
//     const optimize = b.standardOptimizeOption(.{});
//
//     const root_module = b.createModule(.{
//         .root_source_file = b.path("src/main.zig"),
//         .target = target,
//         .optimize = optimize,
//     });
//
//     const lib = b.addLibrary(.{
//         .name = "nf_ziglibs_ai_pathfinder",
//         .root_module = root_module,
//         .linkage = .dynamic,
//     });
//     //
//     // // _ = lib.getEmittedH();
//     b.installArtifact(lib);
//     // const install_lib = b.addInstallArtifact(lib, .{ .h_dir = .{ .override = .header } });
//     // install_lib.emitted_h = lib.getEmittedH();
//     // b.getInstallStep().dependOn(&install_lib.step);
//     const copy_to_a = b.option(bool, "a", "Copy DLL to ../a directory") orelse false;
//
//     if (copy_to_a) {
//         const copy_file = b.addInstallFile(
//             lib.getEmittedBin(),
//             "../../a/nf_ziglibs_ai_pathfinder.dll",
//         );
//
//         b.getInstallStep().dependOn(&copy_file.step);
//     }
// }
