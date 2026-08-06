const std = @import("std");

const ISearcher = @import("../ISearcher.zig");

const PathNode = @import("../Common/PathNode.zig").PathNode_gf_i32;
const PathCostEvaluator = @import("../Common/PathCostEvaluator.zig").PathCostEvaluator_u32_1000;
const int2 = @import("../Common/int2.zig").int2;
const E_DIR = @import("../Common/E_DIR.zig").E_DIR;
const E_DIRSET = @import("../Common/E_DIR.zig").E_DIRSET;
const PriorityQueue = @import("../Common/PriorityQueue.zig").IndexedHeap_4ary;

const JpsplusBakedMap = @import("./JpsplusBakedMap.zig");

const PathNodeAndDir = struct {
    node: *PathNode,
    dir: E_DIR,

    pub fn GetPos(this: *const PathNodeAndDir) int2 {
        return this.node.pathNode.Pos;
    }

    pub fn GetHeapIndexRef(x: PathNodeAndDir) *u32 {
        return &x.node.HeapIndex;
    }

    pub fn CompareFn(_: void, a: PathNodeAndDir, b: PathNodeAndDir) std.math.Order {
        return PathNode.CompareFn({}, a.node, b.node);
    }
};

const Searcher_Jpsplus = @This();
bakedMap: *const JpsplusBakedMap,
fullPathNodes: []PathNode,
openQueue: PriorityQueue(PathNodeAndDir, void, PathNodeAndDir.CompareFn, PathNodeAndDir.GetHeapIndexRef),

pub fn Init(allocator: std.mem.Allocator, bakedMap: *const JpsplusBakedMap) !Searcher_Jpsplus {
    var fullPathNodes = try allocator.alloc(PathNode, bakedMap.blocks.len);
    for (0..@intCast(bakedMap.height)) |y| {
        for (0..@intCast(bakedMap.width)) |x| {
            const idx = y * @as(usize, @intCast(bakedMap.width)) + x;
            fullPathNodes[idx] = PathNode.empty;
            fullPathNodes[idx].Pos = int2.Init(@intCast(x), @intCast(y));
        }
    }

    var openQueue = PriorityQueue(PathNodeAndDir, void, PathNodeAndDir.CompareFn, PathNodeAndDir.GetHeapIndexRef).empty;
    try openQueue.EnsureTotalCapacity(allocator, @intCast(bakedMap.primaryBlockIndexes.len));

    return .{
        .bakedMap = bakedMap,
        .fullPathNodes = fullPathNodes,
        .openQueue = openQueue,
    };
}

pub fn Deinit(this: *Searcher_Jpsplus, allocator: std.mem.Allocator) void {
    allocator.free(this.fullPathNodes);
    this.openQueue.Deinit(allocator);
}

