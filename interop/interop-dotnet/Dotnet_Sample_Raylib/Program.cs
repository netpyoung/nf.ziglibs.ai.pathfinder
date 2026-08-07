using NF.Dotnetlibs.AI.Pathfinder;
using Raylib_cs;

const int SCREEN_WIDTH = 800;
const int SCREEN_HEIGHT = 450;
const int MAP_WIDTH = 20;
const int MAP_HEIGHT = 20;
const float TILE_SIZE = 16.0f;

using (Pathlib.UsingDebugAllocatorGuard())
{
    E_ERRORCODE r;

    HandleJpsbMap? mapOrNull = Pathlib.GetMap_Jpsb(MAP_WIDTH, MAP_HEIGHT, out r);
    if (mapOrNull is not HandleJpsbMap map)
    {
        Console.Error.WriteLine($"r: {r}");
        return;
    }
    HandlePathfinderJpsb? pathfinderOrNull = Pathlib.GetPathfinder_Jpsb(map, out r);
    if (pathfinderOrNull is not HandlePathfinderJpsb pathfinder)
    {
        Console.Error.WriteLine($"r: {r}");
        return;
    }

    using (map)
    using (pathfinder)
    {
        Raylib.SetConfigFlags(ConfigFlags.ResizableWindow | ConfigFlags.HighDpiWindow);
        Raylib.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "C# interop with nf_ziglibs_ai_pathfinder  (Space to search)");
        Raylib.SetTargetFPS(60);

        Mesh mesh = CreateStaticTilemapMesh(MAP_WIDTH, MAP_HEIGHT, TILE_SIZE);

        var handler = new Handler(
            pathfinder,
            map,
            mesh,
            TILE_SIZE,
            new int2(0, 0),
            new int2(MAP_WIDTH - 1, MAP_HEIGHT - 1)
        );
        handler.FillRandomMap();
        handler.DoSearch();

        Renderer renderer = new Renderer(handler, TILE_SIZE);

        while (!Raylib.WindowShouldClose())
        {
            if (Raylib.IsKeyPressed(KeyboardKey.Space))
            {
                handler.DoSearch();
            }

            handler.HandleInput();

            Raylib.BeginDrawing();
            Raylib.ClearBackground(Color.Black);
            {
                renderer.Render();
            }

            Raylib.DrawFPS(10, 10);

            Raylib.EndDrawing();
        }

        Raylib.UnloadMesh(mesh);
        Raylib.CloseWindow();
    }
}

// ================================================================

Mesh CreateStaticTilemapMesh(int map_width, int map_height, float tile_size)
{
    Mesh mesh = new Mesh();

    int total_tiles = map_width * map_height;

    mesh.VertexCount = total_tiles * 4;
    mesh.TriangleCount = total_tiles * 2;
    unsafe
    {
        mesh.Vertices = (float*)Raylib.MemAlloc((uint)(mesh.VertexCount * 3 * sizeof(float)));
        mesh.Colors = (byte*)Raylib.MemAlloc((uint)(mesh.VertexCount * 4 * sizeof(byte)));
        mesh.Indices = (ushort*)Raylib.MemAlloc((uint)(mesh.TriangleCount * 3 * sizeof(ushort)));

        int v_idx = 0;
        int c_idx = 0;
        int i_idx = 0;

        for (int y = 0; y < map_height; ++y)
        {
            for (int x = 0; x < map_width; ++x)
            {
                float x0 = x * tile_size;
                float y0 = y * tile_size;
                float x1 = x0 + tile_size - 1.0f;
                float y1 = y0 + tile_size - 1.0f;

                mesh.Vertices[(v_idx + 0) * 3 + 0] = x0;
                mesh.Vertices[(v_idx + 0) * 3 + 1] = y0;
                mesh.Vertices[(v_idx + 0) * 3 + 2] = 0.0f;

                mesh.Vertices[(v_idx + 1) * 3 + 0] = x1;
                mesh.Vertices[(v_idx + 1) * 3 + 1] = y0;
                mesh.Vertices[(v_idx + 1) * 3 + 2] = 0.0f;

                mesh.Vertices[(v_idx + 2) * 3 + 0] = x1;
                mesh.Vertices[(v_idx + 2) * 3 + 1] = y1;
                mesh.Vertices[(v_idx + 2) * 3 + 2] = 0.0f;

                mesh.Vertices[(v_idx + 3) * 3 + 0] = x0;
                mesh.Vertices[(v_idx + 3) * 3 + 1] = y1;
                mesh.Vertices[(v_idx + 3) * 3 + 2] = 0.0f;

                for (int i = 0; i < 4; ++i)
                {
                    mesh.Colors[c_idx + 0] = 200; // R
                    mesh.Colors[c_idx + 1] = 200; // G
                    mesh.Colors[c_idx + 2] = 200; // B
                    mesh.Colors[c_idx + 3] = 255; // A
                    c_idx += 4;
                }

                int base_v = v_idx;
                mesh.Indices[i_idx + 0] = (ushort)(base_v + 0);
                mesh.Indices[i_idx + 1] = (ushort)(base_v + 2);
                mesh.Indices[i_idx + 2] = (ushort)(base_v + 1);
                mesh.Indices[i_idx + 3] = (ushort)(base_v + 0);
                mesh.Indices[i_idx + 4] = (ushort)(base_v + 3);
                mesh.Indices[i_idx + 5] = (ushort)(base_v + 2);
                v_idx += 4;
                i_idx += 6;
            }
        }
        Raylib.UploadMesh(&mesh, dynamic: true);
    }

    return mesh;
}