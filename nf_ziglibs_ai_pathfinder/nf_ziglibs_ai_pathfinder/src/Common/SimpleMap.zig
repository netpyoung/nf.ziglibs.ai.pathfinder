const std = @import("std");

const IMap = @import("../IMap.zig");
const int2 = @import("./int2.zig").int2;

pub const Map_bool = struct {
    width: i32,
    height: i32,
    walls: []bool,

    pub fn Init(allocator: std.mem.Allocator, width: i32, height: i32) !Map_bool {
        const size: usize = @intCast(width * height);
        const walls = try allocator.alloc(bool, size);
        @memset(walls, false);
        return .{
            .width = width,
            .height = height,
            .walls = walls,
        };
    }

    pub fn Deinit(this: *const Map_bool, allocator: std.mem.Allocator) void {
        allocator.free(this.walls);
    }

    pub inline fn Count(this: *const Map_bool) usize {
        return this.walls.len;
    }

    pub fn IsWallAt(this: *const Map_bool, x: i32, y: i32) bool {
        if (!this.IsInBoundary(x, y)) {
            return true;
        }
        return this.walls[@intCast(y * this.width + x)];
    }

    pub inline fn IsEmptyAt(this: *const Map_bool, x: i32, y: i32) bool {
        return !this.IsWallAt(x, y);
    }

    pub fn SetWallAt(this: *Map_bool, x: i32, y: i32, isWall: bool) void {
        if (!this.IsInBoundary(x, y)) {
            return;
        }
        this.walls[@intCast(y * this.width + x)] = isWall;
    }

    pub fn SetEmptyAt(this: *Map_bool, x: i32, y: i32, isEmpty: bool) void {
        if (!this.IsInBoundary(x, y)) {
            return;
        }
        this.walls[@intCast(y * this.width + x)] = !isEmpty;
    }

    pub inline fn IsWallAt_Unchecked(this: *const Map_bool, x: i32, y: i32) bool {
        return this.walls[@intCast(y * this.width + x)];
    }

    pub inline fn SetWallAt_Unchecked(this: *Map_bool, x: i32, y: i32, isSet: bool) void {
        this.walls[@intCast(y * this.width + x)] = isSet;
    }

    pub inline fn IsInBoundary(this: *const Map_bool, x: i32, y: i32) bool {
        return 0 <= x and x < this.width and
            0 <= y and y < this.height;
    }

    pub inline fn IsEmptyPos(this: *const Map_bool, p: int2) bool {
        return !this.IsWallAt(p.x, p.y);
    }

    pub inline fn IsWallPos(this: *const Map_bool, p: int2) bool {
        return this.IsWallAt(p.x, p.y);
    }

    pub fn format(this: *const Map_bool, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        for (0..@intCast(this.height)) |y| {
            for (0..@intCast(this.width)) |x| {
                if (this.IsWallAt(@intCast(x), @intCast(y))) {
                    try writer.print("#", .{});
                } else {
                    try writer.print(".", .{});
                }
            }
            try writer.print("\n", .{});
        }
    }

    pub fn ToIMap(this: *Map_bool) IMap {
        return .{
            .ptr = this,
            .vtable = &Interface.vtable,
        };
    }

    const Interface = struct {
        const This = Map_bool;

        pub const vtable: IMap.VTable = .{
            .vptr_GetWidth = _vptr_GetWidth,
            .vptr_GetHeight = _vptr_GetHeight,
            .vptr_SetWallAt = _vptr_SetWallAt,
            .vptr_SetEmptyAt = _vptr_SetEmptyAt,
        };

        fn _vptr_GetWidth(context: *anyopaque) i32 {
            const this: *This = @ptrCast(@alignCast(context));
            return this.width;
        }

        fn _vptr_GetHeight(context: *anyopaque) i32 {
            const this: *This = @ptrCast(@alignCast(context));
            return this.height;
        }

        fn _vptr_SetWallAt(context: *anyopaque, x: i32, y: i32, isWall: bool) void {
            const this: *This = @ptrCast(@alignCast(context));
            this.SetWallAt(x, y, isWall);
        }

        fn _vptr_SetEmptyAt(context: *anyopaque, x: i32, y: i32, isEmpty: bool) void {
            const this: *This = @ptrCast(@alignCast(context));
            this.SetEmptyAt(x, y, isEmpty);
        }
    };
};

