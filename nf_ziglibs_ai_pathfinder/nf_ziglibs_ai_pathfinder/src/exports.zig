const std = @import("std");
const builtin = @import("builtin");

pub const int2 = @import("./Common/int2.zig").int2;

pub const JpsbMap = @import("./Jpsb/JpsbMap.zig");
pub const Searcher_Jpsb = @import("./Jpsb/Searcher_Jpsb.zig");

pub const Pathfinder_Jpsb = @import("./Pathfinder_Jpsb.zig");
pub const IPathfinder = @import("./IPathfinder.zig");

pub const E_SMOOTHMETHOD = enum(i32) {
    NONE = 0,
    BRESENHAM_THICKLINE = 1,
    BRESENHAM_THINLINE = 2,
};

pub const E_ERRORCODE = enum(i32) {
    NONE = 0,

    INVALID_OUTPUT_PTR = -1,
    FAIL_TO_ALLOCATE = -2,

    DEBUGGER_ALLOCATOR_ALREADY_ENABLED = -100,
    DEBUGGER_ALLOCATOR_NEED_TO_INIT = -101,
    DEBUGGER_ALLOCATOR_DETECT_LEAK = -103,

    ERR_PATHFINDER_INVALID_PATHFINDER_PTR = -1000,
    ERR_PATHFINDER_INVALID_OUTBUF_PTR = -1001,
    ERR_PATHFINDER_FAIL_TO_SEARCH = -1002,
    ERR_PATHFINDER_NOT_ENOUGH_OUTBUF_SIZE = -1003,
};

var gpa = std.heap.DebugAllocator(.{ .safety = true, .stack_trace_frames = 16 }){};
const gpa_allocator = blk: {
    if (builtin.is_test) {
        break :blk std.testing.allocator;
    }

    if (builtin.os.tag == .freestanding) {
        break :blk std.heap.wasm_allocator;
    }
    break :blk gpa.allocator();
};

var s_isUseDebuggerAllocator: std.atomic.Value(bool) = .init(false);
var s_allocator: std.mem.Allocator = blk: {
    if (builtin.is_test) {
        break :blk std.testing.allocator;
    }

    if (builtin.os.tag == .freestanding) {
        break :blk std.heap.wasm_allocator;
    }
    break :blk std.heap.smp_allocator;
};

// =========================================
// pf_debug_allocator_
// =========================================
pub export fn pf_debug_allocator_init() callconv(.c) E_ERRORCODE {
    if (s_isUseDebuggerAllocator.swap(true, .acquire)) {
        return E_ERRORCODE.DEBUGGER_ALLOCATOR_ALREADY_ENABLED;
    }
    s_allocator = gpa_allocator;
    return E_ERRORCODE.NONE;
}

pub export fn pf_debug_allocator_deinit() callconv(.c) E_ERRORCODE {
    if (!s_isUseDebuggerAllocator.swap(false, .release)) {
        return E_ERRORCODE.DEBUGGER_ALLOCATOR_NEED_TO_INIT;
    }

    if (builtin.os.tag == .freestanding) {
        return E_ERRORCODE.NONE;
    } else {
        const result = gpa.deinit();
        s_allocator = blk: {
            if (builtin.is_test) {
                break :blk std.testing.allocator;
            }

            if (builtin.os.tag == .freestanding) {
                break :blk std.heap.wasm_allocator;
            }
            break :blk std.heap.smp_allocator;
        };

        switch (result) {
            .ok => {
                return E_ERRORCODE.NONE;
            },
            .leak => {
                return E_ERRORCODE.DEBUGGER_ALLOCATOR_DETECT_LEAK;
            },
        }
    }
}

// =========================================
// pf_jpsb_map_
// =========================================
pub export fn pf_jpsb_map_create(width: i32, height: i32, outMap: **JpsbMap) callconv(.c) E_ERRORCODE {
    const map = s_allocator.create(JpsbMap) catch return E_ERRORCODE.FAIL_TO_ALLOCATE;
    map.* = JpsbMap.Init(s_allocator, width, height) catch return E_ERRORCODE.FAIL_TO_ALLOCATE;
    outMap.* = map;
    return E_ERRORCODE.NONE;
}

pub export fn pf_jpsb_map_destroy(map: *JpsbMap) E_ERRORCODE {
    map.Deinit(s_allocator);
    s_allocator.destroy(map);
    return E_ERRORCODE.NONE;
}

pub export fn pf_jpsb_map_set_wall_at(map: *JpsbMap, x: i32, y: i32, isWall: bool) callconv(.c) void {
    map.SetWallAt(x, y, isWall);
}

pub export fn pf_jpsb_map_set_empty_at(map: *JpsbMap, x: i32, y: i32, isEmpty: bool) callconv(.c) void {
    map.SetEmptyAt(x, y, isEmpty);
}

pub export fn pf_jpsb_map_is_wall_at(map: *const JpsbMap, x: i32, y: i32) callconv(.c) bool {
    return map.IsWallAt(x, y);
}

