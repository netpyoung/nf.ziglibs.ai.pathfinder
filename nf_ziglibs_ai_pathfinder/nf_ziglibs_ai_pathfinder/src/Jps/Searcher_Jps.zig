const std = @import("std");

const ISearcher = @import("../ISearcher.zig");
const PathNode = @import("../Common/PathNode.zig").PathNode_gf_i32;
const PathCostEvaluator = @import("../Common/PathCostEvaluator.zig").PathCostEvaluator_u32_1000;
const int2 = @import("../Common/int2.zig").int2;
const E_DIR = @import("../Common/E_DIR.zig").E_DIR;
const E_DIRSET = @import("../Common/E_DIR.zig").E_DIRSET;
const PriorityQueue = @import("../Common/PriorityQueue.zig").IndexedHeap_4ary;

pub const Map_bool = @import("../Common/SimpleMap.zig").Map_bool;

const PathNodeAndDir = struct {
    node: *PathNode,
    dir: E_DIR,

    pub fn GetPos(this: *const PathNodeAndDir) int2 {
        return this.node.Pos;
    }

    pub fn GetHeapIndexRef(x: PathNodeAndDir) *u32 {
        return &x.node.HeapIndex;
    }

    pub fn CompareFn(_: void, a: PathNodeAndDir, b: PathNodeAndDir) std.math.Order {
        return PathNode.CompareFn({}, a.node, b.node);
    }
};

pub const Searcher_Jps = @This();
map: *const Map_bool,
fullPathNodes: []PathNode,
openQueue: PriorityQueue(PathNodeAndDir, void, PathNodeAndDir.CompareFn, PathNodeAndDir.GetHeapIndexRef),

pub fn Init(allocator: std.mem.Allocator, map: *const Map_bool) !Searcher_Jps {
    const width = map.width;
    const height = map.height;
    const size: usize = @intCast(width * height);
    var ret: Searcher_Jps = .{
        .map = map,
        .fullPathNodes = try allocator.alloc(PathNode, size),
        .openQueue = .empty,
    };

    for (0..size) |i| {
        const x: i32 = @rem(@as(i32, @intCast(i)), width);
        const y: i32 = @divTrunc(@as(i32, @intCast(i)), width);
        ret.fullPathNodes[i] = PathNode.empty;
        ret.fullPathNodes[i].Pos = int2.Init(x, y);
    }
    return ret;
}

pub fn Deinit(this: *Searcher_Jps, allocator: std.mem.Allocator) void {
    allocator.free(this.fullPathNodes);
    this.openQueue.Deinit(allocator);
}

pub fn Search(this: *Searcher_Jps, allocator: std.mem.Allocator, ax: i32, ay: i32, bx: i32, by: i32, pathBuffer: *std.ArrayList(int2)) !bool {
    const startp = int2.Init(ax, ay);
    const goalP = int2.Init(bx, by);
    const goalNodeOrNull = try this.TryFind(allocator, startp, goalP);
    if (goalNodeOrNull == null) {
        return false;
    }

    pathBuffer.clearRetainingCapacity();
    var node = goalNodeOrNull.?;
    while (true) {
        try pathBuffer.append(allocator, node.Pos);
        if (node.ParentOrNull) |parent| {
            node = parent;
        } else {
            break;
        }
    }
    std.mem.reverse(int2, pathBuffer.items);
    return true;
}

