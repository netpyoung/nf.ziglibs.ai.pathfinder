const std = @import("std");

const ISearcher = @import("../ISearcher.zig");
const PathNode = @import("../Common/PathNode.zig").PathNode_gf_i32_with_grid_id;
const PathCostEvaluator = @import("../Common/PathCostEvaluator.zig").PathCostEvaluator_u32_1000;
const E_DIR = @import("../Common/E_DIR.zig").E_DIR;
const E_DIRSET = @import("../Common/E_DIR.zig").E_DIRSET;
const int2 = @import("../Common/int2.zig").int2;
const PriorityQueue = @import("../Common/PriorityQueue.zig").IndexedHeap_4ary;

const JpsbMap = @import("./JpsbMap.zig");

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

const Searcher_Jpsb = @This();
fullPathNodes: []PathNode,
openQueue: PriorityQueue(PathNodeAndDir, void, PathNodeAndDir.CompareFn, PathNodeAndDir.GetHeapIndexRef),
map: *const JpsbMap,

pub fn Init(allocator: std.mem.Allocator, map: *const JpsbMap) !Searcher_Jpsb {
    const width: usize = @intCast(map.width);
    const height: usize = @intCast(map.height);
    const size: usize = width * height;

    var fullPathNodes: []PathNode = try allocator.alloc(PathNode, size);
    for (0..height) |y| {
        for (0..width) |x| {
            const fid = map.xy_to_padded_id(@intCast(x), @intCast(y));

            const idx: usize = y * width + x;
            fullPathNodes[idx] = PathNode.empty;
            fullPathNodes[idx].This_grid_id_p = fid;
            fullPathNodes[idx].Pos = int2.Init(@intCast(x), @intCast(y));
        }
    }

    return .{
        .fullPathNodes = fullPathNodes,
        .openQueue = .empty,
        .map = map,
    };
}

pub fn Deinit(this: *Searcher_Jpsb, allocator: std.mem.Allocator) void {
    allocator.free(this.fullPathNodes);
    this.openQueue.Deinit(allocator);
}

pub fn Search(this: *Searcher_Jpsb, allocator: std.mem.Allocator, ax: i32, ay: i32, bx: i32, by: i32, pathBuffer: *std.ArrayList(int2)) !bool {
    const startp = int2.Init(ax, ay);
    const goalP = int2.Init(bx, by);
    const goalNodeOrNull = try this._TryFind(allocator, startp, goalP);
    if (goalNodeOrNull == null) {
        return false;
    }

    pathBuffer.clearRetainingCapacity();
    var node = goalNodeOrNull.?;
    while (true) {
        try pathBuffer.append(allocator, node.Pos);
        if (node.Parent_grid_id_p == PathNode.NO_PARENT) {
            break;
        }
        const idx = this.map.GetNodeIndex_FromGridId(node.Parent_grid_id_p);
        node = &this.fullPathNodes[idx];
    }
    std.mem.reverse(int2, pathBuffer.items);
    return true;
}

