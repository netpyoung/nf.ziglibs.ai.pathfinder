const std = @import("std");
const int2 = @import("./int2.zig").int2;

pub fn BresenhamPathSmoother(comptime Context: type, comptime fnIsWallAt: fn (ctx: Context, x: i32, y: i32) callconv(.@"inline") bool) type {
    return struct {
        const Self = @This();
        context: Context,

        pub const empty: Self = .{
            .context = undefined,
        };

        pub fn initContext(context: Context) Self {
            return Self{
                .context = context,
            };
        }

        // ref: https://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm
        // ref: https://deepnight.net/tutorial/bresenham-magic-raycasting-line-of-sight-pathfinding/
        //   - https://github.com/deepnight/deepnightLibs/blob/master/src/dn/geom/Bresenham.hx
        pub fn CheckThickLine(this: @This(), start: int2, end: int2) bool {
            var x0 = start.x;
            var y0 = start.y;
            var x1 = end.x;
            var y1 = end.y;

            // if (fnIsWallAt(this.context, x0, y0)) {
            //     return false;
            // }
            // if (fnIsWallAt(this.context, x1, y1)) {
            //     return false;
            // }

            const is_swap_xy = @abs(y1 - y0) > @abs(x1 - x0);
            if (is_swap_xy) {
                std.mem.swap(i32, &x0, &y0);
                std.mem.swap(i32, &x1, &y1);
            }

            if (x0 > x1) {
                std.mem.swap(i32, &x0, &x1);
                std.mem.swap(i32, &y0, &y1);
            }

            const delta_x: i32 = x1 - x0;
            const delta_y: i32 = @intCast(@abs(y1 - y0));
            var err = @divTrunc(delta_x, 2);
            var y = y0;
            const ystep: i32 = if (y0 < y1) 1 else -1;

            if (is_swap_xy) {
                var x = x0;
                while (x <= x1) : (x += 1) {
                    if (fnIsWallAt(this.context, y, x)) {
                        return false;
                    }

                    err -= delta_y;
                    if (err < 0) {
                        if (x < x1) {
                            if (fnIsWallAt(this.context, y + ystep, x) or fnIsWallAt(this.context, y, x + 1)) {
                                return false;
                            }
                        }
                        y += ystep;
                        err += delta_x;
                    }
                }
            } else {
                var x = x0;
                while (x <= x1) : (x += 1) {
                    if (fnIsWallAt(this.context, x, y)) {
                        return false;
                    }

                    err -= delta_y;
                    if (err < 0) {
                        if (x < x1) {
                            if (fnIsWallAt(this.context, x, y + ystep) or fnIsWallAt(this.context, x + 1, y)) {
                                return false;
                            }
                        }
                        y += ystep;
                        err += delta_x;
                    }
                }
            }

            return true;
        }

        pub fn CheckThinLine(this: @This(), start: int2, end: int2) bool {
            _ = this;
            _ = start;
            _ = end;
            return false;
        }

        pub fn Smooth_Thickline(this: @This(), allocator: std.mem.Allocator, path: []int2, ret: *std.ArrayList(int2)) !void {
            if (path.len <= 2) {
                for (path) |p| {
                    try ret.append(allocator, p);
                }
                return;
            }

            try ret.append(allocator, path[0]);
            var current_index: usize = 0;
            const last_index = path.len - 1;

            while (current_index < last_index) {
                var next_index = last_index;

                while (next_index > current_index + 1) : (next_index -= 1) {
                    if (this.CheckThickLine(path[current_index], path[next_index])) {
                        break;
                    }
                }

                try ret.append(allocator, path[next_index]);

                current_index = next_index;
            }
        }

        pub fn Smooth_Thinline(this: @This(), allocator: std.mem.Allocator, path: []int2, ret: *std.ArrayList(int2)) !void {
            if (path.len <= 2) {
                for (path) |p| {
                    try ret.append(allocator, p);
                }
                return;
            }

            try ret.append(allocator, path[0]);
            var current_index: usize = 0;
            const last_index = path.len - 1;

            while (current_index < last_index) {
                var next_index = last_index;

                while (next_index > current_index + 1) : (next_index -= 1) {
                    if (this.CheckThinLine(path[current_index], path[next_index])) {
                        break;
                    }
                }

                try ret.append(allocator, path[next_index]);

                current_index = next_index;
            }
        }
    };
}

