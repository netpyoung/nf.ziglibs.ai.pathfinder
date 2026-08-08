const std = @import("std");

const UNIT: i32 = 1; // 1byte
const UNIT_PER_BITS: i32 = 8; // UNIT * 8
const UNIT_BIT_MASK: u3 = 0b0111; // UNIT_PER_BITS - 1
const LOG2_UNIT_BITS: i32 = 3; // ceil(log10(UNIT_PER_BITS) / log10(2));
const PAD_ROW_BEFORE = 3;
const PAD_ROW_AFTER = 3;

const GridMap = @This();
origin_width: u32,
origin_height: u32,
db: []u8,
db_size: u32, // db_width * db_height;
db_width: u32,
db_height: u32,
padded_width: u32,
padded_height: u32,
padding_per_row: u32,
max_id: u32,

pub fn Init(allocator: std.mem.Allocator, width: u32, height: u32) std.mem.Allocator.Error!GridMap {
    var padded_width: u32 = width + 1;
    if ((padded_width % 32) != 0) {
        padded_width = (width / 32 + 1) * 32;
    }
    const padded_height: u32 = PAD_ROW_BEFORE + height + PAD_ROW_AFTER;
    const padding_per_row: u32 = padded_width - width;

    const db_height: u32 = padded_height;
    const db_width: u32 = padded_width >> LOG2_UNIT_BITS;
    const db_size: u32 = db_width * db_height;

    const db = try allocator.alloc(u8, @intCast(db_size));
    @memset(db, 0);

    const max_id: u32 = db_size - 1;

    return .{
        .origin_width = width,
        .origin_height = height,
        .padded_width = padded_width,
        .padded_height = padded_height,
        .padding_per_row = padding_per_row,
        .db_width = db_width,
        .db_height = db_height,
        .db_size = db_size,
        .db = db,
        .max_id = max_id,
    };
}

pub fn Deinit(this: *GridMap, allocator: std.mem.Allocator) void {
    allocator.free(this.db);
}

pub inline fn xy_to_padded_id(this: *const GridMap, x: u32, y: u32) u32 {
    const node_id = y * this.origin_width + x;
    return this.node_id_to_padded_id(node_id);
}

inline fn padded_xy_to_grid_id_p(this: *const GridMap, padded_x: u32, padded_y: u32) u32 {
    const grid_id_p = padded_y * this.padded_width + padded_x;
    return grid_id_p;
}

inline fn node_id_to_padded_id(this: *const GridMap, node_id: u32) u32 {
    const padded_id = node_id +
        (PAD_ROW_BEFORE * this.padded_width) +
        (node_id / this.origin_width) * this.padding_per_row;
    return padded_id;
}

pub inline fn padded_id_to_unpadded_xy(this: *const GridMap, padded_id: u32) struct { x: u32, y: u32 } {
    const v = padded_id - (PAD_ROW_BEFORE * this.padded_width);
    return .{
        .x = v % this.padded_width,
        .y = v / this.padded_width,
    };
}

inline fn padded_id_to_unpadded_id(this: *const GridMap, padded_id: u32) u32 {
    const unpadded = this.padded_id_to_unpadded_xy(padded_id);
    const unpadded_id = unpadded.y * this.origin_width + unpadded.x;
    return unpadded_id;
}

inline fn get_label_fromPaddedXY(this: *const GridMap, padded_x: u32, padded_y: u32) bool {
    const grid_id_p = this.padded_xy_to_grid_id_p(padded_x, padded_y);
    return this.get_label_fromGridId(grid_id_p);
}

inline fn set_label_fromPaddedXY(this: *GridMap, padded_x: u32, padded_y: u32, isSet: bool) void {
    const grid_id_p = this.padded_xy_to_grid_id_p(padded_x, padded_y);
    this.set_label_fromGridId(grid_id_p, isSet);
}

pub inline fn get_label_fromGridId(this: *const GridMap, grid_id_p: u32) bool {
    const db_index = grid_id_p >> LOG2_UNIT_BITS;
    if (db_index > this.max_id) {
        return false;
    }

    const bitmask: u8 = @as(u8, 1) << @intCast(grid_id_p & UNIT_BIT_MASK);
    const label = (this.db[db_index] & bitmask) != 0;
    return label;
}