fn TryFind(this: *Searcher_Jps, allocator: std.mem.Allocator, startp: int2, goalP: int2) !?*PathNode {
    this.openQueue.Clear();
    for (0..this.fullPathNodes.len) |idx| {
        this.fullPathNodes[idx].Status = .NONE;
    }

    const startNode = this.GetNodeOrNull(startp) orelse return null;
    startNode.G = 0;
    startNode.F = 0;
    startNode.ParentOrNull = null;

    const goalNode = this.GetNodeOrNull(goalP) orelse return null;
    goalNode.G = 0;
    goalNode.F = 0;
    goalNode.ParentOrNull = null;

    if (startNode == goalNode) {
        return goalNode;
    }

    const startJpsNode = PathNodeAndDir{ .node = startNode, .dir = E_DIR.START };
    try this.openQueue.Push(allocator, startJpsNode);
    startJpsNode.node.Status = .OPENED;

    while (this.openQueue.PopOrNull()) |poped| {
        poped.node.Status = .CLOSED;

        const currNode = poped.node;
        if (currNode == goalNode) {
            return goalNode;
        }

        const currPos = currNode.Pos;
        const currDir = poped.dir;

        const successors = SuccessorsDirset(this.map, currPos, currDir);
        var iter = successors.iterator();
        while (iter.next()) |succesorDir| {
            var jumpResultOrNull: ?JumpResult = undefined;
            if (succesorDir.IsStraight()) {
                jumpResultOrNull = this.JumpStraightOrNull(currPos, succesorDir, goalP);
            } else {
                jumpResultOrNull = this.JumpDiagonalOrNull(currPos, succesorDir, goalP);
            }

            if (jumpResultOrNull == null) {
                continue;
            }

            const jumpResult = jumpResultOrNull.?;

            const jumpPos = jumpResult.jumpPos;
            const nextPathNode = this.GetNodeOrNull(jumpPos).?;
            if (nextPathNode.Status == .CLOSED) {
                continue;
            }

            const jumpDist = jumpResult.jumpDist;
            var nextG: u32 = undefined;
            if (succesorDir.IsStraight()) {
                nextG = currNode.G + PathCostEvaluator.ForJump.calc_g_straight(jumpDist);
            } else {
                nextG = currNode.G + PathCostEvaluator.ForJump.calc_g_diagonal(jumpDist);
            }

            if (nextPathNode.Status != .OPENED) {
                const h = PathCostEvaluator.calc_h(nextPathNode.Pos.x, nextPathNode.Pos.y, goalNode.Pos.x, goalNode.Pos.y);
                nextPathNode.ParentOrNull = currNode;
                nextPathNode.G = nextG;
                nextPathNode.F = nextG + h;

                const jumpJpsNode = PathNodeAndDir{ .node = nextPathNode, .dir = succesorDir };
                try this.openQueue.Push(allocator, jumpJpsNode);
                nextPathNode.Status = .OPENED;
            } else if (nextG < nextPathNode.G) {
                const beforeH = nextPathNode.F - nextPathNode.G;
                nextPathNode.ParentOrNull = currNode;
                nextPathNode.G = nextG;
                nextPathNode.F = nextG + beforeH;

                const jumpJpsNode = PathNodeAndDir{ .node = nextPathNode, .dir = succesorDir };
                this.openQueue._arraylist.items[nextPathNode.HeapIndex].dir = succesorDir;
                try this.openQueue.TryDecreaseKey(jumpJpsNode);
            }
        }
    }
    return null;
}

fn GetNodeOrNull(this: *const Searcher_Jps, p: int2) ?*PathNode {
    if (!this.map.IsInBoundary(p.x, p.y)) {
        return null;
    }

    return &this.fullPathNodes[@intCast(p.y * this.map.width + p.x)];
}

fn SuccessorsDirset(map: *const Map_bool, pos: int2, dir: E_DIR) E_DIRSET {
    const naturalNeighbourDirset = NaturalNeighbours(dir);
    const forcedNeighbourDirset = ForcedNeighbour(map, pos, dir);
    const successorCandidates = naturalNeighbourDirset.Intersect(forcedNeighbourDirset);
    return successorCandidates;
}

fn NaturalNeighbours(dir: E_DIR) E_DIRSET {
    if (dir.IsStraight()) {
        // . . .
        // p o N
        // . . .
        return dir.ToDirSet();
    } else {
        // . N N
        // . o N
        // p . .
        return dir.ToAroundSet();
    }
}

fn ForcedNeighbour(map: *const Map_bool, pos: int2, dir: E_DIR) E_DIRSET {
    if (dir == .START) {
        return .NONE;
    }

    // NW(7) N(0) NE(1)
    //  W(6)       E(2)
    // SW(5) S(4) SE(3)
    if (dir.IsStraight()) {
        var ret: i32 = 0;
        // . X F
        // p o .
        // . . .
        if (map.IsWallPos(pos.Forward(dir.Left(2))) and map.IsEmptyPos(pos.Forward(dir.Left(1)))) {
            ret |= @intFromEnum(dir.Left(1).ToDirSet());
        }
        // . . .
        // p o .
        // . X F
        if (map.IsWallPos(pos.Forward(dir.Right(2))) and map.IsEmptyPos(pos.Forward(dir.Right(1)))) {
            ret |= @intFromEnum(dir.Right(1).ToDirSet());
        }
        return @enumFromInt(ret);
    } else {
        var ret: i32 = 0;
        // F . .
        // X o .
        // p . .
        if (map.IsWallPos(pos.Forward(dir.Left(3))) and map.IsEmptyPos(pos.Forward(dir.Left(2)))) {
            ret |= @intFromEnum(dir.Left(2).ToDirSet());
        }
        // . . .
        // . o .
        // p X F
        if (map.IsWallPos(pos.Forward(dir.Right(3))) and map.IsEmptyPos(pos.Forward(dir.Right(2)))) {
            ret |= @intFromEnum(dir.Right(2).ToDirSet());
        }
        return @enumFromInt(ret);
    }
}

