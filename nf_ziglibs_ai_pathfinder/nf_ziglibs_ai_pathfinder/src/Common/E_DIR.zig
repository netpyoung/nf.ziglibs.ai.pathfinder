const std = @import("std");
const builtin = @import("builtin");

const int2 = @import("./int2.zig").int2;

pub const E_DIR = enum(i32) {
    // NW(7) N(0) NE(1)
    //  W(6)       E(2)
    // SW(5) S(4) SE(3)

    N = 0,
    NE = 1,
    E = 2,
    SE = 3,
    S = 4,
    SW = 5,
    W = 6,
    NW = 7,
    START = 8,

    const DIR_TO_DIRSET: [9]E_DIRSET = .{
        .NORTH,
        .NORTHEAST,
        .EAST,
        .SOUTHEAST,
        .SOUTH,
        .SOUTHWEST,
        .WEST,
        .NORTHWEST,
        .ALL,
    };

    const DIR_TO_AROUND_DIRSET: [9]E_DIRSET = blk: {
        // NW(7) N(0) NE(1)
        //  W(6)       E(2)
        // SW(5) S(4) SE(3)
        var xs: [9]i32 = undefined;
        xs[@intCast(@intFromEnum(E_DIR.N))] = @intFromEnum(E_DIRSET.NORTHWEST) | @intFromEnum(E_DIRSET.NORTH) | @intFromEnum(E_DIRSET.NORTHEAST);
        xs[@intCast(@intFromEnum(E_DIR.NE))] = @intFromEnum(E_DIRSET.NORTH) | @intFromEnum(E_DIRSET.NORTHEAST) | @intFromEnum(E_DIRSET.EAST);
        xs[@intCast(@intFromEnum(E_DIR.E))] = @intFromEnum(E_DIRSET.NORTHEAST) | @intFromEnum(E_DIRSET.EAST) | @intFromEnum(E_DIRSET.SOUTHEAST);
        xs[@intCast(@intFromEnum(E_DIR.SE))] = @intFromEnum(E_DIRSET.EAST) | @intFromEnum(E_DIRSET.SOUTHEAST) | @intFromEnum(E_DIRSET.SOUTH);
        xs[@intCast(@intFromEnum(E_DIR.S))] = @intFromEnum(E_DIRSET.SOUTHEAST) | @intFromEnum(E_DIRSET.SOUTH) | @intFromEnum(E_DIRSET.SOUTHWEST);
        xs[@intCast(@intFromEnum(E_DIR.SW))] = @intFromEnum(E_DIRSET.SOUTH) | @intFromEnum(E_DIRSET.SOUTHWEST) | @intFromEnum(E_DIRSET.WEST);
        xs[@intCast(@intFromEnum(E_DIR.W))] = @intFromEnum(E_DIRSET.SOUTHWEST) | @intFromEnum(E_DIRSET.WEST) | @intFromEnum(E_DIRSET.NORTHWEST);
        xs[@intCast(@intFromEnum(E_DIR.NW))] = @intFromEnum(E_DIRSET.WEST) | @intFromEnum(E_DIRSET.NORTHWEST) | @intFromEnum(E_DIRSET.NORTH);
        xs[@intCast(@intFromEnum(E_DIR.START))] = @intFromEnum(E_DIRSET.ALL);

        var ret: [9]E_DIRSET = undefined;
        for (0..9) |i| {
            ret[i] = @enumFromInt(xs[i]);
        }
        break :blk ret;
    };

    const dirToPos: [9]int2 = blk: {
        // NW(7) N(0) NE(1)
        //  W(6)       E(2)
        // SW(5) S(4) SE(3)
        var ret: [9]int2 = undefined;
        ret[@intCast(@intFromEnum(E_DIR.N))] = int2.Init(0, -1);
        ret[@intCast(@intFromEnum(E_DIR.NE))] = int2.Init(1, -1);
        ret[@intCast(@intFromEnum(E_DIR.E))] = int2.Init(1, 0);
        ret[@intCast(@intFromEnum(E_DIR.SE))] = int2.Init(1, 1);
        ret[@intCast(@intFromEnum(E_DIR.S))] = int2.Init(0, 1);
        ret[@intCast(@intFromEnum(E_DIR.SW))] = int2.Init(-1, 1);
        ret[@intCast(@intFromEnum(E_DIR.W))] = int2.Init(-1, 0);
        ret[@intCast(@intFromEnum(E_DIR.NW))] = int2.Init(-1, -1);
        ret[@intCast(@intFromEnum(E_DIR.START))] = int2.Init(0, 0);
        break :blk ret;
    };

    pub inline fn IsDiagonal(dir: E_DIR) bool {
        return @intFromEnum(dir) & 1 == 1;
    }

    pub inline fn IsStraight(dir: E_DIR) bool {
        return @intFromEnum(dir) & 1 == 0;
    }

    pub inline fn ToPos(dir: E_DIR) int2 {
        return dirToPos[@intCast(@intFromEnum(dir))];
    }

    pub inline fn Right(dir: E_DIR, offset: i32) E_DIR {
        return @enumFromInt((@intFromEnum(dir) + offset) & 7);
    }

    pub inline fn Left(dir: E_DIR, offset: i32) E_DIR {
        return @enumFromInt((@intFromEnum(dir) -% offset) & 7);
    }

    pub inline fn ToDirSet(dir: E_DIR) E_DIRSET {
        return DIR_TO_DIRSET[@intCast(@intFromEnum(dir))];
    }

    pub inline fn ToAroundSet(dir: E_DIR) E_DIRSET {
        return DIR_TO_AROUND_DIRSET[@intCast(@intFromEnum(dir))];
    }

    pub inline fn GetAround3(dir: E_DIR) [3]E_DIR {
        return .{ dir.Left(1), dir, dir.Right(1) };
    }

    pub inline fn GetAround2(dir: E_DIR) [2]E_DIR {
        return .{ dir.Left(1), dir.Right(1) };
    }

    pub inline fn DiagonalToEastOrWest(dir: E_DIR) E_DIR {
        if (comptime builtin.mode == .Debug) {
            std.debug.assert(dir.IsDiagonal());
        }
        return if (dir == .NE or dir == .SE) .E else .W;
    }

    pub inline fn DiagonalToNorthOrSouth(dir: E_DIR) E_DIR {
        if (comptime builtin.mode == .Debug) {
            std.debug.assert(dir.IsDiagonal());
        }
        return if (dir == .NE or dir == .NW) .N else .S;
    }
};

