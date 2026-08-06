const std = @import("std");

const IMap = @import("../IMap.zig");
const E_DIR = @import("../Common/E_DIR.zig").E_DIR;

const GridMap = @import("./GridMap.zig");

pub const INVALID_MAPID = std.math.maxInt(u32);

const JpsbMap = @This();

width: i32,
height: i32,
map_forward: GridMap,
map_rotated: GridMap,

const FindStopPosResult = struct {
    stop_pos: u32,
    is_stopped_by_wall: bool,
};

const JumpResult = struct {
    jumpNodeId: u32,
    jumpDist: u32,
};

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

pub fn Init(allocator: std.mem.Allocator, width: i32, height: i32) !JpsbMap {
    const map_forward = try GridMap.Init(allocator, @intCast(width), @intCast(height));
    const map_rotated = try GridMap.Init(allocator, @intCast(height), @intCast(width));

    var map = JpsbMap{
        .width = width,
        .height = height,
        .map_forward = map_forward,
        .map_rotated = map_rotated,
    };

    for (0..@intCast(height)) |y| {
        for (0..@intCast(width)) |x| {
            map.SetEmptyAt(@intCast(x), @intCast(y), true);
        }
    }

    return map;
}

pub fn Deinit(this: *JpsbMap, allocator: std.mem.Allocator) void {
    this.map_forward.Deinit(allocator);
    this.map_rotated.Deinit(allocator);
}

pub fn GetNodeIndex_FromGridId(this: *const JpsbMap, grid_id_p: u32) usize {
    const unpadded = this.map_forward.padded_id_to_unpadded_xy(grid_id_p);
    const idx = unpadded.y * this.map_forward.origin_width + unpadded.x;
    return idx;
}

pub fn GetNodeIndexOrNull_FromAt(this: *const JpsbMap, x: i32, y: i32) ?usize {
    const padded_id = this.map_forward.xy_to_padded_id(@intCast(x), @intCast(y));
    if (!this.map_forward.get_label_fromGridId(padded_id)) {
        return null;
    }
    const idx: usize = @intCast(y * @as(i32, @intCast(this.map_forward.origin_width)) + x);
    return idx;
}

pub fn SetEmptyAt(this: *JpsbMap, x: i32, y: i32, isEmpty: bool) void {
    const fid = this.map_forward.xy_to_padded_id(@intCast(x), @intCast(y));
    const rx: u32 = @intCast((this.height - 1) - y);
    const ry: u32 = @intCast(x);
    const rid = this.map_rotated.xy_to_padded_id(rx, ry);

    // 0: wall
    // 1: walkable
    this.map_forward.set_label_fromGridId(fid, isEmpty);
    this.map_rotated.set_label_fromGridId(rid, isEmpty);
}

pub inline fn SetWallAt(this: *JpsbMap, x: i32, y: i32, isWall: bool) void {
    this.SetEmptyAt(x, y, !isWall);
}

pub inline fn IsEmptyAt(this: *const JpsbMap, x: i32, y: i32) bool {
    // 0: wall
    // 1: walkable

    const padded_id = this.map_forward.xy_to_padded_id(@intCast(x), @intCast(y));
    return this.map_forward.get_label_fromGridId(padded_id);
}

pub inline fn IsWallAt(this: *const JpsbMap, x: i32, y: i32) bool {
    // 0: wall
    // 1: walkable
    const padded_id = this.map_forward.xy_to_padded_id(@intCast(x), @intCast(y));
    return !this.map_forward.get_label_fromGridId(padded_id);
}

pub inline fn get_neighbours(this: *const JpsbMap, grid_id_p: u32) u24 {
    const neighbours = this.map_forward.get_neighbours(grid_id_p);
    return neighbours;
}

pub fn xy_to_padded_id(this: *const JpsbMap, x: i32, y: i32) u32 {
    const fid = this.map_forward.xy_to_padded_id(@intCast(x), @intCast(y));
    return fid;
}

pub inline fn map_id_to_rmap_id(this: *const JpsbMap, mapid: u32) u32 {
    // mapid == padded_id

    if (mapid == JpsbMap.INVALID_MAPID) {
        return JpsbMap.INVALID_MAPID;
    }

    const unpadded = this.map_forward.padded_id_to_unpadded_xy(mapid);
    const rx = this.map_forward.origin_height - unpadded.y - 1;
    const ry = unpadded.x;
    return this.map_rotated.xy_to_padded_id(rx, ry);
}

