const std = @import("std");

const int2 = @import("./int2.zig").int2;

pub const E_VISITED_STATUS = enum(i32) {
    NONE = 0,
    OPENED = 1,
    CLOSED = 2,
};

pub const PathNode_gf_i32 = struct {
    ParentOrNull: ?*PathNode_gf_i32,
    Pos: int2,
    G: u32,
    F: u32,
    Status: E_VISITED_STATUS,
    HeapIndex: u32,

    pub const empty = PathNode_gf_i32{
        .ParentOrNull = null,
        .Pos = int2.ZERO,
        .G = 0,
        .F = 0,
        .Status = .NONE,
        .HeapIndex = 0,
    };

    pub fn CompareFn(_: void, a: *PathNode_gf_i32, b: *PathNode_gf_i32) std.math.Order {
        if (a == b) {
            return .eq;
        }

        if (a.F < b.F) {
            return .lt;
        }
        return .gt;
    }

    pub fn GetHeapIndexRef(x: *PathNode_gf_i32) *u32 {
        return &x.HeapIndex;
    }

    pub fn GetPos(p: *const PathNode_gf_i32) int2 {
        return p.Pos;
    }

    pub fn format(p: *PathNode_gf_i32, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        try writer.print("PathNode(Pos={f}, G={d}, F={d})", .{ p.Pos, p.G, p.F });
    }
};

pub const PathNode_g_i32 = struct {
    ParentOrNull: ?*PathNode_g_i32,
    Pos: int2,
    G: u32,
    Status: E_VISITED_STATUS,
    HeapIndex: u32,

    pub const empty = PathNode_g_i32{
        .ParentOrNull = null,
        .Pos = int2.ZERO,
        .G = 0,
        .Status = .NONE,
        .HeapIndex = 0,
    };

    pub fn CompareFn(_: void, a: *PathNode_g_i32, b: *PathNode_g_i32) std.math.Order {
        if (a == b) {
            return .eq;
        }

        if (a.G <= b.G) {
            return .lt;
        }
        return .gt;
    }

    pub fn GetHeapIndexRef(x: *PathNode_g_i32) *u32 {
        return &x.HeapIndex;
    }

    pub fn GetPos(p: *const PathNode_g_i32) int2 {
        return p.Pos;
    }

    pub fn format(p: *PathNode_g_i32, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        try writer.print("PathNode(Pos={f}, G={d})", .{ p.Pos, p.G });
    }
};

pub const PathNode_gf_i32_with_grid_id = struct {
    This_grid_id_p: u32,
    Parent_grid_id_p: u32,
    Pos: int2,
    G: u32,
    F: u32,
    Status: E_VISITED_STATUS,
    HeapIndex: u32,

    pub const ID_MAX = std.math.maxInt(u32);
    pub const INVALID_ID = ID_MAX;
    pub const NO_PARENT = ID_MAX;

    const PathNode = @This();

    pub const empty = PathNode{
        .This_grid_id_p = INVALID_ID,
        .Parent_grid_id_p = NO_PARENT,
        .Pos = int2.ZERO,
        .G = 0,
        .F = 0,
        .Status = .NONE,
        .HeapIndex = 0,
    };

    pub fn CompareFn(_: void, a: *PathNode, b: *PathNode) std.math.Order {
        if (a == b) {
            return .eq;
        }

        if (a.F < b.F) {
            return .lt;
        }
        return .gt;
    }

    pub fn GetHeapIndexRef(x: *PathNode) *u32 {
        return &x.HeapIndex;
    }

    pub fn GetPos(p: *const PathNode) int2 {
        return p.Pos;
    }

    pub fn format(p: *PathNode, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        try writer.print("PathNode(grid_id_p={}, Pos={f}, G={d}, F={d})", .{ p.This_grid_id_p, p.Pos, p.G, p.F });
    }
};
