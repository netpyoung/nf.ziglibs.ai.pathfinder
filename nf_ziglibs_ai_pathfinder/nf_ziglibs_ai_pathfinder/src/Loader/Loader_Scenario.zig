const std = @import("std");

pub fn LoadScenario(allocator: std.mem.Allocator, io: std.Io, file_path: []const u8) !Scenario {
    const contents = try std.Io.Dir.readFileAlloc(std.Io.Dir.cwd(), io, file_path, allocator, .unlimited);
    defer allocator.free(contents);

    var ret: Scenario = undefined;

    var content_line_iter = std.mem.tokenizeAny(u8, contents, "\r\n");
    {
        const header_line = content_line_iter.next().?;

        var header_iter = std.mem.tokenizeAny(u8, header_line, " \t\r");
        if (!std.mem.eql(u8, header_iter.next().?, "version")) {
            return error.InvalidFormat;
        }

        ret.version = try std.fmt.parseFloat(f32, header_iter.next().?);
    }

    {
        ret.experiments = .empty;
        while (content_line_iter.next()) |experiment_line| {
            const experiment = try ParseExperiment(allocator, experiment_line);
            try ret.experiments.append(allocator, experiment);
        }
    }

    return ret;
}

fn ParseExperiment(allocator: std.mem.Allocator, line: []const u8) !Scenario.Experiment {
    var iter = std.mem.tokenizeAny(u8, line, " \t\r");

    const bucket = try std.fmt.parseInt(i32, iter.next() orelse return error.InvalidFormat, 10);
    const mapfile_path = try allocator.dupe(u8, iter.next() orelse return error.InvalidFormat);
    const width = try std.fmt.parseInt(i32, iter.next() orelse return error.InvalidFormat, 10);
    const height = try std.fmt.parseInt(i32, iter.next() orelse return error.InvalidFormat, 10);
    const start_x = try std.fmt.parseInt(i32, iter.next() orelse return error.InvalidFormat, 10);
    const start_y = try std.fmt.parseInt(i32, iter.next() orelse return error.InvalidFormat, 10);
    const goal_x = try std.fmt.parseInt(i32, iter.next() orelse return error.InvalidFormat, 10);
    const goal_y = try std.fmt.parseInt(i32, iter.next() orelse return error.InvalidFormat, 10);
    const dist = try std.fmt.parseFloat(f32, iter.next() orelse return error.InvalidFormat);

    return .{
        .bucket = bucket,
        .mapfile_path = mapfile_path,
        .width = width,
        .height = height,
        .start_x = start_x,
        .start_y = start_y,
        .goal_x = goal_x,
        .goal_y = goal_y,
        .dist = dist,
    };
}

pub const Scenario = struct {
    version: f32,
    experiments: std.ArrayList(Experiment),

    pub const Experiment = struct {
        bucket: i32,
        mapfile_path: []const u8,
        width: i32,
        height: i32,
        start_x: i32,
        start_y: i32,
        goal_x: i32,
        goal_y: i32,
        dist: f32,

        pub fn format(this: Experiment, writer: *std.Io.Writer) std.Io.Writer.Error!void {
            try writer.print("{} {s} {} {} {} {} {} {} {}", .{
                this.bucket,
                this.mapfile_path,
                this.width,
                this.height,
                this.start_x,
                this.start_y,
                this.goal_x,
                this.goal_y,
                this.dist,
            });
        }
    };

    const This = @This();

    pub fn Deinit(this: *This, allocator: std.mem.Allocator) void {
        for (this.experiments.items) |item| {
            allocator.free(item.mapfile_path);
        }
        this.experiments.deinit(allocator);
    }

    pub fn format(this: This, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        try writer.print("version {}\n", .{this.version});
        for (this.experiments.items) |item| {
            try writer.print("{f}\n", .{item});
        }
    }
};
