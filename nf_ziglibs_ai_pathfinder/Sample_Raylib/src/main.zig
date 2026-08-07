const std = @import("std");

const Raylib = @import("raylib");
const RaylibGui = @import("raygui");

const Timer = @import("./Timer.zig");

const pf = @import("nf_ziglibs_ai_pathfinder");
const int2 = pf.int2;

const print = std.debug.print;

const COLOR_EMPTY = Raylib.Color.light_gray;
const COLOR_WALL = Raylib.Color.init(100, 100, 100, 255);
const COLOR_CLOSED = Raylib.Color.init(200, 250, 250, 255);
const COLOR_OPENED = Raylib.Color.init(200, 250, 200, 255);
const COLOR_PATH = Raylib.Color.init(250, 200, 200, 255);
const COLOR_LINE = Raylib.Color.yellow;
const COLOR_START = Raylib.Color.green;
const COLOR_GOAL = Raylib.Color.red;

const SCREEN_WIDTH = 800;
const SCREEN_HEIGHT = 450;
const MAP_WIDTH: c_int = 20;
const MAP_HEIGHT: c_int = 20;
const TILE_SIZE: f32 = 16.0;

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;

    var jpsb_map = try pf.Jpsb.JpsbMap.Init(allocator, MAP_WIDTH, MAP_HEIGHT);
    defer jpsb_map.Deinit(allocator);

    var jpsb_searcher = try pf.Searcher.Searcher_Jpsb.Init(allocator, &jpsb_map);
    defer jpsb_searcher.Deinit(allocator);

    var resultNodes: std.ArrayList(int2) = .empty;
    defer resultNodes.deinit(allocator);

    Raylib.setConfigFlags(.{ .window_resizable = true, .window_highdpi = true });

    Raylib.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "jps(b) test");
    defer Raylib.closeWindow();

    Raylib.setTargetFPS(60);

    const map_mesh = CreateStaticTilemapMesh(MAP_WIDTH, MAP_HEIGHT, TILE_SIZE);
    defer Raylib.unloadMesh(map_mesh);

    var handler = Handler.Init(
        &jpsb_searcher,
        &jpsb_map,
        &resultNodes,
        map_mesh,
        TILE_SIZE,
        int2.Init(0, 0),
        int2.Init(MAP_WIDTH - 1, MAP_HEIGHT - 1),
    );
    handler.FillRandomMap();
    try handler.DoSearch(allocator, init.io);

    const renderer = try Renderer.Init(&handler);

    var isBtnSearchPressed = false;
    while (!Raylib.windowShouldClose()) {
        if (isBtnSearchPressed) {
            try handler.DoSearch(allocator, init.io);
        }

        handler.handleInput();

        {
            Raylib.beginDrawing();

            Raylib.clearBackground(.black);

            {
                renderer.Render();
            }

            Raylib.drawFPS(10, 10);
            isBtnSearchPressed = RaylibGui.button(.{ .x = SCREEN_WIDTH / 2 - 50, .y = 10, .width = 100, .height = 30 }, "Search");
            //            RaylibGui.dropdownBox

            Raylib.endDrawing();
        }
    }
}

// ================================================================

fn CreateStaticTilemapMesh(map_width: i32, map_height: i32, tile_size: f32) Raylib.Mesh {
    var mesh: Raylib.Mesh = std.mem.zeroes(Raylib.Mesh);
    const total_tiles: usize = @intCast(map_width * map_height);

    mesh.vertexCount = @intCast(total_tiles * 4);
    mesh.triangleCount = @intCast(total_tiles * 2);

    const vertices_ptr = Raylib.memAlloc(@intCast(mesh.vertexCount * 3 * @sizeOf(f32)));
    mesh.vertices = @ptrCast(@alignCast(vertices_ptr));

    const colors_ptr = Raylib.memAlloc(@intCast(mesh.vertexCount * 4 * @sizeOf(u8)));
    mesh.colors = @ptrCast(@alignCast(colors_ptr));

    const indices_ptr = Raylib.memAlloc(@intCast(mesh.triangleCount * 3 * @sizeOf(u16)));
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
                mesh.colors[c_idx + 0] = 200; // R
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

    Raylib.uploadMesh(&mesh, true);
    return mesh;
}

inline fn UpdateMeshColor(mesh: *Raylib.Mesh) void {
    Raylib.updateMeshBuffer(
        mesh.*,
        3,
        mesh.colors,
        @intCast(mesh.vertexCount * 4 * @sizeOf(u8)),
        0,
    );
}

