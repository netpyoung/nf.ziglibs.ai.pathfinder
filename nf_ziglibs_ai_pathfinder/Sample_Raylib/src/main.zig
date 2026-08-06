const std = @import("std");
const rl = @import("raylib");
const gui = @import("raygui");

const Timer = @import("./Timer.zig");

const pf = @import("nf_ziglibs_ai_pathfinder");
const int2 = pf.int2;
const IMap = pf.IMap;

const print = std.debug.print;

const COLOR_EMPTY = rl.Color.light_gray;
const COLOR_WALL = rl.Color.init(100, 100, 100, 255);
const COLOR_CLOSED = rl.Color.init(200, 250, 250, 255);
const COLOR_OPENED = rl.Color.init(200, 250, 200, 255);
const COLOR_PATH = rl.Color.init(250, 200, 200, 255);
const COLOR_LINE = rl.Color.yellow;
const COLOR_START = rl.Color.green;
const COLOR_GOAL = rl.Color.red;

const MAP_WIDTH: c_int = 20;
const MAP_HEIGHT: c_int = 20;
const TILE_SIZE: f32 = 16.0;

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;

    const screenWidth = 800;
    const screenHeight = 450;

    rl.setConfigFlags(.{ .window_resizable = true, .window_highdpi = true });

    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - basic window");
    defer rl.closeWindow();

    const default_material = try rl.loadMaterialDefault();

    var map_mesh = createStaticTilemapMesh(MAP_WIDTH, MAP_HEIGHT, TILE_SIZE);
    defer rl.unloadMesh(map_mesh);

    var camera: rl.Camera2D = std.mem.zeroes(rl.Camera2D);
    camera.zoom = 1.0;

    rl.setTargetFPS(60);

    var map = try pf.Jpsb.JpsbMap.Init(allocator, MAP_WIDTH, MAP_HEIGHT);
    defer map.Deinit(allocator);
    var handler: MapHandler = undefined;
    {
        var sx: i32 = 0;
        var sy: i32 = 0;
        var gx: i32 = 0;
        var gy: i32 = 0;

        sx = 0;
        sy = 0;
        gx = map.width - 2;
        gy = map.height - 2;

        //    map.SetWallAt(1, 1, true);
        //    map.SetWallAt(1, 2, true);
        FillMap(map.ToIMap(), sx, sy, gx, gy);
        handler = MapHandler.Init(map.ToIMap(), TILE_SIZE, sx, sy, gx, gy);
    }

    var searcher_jpsb = try pf.Searcher.Searcher_Jpsb.Init(allocator, &map);
    defer searcher_jpsb.Deinit(allocator);
    var searcher = searcher_jpsb.ToISearcher();
    var resultNodes: std.ArrayList(int2) = .empty;
    defer resultNodes.deinit(allocator);

    {
        const sx = handler.start_pos.x;
        const sy = handler.start_pos.y;
        const gx = handler.goal_pos.x;
        const gy = handler.goal_pos.y;

        var timer = Timer.Init("hello", init.io);
        timer.Start();
        const isSuccess = try searcher.Search(allocator, sx, sy, gx, gy, &resultNodes);
        std.debug.assert(isSuccess);
        _ = timer.Stop();

        std.log.debug("{}", .{resultNodes.items.len});

        RenderMap(&map_mesh, map.ToIMap());
        RenderPath(&map_mesh, &resultNodes);
        UpdateMeshColor(&map_mesh);
    }

    var isSearchPressed = false;
    while (!rl.windowShouldClose()) {
        if (isSearchPressed) {
            var timer = Timer.Init("hello", init.io);
            timer.Start();
            const sx = handler.start_pos.x;
            const sy = handler.start_pos.y;
            const gx = handler.goal_pos.x;
            const gy = handler.goal_pos.y;
            const isSuccess = try searcher.Search(allocator, sx, sy, gx, gy, &resultNodes);
            std.log.debug("isSuccess = {}", .{isSuccess});
            _ = timer.Stop();

            std.log.debug("{}", .{resultNodes.items.len});
            RenderMap(&map_mesh, map.ToIMap());
            RenderPath(&map_mesh, &resultNodes);
            UpdateMeshColor(&map_mesh);
        }

        //        if (rl.isMouseButtonDown(rl.MouseButton.left)) {
        //            const world_pos = rl.getScreenToWorld2D(rl.getMousePosition(), camera);
        //            const tile_x: i32 = @intFromFloat(world_pos.x / TILE_SIZE);
        //            const tile_y: i32 = @intFromFloat(world_pos.y / TILE_SIZE);
        //
        //            setTileColor(&map_mesh, tile_x, tile_y, .green);
        // UpdateMeshColor(&map_mesh);
        //        }

        handler.handleInput(camera, &map_mesh);

        {
            rl.beginDrawing();

            rl.clearBackground(.black);

            {
                rl.beginMode2D(camera);
                rl.drawMesh(map_mesh, default_material, rl.Matrix.identity());
                rl.endMode2D();
            }

            RenderLine(&resultNodes);

            rl.drawFPS(10, 10);
            isSearchPressed = gui.button(.{ .x = screenWidth / 2 - 50, .y = 10, .width = 100, .height = 50 }, "asdf");

            rl.endDrawing();
        }
    }
}

