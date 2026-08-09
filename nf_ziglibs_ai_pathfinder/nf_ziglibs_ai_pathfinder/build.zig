const std = @import("std");

const PlatformOption = struct {
    step_name: []const u8,
    targets: []const std.Build.ResolvedTarget,
    linkage: std.builtin.LinkMode,
    optimize: std.builtin.OptimizeMode,
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const platformOptions: []const PlatformOption = &.{
        .{
            .step_name = "windows",
            .targets = &.{
                b.resolveTargetQuery(.{
                    .os_tag = .windows,
                    .cpu_arch = .x86_64,
                }),
                b.resolveTargetQuery(.{
                    .os_tag = .windows,
                    .cpu_arch = .aarch64,
                }),
            },
            .linkage = .dynamic,
            .optimize = optimize,
        },
        .{
            .step_name = "linux",
            .targets = &.{
                b.resolveTargetQuery(.{
                    .os_tag = .linux,
                    .cpu_arch = .x86_64,
                }),
                b.resolveTargetQuery(.{
                    .os_tag = .linux,
                    .cpu_arch = .aarch64,
                }),
            },
            .linkage = .dynamic,
            .optimize = optimize,
        },
        .{
            .step_name = "macos",
            .targets = &.{
                b.resolveTargetQuery(.{
                    .os_tag = .macos,
                    .cpu_arch = .aarch64,
                    .os_version_min = .{ .semver = .{ .major = 13, .minor = 0, .patch = 0 } },
                }),
            },
            .linkage = .dynamic,
            .optimize = optimize,
        },
        .{
            .step_name = "ios",
            .targets = &.{
                b.resolveTargetQuery(.{
                    .os_tag = .ios,
                    .cpu_arch = .aarch64,
                    .abi = null,
                    .os_version_min = .{ .semver = .{ .major = 12, .minor = 0, .patch = 0 } },
                }),
                b.resolveTargetQuery(.{
                    .os_tag = .ios,
                    .cpu_arch = .aarch64,
                    .abi = .simulator,
                    .os_version_min = .{ .semver = .{ .major = 12, .minor = 0, .patch = 0 } },
                }),
            },
            .linkage = .static,
            .optimize = optimize,
        },
        .{
            .step_name = "tvos",
            .targets = &.{
                b.resolveTargetQuery(.{
                    .os_tag = .tvos,
                    .cpu_arch = .aarch64,
                    .os_version_min = .{ .semver = .{ .major = 13, .minor = 0, .patch = 0 } },
                }),
                b.resolveTargetQuery(.{
                    .os_tag = .tvos,
                    .cpu_arch = .aarch64,
                    .abi = .simulator,
                    .os_version_min = .{ .semver = .{ .major = 13, .minor = 0, .patch = 0 } },
                }),
            },
            .linkage = .static,
            .optimize = optimize,
        },
        .{
            .step_name = "android",
            .targets = &.{
                b.resolveTargetQuery(.{
                    .os_tag = .linux,
                    .cpu_arch = .aarch64,
                    .abi = .android,
                    .os_version_min = .{ .semver = .{ .major = 24, .minor = 0, .patch = 0 } },
                }),
            },
            .linkage = .dynamic,
            .optimize = optimize,
        },
        .{
            .step_name = "wasm",
            .targets = &.{
                b.resolveTargetQuery(.{
                    .os_tag = .freestanding,
                    .cpu_arch = .wasm32,
                    .abi = .none,
                }),
            },
            .linkage = .static,
            .optimize = optimize,
        },
    };

    const all_step = b.step("all", "Build libraries for all target platforms");
    for (platformOptions) |platformOption| {
        const step = AddPlatformStep(b, platformOption);
        all_step.dependOn(step);
    }

    // ===========================================
    // for test
    // ===========================================
    const root_module = b.addModule("nf_ziglibs_ai_pathfinder", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .strip = (optimize != .Debug),
    });

    const mod_tests = b.addTest(.{
        .root_module = root_module,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
}

fn AddPlatformStep(b: *std.Build, opt: PlatformOption) *std.Build.Step {
    const step_desc = b.fmt("Build library for {s}", .{opt.step_name});
    const ret = b.step(opt.step_name, step_desc);

    for (opt.targets) |target| {
        const lib = b.addLibrary(.{
            .name = "nf_ziglibs_ai_pathfinder",
            .linkage = opt.linkage,
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/exports.zig"),
                .target = target,
                .optimize = opt.optimize,
                .strip = (opt.optimize != .Debug),
            }),
        });

        lib.rdynamic = true;
        lib.entry = .disabled;

        const folder_name = if (target.result.abi == .simulator)
            b.fmt("{s}_{s}_simulator", .{
                @tagName(target.result.os.tag),
                @tagName(target.result.cpu.arch),
            })
        else if (target.result.abi == .android)
            b.fmt("android_{s}", .{
                @tagName(target.result.cpu.arch),
            })
        else
            b.fmt("{s}_{s}", .{
                @tagName(target.result.os.tag),
                @tagName(target.result.cpu.arch),
            });

        const is_windows = target.result.os.tag == .windows;
        if (is_windows) {
            const install = b.addInstallArtifact(lib, .{
                .dest_dir = .{ .override = .{ .custom = folder_name } },
                .implib_dir = .{ .override = .{ .custom = folder_name } },
                .pdb_dir = if (opt.optimize == .Debug) .{ .override = .{ .custom = folder_name } } else .default,
            });
            ret.dependOn(&install.step);
        } else {
            const install = b.addInstallArtifact(lib, .{
                .dest_dir = .{ .override = .{ .custom = folder_name } },
            });
            ret.dependOn(&install.step);
        }
    }

    return ret;
}