// ================================================================

const Renderer = struct {
    camera: Raylib.Camera2D,
    handler: *Handler,
    material: Raylib.Material,

    pub fn Init(handler: *Handler) !Renderer {
        var camera: Raylib.Camera2D = std.mem.zeroes(Raylib.Camera2D);
        camera.zoom = 1.0;
        const default_material = try Raylib.loadMaterialDefault();
        return .{
            .camera = camera,
            .material = default_material,
            .handler = handler,
        };
    }

    pub fn Render(this: *const Renderer) void {
        Raylib.beginMode2D(this.camera);
        Raylib.drawMesh(this.handler.mesh, this.material, Raylib.Matrix.identity());
        Raylib.endMode2D();
        RenderLine(this.handler.resultNodes);
    }

    fn RenderLine(path: *const std.ArrayList(int2)) void {
        if (path.items.len < 2) {
            return;
        }

        const items = path.items;
        var a: Raylib.Vector2 = undefined;
        var b: Raylib.Vector2 = undefined;
        for (items[0 .. items.len - 1], items[1..]) |p1, p2| {
            a.x = @as(f32, @floatFromInt(p1.x)) * TILE_SIZE + TILE_SIZE / 2;
            a.y = @as(f32, @floatFromInt(p1.y)) * TILE_SIZE + TILE_SIZE / 2;
            b.x = @as(f32, @floatFromInt(p2.x)) * TILE_SIZE + TILE_SIZE / 2;
            b.y = @as(f32, @floatFromInt(p2.y)) * TILE_SIZE + TILE_SIZE / 2;
            Raylib.drawLineEx(a, b, 2, COLOR_LINE);
        }
    }
};

fn SetMeshTileColor(mesh: *Raylib.Mesh, tile_x: i32, tile_y: i32, color: Raylib.Color) void {
    if (tile_x < 0 or MAP_WIDTH <= tile_x) {
        return;
    }
    if (tile_y < 0 or MAP_HEIGHT <= tile_y) {
        return;
    }

    const tile_index: usize = @intCast(tile_y * MAP_WIDTH + tile_x);
    const color_offset = tile_index * 16;
    var i: usize = 0;
    while (i < 4) : (i += 1) {
        mesh.colors[color_offset + i * 4 + 0] = color.r;
        mesh.colors[color_offset + i * 4 + 1] = color.g;
        mesh.colors[color_offset + i * 4 + 2] = color.b;
        mesh.colors[color_offset + i * 4 + 3] = color.a;
    }
}

