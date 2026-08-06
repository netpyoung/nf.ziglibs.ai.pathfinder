const std = @import("std");

const ISearcher = @import("../ISearcher.zig");
const PathNode = @import("../Common/PathNode.zig").PathNode_gf_i32;
const PathCostEvaluator = @import("../Common/PathCostEvaluator.zig").PathCostEvaluator_u32_1000;
const int2 = @import("../Common/int2.zig").int2;
const E_DIR = @import("../Common/E_DIR.zig").E_DIR;
const PriorityQueue = @import("../Common/PriorityQueue.zig").IndexedHeap_4ary;

pub const Map_bool = @import("../Common/SimpleMap.zig").Map_bool;

const Searcher_Astar = @This();
map: *const Map_bool,
fullPathNodes: []PathNode,
openQueue: PriorityQueue(*PathNode, void, PathNode.CompareFn, PathNode.GetHeapIndexRef),

pub fn Init(allocator: std.mem.Allocator, sourceMap: *const Map_bool) !Searcher_Astar {
    const size: usize = @intCast(sourceMap.width * sourceMap.height);
    var ret: Searcher_Astar = .{
        .map = sourceMap,
        .fullPathNodes = try allocator.alloc(PathNode, size),
        .openQueue = .empty,
    };

    var i: usize = 0;
    for (0..@intCast(sourceMap.height)) |h| {
        for (0..@intCast(sourceMap.width)) |w| {
            const x: i32 = @intCast(w);
            const y: i32 = @intCast(h);
            ret.fullPathNodes[i] = PathNode.empty;
            ret.fullPathNodes[i].Pos = int2.Init(x, y);
            i += 1;
        }
    }
    return ret;
}

pub fn Deinit(this: *Searcher_Astar, allocator: std.mem.Allocator) void {
    allocator.free(this.fullPathNodes);
    this.openQueue.Deinit(allocator);
}

pub fn Search(this: *Searcher_Astar, allocator: std.mem.Allocator, ax: i32, ay: i32, bx: i32, by: i32, pathBuffer: *std.ArrayList(int2)) anyerror!bool {
    const startp = int2.Init(ax, ay);
    const goalp = int2.Init(bx, by);

    const goalNodeOrNull = try this.TryFind(allocator, startp, goalp);
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

fn TryFind(this: *Searcher_Astar, allocator: std.mem.Allocator, startp: int2, goalp: int2) !?*PathNode {
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
    try this.openQueue.Push(allocator, startNode);
    startNode.Status = .OPENED;

    const dirs_s: [4]E_DIR = .{ .E, .W, .N, .S };
    const dirs_d: [4]E_DIR = .{ .NE, .NW, .SE, .SW };

    while (this.openQueue.PopOrNull()) |curr| {
        curr.Status = .CLOSED;

        if (curr == goalNode) {
            return goalNode;
        }

        for (dirs_s) |dir| {
            const nextP = curr.Pos.Add(dir.ToPos());
            const adjacentOrNull = this.GetNodeOrNull(nextP);
            if (adjacentOrNull == null) {
                continue;
            }

            const adjacent = adjacentOrNull.?;
            if (adjacent.Status == .CLOSED) {
                continue;
            }

            const nextG = curr.G + PathCostEvaluator.calc_g(curr.Pos.x, curr.Pos.y, adjacent.Pos.x, adjacent.Pos.y);
            if (adjacent.Status != .OPENED) {
                const h = PathCostEvaluator.calc_h(adjacent.Pos.x, adjacent.Pos.y, goalNode.Pos.x, goalNode.Pos.y);
                adjacent.ParentOrNull = curr;
                adjacent.G = nextG;
                adjacent.F = nextG + h + (h >> 10);

                try this.openQueue.Push(allocator, adjacent);
                adjacent.Status = .OPENED;
            } else if (nextG < adjacent.G) {
                const beforeH = adjacent.F - adjacent.G;
                adjacent.ParentOrNull = curr;
                adjacent.G = nextG;
                adjacent.F = nextG + beforeH;

                try this.openQueue.TryDecreaseKey(adjacent);
            }
        }

        outer: for (dirs_d) |dir| {
            const nextP = curr.Pos.Add(dir.ToPos());
            const adjacentOrNull = this.GetNodeOrNull(nextP);
            if (adjacentOrNull == null) {
                continue;
            }

            const adjacent = adjacentOrNull.?;
            if (adjacent.Status == .CLOSED) {
                continue;
            }

            // disable corner-cutting
            const aroundDirs = dir.GetAround2();
            for (aroundDirs) |adir| {
                const aroundP = curr.Pos.Add(adir.ToPos());
                const aroundOrNull = this.GetNodeOrNull(aroundP);
                if (aroundOrNull == null) {
                    continue :outer;
                }
            }

            const nextG = curr.G + PathCostEvaluator.calc_g(curr.Pos.x, curr.Pos.y, adjacent.Pos.x, adjacent.Pos.y);
            if (adjacent.Status != .OPENED) {
                const h = PathCostEvaluator.calc_h(adjacent.Pos.x, adjacent.Pos.y, goalNode.Pos.x, goalNode.Pos.y);
                adjacent.ParentOrNull = curr;
                adjacent.G = nextG;
                adjacent.F = nextG + h;

                try this.openQueue.Push(allocator, adjacent);
                adjacent.Status = .OPENED;
            } else if (nextG < adjacent.G) {
                const beforeH = adjacent.F - adjacent.G;
                adjacent.ParentOrNull = curr;
                adjacent.G = nextG;
                adjacent.F = nextG + beforeH;

                try this.openQueue.TryDecreaseKey(adjacent);
            }
        }
    }
    return null;
}

fn GetNodeOrNull(this: *const Searcher_Astar, p: int2) ?*PathNode {
    if (this.map.IsWallPos(p)) {
        return null;
    }

    return &this.fullPathNodes[@intCast(p.y * this.map.width + p.x)];
}

// =======================

pub fn ToISearcher(this: *@This()) ISearcher {
    return .{
        .ptr = this,
        .vtable = &Interface.vtable,
    };
}

const Interface = struct {
    const This = Searcher_Astar;

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
    const PathFinder = Searcher_Astar;

    const allocator = std.testing.allocator;

    var m = try Map_bool.Init(allocator, 10, 10);
    defer m.Deinit(allocator);

    var x = try PathFinder.Init(allocator, &m);
    defer x.Deinit(allocator);

    var resultNodes: std.ArrayList(int2) = .empty;
    defer resultNodes.deinit(allocator);

    _ = try x.Search(allocator, 1, 1, 3, 5, &resultNodes);

    for (resultNodes.items) |p| {
        std.debug.print("{f}\n", .{p});
    }
}


