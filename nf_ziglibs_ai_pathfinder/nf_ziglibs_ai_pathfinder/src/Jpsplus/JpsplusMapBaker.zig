const std = @import("std");

const int2 = @import("../Common/int2.zig").int2;
const E_DIRSET = @import("../Common/E_DIR.zig").E_DIRSET;
const E_DIR = @import("../Common/E_DIR.zig").E_DIR;
const SourceMap = @import("../Common/SimpleMap.zig").Map_bool;

const JpsplusBakedMap = @import("./JpsplusBakedMap.zig");

const JpsplusMapBaker = @This();
dirsets: std.ArrayList(E_DIRSET),
primaryBlockIndexes: std.ArrayList(i32),

pub const empty: JpsplusMapBaker = .{
    .dirsets = .empty,
    .primaryBlockIndexes = .empty,
};

pub fn Deinit(this: *JpsplusMapBaker, allocator: std.mem.Allocator) void {
    this.dirsets.deinit(allocator);
    this.primaryBlockIndexes.deinit(allocator);
}

pub fn Bake(this: *JpsplusMapBaker, allocator: std.mem.Allocator, sourceMap: *const SourceMap, bakedmap: *JpsplusBakedMap) !void {
    try bakedmap.Setup(allocator, sourceMap);

    this.dirsets.clearRetainingCapacity();
    //    try this.dirsets.ensureTotalCapacity(allocator, bakedmap.blocks.len);
    //    this.dirsets.appendNTimesAssumeCapacity(.NONE, bakedmap.blocks.len);
    //        try this.dirsets.appendNTimes(allocator, .NONE, bakedmap.blocks.len);
    for (0..bakedmap.blocks.len) |_| {
        try this.dirsets.append(allocator, .NONE);
    }

    this.primaryBlockIndexes.clearRetainingCapacity();
    try this.primaryBlockIndexes.ensureTotalCapacity(allocator, @divTrunc(bakedmap.blocks.len, 4));

    try this.MarkPrimary(allocator, sourceMap, bakedmap);

    bakedmap.primaryBlockIndexes = try allocator.alloc(i32, this.primaryBlockIndexes.items.len);
    @memcpy(bakedmap.primaryBlockIndexes, this.primaryBlockIndexes.items);

    this.MarkStraight(sourceMap, bakedmap);
    this.MarkDiagonal(sourceMap, bakedmap);

    // std.debug.print("{f}", .{sourceMap});
    // std.debug.print("{f}", .{bakedmap});
    // std.process.exit(1);
}

fn MarkPrimary(this: *JpsplusMapBaker, allocator: std.mem.Allocator, sourceMap: *const SourceMap, bakedmap: *JpsplusBakedMap) !void {
    var x: i32 = 0;
    var y: i32 = 0;
    while (y < sourceMap.height) : (y += 1) {
        x = 0;
        while (x < sourceMap.width) : (x += 1) {
            const idx: usize = @intCast(y * bakedmap.width + x);
            if (sourceMap.IsWallAt(x, y)) {
                continue;
            }

            // NW(7) N(0) NE(1)
            //  W(6)       E(2)
            // SW(5) S(4) SE(3)
            var isFound: bool = false;
            if (IsJumpPoint(sourceMap, x, y, 0, 1)) {
                this.dirsets.items[idx] = this.dirsets.items[idx].Intersect(.SOUTH);
                isFound = true;
            }
            if (IsJumpPoint(sourceMap, x, y, 0, -1)) {
                this.dirsets.items[idx] = this.dirsets.items[idx].Intersect(.NORTH);
                isFound = true;
            }
            if (IsJumpPoint(sourceMap, x, y, 1, 0)) {
                this.dirsets.items[idx] = this.dirsets.items[idx].Intersect(.EAST);
                isFound = true;
            }
            if (IsJumpPoint(sourceMap, x, y, -1, 0)) {
                this.dirsets.items[idx] = this.dirsets.items[idx].Intersect(.WEST);
                isFound = true;
            }
            if (isFound) {
                try this.primaryBlockIndexes.append(allocator, @intCast(idx));
            }
        }
    }
}

