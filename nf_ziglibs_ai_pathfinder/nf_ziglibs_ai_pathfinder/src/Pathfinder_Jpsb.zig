const std = @import("std");
const builtin = @import("builtin");

const int2 = @import("./Common/int2.zig").int2;
const BresenhamPathSmoother = @import("./Common/BresenhamPathSmoother.zig");

pub const JpsbMap = @import("./Jpsb/JpsbMap.zig");
pub const Searcher_Jpsb = @import("./Jpsb/Searcher_Jpsb.zig");
const E_SMOOTHMETHOD = @import("./root.zig").E_SMOOTHMETHOD;
const IPathfinder = @import("./IPathfinder.zig");
const E_ERRORCODE = @import("./exports.zig").E_ERRORCODE;

pub const Pathfinder_Jpsb = @This();
jpsb: Searcher_Jpsb,
map: *const JpsbMap,
pathBuffer: std.ArrayList(int2),
interface: IPathfinder,

pub fn Init(allocator: std.mem.Allocator, map: *const JpsbMap) !Pathfinder_Jpsb {
    var jpsb = try Searcher_Jpsb.Init(allocator, map);
    try jpsb.openQueue.EnsureTotalCapacity(allocator, @intCast(@divTrunc(map.width * map.height, 16)));

    const pathBuffer = try std.ArrayList(int2).initCapacity(allocator, @intCast(map.width + map.height));

    return .{
        .jpsb = jpsb,
        .map = map,
        .pathBuffer = pathBuffer,
        .interface = .{
            .ptr = undefined,
            .vtable = &Interface.vtable,
        },
    };
}

pub fn Search(
    this: *Pathfinder_Jpsb,
    allocator: std.mem.Allocator,
    ax: i32,
    ay: i32,
    bx: i32,
    by: i32,
    smoothMethod: E_SMOOTHMETHOD,
    resultNodes: *std.ArrayList(int2),
) anyerror!i32 {
    const isFound = try this.jpsb.Search(allocator, ax, ay, bx, by, &this.pathBuffer);
    if (!isFound) {
        return @intFromEnum(E_ERRORCODE.ERR_PATHFINDER_FAIL_TO_SEARCH);
    }

    if (this.pathBuffer.items.len > resultNodes.capacity) {
        return @intFromEnum(E_ERRORCODE.ERR_PATHFINDER_NOT_ENOUGH_OUTBUF_SIZE);
    }

    resultNodes.clearRetainingCapacity();
    switch (smoothMethod) {
        .NONE => {
            for (this.pathBuffer.items) |p| {
                resultNodes.appendAssumeCapacity(p);
            }
        },
        .BRESENHAM_THICKLINE => {
            const smoother = BresenhamPathSmoother.BresenhamPathSmoother_WithoutAlloc(*const JpsbMap, JpsbMap.IsWallAt).initContext(this.map);
            try smoother.Smooth_Thickline_WithoutAlloc(this.pathBuffer.items, resultNodes);
        },
        .BRESENHAM_THINLINE => {
            const smoother = BresenhamPathSmoother.BresenhamPathSmoother_WithoutAlloc(*const JpsbMap, JpsbMap.IsWallAt).initContext(this.map);
            try smoother.Smooth_Thinline_WithoutAlloc(this.pathBuffer.items, resultNodes);
        },
    }
    return @intCast(resultNodes.items.len);
}

pub fn EnsureOpenlistTotalCapacity(this: *Pathfinder_Jpsb, allocator: std.mem.Allocator, capacity: u32) !usize {
    const size: u32 = @intCast(std.math.clamp(capacity, 512, this.map.width * this.map.height));
    try this.jpsb.openQueue.EnsureTotalCapacity(allocator, size);
    return @intCast(this.jpsb.openQueue._arraylist.capacity);
}

pub fn EnsurePathbufferTotalCapacity(this: *Pathfinder_Jpsb, allocator: std.mem.Allocator, capacity: u32) !usize {
    const size: usize = @intCast(std.math.clamp(capacity, 256, this.map.width * this.map.height));
    try this.pathBuffer.ensureTotalCapacity(allocator, size);
    return @intCast(this.pathBuffer.capacity);
}

fn Deinit(this: *Pathfinder_Jpsb, allocator: std.mem.Allocator) void {
    this.jpsb.Deinit(allocator);
    this.pathBuffer.deinit(allocator);
}

const Interface = struct {
    const This = Pathfinder_Jpsb;

    pub const vtable: IPathfinder.VTable = .{
        .vptr_Search = _vptr_Search,
        .vptr_Deinit = _vptr_Deinit,
        .vptr_EnsureOpenlistTotalCapacity = _vptr_EnsureOpenlistTotalCapacity,
        .vptr_EnsurePathbufferTotalCapacity = _vptr_EnsurePathbufferTotalCapacity,
    };

    fn _vptr_Search(context: *anyopaque, allocator: std.mem.Allocator, ax: i32, ay: i32, bx: i32, by: i32, smoothMethod: E_SMOOTHMETHOD, resultNodes: *std.ArrayList(int2)) !i32 {
        const this: *This = @ptrCast(@alignCast(context));
        return this.Search(allocator, ax, ay, bx, by, smoothMethod, resultNodes);
    }

    fn _vptr_Deinit(context: *anyopaque, allocator: std.mem.Allocator) void {
        const this: *This = @ptrCast(@alignCast(context));
        this.Deinit(allocator);
    }

    fn _vptr_EnsureOpenlistTotalCapacity(context: *anyopaque, allocator: std.mem.Allocator, capacity: u32) !usize {
        const this: *This = @ptrCast(@alignCast(context));
        return this.EnsureOpenlistTotalCapacity(allocator, capacity);
    }

    fn _vptr_EnsurePathbufferTotalCapacity(context: *anyopaque, allocator: std.mem.Allocator, capacity: u32) !usize {
        const this: *This = @ptrCast(@alignCast(context));
        return this.EnsurePathbufferTotalCapacity(allocator, capacity);
    }
};