pub const E_DIRSET = enum(u8) {
    NONE = 0, // 0b_0000_0000
    NORTH = 1, // 0b_0000_0001
    SOUTH = 2, // 0b_0000_0010
    EAST = 4, // 0b_0000_0100
    WEST = 8, // 0b_0000_1000
    NORTHEAST = 16, // 0b_0001_0000
    NORTHWEST = 32, // 0b_0010_0000
    SOUTHEAST = 64, // 0b_0100_0000
    SOUTHWEST = 128, // 0b_1000_0000
    ALL = 255, // .NORTH | .SOUTH | .EAST | .WEST | .NORTHEAST | .NORTHWEST | .SOUTHEAST | .SOUTHWEST
    _,

    pub const BIT_SHIFT = struct {
        // ex) 1 << shiftvalue;
        pub const NORTH: u8 = 0; // 0b_0000_0001
        pub const SOUTH: u8 = 1; // 0b_0000_0010
        pub const EAST: u8 = 2; // 0b_0000_0100
        pub const WEST: u8 = 3; // 0b_0000_1000
        pub const NORTHEAST: u8 = 4; // 0b_0001_0000
        pub const NORTHWEST: u8 = 5; // 0b_0010_0000
        pub const SOUTHEAST: u8 = 6; // 0b_0100_0000
        pub const SOUTHWEST: u8 = 7; // 0b_1000_0000
    };

    pub fn format(s: E_DIRSET, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        if (s == .ALL) {
            try writer.print("{}", .{E_DIRSET.ALL});
            return;
        }
        const x: i32 = @intFromEnum(s);
        var isMulti = false;
        if ((x & @intFromEnum(E_DIRSET.NORTH)) != 0) {
            try writer.print("{}", .{E_DIRSET.NORTH});
            isMulti = true;
        }
        if ((x & @intFromEnum(E_DIRSET.SOUTH)) != 0) {
            if (isMulti) {
                try writer.print(" | ", .{});
            }
            try writer.print("{}", .{E_DIRSET.SOUTH});
            isMulti = true;
        }
        if ((x & @intFromEnum(E_DIRSET.EAST)) != 0) {
            if (isMulti) {
                try writer.print(" | ", .{});
            }
            try writer.print("{}", .{E_DIRSET.EAST});
            isMulti = true;
        }
        if ((x & @intFromEnum(E_DIRSET.WEST)) != 0) {
            if (isMulti) {
                try writer.print(" | ", .{});
            }
            try writer.print("{}", .{E_DIRSET.WEST});
            isMulti = true;
        }
        if ((x & @intFromEnum(E_DIRSET.NORTHEAST)) != 0) {
            if (isMulti) {
                try writer.print(" | ", .{});
            }
            try writer.print("{}", .{E_DIRSET.NORTHEAST});
            isMulti = true;
        }

        if ((x & @intFromEnum(E_DIRSET.NORTHWEST)) != 0) {
            if (isMulti) {
                try writer.print(" | ", .{});
            }
            try writer.print("{}", .{E_DIRSET.NORTHWEST});
            isMulti = true;
        }

        if ((x & @intFromEnum(E_DIRSET.SOUTHEAST)) != 0) {
            if (isMulti) {
                try writer.print(" | ", .{});
            }
            try writer.print("{}", .{E_DIRSET.SOUTHEAST});
            isMulti = true;
        }

        if ((x & @intFromEnum(E_DIRSET.SOUTHWEST)) != 0) {
            if (isMulti) {
                try writer.print(" | ", .{});
            }
            try writer.print("{}", .{E_DIRSET.SOUTHWEST});
            isMulti = true;
        }
    }

    pub inline fn Intersect(a: E_DIRSET, b: E_DIRSET) E_DIRSET {
        return @enumFromInt(@intFromEnum(a) | @intFromEnum(b));
    }

    pub inline fn IsContains(dirset: E_DIRSET, dir: E_DIR) bool {
        const checkDirset = dir.ToDirSet();
        return (@intFromEnum(dirset) & @intFromEnum(checkDirset)) == @intFromEnum(checkDirset);
    }

    pub fn iterator(this: E_DIRSET) IteratorDir {
        return .{ .inner = @intFromEnum(this), .count = 0 };
    }

    pub const IteratorDir = struct {
        inner: u8,
        count: usize,

        const DIR_TABLE: [8]E_DIR = .{ .N, .S, .E, .W, .NE, .NW, .SE, .SW };
        // NORTH = 1, // 0b_0000_0001
        // SOUTH = 2, // 0b_0000_0010
        // EAST = 4, // 0b_0000_0100
        // WEST = 8, // 0b_0000_1000
        // NORTHEAST = 16, // 0b_0001_0000
        // NORTHWEST = 32, // 0b_0010_0000
        // SOUTHEAST = 64, // 0b_0100_0000
        // SOUTHWEST = 128, // 0b_1000_0000
        pub fn next(this: *IteratorDir) ?E_DIR {
            while (true) {
                if (this.count > 7) {
                    return null;
                }

                const isFound = (this.inner & 1) == 1;
                if (isFound) {
                    const ret = DIR_TABLE[this.count];
                    this.inner >>= 1;
                    this.count += 1;
                    return ret;
                }

                this.inner >>= 1;
                this.count += 1;
            }
        }
    };
};