fn RenderPath(mesh: *rl.Mesh, path: *const std.ArrayList(int2)) void {
    for (path.items, 0..) |node, i| {
        std.log.debug("{}", .{node});

        if (i == 0) {
            setTileColor(mesh, node.x, node.y, COLOR_START);
        } else if (i == path.items.len - 1) {
            setTileColor(mesh, node.x, node.y, COLOR_GOAL);
        } else {
            setTileColor(mesh, node.x, node.y, COLOR_PATH);
        }
    }
}

fn RenderMap(mesh: *rl.Mesh, map: IMap) void {
    for (0..@intCast(map.GetHeight())) |y| {
        for (0..@intCast(map.GetWidth())) |x| {
            if (map.IsWallAt(@intCast(x), @intCast(y))) {
                setTileColor(mesh, @intCast(x), @intCast(y), COLOR_WALL);
            } else {
                setTileColor(mesh, @intCast(x), @intCast(y), COLOR_EMPTY);
            }
        }
    }
}

fn RenderLine(path: *const std.ArrayList(int2)) void {
    if (path.items.len < 2) {
        return;
    }

    const items = path.items;
    var a: rl.Vector2 = undefined;
    var b: rl.Vector2 = undefined;
    for (items[0 .. items.len - 1], items[1..]) |p1, p2| {
        a.x = @as(f32, @floatFromInt(p1.x)) * TILE_SIZE + TILE_SIZE / 2;
        a.y = @as(f32, @floatFromInt(p1.y)) * TILE_SIZE + TILE_SIZE / 2;
        b.x = @as(f32, @floatFromInt(p2.x)) * TILE_SIZE + TILE_SIZE / 2;
        b.y = @as(f32, @floatFromInt(p2.y)) * TILE_SIZE + TILE_SIZE / 2;
        rl.drawLineEx(a, b, 2, COLOR_LINE);
    }
}

fn FillMap(map: IMap, sx: i32, sy: i32, ex: i32, ey: i32) void {
    var prng = std.Random.DefaultPrng.init(32);
    const rand = prng.random();
    for (0..@intCast(map.GetHeight())) |y| {
        for (0..@intCast(map.GetWidth())) |x| {
            if (x == sx and y == sy) {
                continue;
            }
            if (x == ex and y == ey) {
                continue;
            }
            // if (@rem(rand.int(i32), 10) == 0) {
            if (@rem(rand.int(i32), 10) == 0) {
                map.SetWallAt(@intCast(x), @intCast(y), true);
            }
        }
    }
}