pub inline fn set_label_fromGridId(this: *GridMap, grid_id_p: u32, isSet: bool) void {
    const db_index = grid_id_p >> LOG2_UNIT_BITS;
    if (db_index > this.max_id) {
        return;
    }

    const bitmask: u8 = @as(u8, 1) << @intCast(grid_id_p & UNIT_BIT_MASK);
    if (isSet) {
        this.db[db_index] |= bitmask;
    } else {
        this.db[db_index] &= ~bitmask;
    }
}

inline fn _get_u8(db_ptr: [*]u8, offset: u32, shift: u5) u8 {
    const ptr: *align(1) const u32 = @ptrCast(db_ptr + offset);
    return @truncate(ptr.* >> shift);
}

inline fn _get_u32(db_ptr: [*]const u8, offset: u32, shift: u6) u32 {
    const ptr: *align(1) const u64 = @ptrCast(db_ptr + offset);
    return @truncate(ptr.* >> shift);
}

pub inline fn get_neighbours(this: *const GridMap, grid_id_p: u32) u24 {
    const bit_offset: u3 = @intCast(grid_id_p & UNIT_BIT_MASK);
    const db_index = grid_id_p >> LOG2_UNIT_BITS;

    const pos0 = db_index - this.db_width;
    const pos1 = db_index;
    const pos2 = db_index + this.db_width;

    const ret: [3]u8 = .{
        _get_u8(this.db.ptr, pos0 - 1, @as(u5, bit_offset) + 7),
        _get_u8(this.db.ptr, pos1 - 1, @as(u5, bit_offset) + 7),
        _get_u8(this.db.ptr, pos2 - 1, @as(u5, bit_offset) + 7),
    };
    return @bitCast(ret);
}

pub inline fn get_neighbours_32bit(this: *const GridMap, grid_id_p: u32) [3]u32 {
    const bit_offset: u3 = @intCast(grid_id_p & UNIT_BIT_MASK);
    const db_index = grid_id_p >> LOG2_UNIT_BITS;

    const pos0 = db_index - this.db_width;
    const pos1 = db_index;
    const pos2 = db_index + this.db_width;

    const val0 = _get_u32(this.db.ptr, pos0, @as(u6, bit_offset));
    const val1 = _get_u32(this.db.ptr, pos1, @as(u6, bit_offset));
    const val2 = _get_u32(this.db.ptr, pos2, @as(u6, bit_offset));
    return .{ val0, val1, val2 };
}

pub inline fn get_neighbours_upper_32bit(this: *const GridMap, grid_id_p: u32) [3]u32 {
    const bit_offset: u3 = @intCast(grid_id_p & UNIT_BIT_MASK);
    const db_index = (grid_id_p >> LOG2_UNIT_BITS) - 4;

    const pos0 = db_index - this.db_width;
    const pos1 = db_index;
    const pos2 = db_index + this.db_width;

    const val0 = _get_u32(this.db.ptr, pos0, @as(u6, bit_offset) + 1);
    const val1 = _get_u32(this.db.ptr, pos1, @as(u6, bit_offset) + 1);
    const val2 = _get_u32(this.db.ptr, pos2, @as(u6, bit_offset) + 1);
    return .{ val0, val1, val2 };
}

test "x" {
    const allocator = std.testing.allocator;

    var x = try Init(allocator, 100, 40);
    defer x.Deinit(allocator);
    // 100x40
    // padded_width  = 100 + 1 =>
    //                 101 / 32 = 3 != 0
    //                 (100/32 + 1) * 32
    //                 (3 + 1) * 32
    //               = 128
    // padded_height = 3 + 40 + 3 = 46
    // padding_per_row = 128 - 100 = 28
    //
    // db_width = 128 >> 3 = 128 / 8 = 16
    // db_height = 46
    // db_size = 46 * 16 = 736
    // max_id = 736 - 1 = 735

    try std.testing.expectEqual(384, x.xy_to_padded_id(0, 0));
    try std.testing.expectEqual(513, x.xy_to_padded_id(1, 1));

    const padded_id = x.xy_to_padded_id(10, 4);
    const tiles1 = x.get_neighbours(padded_id);
    const tiles3 = x.get_neighbours_upper_32bit(padded_id);
    _ = tiles1;
    _ = tiles3;
}
