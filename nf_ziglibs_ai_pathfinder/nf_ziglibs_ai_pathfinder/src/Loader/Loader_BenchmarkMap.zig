const std = @import("std");

const IMap = @import("../IMap.zig");

pub fn LoadMapFromBenchmarkMapFile(allocator: std.mem.Allocator, io: std.Io, map: IMap, file_path: []const u8) !void {
    const contents = try std.Io.Dir.readFileAlloc(std.Io.Dir.cwd(), io, file_path, allocator, .unlimited);
    defer allocator.free(contents);
    return try _LoadMapFromBenchmarkMapStr(map, contents);
}

fn _LoadMapFromBenchmarkMapStr(map: IMap, input: []const u8) !void {
    var line_iter = std.mem.tokenizeAny(u8, input, "\r\n");

    var width: ?i32 = null;
    var height: ?i32 = null;

    while (line_iter.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t");
        if (trimmed.len == 0) {
            continue;
        }

        if (std.mem.startsWith(u8, trimmed, "map")) {
            break;
        }

        var key_val = std.mem.tokenizeAny(u8, trimmed, " \t");
        const key = key_val.next() orelse continue;
        const val = key_val.next() orelse continue;

        if (std.mem.eql(u8, key, "width")) {
            width = try std.fmt.parseInt(i32, val, 10);
        } else if (std.mem.eql(u8, key, "height")) {
            height = try std.fmt.parseInt(i32, val, 10);
        }
    }

    const w = width orelse return error.MissingWidth;
    const h = height orelse return error.MissingHeight;

    if (w <= 0 or h <= 0) {
        return error.InvalidDimensions;
    }

    var row: usize = 0;
    while (line_iter.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t");
        if (trimmed.len == 0) continue;

        if (row >= @as(usize, @intCast(h))) break;

        for (trimmed, 0..) |ch, col| {
            if (col >= @as(usize, @intCast(w))) break;

            // const idx = row * @as(usize, @intCast(w)) + col;
            map.SetWallAt(@intCast(col), @intCast(row), (ch != '.'));
        }

        row += 1;
    }

    if (row < @as(usize, @intCast(h))) {
        return error.IncompleteMapData;
    }
}