const JumpResult = struct {
    jumpPos: int2,
    jumpDist: u32,
};

fn JumpStraightOrNull(this: *const Searcher_Jps, p: int2, dir: E_DIR, goalP: int2) ?JumpResult {
    var next = p.Forward(dir);
    var jumpDist: u32 = 1;

    while (true) {
        if (next == goalP) {
            return .{ .jumpPos = next, .jumpDist = jumpDist };
        }

        if (this.map.IsWallPos(next)) {
            return null;
        }

        if (ForcedNeighbour(this.map, next, dir) != .NONE) {
            return .{ .jumpPos = next, .jumpDist = jumpDist };
        }

        next = next.Forward(dir);
        jumpDist += 1;
    }
}

fn JumpDiagonalOrNull(this: *const Searcher_Jps, p: int2, dir: E_DIR, goalP: int2) ?JumpResult {
    var next = p.Forward(dir);
    var jumpDist: u32 = 1;

    while (true) {
        if (next == goalP) {
            return .{ .jumpPos = next, .jumpDist = jumpDist };
        }

        if (this.map.IsWallPos(next)) {
            return null;
        }

        if (ForcedNeighbour(this.map, next, dir) != .NONE) {
            return .{ .jumpPos = next, .jumpDist = jumpDist };
        }

        if (this.JumpStraightOrNull(next, dir.DiagonalToEastOrWest(), goalP)) |_| {
            return .{ .jumpPos = next, .jumpDist = jumpDist };
        }

        if (this.JumpStraightOrNull(next, dir.DiagonalToNorthOrSouth(), goalP)) |_| {
            return .{ .jumpPos = next, .jumpDist = jumpDist };
        }

        next = next.Forward(dir);
        jumpDist += 1;
    }
}

// =======================

pub fn ToISearcher(this: *@This()) ISearcher {
    return .{
        .ptr = this,
        .vtable = &Interface.vtable,
    };
}

const Interface = struct {
    const This = Searcher_Jps;

    pub const vtable: ISearcher.VTable = .{
        .vptr_Search = _vptr_Search,
    };

    fn _vptr_Search(context: *anyopaque, allocator: std.mem.Allocator, ax: i32, ay: i32, bx: i32, by: i32, resultNodes: *std.ArrayList(int2)) !bool {
        const this: *This = @ptrCast(@alignCast(context));
        return this.Search(allocator, ax, ay, bx, by, resultNodes);
    }
};

// =======================

test "a" {
    std.debug.print("WWWWWWWWWWWW\n", .{});

    const PathFinder = Searcher_Jps;

    const allocator = std.testing.allocator;

    var m = try Map_bool.Init(allocator, 10, 10);
    defer m.Deinit(allocator);

    var x = try PathFinder.Init(allocator, &m);
    defer x.Deinit(allocator);

    var resultNodes: std.ArrayList(int2) = .empty;
    defer resultNodes.deinit(allocator);

    _ = try x.Search(allocator, 1, 1, 3, 5, &resultNodes);

    std.debug.print("--PathFinder_Jps start\n", .{});
    for (resultNodes.items) |p| {
        std.debug.print("{f}\n", .{p});
    }
    std.debug.print("--PathFinder_Jps end\n", .{});
}

test "X" {
    const matrix = [5][5]bool{
        .{ false, false, false, false, false },
        .{ false, false, false, false, false },
        .{ false, false, false, true, false }, // (3, 2)
        .{ false, false, false, false, false },
        .{ false, false, false, false, false },
    };

    const allocator = std.testing.allocator;
    var map = try Map_bool.Init(allocator, 5, 5);
    defer map.Deinit(allocator);

    for (0..5) |y| {
        for (0..5) |x| {
            if (matrix[y][x]) {
                std.debug.print("*", .{});
            } else {
                std.debug.print(".", .{});
            }
            map.SetWallAt(@intCast(x), @intCast(y), matrix[y][x]);
        }
        std.debug.print("\n", .{});
    }

    {
        const o = int2.Init(2, 2);
        // . . F
        // . o X
        // . . P
        const forcedNeighbourDir = ForcedNeighbour(&map, o, .NW);
        try std.testing.expectEqual(E_DIRSET.NORTHEAST, forcedNeighbourDir);

        // N N .
        // N o X
        // . . P
        const naturalNeighbours = NaturalNeighbours(.NW);
        try std.testing.expectEqual(@as(E_DIRSET, @enumFromInt(@intFromEnum(E_DIRSET.NORTHWEST) | @intFromEnum(E_DIRSET.NORTH) | @intFromEnum(E_DIRSET.WEST))), naturalNeighbours);

        // S S S
        // S o X
        // . . P
        const succesorsDir = SuccessorsDirset(&map, o, .NW);
        try std.testing.expectEqual(
            @as(E_DIRSET, @enumFromInt(@intFromEnum(E_DIRSET.NORTHWEST) | @intFromEnum(E_DIRSET.NORTH) | @intFromEnum(E_DIRSET.NORTHEAST) | @intFromEnum(E_DIRSET.WEST))),
            succesorsDir,
        );
    }

    {
        const o = int2.Init(3, 1);
        // . . .
        // P o .
        // . X F
        const forcedNeighbourDir = ForcedNeighbour(&map, o, .E);
        try std.testing.expectEqual(E_DIRSET.SOUTHEAST, forcedNeighbourDir);

        // . . .
        // P o N
        // . X .
        const naturalNeighbours = NaturalNeighbours(.E);
        try std.testing.expectEqual(E_DIRSET.EAST, naturalNeighbours);

        // . . .
        // P o S
        // . X S
        const succesorsDir = SuccessorsDirset(&map, o, .E);
        try std.testing.expectEqual(
            @as(E_DIRSET, @enumFromInt(@intFromEnum(E_DIRSET.EAST) | @intFromEnum(E_DIRSET.SOUTHEAST))),
            succesorsDir,
        );
    }
}