pub inline fn rmap_id_to_map_id(this: *const JpsbMap, rmapid: u32) u32 {
    if (rmapid == JpsbMap.INVALID_MAPID) {
        return JpsbMap.INVALID_MAPID;
    }

    const unpadded_r = this.map_rotated.padded_id_to_unpadded_xy(rmapid);
    const x = unpadded_r.y;
    const y = this.map_rotated.origin_width - unpadded_r.x - 1;
    return this.map_forward.xy_to_padded_id(x, y);
}

pub fn Jump(this: *const JpsbMap, dir: E_DIR, nodeId: u32, goalId: u32) JpsbMap.JumpResult {
    switch (dir) {
        .E => {
            return _JumpEast(nodeId, goalId, &this.map_forward);
        },
        .W => {
            return _JumpWest(nodeId, goalId, &this.map_forward);
        },
        .N => {
            const rnode_id = this.map_id_to_rmap_id(nodeId);
            const rgoal_id = this.map_id_to_rmap_id(goalId);
            var r = _JumpEast(rnode_id, rgoal_id, &this.map_rotated); // __jump_north
            r.jumpNodeId = this.rmap_id_to_map_id(r.jumpNodeId);
            return r;
        },
        .S => {
            const rnode_id = this.map_id_to_rmap_id(nodeId);
            const rgoal_id = this.map_id_to_rmap_id(goalId);
            var r = _JumpWest(rnode_id, rgoal_id, &this.map_rotated); // __jump_south
            r.jumpNodeId = this.rmap_id_to_map_id(r.jumpNodeId);
            return r;
        },
        .NE => {
            return this._Jump_NorthEast(nodeId, goalId);
        },
        .NW => {
            return this._Jump_NorthWest(nodeId, goalId);
        },
        .SE => {
            return this._Jump_SouthEast(nodeId, goalId);
        },
        .SW => {
            return this._Jump_SouthWest(nodeId, goalId);
        },
        else => {
            return .{
                .jumpDist = 0,
                .jumpNodeId = JpsbMap.INVALID_MAPID,
            };
        },
    }
}

fn _Jump_NorthEast(this: *const JpsbMap, nodeId: u32, goalId: u32) JpsbMap.JumpResult {
    const neighbours = this.map_forward.get_neighbours(nodeId);
    const bits = (TILE_BITS.N_ | TILE_BITS.E_ | TILE_BITS.NE | TILE_BITS.C_);
    if ((neighbours & bits) != bits) {
        return .{
            .jumpNodeId = JpsbMap.INVALID_MAPID,
            .jumpDist = 0,
        };
    }

    var next_id = nodeId;
    var rnext_id = this.map_id_to_rmap_id(next_id);
    const rgoal_id = this.map_id_to_rmap_id(goalId);
    const fmapw = this.map_forward.padded_width;
    const rmapw = this.map_rotated.padded_width;

    var nums_steps: u32 = 0;

    while (true) {
        nums_steps += 1;
        next_id = next_id - fmapw + 1;
        rnext_id = rnext_id + rmapw + 1;

        const j1 = _JumpEast(rnext_id, rgoal_id, &this.map_rotated); // __jump_north
        if (j1.jumpNodeId != JpsbMap.INVALID_MAPID) {
            break;
        }

        const j2 = _JumpEast(next_id, goalId, &this.map_forward);
        if (j2.jumpNodeId != JpsbMap.INVALID_MAPID) {
            break;
        }

        if (j1.jumpDist == 0 or j2.jumpDist == 0) {
            next_id = JpsbMap.INVALID_MAPID;
            break;
        }
    }

    return .{
        .jumpNodeId = next_id,
        .jumpDist = nums_steps,
    };
}