fn createStaticTilemapMesh(map_width: i32, map_height: i32, tile_size: f32) rl.Mesh {
    var mesh: rl.Mesh = std.mem.zeroes(rl.Mesh);
    const total_tiles: usize = @intCast(map_width * map_height);

    mesh.vertexCount = @intCast(total_tiles * 4);
    mesh.triangleCount = @intCast(total_tiles * 2);

    const vertices_ptr = rl.memAlloc(@intCast(mesh.vertexCount * 3 * @sizeOf(f32)));
    mesh.vertices = @ptrCast(@alignCast(vertices_ptr));

    const colors_ptr = rl.memAlloc(@intCast(mesh.vertexCount * 4 * @sizeOf(u8)));
    mesh.colors = @ptrCast(@alignCast(colors_ptr));

    const indices_ptr = rl.memAlloc(@intCast(mesh.triangleCount * 3 * @sizeOf(u16)));
    mesh.indices = @ptrCast(@alignCast(indices_ptr));

    var v_idx: usize = 0;
    var c_idx: usize = 0;
    var i_idx: usize = 0;

    var y: i32 = 0;
    while (y < map_height) : (y += 1) {
        var x: i32 = 0;
        while (x < map_width) : (x += 1) {
            const x0 = @as(f32, @floatFromInt(x)) * tile_size;
            const y0 = @as(f32, @floatFromInt(y)) * tile_size;
            const x1 = x0 + tile_size - 1.0;
            const y1 = y0 + tile_size - 1.0;

            mesh.vertices[v_idx * 3 + 0] = x0;
            mesh.vertices[v_idx * 3 + 1] = y0;
            mesh.vertices[v_idx * 3 + 2] = 0.0;

            mesh.vertices[(v_idx + 1) * 3 + 0] = x1;
            mesh.vertices[(v_idx + 1) * 3 + 1] = y0;
            mesh.vertices[(v_idx + 1) * 3 + 2] = 0.0;

            mesh.vertices[(v_idx + 2) * 3 + 0] = x1;
            mesh.vertices[(v_idx + 2) * 3 + 1] = y1;
            mesh.vertices[(v_idx + 2) * 3 + 2] = 0.0;

            mesh.vertices[(v_idx + 3) * 3 + 0] = x0;
            mesh.vertices[(v_idx + 3) * 3 + 1] = y1;
            mesh.vertices[(v_idx + 3) * 3 + 2] = 0.0;

            for (0..4) |_| {
                mesh.colors[c_idx] = 200; // R
                mesh.colors[c_idx + 1] = 200; // G
                mesh.colors[c_idx + 2] = 200; // B
                mesh.colors[c_idx + 3] = 255; // A
                c_idx += 4;
            }

            const base_v: u16 = @intCast(v_idx);
            mesh.indices[i_idx + 0] = base_v + 0;
            mesh.indices[i_idx + 1] = base_v + 2;
            mesh.indices[i_idx + 2] = base_v + 1;
            mesh.indices[i_idx + 3] = base_v + 0;
            mesh.indices[i_idx + 4] = base_v + 3;
            mesh.indices[i_idx + 5] = base_v + 2;
            v_idx += 4;
            i_idx += 6;
        }
    }

    rl.uploadMesh(&mesh, true);
    return mesh;
}

fn setTileColor(mesh: *rl.Mesh, tile_x: i32, tile_y: i32, new_color: rl.Color) void {
    if (tile_x < 0 or tile_x >= MAP_WIDTH or tile_y < 0 or tile_y >= MAP_HEIGHT) return;

    const tile_index: usize = @intCast(tile_y * MAP_WIDTH + tile_x);
    const color_offset = tile_index * 16;
    var i: usize = 0;
    while (i < 4) : (i += 1) {
        mesh.colors[color_offset + i * 4 + 0] = new_color.r;
        mesh.colors[color_offset + i * 4 + 1] = new_color.g;
        mesh.colors[color_offset + i * 4 + 2] = new_color.b;
        mesh.colors[color_offset + i * 4 + 3] = new_color.a;
    }
}

inline fn UpdateMeshColor(mesh: *rl.Mesh) void {
    rl.updateMeshBuffer(
        mesh.*,
        3,
        mesh.colors,
        @intCast(mesh.vertexCount * 4 * @sizeOf(u8)),
        0,
    );
}