test "XY" {
    const matrix = [5][5]bool{
        .{ false, false, false, true, false }, // (3, 0)
        .{ false, false, false, false, false },
        .{ false, false, false, true, false }, // (3, 2)
        .{ false, false, true, false, false }, // (2, 3)
        .{ false, false, false, false, false },
    };

    const allocator = std.testing.allocator;
    var map = try Map_bool.Init(allocator, 5, 5);
    defer map.Deinit(allocator);

    for (0..5) |y| {
        for (0..5) |x| {
            if (matrix[y][x]) {
                std.debug.print("*", .{});
            } else {
                std.debug.print(".", .{});
            }
            map.SetWallAt(@intCast(x), @intCast(y), matrix[y][x]);
        }
        std.debug.print("\n", .{});
    }

    {
        const o = int2.Init(2, 2);
        // . . F
        // . o X
        // F X P
        const forcedNeighbourDir = ForcedNeighbour(&map, o, .NW);
        try std.testing.expectEqual(
            @as(E_DIRSET, @enumFromInt(@intFromEnum(E_DIRSET.NORTHEAST) | @intFromEnum(E_DIRSET.SOUTHWEST))),
            forcedNeighbourDir,
        );

        // N N .
        // N o X
        // . X P
        const naturalNeighbours = NaturalNeighbours(.NW);
        try std.testing.expectEqual(@as(E_DIRSET, @enumFromInt(@intFromEnum(E_DIRSET.NORTHWEST) | @intFromEnum(E_DIRSET.NORTH) | @intFromEnum(E_DIRSET.WEST))), naturalNeighbours);

        // S S S
        // S o X
        // S X P
        const succesorsDir = SuccessorsDirset(&map, o, .NW);
        try std.testing.expectEqual(
            @as(E_DIRSET, @enumFromInt(@intFromEnum(E_DIRSET.NORTHWEST) | @intFromEnum(E_DIRSET.NORTH) | @intFromEnum(E_DIRSET.NORTHEAST) | @intFromEnum(E_DIRSET.WEST) | @intFromEnum(E_DIRSET.SOUTHWEST))),
            succesorsDir,
        );
    }

    {
        const o = int2.Init(3, 1);
        // . X F
        // P o .
        // . X F
        const forcedNeighbourDir = ForcedNeighbour(&map, o, .E);
        try std.testing.expectEqual(
            @as(E_DIRSET, @enumFromInt(@intFromEnum(E_DIRSET.NORTHEAST) | @intFromEnum(E_DIRSET.SOUTHEAST))),
            forcedNeighbourDir,
        );

        // . X .
        // P o N
        // . X .
        const naturalNeighbours = NaturalNeighbours(.E);
        try std.testing.expectEqual(E_DIRSET.EAST, naturalNeighbours);

        // . X S
        // P o S
        // . X S
        const succesorsDir = SuccessorsDirset(&map, o, .E);
        try std.testing.expectEqual(
            @as(E_DIRSET, @enumFromInt(@intFromEnum(E_DIRSET.EAST) | @intFromEnum(E_DIRSET.SOUTHEAST) | @intFromEnum(E_DIRSET.NORTHEAST))),
            succesorsDir,
        );
    }
    {
        const forcedNeighbourDir = ForcedNeighbour(&map, int2.ZERO, .E);
        try std.testing.expectEqual(
            E_DIRSET.NONE,
            forcedNeighbourDir,
        );
    }
}
