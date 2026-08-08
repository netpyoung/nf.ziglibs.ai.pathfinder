const std = @import("std");
const int2 = @import("./Common/int2.zig").int2;

const SearcherError = @import("./errors.zig").SearcherError;
const E_SMOOTHMETHOD = @import("./root.zig").E_SMOOTHMETHOD;

const IPathFinder = @This();

ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    vptr_Deinit: *const fn (*anyopaque, allocator: std.mem.Allocator) void,
    vptr_Search: *const fn (
        *anyopaque,
        allocator: std.mem.Allocator,
        sx: i32,
        sy: i32,
        gx: i32,
        gy: i32,
        smoothMethod: E_SMOOTHMETHOD,
        resultNodes: *std.ArrayList(int2),
    ) SearcherError!i32,
    vptr_EnsureOpenlistTotalCapacity: *const fn (*anyopaque, allocator: std.mem.Allocator, capacity: u32) std.mem.Allocator.Error!usize,
    vptr_EnsurePathbufferTotalCapacity: *const fn (*anyopaque, allocator: std.mem.Allocator, capacity: u32) std.mem.Allocator.Error!usize,
};

pub inline fn Deinit(this: IPathFinder, allocator: std.mem.Allocator) void {
    this.vtable.vptr_Deinit(this.ptr, allocator);
}

pub inline fn Search(
    this: IPathFinder,
    allocator: std.mem.Allocator,
    sx: i32,
    sy: i32,
    gx: i32,
    gy: i32,
    smoothMethod: E_SMOOTHMETHOD,
    resultNodes: *std.ArrayList(int2),
) !i32 {
    return this.vtable.vptr_Search(this.ptr, allocator, sx, sy, gx, gy, smoothMethod, resultNodes);
}

pub inline fn EnsureOpenlistTotalCapacity(this: IPathFinder, allocator: std.mem.Allocator, capacity: u32) std.mem.Allocator.Error!usize {
    return this.vtable.vptr_EnsureOpenlistTotalCapacity(this.ptr, allocator, capacity);
}
pub inline fn EnsurePathbufferTotalCapacity(this: IPathFinder, allocator: std.mem.Allocator, capacity: u32) std.mem.Allocator.Error!usize {
    return this.vtable.vptr_EnsurePathbufferTotalCapacity(this.ptr, allocator, capacity);
}