fn _Jump_NorthWest(this: *const JpsbMap, nodeId: u32, goalId: u32) JpsbMap.JumpResult {
    const neighbours = this.map_forward.get_neighbours(nodeId);
    const bits = (TILE_BITS.N_ | TILE_BITS.W_ | TILE_BITS.NW | TILE_BITS.C_);
    if ((neighbours & bits) != bits) {
        return .{
            .jumpNodeId = JpsbMap.INVALID_MAPID,
            .jumpDist = 0,
        };
    }

    var next_id = nodeId;
    var rnext_id = this.map_id_to_rmap_id(next_id);
    const rgoal_id = this.map_id_to_rmap_id(goalId);
    const fmapw = this.map_forward.padded_width;
    const rmapw = this.map_rotated.padded_width;

    var nums_steps: u32 = 0;
    while (true) {
        nums_steps += 1;
        next_id = next_id - fmapw - 1;
        rnext_id = rnext_id - (rmapw - 1);

        const j1 = _JumpEast(rnext_id, rgoal_id, &this.map_rotated); // __jump_north
        if (j1.jumpNodeId != JpsbMap.INVALID_MAPID) {
            break;
        }
        const j2 = _JumpWest(next_id, goalId, &this.map_forward);
        if (j2.jumpNodeId != JpsbMap.INVALID_MAPID) {
            break;
        }

        if (j1.jumpDist == 0 or j2.jumpDist == 0) {
            next_id = JpsbMap.INVALID_MAPID;
            break;
        }
    }

    return .{
        .jumpNodeId = next_id,
        .jumpDist = nums_steps,
    };
}

fn _Jump_SouthEast(this: *const JpsbMap, nodeId: u32, goalId: u32) JumpResult {
    const neighbours = this.map_forward.get_neighbours(nodeId);
    const bits = (TILE_BITS.S_ | TILE_BITS.E_ | TILE_BITS.SE | TILE_BITS.C_);
    if ((neighbours & bits) != bits) {
        return .{
            .jumpNodeId = JpsbMap.INVALID_MAPID,
            .jumpDist = 0,
        };
    }

    var next_id = nodeId;
    var rnext_id = this.map_id_to_rmap_id(next_id);
    const rgoal_id = this.map_id_to_rmap_id(goalId);
    const fmapw = this.map_forward.padded_width;
    const rmapw = this.map_rotated.padded_width;

    var nums_steps: u32 = 0;
    while (true) {
        nums_steps += 1;
        next_id = next_id + fmapw + 1;
        rnext_id = rnext_id + rmapw - 1;

        const j1 = _JumpWest(rnext_id, rgoal_id, &this.map_rotated); // __jump_south
        if (j1.jumpNodeId != JpsbMap.INVALID_MAPID) {
            break;
        }
        const j2 = _JumpEast(next_id, goalId, &this.map_forward);
        if (j2.jumpNodeId != JpsbMap.INVALID_MAPID) {
            break;
        }

        if (j1.jumpDist == 0 or j2.jumpDist == 0) {
            next_id = JpsbMap.INVALID_MAPID;
            break;
        }
    }

    return .{
        .jumpNodeId = next_id,
        .jumpDist = nums_steps,
    };
}

fn _Jump_SouthWest(this: *const JpsbMap, nodeId: u32, goalId: u32) JpsbMap.JumpResult {
    const neighbours = this.map_forward.get_neighbours(nodeId);
    const bits = (TILE_BITS.S_ | TILE_BITS.W_ | TILE_BITS.SW | TILE_BITS.C_);
    if ((neighbours & bits) != bits) {
        return .{
            .jumpNodeId = JpsbMap.INVALID_MAPID,
            .jumpDist = 0,
        };
    }

    var next_id = nodeId;
    var rnext_id = this.map_id_to_rmap_id(next_id);
    const rgoal_id = this.map_id_to_rmap_id(goalId);
    const fmapw = this.map_forward.padded_width;
    const rmapw = this.map_rotated.padded_width;

    var nums_steps: u32 = 0;
    while (true) {
        nums_steps += 1;
        next_id = next_id + fmapw - 1;
        rnext_id = rnext_id - (rmapw + 1);

        const j1 = _JumpWest(rnext_id, rgoal_id, &this.map_rotated); // __jump_south
        if (j1.jumpNodeId != JpsbMap.INVALID_MAPID) {
            break;
        }

        const j2 = _JumpWest(next_id, goalId, &this.map_forward);
        if (j2.jumpNodeId != JpsbMap.INVALID_MAPID) {
            break;
        }

        if (j1.jumpDist == 0 or j2.jumpDist == 0) {
            next_id = JpsbMap.INVALID_MAPID;
            break;
        }
    }

    return .{
        .jumpNodeId = next_id,
        .jumpDist = nums_steps,
    };
}

inline fn FindStopPosOrNull_East(map: *const GridMap, jumpnode_id: u32) ?FindStopPosResult {
    // 0: wall
    // 1: walkable
    const neighbours = map.get_neighbours_32bit(jumpnode_id);

    const forced_B_up = (~neighbours[0] << 1) & neighbours[0];
    const B_n = ~neighbours[1];
    const forced_B_down = (~neighbours[2] << 1) & neighbours[2];

    const B_s = forced_B_up | forced_B_down | B_n; // stop_bits
    if (B_s == 0) {
        return null;
    }

    const stop_pos: u5 = @truncate(@ctz(B_s));
    const is_deadend = (B_n & (@as(u32, 1) << stop_pos)) != 0;
    return .{
        .stop_pos = stop_pos,
        .is_stopped_by_wall = is_deadend,
    };
}