fn MarkPrimary33(this: *JpsplusMapBaker, allocator: std.mem.Allocator, sourceMap: *const SourceMap, bakedmap: *JpsplusBakedMap) !void {
    const diagonalDirs: [4]E_DIR = .{ .NE, .SE, .SW, .NW };

    for (0..@intCast(bakedmap.height)) |h| {
        for (0..@intCast(bakedmap.width)) |w| {
            const x: i32 = @intCast(w);
            const y: i32 = @intCast(h);

            if (!sourceMap.IsWallAt(x, y)) {
                continue;
            }

            const p = int2.Init(x, y);
            for (diagonalDirs) |diagonalDir| {
                const primaryP = p.Forward(diagonalDir);
                const primaryBlockIndexOrNull = bakedmap.GetBlockIndexOrNull(primaryP);
                if (primaryBlockIndexOrNull == null) {
                    continue;
                }

                const primaryBlockIndex = primaryBlockIndexOrNull.?;
                //           N(0)
                //     NW(7)      NE(1)
                //W(6)                  E(2)
                //     SW(5)      SE(3)
                //           S(4)
                // ex)
                //
                //   diagonalDir: NE
                //
                //   left1 : N
                //   right1: E
                if (!sourceMap.IsWallPos(p.Forward(diagonalDir.Left1())) and !sourceMap.IsWallPos(p.Forward(diagonalDir.Right1()))) {
                    //   left3 : W
                    //   right3: S
                    this.dirsets.items[primaryBlockIndex] = this.dirsets.items[primaryBlockIndex].Intersect(diagonalDir.Left3().ToDirSet());
                    this.dirsets.items[primaryBlockIndex] = this.dirsets.items[primaryBlockIndex].Intersect(diagonalDir.Right3().ToDirSet());
                    try this.primaryBlockIndexes.append(allocator, @intCast(primaryBlockIndex));

                    std.log.debug("primaryBlockIndex - {} {} {}", .{ primaryBlockIndex, diagonalDir.Left3().ToDirSet(), diagonalDir.Right3().ToDirSet() });
                }
            }
        }
    }
}

fn IsJumpPoint(sourceMap: *const SourceMap, x: i32, y: i32, addx: i32, addy: i32) bool {
    const isParentNotWall = sourceMap.IsEmptyAt(x - addx, y - addy);
    if (!isParentNotWall) {
        return false;
    }
    const isForcedNeighbor1 = (sourceMap.IsEmptyAt(x + addy, y + addx) and sourceMap.IsWallAt(x - addx + addy, y - addy + addx));
    if (isForcedNeighbor1) {
        return true;
    }

    const isForcedNeighbor2 = (sourceMap.IsEmptyAt(x - addy, y - addx) and sourceMap.IsWallAt(x - addx - addy, y - addy - addx));
    if (isForcedNeighbor2) {
        return true;
    }
    return false;
}

fn MarkStraight(this: *JpsplusMapBaker, sourceMap: *const SourceMap, bakedmap: *JpsplusBakedMap) void {
    // WEST ------------------------------
    // . . .
    // W . .
    // . . .
    for (0..@intCast(sourceMap.height)) |h| {
        var isJumpPointLastSeen = false;
        var distance: i16 = -1;

        for (0..@intCast(sourceMap.width)) |w| {
            const x: i32 = @intCast(w);
            const y: i32 = @intCast(h);

            const blocki: usize = @intCast(y * sourceMap.width + x);

            if (sourceMap.IsWallAt(x, y)) {
                distance = -1;
                isJumpPointLastSeen = false;
                bakedmap.SetDistance(blocki, .W, 0);
                continue;
            }

            distance += 1;

            if (isJumpPointLastSeen) {
                bakedmap.SetDistance(blocki, .W, distance); // Straight Distance
            } else {
                bakedmap.SetDistance(blocki, .W, -distance); // Straight-Wall Distance
            }

            if (this.IsJumpable(blocki, .W)) {
                distance = 0;
                isJumpPointLastSeen = true;
            }
        }
    }

    // EAST ------------------------------
    // . . .
    // . . E
    // . . .
    for (0..@intCast(sourceMap.height)) |h| {
        var isJumpPointLastSeen = false;
        var distance: i16 = -1;

        const y: i32 = @intCast(h);
        var x: i32 = sourceMap.width - 1;
        while (x >= 0) : (x -= 1) {
            const blocki: usize = @intCast(y * sourceMap.width + x);

            if (sourceMap.IsWallAt(x, y)) {
                distance = -1;
                isJumpPointLastSeen = false;
                bakedmap.SetDistance(blocki, .E, 0);
                continue;
            }

            distance += 1;

            if (isJumpPointLastSeen) {
                bakedmap.SetDistance(blocki, .E, distance); // Straight Distance
            } else {
                bakedmap.SetDistance(blocki, .E, -distance); // Straight-Wall Distance
            }

            if (this.IsJumpable(blocki, .E)) {
                distance = 0;
                isJumpPointLastSeen = true;
            }
        }
    }

    // NORTH ------------------------------
    // . N .
    // . . .
    // . . .
    for (0..@intCast(sourceMap.width)) |w| {
        var isJumpPointLastSeen = false;
        var distance: i16 = -1;

        for (0..@intCast(sourceMap.height)) |h| {
            const x: i32 = @intCast(w);
            const y: i32 = @intCast(h);

            const blocki: usize = @intCast(y * sourceMap.width + x);

            if (sourceMap.IsWallAt(x, y)) {
                distance = -1;
                isJumpPointLastSeen = false;
                bakedmap.SetDistance(blocki, .N, 0);
                continue;
            }

            distance += 1;

            if (isJumpPointLastSeen) {
                bakedmap.SetDistance(blocki, .N, distance); // Straight Distance
            } else {
                bakedmap.SetDistance(blocki, .N, -distance); // Straight-Wall Distance
            }

            if (this.IsJumpable(blocki, .N)) {
                distance = 0;
                isJumpPointLastSeen = true;
            }
        }
    }

    // SOUTH ------------------------------
    // . . .
    // . . .
    // . S .
    for (0..@intCast(sourceMap.width)) |w| {
        var isJumpPointLastSeen = false;
        var distance: i16 = -1;

        const x: i32 = @intCast(w);
        var y = sourceMap.height - 1;
        while (y >= 0) : (y -= 1) {
            const blocki: usize = @intCast(y * sourceMap.width + x);

            if (sourceMap.IsWallAt(x, y)) {
                distance = -1;
                isJumpPointLastSeen = false;
                bakedmap.SetDistance(blocki, .S, 0);
                continue;
            }

            distance += 1;

            if (isJumpPointLastSeen) {
                bakedmap.SetDistance(blocki, .S, distance); // Straight Distance
            } else {
                bakedmap.SetDistance(blocki, .S, -distance); // Straight-Wall Distance
            }

            if (this.IsJumpable(blocki, .S)) {
                distance = 0;
                isJumpPointLastSeen = true;
            }
        }
    }
}