fn _TryFind(this: *Searcher_Jpsb, allocator: std.mem.Allocator, startp: int2, goalP: int2) !?*PathNode {
    this.openQueue.Clear();
    for (0..this.fullPathNodes.len) |idx| {
        this.fullPathNodes[idx].Status = .NONE;
    }

    const startNode = this._GetNodeOrNull(startp) orelse return null;
    startNode.G = 0;
    startNode.F = 0;
    startNode.Parent_grid_id_p = JpsbMap.INVALID_MAPID;

    const goalNode = this._GetNodeOrNull(goalP) orelse return null;
    goalNode.G = 0;
    goalNode.F = 0;
    goalNode.Parent_grid_id_p = JpsbMap.INVALID_MAPID;

    const goalId = goalNode.This_grid_id_p;

    const startJpsNode = PathNodeAndDir{ .node = startNode, .dir = E_DIR.START };
    try this.openQueue.Push(allocator, startJpsNode);
    startJpsNode.node.Status = .OPENED;

    while (this.openQueue.PopOrNull()) |poped| {
        poped.node.Status = .CLOSED;

        const currNode = poped.node;
        if (currNode == goalNode) {
            return goalNode;
        }

        const currId = currNode.This_grid_id_p;
        const currDir = poped.dir;

        const neighbours = this.map.get_neighbours(currId);
        // debug_u24(neighbours);
        const successors = compute_successors(currDir, neighbours);

        var iter = successors.iterator();
        while (iter.next()) |succesorDir| {
            const jumpResult = this.map.Jump(succesorDir, currId, goalId);
            if (jumpResult.jumpNodeId == JpsbMap.INVALID_MAPID) {
                continue;
            }

            const nextPathNode = this._GetNodeByGridId(jumpResult.jumpNodeId);
            if (nextPathNode.Status == .CLOSED) {
                continue;
            }

            var nextG: u32 = undefined;
            if (succesorDir.IsStraight()) {
                nextG = currNode.G + PathCostEvaluator.ForJump.calc_g_straight(@intCast(jumpResult.jumpDist));
            } else {
                nextG = currNode.G + PathCostEvaluator.ForJump.calc_g_diagonal(@intCast(jumpResult.jumpDist));
            }

            if (nextPathNode.Status != .OPENED) {
                const h = PathCostEvaluator.calc_h(nextPathNode.Pos.x, nextPathNode.Pos.y, goalNode.Pos.x, goalNode.Pos.y);
                nextPathNode.Parent_grid_id_p = currNode.This_grid_id_p;
                nextPathNode.G = nextG;
                nextPathNode.F = nextG + h;

                const jumpJpsNode = PathNodeAndDir{ .node = nextPathNode, .dir = succesorDir };
                try this.openQueue.Push(allocator, jumpJpsNode);
                nextPathNode.Status = .OPENED;
            } else if (nextG < nextPathNode.G) {
                const beforeH = nextPathNode.F - nextPathNode.G;
                nextPathNode.Parent_grid_id_p = currNode.This_grid_id_p;
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

fn _GetNodeOrNull(this: *const Searcher_Jpsb, p: int2) ?*PathNode {
    if (this.map.GetNodeIndexOrNull_FromAt(p.x, p.y)) |idx| {
        return &this.fullPathNodes[idx];
    }
    return null;
}

fn _GetNodeByGridId(this: *const Searcher_Jpsb, gridId: u32) *PathNode {
    const idx = this.map.GetNodeIndex_FromGridId(gridId);
    return &this.fullPathNodes[idx];
}

const TILE_BITS = struct {
    // NW N NE | 0 1 2
    //  W C  E | 3 4 5
    // SW S SE | 6 7 8
    //
    // => bit position order
    // SE S SW | 8 7 6
    // E  C  W | 5 4 3
    // NE N NW | 2 1 0
    //
    // => u32
    // 0000_0000
    // 0000_..S.
    // 0000_.E.W
    // 0000_..N.
    //                                   ..S.      .E.W      ..N.
    pub const N_: u32 = 0b0000_0000_0000_0000_0000_0000_0000_0010;
    pub const S_: u32 = 0b0000_0000_0000_0010_0000_0000_0000_0000;
    pub const E_: u32 = 0b0000_0000_0000_0000_0000_0100_0000_0000;
    pub const W_: u32 = 0b0000_0000_0000_0000_0000_0001_0000_0000;
    //                                   .eSw      .E.W      .eNw
    pub const NE: u32 = 0b0000_0000_0000_0000_0000_0000_0000_0100;
    pub const NW: u32 = 0b0000_0000_0000_0000_0000_0000_0000_0001;
    pub const SE: u32 = 0b0000_0000_0000_0100_0000_0000_0000_0000;
    pub const SW: u32 = 0b0000_0000_0000_0001_0000_0000_0000_0000;
    //                                   ..S.      ..C.      ..N.
    pub const C_: u32 = 0b0000_0000_0000_0000_0000_0010_0000_0000;
};

inline fn compute_successors(dir: E_DIR, tiles: u24) E_DIRSET {
    const successors = compute_forced(dir, tiles) | compute_natural(dir, tiles);
    return @enumFromInt(successors);
}

fn compute_forced(dir: E_DIR, tiles: u24) u8 {
    var ret: u8 = 0;
    switch (dir) {
        .N => {
            // F . .
            // F o .
            // # P .
            const branch_nw: u8 = @intFromBool(tiles & (TILE_BITS.SW | TILE_BITS.W_) == TILE_BITS.W_);
            ret |= (branch_nw << E_DIRSET.BIT_SHIFT.WEST);
            ret |= (branch_nw << E_DIRSET.BIT_SHIFT.NORTHWEST);
            // . . F
            // . o F
            // . P #
            const branch_ne: u8 = @intFromBool(tiles & (TILE_BITS.SE | TILE_BITS.E_) == TILE_BITS.E_);
            ret |= (branch_ne << E_DIRSET.BIT_SHIFT.EAST);
            ret |= (branch_ne << E_DIRSET.BIT_SHIFT.NORTHEAST);
        },
        .S => {
            // # P .
            // F o .
            // F . .
            const branch_sw: u8 = @intFromBool(tiles & (TILE_BITS.NW | TILE_BITS.W_) == TILE_BITS.W_);
            ret |= (branch_sw << E_DIRSET.BIT_SHIFT.WEST);
            ret |= (branch_sw << E_DIRSET.BIT_SHIFT.SOUTHWEST);
            // . P #
            // . o F
            // . . F
            const branch_se: u8 = @intFromBool(tiles & (TILE_BITS.NE | TILE_BITS.E_) == TILE_BITS.E_);
            ret |= (branch_se << E_DIRSET.BIT_SHIFT.EAST);
            ret |= (branch_se << E_DIRSET.BIT_SHIFT.SOUTHEAST);
        },
        .E => {
            // # F F
            // P o .
            // . . .
            const branch_ne: u8 = @intFromBool(tiles & (TILE_BITS.NW | TILE_BITS.N_) == TILE_BITS.N_);
            ret |= (branch_ne << E_DIRSET.BIT_SHIFT.NORTH);
            ret |= (branch_ne << E_DIRSET.BIT_SHIFT.NORTHEAST);
            // . . .
            // P o .
            // # F F
            const branch_se: u8 = @intFromBool(tiles & (TILE_BITS.SW | TILE_BITS.S_) == TILE_BITS.S_);
            ret |= (branch_se << E_DIRSET.BIT_SHIFT.SOUTH);
            ret |= (branch_se << E_DIRSET.BIT_SHIFT.SOUTHEAST);
        },
        .W => {
            // F F #
            // . o P
            // . . .
            const branch_nw: u8 = @intFromBool(tiles & (TILE_BITS.NE | TILE_BITS.N_) == TILE_BITS.N_);
            ret |= (branch_nw << E_DIRSET.BIT_SHIFT.NORTH);
            ret |= (branch_nw << E_DIRSET.BIT_SHIFT.NORTHWEST);
            // . . .
            // . o P
            // F F #
            const branch_sw: u8 = @intFromBool(tiles & (TILE_BITS.SE | TILE_BITS.S_) == TILE_BITS.S_);
            ret |= (branch_sw << E_DIRSET.BIT_SHIFT.SOUTH);
            ret |= (branch_sw << E_DIRSET.BIT_SHIFT.SOUTHWEST);
        },
        else => {},
    }
    return ret;
}

fn compute_natural(dir: E_DIR, tiles: u24) u8 {

    // NW N NE | 0 1 2
    //  W C  E | 3 4 5
    // SW S SE | 6 7 8
    //
    // => bit position order
    // SE S SW | 8 7 6
    // E  C  W | 5 4 3
    // NE N NW | 2 1 0
    //
    // 0000_0000
    // 0000_..S.
    // 0000_.E.W
    // 0000_..N.

    var ret: u8 = 0;
    switch (dir) {
        .N => {
            ret |= @as(u8, @intFromBool(tiles & TILE_BITS.N_ == TILE_BITS.N_)) << E_DIRSET.BIT_SHIFT.NORTH;
        },
        .S => {
            ret |= @as(u8, @intFromBool(tiles & TILE_BITS.S_ == TILE_BITS.S_)) << E_DIRSET.BIT_SHIFT.SOUTH;
        },
        .E => {
            ret |= @as(u8, @intFromBool(tiles & TILE_BITS.E_ == TILE_BITS.E_)) << E_DIRSET.BIT_SHIFT.EAST;
        },
        .W => {
            ret |= @as(u8, @intFromBool(tiles & TILE_BITS.W_ == TILE_BITS.W_)) << E_DIRSET.BIT_SHIFT.WEST;
        },
        .NW => {
            ret |= @as(u8, @intFromBool(tiles & TILE_BITS.N_ == TILE_BITS.N_)) << E_DIRSET.BIT_SHIFT.NORTH;
            ret |= @as(u8, @intFromBool(tiles & TILE_BITS.W_ == TILE_BITS.W_)) << E_DIRSET.BIT_SHIFT.WEST;
            ret |= @as(u8, @intFromBool(tiles & (TILE_BITS.N_ | TILE_BITS.W_ | TILE_BITS.NW) == (TILE_BITS.N_ | TILE_BITS.W_ | TILE_BITS.NW))) << E_DIRSET.BIT_SHIFT.NORTHWEST;
        },
        .NE => {
            ret |= @as(u8, @intFromBool(tiles & TILE_BITS.N_ == TILE_BITS.N_)) << E_DIRSET.BIT_SHIFT.NORTH;
            ret |= @as(u8, @intFromBool(tiles & TILE_BITS.E_ == TILE_BITS.E_)) << E_DIRSET.BIT_SHIFT.EAST;
            ret |= @as(u8, @intFromBool(tiles & (TILE_BITS.N_ | TILE_BITS.E_ | TILE_BITS.NE) == (TILE_BITS.N_ | TILE_BITS.E_ | TILE_BITS.NE))) << E_DIRSET.BIT_SHIFT.NORTHEAST;
        },
        .SW => {
            ret |= @as(u8, @intFromBool(tiles & TILE_BITS.S_ == TILE_BITS.S_)) << E_DIRSET.BIT_SHIFT.SOUTH;
            ret |= @as(u8, @intFromBool(tiles & TILE_BITS.W_ == TILE_BITS.W_)) << E_DIRSET.BIT_SHIFT.WEST;
            ret |= @as(u8, @intFromBool(tiles & (TILE_BITS.S_ | TILE_BITS.W_ | TILE_BITS.SW) == (TILE_BITS.S_ | TILE_BITS.W_ | TILE_BITS.SW))) << E_DIRSET.BIT_SHIFT.SOUTHWEST;
        },
        .SE => {
            ret |= @as(u8, @intFromBool(tiles & TILE_BITS.S_ == TILE_BITS.S_)) << E_DIRSET.BIT_SHIFT.SOUTH;
            ret |= @as(u8, @intFromBool(tiles & TILE_BITS.E_ == TILE_BITS.E_)) << E_DIRSET.BIT_SHIFT.EAST;
            ret |= @as(u8, @intFromBool(tiles & (TILE_BITS.S_ | TILE_BITS.E_ | TILE_BITS.SE) == (TILE_BITS.S_ | TILE_BITS.E_ | TILE_BITS.SE))) << E_DIRSET.BIT_SHIFT.SOUTHEAST;
        },
        else => {
            ret |= @as(u8, @intFromBool(tiles & TILE_BITS.N_ == TILE_BITS.N_)) << E_DIRSET.BIT_SHIFT.NORTH;
            ret |= @as(u8, @intFromBool(tiles & TILE_BITS.S_ == TILE_BITS.S_)) << E_DIRSET.BIT_SHIFT.SOUTH;
            ret |= @as(u8, @intFromBool(tiles & TILE_BITS.E_ == TILE_BITS.E_)) << E_DIRSET.BIT_SHIFT.EAST;
            ret |= @as(u8, @intFromBool(tiles & TILE_BITS.W_ == TILE_BITS.W_)) << E_DIRSET.BIT_SHIFT.WEST;
            ret |= @as(u8, @intFromBool(tiles & (TILE_BITS.N_ | TILE_BITS.E_ | TILE_BITS.NE) == (TILE_BITS.N_ | TILE_BITS.E_ | TILE_BITS.NE))) << E_DIRSET.BIT_SHIFT.NORTHEAST;
            ret |= @as(u8, @intFromBool(tiles & (TILE_BITS.N_ | TILE_BITS.W_ | TILE_BITS.NW) == (TILE_BITS.N_ | TILE_BITS.W_ | TILE_BITS.NW))) << E_DIRSET.BIT_SHIFT.NORTHWEST;
            ret |= @as(u8, @intFromBool(tiles & (TILE_BITS.S_ | TILE_BITS.E_ | TILE_BITS.SE) == (TILE_BITS.S_ | TILE_BITS.E_ | TILE_BITS.SE))) << E_DIRSET.BIT_SHIFT.SOUTHEAST;
            ret |= @as(u8, @intFromBool(tiles & (TILE_BITS.S_ | TILE_BITS.W_ | TILE_BITS.SW) == (TILE_BITS.S_ | TILE_BITS.W_ | TILE_BITS.SW))) << E_DIRSET.BIT_SHIFT.SOUTHWEST;
        },
    }
    return ret;
}

fn debug_u24(val: u24) void {
    const b1: u8 = @truncate(val >> 16);
    const b2: u8 = @truncate(val >> 8);
    const b3: u8 = @truncate(val);

    std.debug.print(
        \\{b:0>4} {b:0>4}
        \\{b:0>4} {b:0>4}
        \\{b:0>4} {b:0>4}
        \\
    , .{
        @as(u4, @intCast(b1 >> 4)), @as(u4, @truncate(b1)),
        @as(u4, @intCast(b2 >> 4)), @as(u4, @truncate(b2)),
        @as(u4, @intCast(b3 >> 4)), @as(u4, @truncate(b3)),
    });
}

pub fn ToISearcher(this: *@This()) ISearcher {
    return .{
        .ptr = this,
        .vtable = &Interface.vtable,
    };
}

const Interface = struct {
    const This = Searcher_Jpsb;

    pub const vtable: ISearcher.VTable = .{
        .vptr_Search = _vptr_Search,
    };

    fn _vptr_Search(context: *anyopaque, allocator: std.mem.Allocator, ax: i32, ay: i32, bx: i32, by: i32, resultNodes: *std.ArrayList(int2)) !bool {
        const this: *This = @ptrCast(@alignCast(context));
        return this.Search(allocator, ax, ay, bx, by, resultNodes);
    }
};
