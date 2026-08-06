const std = @import("std");

const SourceMap = @import("../Common/SimpleMap.zig").Map_bool;

const int2 = @import("../Common/int2.zig").int2;
const E_DIR = @import("../Common/E_DIR.zig").E_DIR;

pub const JpsplusBakedMapBlock = struct {
    jumpDistances: [8]i16,
};

const JpsplusBakedMap = @This();
width: i32,
height: i32,
walls: []bool,
blocks: []JpsplusBakedMapBlock,
primaryBlockIndexes: []i32,

pub const empty: JpsplusBakedMap = .{
    .width = 0,
    .height = 0,
    .walls = &.{},
    .blocks = &.{},
    .primaryBlockIndexes = &.{},
};

// TODO(pyoung): refactor setup
pub fn Setup(this: *JpsplusBakedMap, allocator: std.mem.Allocator, sourceMap: *const SourceMap) !void {
    const blocks = try allocator.alloc(JpsplusBakedMapBlock, sourceMap.Count());
    for (0..sourceMap.Count()) |idx| {
        @memset(&blocks[idx].jumpDistances, 0);
    }

    const walls = try allocator.alloc(bool, sourceMap.Count());
    for (0..@intCast(sourceMap.height)) |y| {
        for (0..@intCast(sourceMap.width)) |x| {
            const idx: usize = @intCast(y * @as(usize, @intCast(sourceMap.width)) + x);
            walls[idx] = sourceMap.IsWallAt(@intCast(x), @intCast(y));
        }
    }

    this.width = sourceMap.width;
    this.height = sourceMap.height;
    this.walls = walls;
    this.blocks = blocks;
    this.primaryBlockIndexes = &.{};
}

pub fn Deinit(this: *const JpsplusBakedMap, allocator: std.mem.Allocator) void {
    allocator.free(this.walls);
    allocator.free(this.blocks);
    allocator.free(this.primaryBlockIndexes);
}

pub inline fn IsInBoundary(this: *const JpsplusBakedMap, x: i32, y: i32) bool {
    return 0 <= x and x < this.width and 0 <= y and y < this.height;
}

pub inline fn GetBlockIndex_Uncheck(this: *const JpsplusBakedMap, p: int2) usize {
    const idx: usize = @intCast(p.y * this.width + p.x);
    return idx;
}

pub inline fn GetBlockIndexOrNull(this: *const JpsplusBakedMap, p: int2) ?usize {
    if (!this.IsInBoundary(p.x, p.y)) {
        return null;
    }

    const idx: usize = @intCast(p.y * this.width + p.x);
    if (this.walls[idx]) {
        return null;
    }

    return idx;
}

pub inline fn GetDistanceAt(this: *const JpsplusBakedMap, x: i32, y: i32, dir: E_DIR) i16 {
    return this.blocks[@intCast(y * this.width + x)].jumpDistances[@intCast(@intFromEnum(dir))];
}

pub inline fn GetDistanceByBlocki(this: *const JpsplusBakedMap, blocki: usize, dir: E_DIR) i16 {
    return this.blocks[blocki].jumpDistances[@intCast(@intFromEnum(dir))];
}

pub inline fn SetDistance(this: *JpsplusBakedMap, blocki: usize, dir: E_DIR, distance: i16) void {
    this.blocks[blocki].jumpDistances[@intCast(@intFromEnum(dir))] = distance;
}

pub inline fn IsWallAt(this: *const JpsplusBakedMap, x: i32, y: i32) bool {
    if (!this.IsInBoundary(x, y)) {
        return true;
    }
    return this.walls[@intCast(y * this.width + x)];
}

pub fn format(this: *const JpsplusBakedMap, writer: *std.Io.Writer) std.Io.Writer.Error!void {
    try ForDebug.Print(this, writer);
}

