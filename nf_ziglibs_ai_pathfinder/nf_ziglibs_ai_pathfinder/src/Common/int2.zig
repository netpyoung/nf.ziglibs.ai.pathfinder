const std = @import("std");

const E_DIR = @import("./E_DIR.zig").E_DIR;

pub const int2 = packed struct(u64) {
    x: i32,
    y: i32,

    pub const MINUS_ONE = int2.Init(-1, -1);
    pub const ZERO = int2.Init(0, 0);

    pub fn Init(x: i32, y: i32) int2 {
        return .{
            .x = x,
            .y = y,
        };
    }

    pub fn format(p: int2, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        try writer.print("int2({d}, {d})", .{ p.x, p.y });
    }

    pub inline fn Add(a: int2, b: int2) int2 {
        return .{ .x = a.x + b.x, .y = a.y + b.y };
    }

    pub inline fn Sub(a: int2, b: int2) int2 {
        return .{ .x = a.x - b.x, .y = a.y - b.y };
    }

    pub inline fn Mul(a: int2, b: int2) int2 {
        return .{ .x = a.x * b.x, .y = a.y * b.y };
    }

    pub inline fn MulWithScala(a: int2, s: i32) int2 {
        return .{ .x = a.x * s, .y = a.y * s };
    }

    pub fn DistanceSqrt(a: int2, b: int2) f32 {
        const absx = @abs(a.x - b.x);
        const absy = @abs(a.y - b.y);
        const dist_diagonal = @min(absx, absy);
        const dist_straight = @max(absx, absy) - dist_diagonal;

        const sqrt2: f32 = 1.4142135;
        const ret = @as(f32, @floatFromInt(dist_diagonal)) * sqrt2 + @as(f32, @floatFromInt(dist_straight));
        return ret;
    }

    pub inline fn Forward(p: int2, dir: E_DIR) int2 {
        return p.Add(dir.ToPos());
    }

    pub inline fn Backward(p: int2, dir: E_DIR) int2 {
        return p.Sub(dir.ToPos());
    }
};
