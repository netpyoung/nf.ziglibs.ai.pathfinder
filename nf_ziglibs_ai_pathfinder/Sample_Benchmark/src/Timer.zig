const std = @import("std");

const Timer = @This();
name: []const u8,
io: std.Io,
clock: std.Io.Clock,
started: std.Io.Timestamp,

pub fn Init(name: []const u8, io: std.Io) Timer {
    return .{
        .name = name,
        .io = io,
        .clock = std.Io.Clock.awake,
        .started = .zero,
    };
}

pub fn Start(this: *Timer) void {
    this.started = this.clock.now(this.io);
}

pub fn Stop(this: *const Timer) i64 {
    const duration = this.started.untilNow(this.io, .awake);
    const elapsed_ms = duration.toMilliseconds();
    std.debug.print("{s} | elapsed_ms: {} ms\n", .{ this.name, elapsed_ms });
    return elapsed_ms;
}
