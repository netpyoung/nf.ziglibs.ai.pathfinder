const std = @import("std");
const int2 = @import("./Common/int2.zig").int2;

const IMap = @This();

ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    vptr_GetWidth: *const fn (*anyopaque) i32,
    vptr_GetHeight: *const fn (*anyopaque) i32,
    vptr_SetWallAt: *const fn (*anyopaque, x: i32, y: i32, isWall: bool) void,
    vptr_SetEmptyAt: *const fn (*anyopaque, x: i32, y: i32, isWall: bool) void,
    vptr_IsWallAt: *const fn (*anyopaque, x: i32, y: i32) bool,
    vptr_IsEmptyAt: *const fn (*anyopaque, x: i32, y: i32) bool,
};

pub inline fn GetWidth(this: IMap) i32 {
    return this.vtable.vptr_GetWidth(this.ptr);
}

pub inline fn GetHeight(this: IMap) i32 {
    return this.vtable.vptr_GetHeight(this.ptr);
}

pub inline fn SetWallAt(this: IMap, x: i32, y: i32, isWall: bool) void {
    this.vtable.vptr_SetWallAt(this.ptr, x, y, isWall);
}

pub inline fn SetEmptyAt(this: IMap, x: i32, y: i32, isWall: bool) void {
    this.vtable.vptr_SetEmptyAt(this.ptr, x, y, isWall);
}

pub inline fn IsWallAt(this: IMap, x: i32, y: i32) bool {
    return this.vtable.vptr_IsWallAt(this.ptr, x, y);
}

pub inline fn IsEmptyAt(this: IMap, x: i32, y: i32) bool {
    return this.vtable.vptr_IsEmptyAt(this.ptr, x, y);
}


pub fn LoadMapFromCollisionFile(io: std.Io, allocator: std.mem.Allocator, map: IMap, collisionFilePath: []const u8) !void {
    const contents = try std.Io.Dir.cwd().readFileAlloc(io, collisionFilePath, allocator, .unlimited);
    defer allocator.free(contents);

    LoadFromCollisionsStr(map, contents);
}

pub fn LoadFromCollisionsStr(map: IMap, collisionStr: []const u8) void {
    const width = map.GetWidth();
    //    const height = map.GetHeight();

    var lines = std.mem.splitAny(u8, collisionStr, "\r\n");
    while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        var tokens = std.mem.splitScalar(u8, line, ',');
        while (tokens.next()) |token| {
            const trimmed = std.mem.trim(u8, token, " \t");
            if (trimmed.len == 0) {
                continue;
            }

            const index = std.fmt.parseInt(i32, trimmed, 10) catch continue;
            const x = @rem(index, width);
            const y = @divTrunc(index, width);
            map.SetWallAt(x, y, true);
        }
    }
}