pub fn BresenhamPathSmoother_WithoutAlloc(comptime Context: type, comptime fnIsWallAt: fn (ctx: Context, x: i32, y: i32) callconv(.@"inline") bool) type {
    return struct {
        const Self = @This();
        context: Context,

        pub const empty: Self = .{
            .context = undefined,
        };

        pub fn initContext(context: Context) Self {
            return Self{
                .context = context,
            };
        }

        // ref: https://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm
        // ref: https://deepnight.net/tutorial/bresenham-magic-raycasting-line-of-sight-pathfinding/
        //   - https://github.com/deepnight/deepnightLibs/blob/master/src/dn/geom/Bresenham.hx
        pub fn CheckThickLine(this: @This(), start: int2, end: int2) bool {
            var x0 = start.x;
            var y0 = start.y;
            var x1 = end.x;
            var y1 = end.y;

            // if (fnIsWallAt(this.context, x0, y0)) {
            //     return false;
            // }
            // if (fnIsWallAt(this.context, x1, y1)) {
            //     return false;
            // }

            const is_swap_xy = @abs(y1 - y0) > @abs(x1 - x0);
            if (is_swap_xy) {
                std.mem.swap(i32, &x0, &y0);
                std.mem.swap(i32, &x1, &y1);
            }

            if (x0 > x1) {
                std.mem.swap(i32, &x0, &x1);
                std.mem.swap(i32, &y0, &y1);
            }

            const delta_x: i32 = x1 - x0;
            const delta_y: i32 = @intCast(@abs(y1 - y0));
            var err = @divTrunc(delta_x, 2);
            var y = y0;
            const ystep: i32 = if (y0 < y1) 1 else -1;

            if (is_swap_xy) {
                var x = x0;
                while (x <= x1) : (x += 1) {
                    if (fnIsWallAt(this.context, y, x)) {
                        return false;
                    }

                    err -= delta_y;
                    if (err < 0) {
                        if (x < x1) {
                            if (fnIsWallAt(this.context, y + ystep, x) or fnIsWallAt(this.context, y, x + 1)) {
                                return false;
                            }
                        }
                        y += ystep;
                        err += delta_x;
                    }
                }
            } else {
                var x = x0;
                while (x <= x1) : (x += 1) {
                    if (fnIsWallAt(this.context, x, y)) {
                        return false;
                    }

                    err -= delta_y;
                    if (err < 0) {
                        if (x < x1) {
                            if (fnIsWallAt(this.context, x, y + ystep) or fnIsWallAt(this.context, x + 1, y)) {
                                return false;
                            }
                        }
                        y += ystep;
                        err += delta_x;
                    }
                }
            }

            return true;
        }

        pub fn CheckThinLine(this: @This(), start: int2, end: int2) bool {
            _ = this;
            _ = start;
            _ = end;
            return false;
        }

        pub fn Smooth_Thickline_WithoutAlloc(this: @This(), path: []int2, ret: *std.ArrayList(int2)) !void {
            if (path.len <= 2) {
                for (path) |p| {
                    ret.appendAssumeCapacity(p);
                }
                return;
            }

            ret.appendAssumeCapacity(path[0]);
            var current_index: usize = 0;
            const last_index = path.len - 1;

            while (current_index < last_index) {
                var next_index = last_index;

                while (next_index > current_index + 1) : (next_index -= 1) {
                    if (this.CheckThickLine(path[current_index], path[next_index])) {
                        break;
                    }
                }

                ret.appendAssumeCapacity(path[next_index]);

                current_index = next_index;
            }
        }

        pub fn Smooth_Thinline_WithoutAlloc(this: @This(), path: []int2, ret: *std.ArrayList(int2)) !void {
            if (path.len <= 2) {
                for (path) |p| {
                    ret.appendAssumeCapacity(p);
                }
                return;
            }

            ret.appendAssumeCapacity(path[0]);
            var current_index: usize = 0;
            const last_index = path.len - 1;

            while (current_index < last_index) {
                var next_index = last_index;

                while (next_index > current_index + 1) : (next_index -= 1) {
                    if (this.CheckThinLine(path[current_index], path[next_index])) {
                        break;
                    }
                }

                ret.appendAssumeCapacity(path[next_index]);

                current_index = next_index;
            }
        }
    };
}