pub fn Search(this: *Searcher_Jpsplus, allocator: std.mem.Allocator, ax: i32, ay: i32, bx: i32, by: i32, pathBuffer: *std.ArrayList(int2)) !bool {
    const startp = int2.Init(ax, ay);
    const goalp = int2.Init(bx, by);
    const goalNodeOrNull = try this.TryFind(allocator, startp, goalp);
    if (goalNodeOrNull == null) {
        return false;
    }

    const goalNode = goalNodeOrNull.?;

    pathBuffer.clearRetainingCapacity();
    var node = goalNode;
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

fn TryFind(this: *Searcher_Jpsplus, allocator: std.mem.Allocator, startp: int2, goalp: int2) !?*PathNode {
    this.openQueue.Clear();
    for (0..this.fullPathNodes.len) |idx| {
        this.fullPathNodes[idx].Status = .NONE;
    }

    const startNode = this.GetNodeOrNull(startp) orelse return null;
    startNode.G = 0;
    startNode.F = 0;
    startNode.ParentOrNull = null;

    const goalNode = this.GetNodeOrNull(goalp) orelse return null;
    goalNode.G = 0;
    goalNode.F = 0;
    goalNode.ParentOrNull = null;

    const startJpsNode = PathNodeAndDir{ .node = startNode, .dir = E_DIR.START };
    try this.openQueue.Push(allocator, startJpsNode);
    startJpsNode.node.Status = .OPENED;

    while (this.openQueue.PopOrNull()) |poped| {
        poped.node.Status = .CLOSED;

        const currNode = poped.node;
        if (currNode == goalNode) {
            return goalNode;
        }

        const dx = goalNode.Pos.x - currNode.Pos.x;
        const dy = goalNode.Pos.y - currNode.Pos.y;
        const abs_dx: u32 = @intCast(@abs(dx));
        const abs_dy: u32 = @intCast(@abs(dy));
        const minDiff = @min(abs_dx, abs_dy);
        const maxDiff = @max(abs_dx, abs_dy);

        const validDirs_straight = VALID_LOOKUP_TABLE_S[@intCast(@intFromEnum(poped.dir))];
        for (validDirs_straight) |processDir| {
            const dirDistance = this.bakedMap.GetDistanceAt(currNode.Pos.x, currNode.Pos.y, processDir);
            if (dirDistance == 0) {
                continue;
            }

            const abs_dirDistance = @abs(dirDistance);

            var nextPathNode: *PathNode = undefined;
            var nextDistance: u32 = undefined;
            if (maxDiff <= abs_dirDistance and IsGoalInExactDirection(dx, dy, abs_dx, abs_dy, processDir)) {
                // straight - detect goal
                nextPathNode = goalNode;
                nextDistance = maxDiff;
            } else if (dirDistance > 0) {
                // jump dir
                nextPathNode = this.GetNodeWithDist(currNode, processDir, @intCast(dirDistance));
                nextDistance = @intCast(dirDistance);
            } else {
                // not found - nextNode
                continue;
            }

            if (nextPathNode.Status == .CLOSED) {
                continue;
            }

            const nextG: u32 = currNode.G + PathCostEvaluator.ForJump.calc_g_straight(nextDistance);
            if (nextPathNode.Status != .OPENED) {
                const h = PathCostEvaluator.calc_h(nextPathNode.Pos.x, nextPathNode.Pos.y, goalNode.Pos.x, goalNode.Pos.y);
                nextPathNode.ParentOrNull = currNode;
                nextPathNode.G = nextG;
                nextPathNode.F = nextG + h;

                const jumpJpsNode = PathNodeAndDir{ .node = nextPathNode, .dir = processDir };
                try this.openQueue.Push(allocator, jumpJpsNode);
                nextPathNode.Status = .OPENED;
            } else if (nextG < nextPathNode.G) {
                const beforeH = nextPathNode.F - nextPathNode.G;
                nextPathNode.ParentOrNull = currNode;
                nextPathNode.G = nextG;
                nextPathNode.F = nextG + beforeH;

                const jumpJpsNode = PathNodeAndDir{ .node = nextPathNode, .dir = processDir };
                this.openQueue._arraylist.items[nextPathNode.HeapIndex].dir = processDir;
                try this.openQueue.TryDecreaseKey(jumpJpsNode);
            }
        }

        const validDirs_diagonal = VALID_LOOKUP_TABLE_D[@intCast(@intFromEnum(poped.dir))];
        for (validDirs_diagonal) |processDir| {
            const dirDistance = this.bakedMap.GetDistanceAt(currNode.Pos.x, currNode.Pos.y, processDir);
            if (dirDistance == 0) {
                continue;
            }

            const abs_dirDistance = @abs(dirDistance);

            var nextPathNode: *PathNode = undefined;
            var nextDistance: u32 = undefined;
            if (minDiff <= abs_dirDistance and IsGoalInGeneralDirection(dx, dy, processDir)) {
                // directional - Target Jump Point
                nextPathNode = this.GetNodeWithDist(currNode, processDir, minDiff);
                nextDistance = minDiff;
            } else if (dirDistance > 0) {
                // jump dir
                nextPathNode = this.GetNodeWithDist(currNode, processDir, @intCast(dirDistance));
                nextDistance = @intCast(dirDistance);
            } else {
                // not found - nextNode
                continue;
            }

            if (nextPathNode.Status == .CLOSED) {
                continue;
            }

            const nextG: u32 = currNode.G + PathCostEvaluator.ForJump.calc_g_diagonal(nextDistance);
            if (nextPathNode.Status != .OPENED) {
                const h = PathCostEvaluator.calc_h(nextPathNode.Pos.x, nextPathNode.Pos.y, goalNode.Pos.x, goalNode.Pos.y);
                nextPathNode.ParentOrNull = currNode;
                nextPathNode.G = nextG;
                nextPathNode.F = nextG + h;

                const jumpJpsNode = PathNodeAndDir{ .node = nextPathNode, .dir = processDir };
                try this.openQueue.Push(allocator, jumpJpsNode);
                nextPathNode.Status = .OPENED;
            } else if (nextG < nextPathNode.G) {
                const beforeH = nextPathNode.F - nextPathNode.G;
                nextPathNode.ParentOrNull = currNode;
                nextPathNode.G = nextG;
                nextPathNode.F = nextG + beforeH;

                const jumpJpsNode = PathNodeAndDir{ .node = nextPathNode, .dir = processDir };
                try this.openQueue.TryDecreaseKey(jumpJpsNode);
            }
        }
    }

    return null;
}

inline fn GetNodeOrNull(this: *Searcher_Jpsplus, p: int2) ?*PathNode {
    if (this.bakedMap.GetBlockIndexOrNull(p)) |blocki| {
        return &this.fullPathNodes[blocki];
    }
    return null;
}

inline fn GetNodeWithDist(this: *Searcher_Jpsplus, node: *const PathNode, dir: E_DIR, dist: u32) *PathNode {
    const dirp = dir.ToPos();
    const x = node.Pos.x + dirp.x * @as(i32, @intCast(dist));
    const y = node.Pos.y + dirp.y * @as(i32, @intCast(dist));
    return &this.fullPathNodes[@intCast(y * this.bakedMap.width + x)];
}

const VALID_LOOKUP_TABLE_S: [9][]const E_DIR = blk: {
    // NW(7) N(0) NE(1)
    //  W(6)       E(2)
    // SW(5) S(4) SE(3)
    var ret: [9][]const E_DIR = undefined;
    ret[@intCast(@intFromEnum(E_DIR.N))] = &[_]E_DIR{ .E, .N, .W };
    ret[@intCast(@intFromEnum(E_DIR.E))] = &[_]E_DIR{ .S, .E, .N };
    ret[@intCast(@intFromEnum(E_DIR.S))] = &[_]E_DIR{ .W, .S, .E };
    ret[@intCast(@intFromEnum(E_DIR.W))] = &[_]E_DIR{ .N, .W, .S };
    ret[@intCast(@intFromEnum(E_DIR.NE))] = &[_]E_DIR{ .N, .E };
    ret[@intCast(@intFromEnum(E_DIR.SE))] = &[_]E_DIR{ .S, .E };
    ret[@intCast(@intFromEnum(E_DIR.SW))] = &[_]E_DIR{ .S, .W };
    ret[@intCast(@intFromEnum(E_DIR.NW))] = &[_]E_DIR{ .N, .W };
    ret[@intCast(@intFromEnum(E_DIR.START))] = &[_]E_DIR{ .N, .E, .S, .W };
    break :blk ret;
};

const VALID_LOOKUP_TABLE_D: [9][]const E_DIR = blk: {
    // NW(7) N(0) NE(1)
    //  W(6)       E(2)
    // SW(5) S(4) SE(3)
    var ret: [9][]const E_DIR = undefined;
    ret[@intCast(@intFromEnum(E_DIR.NE))] = &[_]E_DIR{.NE};
    ret[@intCast(@intFromEnum(E_DIR.SE))] = &[_]E_DIR{.SE};
    ret[@intCast(@intFromEnum(E_DIR.SW))] = &[_]E_DIR{.SW};
    ret[@intCast(@intFromEnum(E_DIR.NW))] = &[_]E_DIR{.NW};
    ret[@intCast(@intFromEnum(E_DIR.N))] = &[_]E_DIR{ .NE, .NW };
    ret[@intCast(@intFromEnum(E_DIR.E))] = &[_]E_DIR{ .SE, .NE };
    ret[@intCast(@intFromEnum(E_DIR.S))] = &[_]E_DIR{ .SW, .SE };
    ret[@intCast(@intFromEnum(E_DIR.W))] = &[_]E_DIR{ .NW, .SW };
    ret[@intCast(@intFromEnum(E_DIR.START))] = &[_]E_DIR{ .NE, .SE, .SW, .NW };
    break :blk ret;
};

fn IsGoalInExactDirection(dx: i32, dy: i32, abs_dx: u32, abs_dy: u32, processDir: E_DIR) bool {
    // NW(7) N(0) NE(1)
    //  W(6)       E(2)
    // SW(5) S(4) SE(3)
    switch (processDir) {
        .N => return dx == 0 and dy < 0,
        .S => return dx == 0 and dy > 0,
        .W => return dx < 0 and dy == 0,
        .E => return dx > 0 and dy == 0,
        .NW => return dx < 0 and dy < 0 and (abs_dx == abs_dy),
        .NE => return dx > 0 and dy < 0 and (abs_dx == abs_dy),
        .SW => return dx < 0 and dy > 0 and (abs_dx == abs_dy),
        .SE => return dx > 0 and dy > 0 and (abs_dx == abs_dy),
        .START => return false,
    }
}

fn IsGoalInGeneralDirection(dx: i32, dy: i32, processDir: E_DIR) bool {
    switch (processDir) {
        .N => return dx == 0 and dy < 0,
        .S => return dx == 0 and dy > 0,
        .W => return dx < 0 and dy == 0,
        .E => return dx > 0 and dy == 0,
        .NW => return dx < 0 and dy < 0,
        .NE => return dx > 0 and dy < 0,
        .SW => return dx < 0 and dy > 0,
        .SE => return dx > 0 and dy > 0,
        .START => return false,
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
    const This = Searcher_Jpsplus;

    pub const vtable: ISearcher.VTable = .{
        .vptr_Search = _vptr_Search,
    };

    fn _vptr_Search(context: *anyopaque, allocator: std.mem.Allocator, ax: i32, ay: i32, bx: i32, by: i32, resultNodes: *std.ArrayList(int2)) !bool {
        const this: *This = @ptrCast(@alignCast(context));
        return this.Search(allocator, ax, ay, bx, by, resultNodes);
    }
};

// =======================
