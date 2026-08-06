const std = @import("std");
const rl = @import("raylib");

const pf = @import("nf_ziglibs_ai_pathfinder");

const print = std.debug.print;

pub fn main2() !void {
    var a: i32 = 10;
    a -= 20;

    a += 40;
    print("hello, world\n", .{});

    print("{}\n", .{pf.add(1, 2)});
}

pub fn main() !void {
    const screenWidth = 800;
    const screenHeight = 450;

    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - basic window");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);

        rl.drawText("Congrats! You created your first window!", 190, 200, 20, .light_gray);
    }
}