// ================================================================
const Handler = struct {
    width: i32,
    height: i32,
    tile_size: f32,
    searcher: *pf.Searcher.Searcher_Jpsb,
    map: *pf.Jpsb.JpsbMap,
    resultNodes: *std.ArrayList(int2),
    mesh: Raylib.Mesh,
    camera: Raylib.Camera2D,
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

    pub fn Init(
        searcher: *pf.Searcher.Searcher_Jpsb,
        map: *pf.Jpsb.JpsbMap,
        resultNodes: *std.ArrayList(int2),
        mesh: Raylib.Mesh,
        tile_size: f32,
        start_pos: int2,
        goal_pos: int2,
    ) Handler {
        var camera: Raylib.Camera2D = std.mem.zeroes(Raylib.Camera2D);
        camera.zoom = 1.0;

        return .{
            .width = map.width,
            .height = map.height,
            .tile_size = tile_size,
            .searcher = searcher,
            .map = map,
            .resultNodes = resultNodes,
            .mesh = mesh,
            .camera = camera,
            .start_pos = start_pos,
            .goal_pos = goal_pos,
            .drag_mode = .NONE,
        };
    }

    pub fn FillRandomMap(this: *Handler) void {
        const sx = this.start_pos.x;
        const sy = this.start_pos.y;
        const ex = this.goal_pos.x;
        const ey = this.goal_pos.y;

        var prng = std.Random.DefaultPrng.init(32);
        const rand = prng.random();
        for (0..@intCast(this.map.height)) |y| {
            for (0..@intCast(this.map.width)) |x| {
                if (x == sx and y == sy) {
                    continue;
                }
                if (x == ex and y == ey) {
                    continue;
                }
                // if (@rem(rand.int(i32), 10) == 0) {
                if (@rem(rand.int(i32), 10) == 0) {
                    this.map.SetWallAt(@intCast(x), @intCast(y), true);
                }
            }
        }
    }

    pub fn DoSearch(this: *Handler, allocator: std.mem.Allocator, io: std.Io) !void {
        var timer = Timer.Init("jps(b) search", io);
        timer.Start();
        const sx = this.start_pos.x;
        const sy = this.start_pos.y;
        const gx = this.goal_pos.x;
        const gy = this.goal_pos.y;
        const isSuccess = try this.searcher.Search(allocator, sx, sy, gx, gy, this.resultNodes);
        std.log.debug("isSuccess = {}", .{isSuccess});
        _ = timer.Stop();

        std.log.debug("{}", .{this.resultNodes.items.len});

        this.RefreshMap();
    }

    fn RefreshMap(this: *Handler) void {
        PaintMap(&this.mesh, this.map);
        PaintPath(&this.mesh, this.start_pos, this.goal_pos, this.resultNodes);
        UpdateMeshColor(&this.mesh);
    }

    fn PaintPath(mesh: *Raylib.Mesh, start_pos: int2, goal_pos: int2, path: *const std.ArrayList(int2)) void {
        for (path.items) |node| {
            SetMeshTileColor(mesh, node.x, node.y, COLOR_PATH);
        }

        SetMeshTileColor(mesh, start_pos.x, start_pos.y, COLOR_START);
        SetMeshTileColor(mesh, goal_pos.x, goal_pos.y, COLOR_GOAL);
    }

    fn PaintMap(mesh: *Raylib.Mesh, map: *const pf.Jpsb.JpsbMap) void {
        for (0..@intCast(map.height)) |y| {
            for (0..@intCast(map.width)) |x| {
                if (map.IsWallAt(@intCast(x), @intCast(y))) {
                    SetMeshTileColor(mesh, @intCast(x), @intCast(y), COLOR_WALL);
                } else {
                    SetMeshTileColor(mesh, @intCast(x), @intCast(y), COLOR_EMPTY);
                }
            }
        }
    }

    pub fn handleInput(this: *Handler) void {
        const mouse_pos = Raylib.getMousePosition();
        const world_pos = Raylib.getScreenToWorld2D(mouse_pos, this.camera);

        const tile_x: i32 = @intFromFloat(world_pos.x / this.tile_size);
        const tile_y: i32 = @intFromFloat(world_pos.y / this.tile_size);

        if (tile_x < 0 or this.width <= tile_x or tile_y < 0 or this.height <= tile_y) {
            return;
        }

        if (Raylib.isMouseButtonPressed(.left)) {
            const current_tile = this._GetTileType(tile_x, tile_y);

            this.drag_mode = switch (current_tile) {
                .TILE_EMPTY => .WALL_SET,
                .TILE_WALL => .WALL_CLEAR,
                .TILE_START => .MOVE_START,
                .TILE_GOAL => .MOVE_GOAL,
            };
        } else if (Raylib.isMouseButtonDown(.left)) {
            const p = int2.Init(tile_x, tile_y);
            switch (this.drag_mode) {
                .NONE => {},
                .WALL_SET => {
                    if (p != this.start_pos and p != this.goal_pos) {
                        this.resultNodes.clearRetainingCapacity();
                        this.map.SetWallAt(p.x, p.y, true);
                        this.RefreshMap();
                    }
                },
                .WALL_CLEAR => {
                    if (p != this.start_pos and p != this.goal_pos) {
                        this.resultNodes.clearRetainingCapacity();

                        this.map.SetEmptyAt(p.x, p.y, true);
                        this.RefreshMap();
                    }
                },
                .MOVE_START => {
                    if (p != this.start_pos and p != this.goal_pos) {
                        this.resultNodes.clearRetainingCapacity();

                        this.start_pos = .Init(tile_x, tile_y);
                        this.RefreshMap();
                    }
                },
                .MOVE_GOAL => {
                    if (p != this.start_pos and p != this.goal_pos) {
                        this.resultNodes.clearRetainingCapacity();

                        this.goal_pos = .Init(tile_x, tile_y);
                        this.RefreshMap();
                    }
                },
            }
        } else if (Raylib.isMouseButtonReleased(.left)) {
            this.drag_mode = .NONE;
        }
    }

    fn _GetTileType(this: *const Handler, x: i32, y: i32) E_TILE_TYPE {
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
};