test "left right" {
    // NW(7) N(0) NE(1)
    //  W(6)       E(2)
    // SW(5) S(4) SE(3)

    try std.testing.expectEqual(E_DIR.NE, E_DIR.N.Right(1));
    try std.testing.expectEqual(E_DIR.NW, E_DIR.N.Left(1));

    try std.testing.expectEqual(E_DIR.E, E_DIR.N.Right(2));
    try std.testing.expectEqual(E_DIR.W, E_DIR.N.Left(2));

    try std.testing.expectEqual(E_DIR.NW, E_DIR.N.Right(7));
    try std.testing.expectEqual(E_DIR.NE, E_DIR.N.Left(7));

    try std.testing.expectEqual(E_DIR.N, E_DIR.N.Right(8));
    try std.testing.expectEqual(E_DIR.N, E_DIR.N.Left(8));

    try std.testing.expectEqual(E_DIR.NE, E_DIR.N.Right(9));
    try std.testing.expectEqual(E_DIR.NW, E_DIR.N.Left(9));

    try std.testing.expectEqual(E_DIR.N, E_DIR.NW.Right(1));
    try std.testing.expectEqual(E_DIR.N, E_DIR.NE.Left(1));
}

test "diagonal e/w/ or n/s" {
    try std.testing.expectEqual(E_DIR.E, E_DIR.NE.DiagonalToEastOrWest());
    try std.testing.expectEqual(E_DIR.E, E_DIR.SE.DiagonalToEastOrWest());
    try std.testing.expectEqual(E_DIR.W, E_DIR.NW.DiagonalToEastOrWest());
    try std.testing.expectEqual(E_DIR.W, E_DIR.SW.DiagonalToEastOrWest());

    try std.testing.expectEqual(E_DIR.N, E_DIR.NE.DiagonalToNorthOrSouth());
    try std.testing.expectEqual(E_DIR.N, E_DIR.NW.DiagonalToNorthOrSouth());
    try std.testing.expectEqual(E_DIR.S, E_DIR.SE.DiagonalToNorthOrSouth());
    try std.testing.expectEqual(E_DIR.S, E_DIR.SW.DiagonalToNorthOrSouth());
}

test "dirset iterator" {
    var iter = E_DIRSET.ALL.iterator();
    var i: usize = 0;
    const dirs = [_]E_DIR{ .N, .S, .E, .W, .NE, .NW, .SE, .SW };
    while (iter.next()) |dir| {
        try std.testing.expectEqual(dirs[i], dir);
        i += 1;
    }

    try std.testing.expectEqual(i, dirs.len);
}