fn MarkDiagonal(this: *JpsplusMapBaker, sourceMap: *const SourceMap, bakedmap: *JpsplusBakedMap) void {
    _ = this;

    const width = sourceMap.width;
    const height = sourceMap.height;

    var x: i32 = undefined;
    var y: i32 = undefined;

    // NORTH & WEST ------------------------------
    // * N .
    // W . .
    // . . .
    y = 0;
    while (y < height) : (y += 1) { // 0..height
        x = 0;
        while (x < width) : (x += 1) { // 0..width
            if (sourceMap.IsWallAt(x, y)) {
                continue;
            }

            const blocki: usize = @intCast(y * width + x);
            if (x == 0 or y == 0) {
                bakedmap.SetDistance(blocki, .NW, 0); // Diagonal-Wall Distance
                continue;
            }

            const p = int2.Init(x, y);
            const p1 = p.Forward(.N);
            const p2 = p.Forward(.NW);
            const p3 = p.Forward(.W);
            const isWall_p1 = sourceMap.IsWallPos(p1);
            const isWall_p3 = sourceMap.IsWallPos(p3);
            if (isWall_p1 or isWall_p3 or sourceMap.IsWallPos(p2)) {
                bakedmap.SetDistance(blocki, .NW, 0); // Diagonal-Wall Distance
                continue;
            }

            const prevBlocki: usize = @intCast(p2.y * width + p2.x);
            if (!isWall_p1 and !isWall_p3 and
                bakedmap.GetDistanceByBlocki(prevBlocki, .N) > 0 or
                bakedmap.GetDistanceByBlocki(prevBlocki, .W) > 0)
            {
                bakedmap.SetDistance(blocki, .NW, 1); // Initial Diagonal Distance
                continue;
            }

            const distanceFromPrev = bakedmap.GetDistanceByBlocki(prevBlocki, .NW);
            if (distanceFromPrev > 0) {
                bakedmap.SetDistance(blocki, .NW, distanceFromPrev + 1); // Diagonal Distance
            } else {
                bakedmap.SetDistance(blocki, .NW, distanceFromPrev - 1); // Diagonal-Wall Distance
            }
        }
    }

    // NORTH & EAST ------------------------------
    // . N *
    // . . E
    // . . .
    y = 0;
    while (y < height) : (y += 1) { // 0..height
        x = width - 1;
        while (x >= 0) : (x -= 1) { // (width-1)..=0
            if (sourceMap.IsWallAt(x, y)) {
                continue;
            }

            const blocki: usize = @intCast(y * width + x);
            if (x == width - 1 or y == 0) {
                bakedmap.SetDistance(blocki, .NE, 0); // Diagonal-Wall Distance
                continue;
            }

            const p = int2.Init(x, y);
            const p1 = p.Forward(.N);
            const p2 = p.Forward(.NE);
            const p3 = p.Forward(.E);
            const isWall_p1 = sourceMap.IsWallPos(p1);
            const isWall_p3 = sourceMap.IsWallPos(p3);
            if (isWall_p1 or isWall_p3 or sourceMap.IsWallPos(p2)) {
                bakedmap.SetDistance(blocki, .NE, 0); // Diagonal-Wall Distance
                continue;
            }

            const prevBlocki: usize = @intCast(p2.y * width + p2.x);
            if (!isWall_p1 and !isWall_p3 and
                (bakedmap.GetDistanceByBlocki(prevBlocki, .N) > 0 or bakedmap.GetDistanceByBlocki(prevBlocki, .E) > 0))
            {
                bakedmap.SetDistance(blocki, .NE, 1); // Initial Diagonal Distance
                continue;
            }

            const distanceFromPrev = bakedmap.GetDistanceByBlocki(prevBlocki, .NE);
            if (distanceFromPrev > 0) {
                bakedmap.SetDistance(blocki, .NE, distanceFromPrev + 1); // Diagonal Distance
            } else {
                bakedmap.SetDistance(blocki, .NE, distanceFromPrev - 1); // Diagonal-Wall Distance
            }
        }
    }

    // SOUTH & WEST ------------------------------
    // . . .
    // W . .
    // * S .
    y = height - 1;
    while (y >= 0) : (y -= 1) { // (height-1)..=0
        x = 0;
        while (x < width) : (x += 1) { // 0..width
            if (sourceMap.IsWallAt(x, y)) {
                continue;
            }

            const blocki: usize = @intCast(y * width + x);
            if (x == 0 or y == height - 1) {
                bakedmap.SetDistance(blocki, .SW, 0); // Diagonal-Wall Distance
                continue;
            }

            const p = int2.Init(x, y);
            const p1 = p.Forward(.S);
            const p2 = p.Forward(.SW);
            const p3 = p.Forward(.W);
            const isWall_p1 = sourceMap.IsWallPos(p1);
            const isWall_p3 = sourceMap.IsWallPos(p3);
            if (isWall_p1 or isWall_p3 or sourceMap.IsWallPos(p2)) {
                bakedmap.SetDistance(blocki, .SW, 0); // Diagonal-Wall Distance
                continue;
            }

            const prevBlocki = bakedmap.GetBlockIndex_Uncheck(p2);
            if (!isWall_p1 and !isWall_p3 and
                (bakedmap.GetDistanceByBlocki(prevBlocki, .S) > 0 or bakedmap.GetDistanceByBlocki(prevBlocki, .W) > 0))
            {
                bakedmap.SetDistance(blocki, .SW, 1); // Initial Diagonal Distance
                continue;
            }

            const distanceFromPrev = bakedmap.GetDistanceByBlocki(prevBlocki, .SW);
            if (distanceFromPrev > 0) {
                bakedmap.SetDistance(blocki, .SW, distanceFromPrev + 1); // Diagonal Distance
            } else {
                bakedmap.SetDistance(blocki, .SW, distanceFromPrev - 1); // Diagonal-Wall Distance
            }
        }
    }

    // SOUTH & EAST ------------------------------
    // . . .
    // . . E
    // . S *
    y = height - 1;
    while (y >= 0) : (y -= 1) { // (height-1)..=0
        x = 0;
        while (x < width) : (x += 1) { // 0..width
            if (sourceMap.IsWallAt(x, y)) {
                continue;
            }

            if (sourceMap.IsWallAt(x, y)) {
                continue;
            }

            const blocki: usize = @intCast(y * width + x);
            if (x == width - 1 or y == height - 1) {
                bakedmap.SetDistance(blocki, .SE, 0); // Diagonal-Wall Distance
                continue;
            }

            const p = int2.Init(x, y);
            const p1 = p.Forward(.S);
            const p2 = p.Forward(.SE);
            const p3 = p.Forward(.E);
            const isWall_p1 = sourceMap.IsWallPos(p1);
            const isWall_p3 = sourceMap.IsWallPos(p3);
            if (isWall_p1 or isWall_p3 or sourceMap.IsWallPos(p2)) {
                bakedmap.SetDistance(blocki, .SE, 0); // Diagonal-Wall Distance
                continue;
            }

            const prevBlocki = bakedmap.GetBlockIndex_Uncheck(p2);
            if (!isWall_p1 and !isWall_p3 and
                (bakedmap.GetDistanceByBlocki(prevBlocki, .S) > 0 or bakedmap.GetDistanceByBlocki(prevBlocki, .E) > 0))
            {
                bakedmap.SetDistance(blocki, .SE, 1); // Initial Diagonal Distance
                continue;
            }

            const distanceFromPrev = bakedmap.GetDistanceByBlocki(prevBlocki, .SE);
            if (distanceFromPrev > 0) {
                bakedmap.SetDistance(blocki, .SE, distanceFromPrev + 1); // Diagonal Distance
            } else {
                bakedmap.SetDistance(blocki, .SE, distanceFromPrev - 1); // Diagonal-Wall Distance
            }
        }
    }
}

fn IsJumpable(this: *const JpsplusMapBaker, blockidx: usize, dir: E_DIR) bool {
    return this.dirsets.items[blockidx].IsContains(dir);
}