const ForDebug = struct {
    fn Print(this: *const JpsplusBakedMap, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        const jumpDistance = _GetMaxAbsJumpDistance(this);
        const maxDigitWidth = _GetDigitCountMath(jumpDistance) + 1;

        const up_row: [3]E_DIR = .{ .NW, .N, .NE };
        const mid_row: [3]E_DIR = .{ .W, .START, .E };
        const down_row: [3]E_DIR = .{ .SW, .S, .SE };

        for (0..@intCast(this.width)) |_| {
            for (0..maxDigitWidth * 3 + 3) |_| {
                try writer.print("-", .{});
            }
            try writer.print("+", .{});
        }
        try writer.print("\n", .{});
        for (0..@intCast(this.height)) |h| {
            for (0..@intCast(this.width)) |w| {
                const idx = h * @as(usize, @intCast(this.width)) + w;
                for (up_row) |dir| {
                    try _PrintDist(this, writer, idx, dir, maxDigitWidth);
                }
                try writer.print("|", .{});
            }
            try writer.print("\n", .{});

            for (0..@intCast(this.width)) |w| {
                const idx = h * @as(usize, @intCast(this.width)) + w;
                for (mid_row) |dir| {
                    try _PrintDist(this, writer, idx, dir, maxDigitWidth);
                }
                try writer.print("|", .{});
            }
            try writer.print("\n", .{});
            for (0..@intCast(this.width)) |w| {
                const idx = h * @as(usize, @intCast(this.width)) + w;
                for (down_row) |dir| {
                    try _PrintDist(this, writer, idx, dir, maxDigitWidth);
                }
                try writer.print("|", .{});
            }
            try writer.print("\n", .{});

            for (0..@intCast(this.width)) |_| {
                for (0..maxDigitWidth * 3 + 3) |_| {
                    try writer.print("-", .{});
                }
                try writer.print("+", .{});
            }
            try writer.print("\n", .{});
        }
    }

    fn _PrintDist(this: *const JpsplusBakedMap, writer: *std.Io.Writer, idx: usize, dir: E_DIR, maxDigitWidth: usize) std.Io.Writer.Error!void {
        if (this.walls[idx]) {
            for (0..maxDigitWidth) |_| {
                try writer.print("#", .{});
            }
            try writer.print(" ", .{});
        } else if (dir == .START) {
            if (std.mem.indexOfScalar(i32, this.primaryBlockIndexes, @intCast(idx)) != null) {
                for (0..maxDigitWidth - 1) |_| {
                    try writer.print(" ", .{});
                }
                try writer.print("@", .{});
            } else {
                for (0..maxDigitWidth) |_| {
                    try writer.print(" ", .{});
                }
            }
            try writer.print(" ", .{});
        } else {
            const dist = this.blocks[idx].jumpDistances[@intCast(@intFromEnum(dir))];
            const digitWidth = _GetDigitCountMath(dist);
            const space: usize = maxDigitWidth - digitWidth;
            for (0..space) |_| {
                try writer.print(" ", .{});
            }
            try writer.print("{}", .{dist});
            try writer.print(" ", .{});
        }
    }

    fn _GetMaxAbsJumpDistance(this: *const JpsplusBakedMap) i32 {
        var ret: u32 = 0;
        var isMinus = false;
        for (this.blocks) |block| {
            for (block.jumpDistances) |dist| {
                const absDist = @abs(dist);
                if (absDist > ret) {
                    ret = absDist;
                    if (dist < 0) {
                        isMinus = true;
                    } else {
                        isMinus = false;
                    }
                }
            }
        }
        if (isMinus) {
            return -@as(i32, @intCast(ret));
        }
        return @as(i32, @intCast(ret));
    }

    fn _GetDigitCountMath(val: i32) usize {
        if (val == 0) {
            return 1;
        }

        var count: usize = 0;
        var n: i64 = val;

        if (n < 0) {
            count += 1;
            n = -n;
        }

        while (n > 0) : (n = @divTrunc(n, 10)) {
            count += 1;
        }

        return count;
    }
};