pub export fn pf_jpsb_map_is_empty_at(map: *const JpsbMap, x: i32, y: i32) callconv(.c) bool {
    return map.IsEmptyAt(x, y);
}

pub export fn pf_jpsb_map_get_width(map: *const JpsbMap) callconv(.c) i32 {
    return map.width;
}

pub export fn pf_jpsb_map_get_height(map: *const JpsbMap) callconv(.c) i32 {
    return map.height;
}

// =========================================
// pf_jpsb_pathfinder_
// =========================================

pub export fn pf_jpsb_pathfinder_create(map: *const JpsbMap, outPathfinder: **IPathfinder) callconv(.c) E_ERRORCODE {
    const pathfinder_jpsb = s_allocator.create(Pathfinder_Jpsb) catch return E_ERRORCODE.FAIL_TO_ALLOCATE;
    pathfinder_jpsb.* = Pathfinder_Jpsb.Init(s_allocator, map) catch return E_ERRORCODE.FAIL_TO_ALLOCATE;
    pathfinder_jpsb.interface.ptr = pathfinder_jpsb;

    const pathfinder = &pathfinder_jpsb.interface;
    outPathfinder.* = pathfinder;
    return E_ERRORCODE.NONE;
}

pub export fn pf_jpsb_pathfinder_destroy(pathfinder: *IPathfinder) callconv(.c) E_ERRORCODE {
    pathfinder.Deinit(s_allocator);

    const pathfinder_jpsb: *Pathfinder_Jpsb = @ptrCast(@alignCast(pathfinder.ptr));
    s_allocator.destroy(pathfinder_jpsb);
    return E_ERRORCODE.NONE;
}

// =========================================
// pf_pathfinder_
// =========================================

pub export fn pf_pathfinder_find_path_with_smoothmethod(
    pathfinder: *IPathfinder,
    sx: i32,
    sy: i32,
    ex: i32,
    ey: i32,
    smoothmode: E_SMOOTHMETHOD,
    out_buf: [*]int2,
    max_len: i32,
) callconv(.c) i32 {
    return _pf_pathfinder_find_path_with_smoothmethod(pathfinder, sx, sy, ex, ey, smoothmode, out_buf, max_len);
}

pub export fn pf_pathfinder_openlist_ensuretotalcapacity(pathfinder: *IPathfinder, capacity: u32) callconv(.c) i32 {
    const len = pathfinder.EnsureOpenlistTotalCapacity(s_allocator, capacity) catch return -1;
    return @intCast(len);
}

pub export fn pf_pathfinder_pathbuffer_ensuretotalcapacity(pathfinder: *IPathfinder, capacity: u32) callconv(.c) i32 {
    const len = pathfinder.EnsurePathbufferTotalCapacity(s_allocator, capacity) catch return -1;
    return @intCast(len);
}

// =========================================
// internal
// =========================================
inline fn _pf_pathfinder_find_path_with_smoothmethod(
    pathfinder: *IPathfinder,
    sx: i32,
    sy: i32,
    ex: i32,
    ey: i32,
    smoothmode: E_SMOOTHMETHOD,
    out_buf: [*]int2,
    max_len: i32,
) i32 {
    if (@intFromPtr(pathfinder) == 0) {
        return @intFromEnum(E_ERRORCODE.ERR_PATHFINDER_INVALID_PATHFINDER_PTR);
    }
    if (@intFromPtr(out_buf) == 0) {
        return @intFromEnum(E_ERRORCODE.ERR_PATHFINDER_INVALID_OUTBUF_PTR);
    }
    const buffer = out_buf[0..@intCast(max_len)];

    var arr = std.ArrayList(int2).initBuffer(buffer);
    const searchResult = pathfinder.Search(s_allocator, sx, sy, ex, ey, smoothmode, &arr) catch unreachable;
    return searchResult;
}

// =========================================
// test
// =========================================

test "simple" {
    var err: E_ERRORCODE = undefined;
    var map: *JpsbMap = undefined;
    err = pf_jpsb_map_create(100, 100, &map);
    try std.testing.expect(err == .NONE);
    defer {
        _ = pf_jpsb_map_destroy(map);
    }

    pf_jpsb_map_set_wall_at(map, 1, 1, true);
    pf_jpsb_map_set_wall_at(map, 1, 2, true);

    var pathfinder: *IPathfinder = undefined;
    err = pf_jpsb_pathfinder_create(map, &pathfinder);
    try std.testing.expect(err == .NONE);
    defer {
        _ = pf_jpsb_pathfinder_destroy(pathfinder);
    }

    var arr: [50]int2 = undefined;
    const len = pf_pathfinder_find_path_with_smoothmethod(pathfinder, 0, 0, 99, 99, .BRESENHAM_THICKLINE, &arr, arr.len);
    try std.testing.expect(len > 0);
}
