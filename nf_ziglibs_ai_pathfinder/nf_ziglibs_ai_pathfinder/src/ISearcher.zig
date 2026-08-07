const std = @import("std");
const int2 = @import("./Common/int2.zig").int2;

const ISearcher = @This();

ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    vptr_Search: *const fn (*anyopaque, allocator: std.mem.Allocator, sx: i32, sy: i32, gx: i32, gy: i32, resultNodes: *std.ArrayList(int2)) anyerror!bool,
};

pub fn Search(this: ISearcher, allocator: std.mem.Allocator, sx: i32, sy: i32, gx: i32, gy: i32, resultNodes: *std.ArrayList(int2)) !bool {
    return this.vtable.vptr_Search(this.ptr, allocator, sx, sy, gx, gy, resultNodes);
}