inline fn FindStopPosOrNull_West(map: *const GridMap, jumpnode_id: u32) ?FindStopPosResult {
    // 0: wall
    // 1: walkable
    const neighbours = map.get_neighbours_upper_32bit(jumpnode_id);

    const forced_B_up = (~neighbours[0] >> 1) & neighbours[0];
    const B_n = ~neighbours[1];
    const forced_B_down = (~neighbours[2] >> 1) & neighbours[2];

    const B_s = forced_B_up | forced_B_down | B_n; // stop_bits
    if (B_s == 0) {
        return null;
    }

    const stop_pos: u5 = @truncate(@clz(B_s));
    const is_deadend = (B_n & (@as(u32, 0x80_00_00_00) >> stop_pos)) != 0; // 0b_1000_0000_0000_0000_0000_0000_0000_0000
    return .{
        .stop_pos = stop_pos,
        .is_stopped_by_wall = is_deadend,
    };
}

fn _JumpEast(nodeId: u32, goalId: u32, map: *const GridMap) JumpResult {
    var jumpnode_id = nodeId;
    var isDeadEnd = false;

    while (true) {
        const resultOrNull = FindStopPosOrNull_East(map, jumpnode_id);
        if (resultOrNull) |result| {
            jumpnode_id += result.stop_pos;
            isDeadEnd = result.is_stopped_by_wall;
            break;
        }

        jumpnode_id += 31;
    }

    var num_steps = jumpnode_id - nodeId;
    const goal_dist = goalId -% nodeId;
    // const goal_dist = goalId - nodeId;
    if (num_steps > goal_dist) {
        return .{
            .jumpNodeId = goalId,
            .jumpDist = goal_dist,
        };
    }

    if (isDeadEnd) {
        if (num_steps != 0) {
            num_steps -= 1;
        }
        jumpnode_id = INVALID_MAPID;
    }

    return .{
        .jumpNodeId = jumpnode_id,
        .jumpDist = num_steps,
    };
}

fn _JumpWest(nodeId: u32, goalId: u32, map: *const GridMap) JumpResult {
    var jumpnode_id = nodeId;
    var isDeadEnd = false;

    while (true) {
        const resultOrNull = FindStopPosOrNull_West(map, jumpnode_id);
        if (resultOrNull) |result| {
            jumpnode_id -= result.stop_pos;
            isDeadEnd = result.is_stopped_by_wall;
            break;
        }

        jumpnode_id -= 31;
    }

    var num_steps = nodeId - jumpnode_id;
    const goal_dist = nodeId -% goalId;
    // const goal_dist = nodeId - goalId;
    if (num_steps > goal_dist) {
        return .{
            .jumpNodeId = goalId,
            .jumpDist = goal_dist,
        };
    }

    if (isDeadEnd) {
        if (num_steps != 0) {
            num_steps -= 1;
        }
        jumpnode_id = INVALID_MAPID;
    }

    return .{
        .jumpNodeId = jumpnode_id,
        .jumpDist = num_steps,
    };
}

pub fn ToIMap(this: *JpsbMap) IMap {
    return .{
        .ptr = this,
        .vtable = &Interface.vtable,
    };
}

const Interface = struct {
    const This = JpsbMap;

    pub const vtable: IMap.VTable = .{
        .vptr_GetWidth = _vptr_GetWidth,
        .vptr_GetHeight = _vptr_GetHeight,
        .vptr_SetWallAt = _vptr_SetWallAt,
        .vptr_SetEmptyAt = _vptr_SetEmptyAt,
        .vptr_IsEmptyAt = _vptr_IsEmptyAt,
        .vptr_IsWallAt = _vptr_IsWallAt,
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

    fn _vptr_IsEmptyAt(context: *anyopaque, x: i32, y: i32) bool {
        const this: *This = @ptrCast(@alignCast(context));
        return this.IsEmptyAt(x, y);
    }

    fn _vptr_IsWallAt(context: *anyopaque, x: i32, y: i32) bool {
        const this: *This = @ptrCast(@alignCast(context));
        return this.IsWallAt(x, y);
    }
};