pub const Map_i32 = struct {
    width: i32,
    height: i32,
    walls: []i32,

    pub fn Init(allocator: std.mem.Allocator, width: i32, height: i32) !Map_i32 {
        const size: usize = @intCast(width * height);
        const walls = try allocator.alloc(i32, size);
        @memset(walls, false);
        return .{
            .width = width,
            .height = height,
            .walls = walls,
        };
    }

    pub fn Deinit(this: *const Map_i32, allocator: std.mem.Allocator) void {
        allocator.free(this.walls);
    }

    pub inline fn Count(this: *const Map_i32) usize {
        return this.walls.len;
    }

    pub fn IsWallAt(this: *const Map_i32, x: i32, y: i32) bool {
        if (!this.IsInBoundary(x, y)) {
            return true;
        }
        return this.walls[@intCast(y * this.width + x)];
    }

    pub fn SetWallAt(this: *Map_i32, x: i32, y: i32, isSet: bool) void {
        if (!this.IsInBoundary(x, y)) {
            return;
        }
        this.walls[@intCast(y * this.width + x)] = isSet;
    }

    pub inline fn IsWallAt_Unchecked(this: *const Map_i32, x: i32, y: i32) bool {
        return this.walls[@intCast(y * this.width + x)];
    }

    pub inline fn SetWallAt_Unchecked(this: *Map_i32, x: i32, y: i32, isSet: bool) void {
        this.walls[@intCast(y * this.width + x)] = isSet;
    }

    pub inline fn IsInBoundary(this: *const Map_i32, x: i32, y: i32) bool {
        return 0 <= x and x < this.width and 0 <= y and y < this.height;
    }

    pub fn IsWallPos(this: *const Map_i32, pos: int2) bool {
        if (!this.IsInBoundary(pos.x, pos.y)) {
            return true;
        }

        return this.walls[@intCast(pos.y * this.width + pos.x)];
    }

    pub fn format(this: *const Map_i32, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        for (0..@intCast(this.height)) |y| {
            for (0..@intCast(this.width)) |x| {
                if (this.IsWallAt(@intCast(x), @intCast(y)) == 0) {
                    try writer.print("#", .{});
                } else {
                    try writer.print(".", .{});
                }
            }
            try writer.print("\n", .{});
        }
    }
};

pub const Map_bitset2 = struct {
    width: i32,
    height: i32,
    walls: std.DynamicBitSetUnmanaged,

    pub fn Init(allocator: std.mem.Allocator, width: i32, height: i32) !Map_bitset2 {
        const size: usize = @intCast(width * height);
        const x = try std.DynamicBitSetUnmanaged.initEmpty(allocator, size);
        return .{
            .width = width,
            .height = height,
            .walls = x,
        };
    }

    pub fn Deinit(this: *Map_bitset2, allocator: std.mem.Allocator) void {
        this.walls.deinit(allocator);
    }

    pub inline fn Count(this: *const Map_bitset2) usize {
        return this.walls.bit_length;
    }

    pub fn IsWallAt(this: *const Map_bitset2, x: i32, y: i32) bool {
        if (!this.IsInBoundary(x, y)) {
            return true;
        }
        return this.walls.isSet(@intCast(y * this.width + x));
    }

    pub inline fn IsEmptyAt(this: *const Map_bitset2, x: i32, y: i32) bool {
        return !this.IsWallAt(x, y);
    }

    pub fn SetWallAt(this: *Map_bitset2, x: i32, y: i32, isSet: bool) void {
        if (!this.IsInBoundary(x, y)) {
            return;
        }
        if (isSet) {
            this.walls.set(@intCast(y * this.width + x));
        } else {
            this.walls.unset(@intCast(y * this.width + x));
        }
    }

    pub inline fn IsWallAt_Unchecked(this: *const Map_bitset2, x: i32, y: i32) bool {
        return this.walls.isSet(@intCast(y * this.width + x));
    }

    pub inline fn SetWallAt_Unchecked(this: *Map_bitset2, x: i32, y: i32, isSet: bool) void {
        if (isSet) {
            this.walls.set(@intCast(y * this.width + x));
        } else {
            this.walls.unset(@intCast(y * this.width + x));
        }
    }

    pub inline fn IsInBoundary(this: *const Map_bitset2, x: i32, y: i32) bool {
        return 0 <= x and x < this.width and
            0 <= y and y < this.height;
    }

    pub inline fn IsEmptyPos(this: *const Map_bitset2, p: int2) bool {
        return !this.IsWallAt(p.x, p.y);
    }

    pub inline fn IsWallPos(this: *const Map_bitset2, p: int2) bool {
        return this.IsWallAt(p.x, p.y);
    }

    pub fn format(this: *const Map_bitset2, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        for (0..@intCast(this.height)) |y| {
            for (0..@intCast(this.width)) |x| {
                if (this.IsWallAt(@intCast(x), @intCast(y))) {
                    try writer.print("#", .{});
                } else {
                    try writer.print(".", .{});
                }
            }
            try writer.print("\n", .{});
        }
    }
};