const MapHandler = struct {
    width: i32,
    height: i32,
    tile_size: f32,
    map: IMap,
    start_pos: int2,
    goal_pos: int2,
    drag_mode: E_DRAG_MODE,

    const E_TILE_TYPE = enum {
        TILE_EMPTY,
        TILE_WALL,
        TILE_START,
        TILE_GOAL,
    };

    const E_DRAG_MODE = enum {
        NONE,
        WALL_SET,
        WALL_CLEAR,
        MOVE_START,
        MOVE_GOAL,
    };

    pub fn Init(map: IMap, tile_size: f32, sx: i32, sy: i32, gx: i32, gy: i32) MapHandler {
        return .{
            .width = map.GetWidth(),
            .height = map.GetHeight(),
            .tile_size = tile_size,
            .map = map,
            .start_pos = int2.Init(sx, sy),
            .goal_pos = int2.Init(gx, gy),
            .drag_mode = .NONE,
        };
    }

    pub fn handleInput(this: *MapHandler, camera: rl.Camera2D, mesh: *rl.Mesh) void {
        const mouse_pos = rl.getMousePosition();
        const world_pos = rl.getScreenToWorld2D(mouse_pos, camera);

        const tile_x: i32 = @intFromFloat(world_pos.x / this.tile_size);
        const tile_y: i32 = @intFromFloat(world_pos.y / this.tile_size);

        if (tile_x < 0 or this.width <= tile_x or tile_y < 0 or this.height <= tile_y) {
            return;
        }

        if (rl.isMouseButtonPressed(.left)) {
            const current_tile = this.getTileType(tile_x, tile_y);

            this.drag_mode = switch (current_tile) {
                .TILE_EMPTY => .WALL_SET,
                .TILE_WALL => .WALL_CLEAR,
                .TILE_START => .MOVE_START,
                .TILE_GOAL => .MOVE_GOAL,
            };
        } else if (rl.isMouseButtonDown(.left)) {
            switch (this.drag_mode) {
                .NONE => {},
                .WALL_SET => {
                    if (!this.isStartOrGoal(tile_x, tile_y)) {
                        this.setTileAndColor(mesh, tile_x, tile_y, .TILE_WALL, COLOR_WALL);
                    }
                },
                .WALL_CLEAR => {
                    if (!this.isStartOrGoal(tile_x, tile_y)) {
                        this.setTileAndColor(mesh, tile_x, tile_y, .TILE_EMPTY, COLOR_EMPTY);
                    }
                },
                .MOVE_START => {
                    if (!this.isGoal(tile_x, tile_y) and (tile_x != this.start_pos.x or tile_y != this.start_pos.y)) {
                        this.setTileAndColor(mesh, this.start_pos.x, this.start_pos.y, .TILE_EMPTY, COLOR_EMPTY);

                        this.start_pos = .Init(tile_x, tile_y);
                        this.setTileAndColor(mesh, tile_x, tile_y, .TILE_START, COLOR_START);
                    }
                },
                .MOVE_GOAL => {
                    if (!this.isStart(tile_x, tile_y) and (tile_x != this.goal_pos.x or tile_y != this.goal_pos.y)) {
                        this.setTileAndColor(mesh, this.goal_pos.x, this.goal_pos.y, .TILE_EMPTY, COLOR_EMPTY);

                        this.goal_pos = .Init(tile_x, tile_y);
                        this.setTileAndColor(mesh, tile_x, tile_y, .TILE_GOAL, COLOR_GOAL);
                    }
                },
            }
        } else if (rl.isMouseButtonReleased(.left)) {
            this.drag_mode = .NONE;
        }

        UpdateMeshColor(mesh);
    }

    fn isStart(this: *const MapHandler, x: i32, y: i32) bool {
        const p = int2.Init(x, y);
        return p == this.start_pos;
    }

    fn isGoal(this: *const MapHandler, x: i32, y: i32) bool {
        const p = int2.Init(x, y);
        return p == this.goal_pos;
    }

    fn isStartOrGoal(this: *const MapHandler, x: i32, y: i32) bool {
        return this.isStart(x, y) or this.isGoal(x, y);
    }

    fn getTileType(this: *const MapHandler, x: i32, y: i32) E_TILE_TYPE {
        const p = int2.Init(x, y);
        if (p == this.start_pos) {
            return .TILE_START;
        }

        if (p == this.goal_pos) {
            return .TILE_GOAL;
        }

        if (this.map.IsWallAt(x, y)) {
            return .TILE_WALL;
        } else {
            return .TILE_EMPTY;
        }

        unreachable;
    }

    fn setTileAndColor(this: *MapHandler, mesh: *rl.Mesh, x: i32, y: i32, tile_type: E_TILE_TYPE, color: rl.Color) void {
        switch (tile_type) {
            .TILE_EMPTY => {
                this.map.SetEmptyAt(x, y, true);
            },
            .TILE_WALL => {
                this.map.SetWallAt(x, y, true);
            },
            .TILE_START => {
                this.start_pos = int2.Init(x, y);
            },
            .TILE_GOAL => {
                this.goal_pos = int2.Init(x, y);
            },
        }
        setTileColor(mesh, x, y, color);
    }
};
