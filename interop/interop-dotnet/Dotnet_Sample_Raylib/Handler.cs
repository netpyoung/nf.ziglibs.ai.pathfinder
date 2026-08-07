using NF.Dotnetlibs.AI.Pathfinder;
using Raylib_cs;

internal class Handler
{
    private HandlePathfinderJpsb _pathfinder;
    private HandleJpsbMap _map;
    internal Mesh _mesh;
    private float _tileSize;
    private int2 _start_pos;
    private int2 _goal_pos;
    private int _height;
    private int _width;
    internal List<int2> _resultNodes = new List<int2>(100);
    Camera2D _camera;
    E_DRAG_MODE _drag_mode = E_DRAG_MODE.NONE;

    static readonly Color COLOR_EMPTY = Color.LightGray;
    static readonly Color COLOR_WALL = new Color(100, 100, 100, 255);
    static readonly Color COLOR_CLOSED = new Color(200, 250, 250, 255);
    static readonly Color COLOR_OPENED = new Color(200, 250, 200, 255);
    static readonly Color COLOR_PATH = new Color(250, 200, 200, 255);
    static readonly Color COLOR_LINE = Color.Yellow;
    static readonly Color COLOR_START = Color.Green;
    static readonly Color COLOR_GOAL = Color.Red;

    enum E_TILE_TYPE
    {
        TILE_EMPTY,
        TILE_WALL,
        TILE_START,
        TILE_GOAL,
    };

    enum E_DRAG_MODE
    {
        NONE,
        WALL_SET,
        WALL_CLEAR,
        MOVE_START,
        MOVE_GOAL,
    };

    public Handler(HandlePathfinderJpsb pathfinder, HandleJpsbMap map, Mesh mesh, float tileSize, int2 start_pos, int2 goal_pos)
    {
        _pathfinder = pathfinder;
        _map = map;
        _mesh = mesh;
        _tileSize = tileSize;
        _start_pos = start_pos;
        _goal_pos = goal_pos;
        _width = map.GetWidth();
        _height = map.GetHeight();
        _camera.Zoom = 1.0f;
    }

    internal void DoSearch()
    {
        int sx = _start_pos.x;
        int sy = _start_pos.y;
        int gx = _goal_pos.x;
        int gy = _goal_pos.y;

        ReadOnlySpan<int2> points = _pathfinder.FindPath(sx, sy, gx, gy, E_SMOOTHMETHOD.NONE, out E_ERRORCODE r);
        if (r != E_ERRORCODE.NONE)
        {
            Console.Error.WriteLine($"r: {r}");
            return;
        }
        Console.WriteLine($"points.Length={points.Length}");
        _resultNodes.Clear();
        _resultNodes.AddRange(points);
        _RefreshMap();
    }

    private void _RefreshMap()
    {
        PaintMap(_mesh, _map);
        PaintPath(_mesh, _start_pos, _goal_pos, _resultNodes);
        UpdateMeshColor(_mesh);
    }

    private void PaintMap(Mesh mesh, HandleJpsbMap map)
    {
        int height = _map.GetHeight();
        int width = _map.GetWidth();
        for (int y = 0; y < height; ++y)
        {
            for (int x = 0; x < height; ++x)
            {
                if (map.IsWallAt(x, y))
                {
                    SetMeshTileColor(mesh, x, y, COLOR_WALL);
                }
                else
                {
                    SetMeshTileColor(mesh, x, y, COLOR_EMPTY);
                }
            }
        }
    }

    private void PaintPath(Mesh mesh, int2 start_pos, int2 goal_pos, List<int2> resultNodes)
    {
        foreach (var p in resultNodes)
        {
            SetMeshTileColor(mesh, p.x, p.y, COLOR_PATH);
        }

        SetMeshTileColor(mesh, start_pos.x, start_pos.y, COLOR_START);
        SetMeshTileColor(mesh, goal_pos.x, goal_pos.y, COLOR_GOAL);
    }

    private void UpdateMeshColor(Mesh mesh)
    {
        unsafe
        {
            Raylib.UpdateMeshBuffer(mesh, 3, mesh.Colors, mesh.VertexCount * 4 * sizeof(byte), 0);
        }
    }

    void SetMeshTileColor(Mesh mesh, int tile_x, int tile_y, Color color)
    {

        if (tile_x < 0 || _width <= tile_x)
        {
            return;
        }
        if (tile_y < 0 || _height <= tile_y)
        {
            return;
        }

        unsafe
        {
            int tile_index = tile_y * _width + tile_x;
            int color_offset = tile_index * 16;
            for (int i = 0; i < 4; ++i)
            {
                mesh.Colors[color_offset + i * 4 + 0] = color.R;
                mesh.Colors[color_offset + i * 4 + 1] = color.G;
                mesh.Colors[color_offset + i * 4 + 2] = color.B;
                mesh.Colors[color_offset + i * 4 + 3] = color.A;
            }
        }
    }

    internal void FillRandomMap()
    {
        Random seededInstance = new Random(42);

        int sx = _start_pos.x;
        int sy = _start_pos.y;
        int ex = _goal_pos.x;
        int ey = _goal_pos.y;

        for (int y = 0; y < _height; ++y)
        {
            for (int x = 0; x < _width; ++x)
            {
                if (x == sx && y == sy)
                {
                    continue;
                }
                if (x == ex && y == ey)
                {
                    continue;
                }
                if (seededInstance.Next(0, 10) == 0)
                {
                    _map.SetWallAt(x, y, true);
                }
            }
        }
    }

    internal void HandleInput()
    {
        var mouse_pos = Raylib.GetMousePosition();
        var world_pos = Raylib.GetScreenToWorld2D(mouse_pos, _camera);

        int tile_x = (int)(world_pos.X / _tileSize);
        int tile_y = (int)(world_pos.Y / _tileSize);

        if (tile_x < 0 || _width <= tile_x)
        {
            return;
        }
        if (tile_y < 0 || _height <= tile_y)
        {
            return;
        }

        if (Raylib.IsMouseButtonPressed(MouseButton.Left))
        {
            _drag_mode = _GetDragMode(tile_x, tile_y);

        }
        else if (Raylib.IsMouseButtonDown(MouseButton.Left))
        {
            var p = new int2(tile_x, tile_y);
            switch (_drag_mode)
            {
                case E_DRAG_MODE.NONE: break;
                case E_DRAG_MODE.WALL_SET:
                    {
                        if (p != _start_pos && p != _goal_pos)
                        {
                            _resultNodes.Clear();
                            _map.SetWallAt(p.x, p.y, true);
                            _RefreshMap();
                        }
                        break;
                    }
                case E_DRAG_MODE.WALL_CLEAR:
                    {
                        if (p != _start_pos && p != _goal_pos)
                        {
                            _resultNodes.Clear();

                            _map.SetEmptyAt(p.x, p.y, true);
                            _RefreshMap();
                        }
                        break;
                    }
                case E_DRAG_MODE.MOVE_START:
                    {
                        if (p != _start_pos && p != _goal_pos)
                        {
                            _resultNodes.Clear();

                            _start_pos = new int2(tile_x, tile_y);
                            _RefreshMap();
                        }
                        break;
                    }
                case E_DRAG_MODE.MOVE_GOAL:
                    {
                        if (p != _start_pos && p != _goal_pos)
                        {
                            _resultNodes.Clear();

                            _goal_pos = new int2(tile_x, tile_y);
                            _RefreshMap();
                        }
                        break;
                    }
            }
        }
        else if (Raylib.IsMouseButtonReleased(MouseButton.Left))
        {
            _drag_mode = E_DRAG_MODE.NONE;
        }
    }

    E_DRAG_MODE _GetDragMode(int x, int y)
    {
        var p = new int2(x, y);
        if (p == _start_pos)
        {
            return E_DRAG_MODE.MOVE_START;
        }

        if (p == _goal_pos)
        {
            return E_DRAG_MODE.MOVE_GOAL;
        }

        if (_map.IsWallAt(x, y))
        {
            return E_DRAG_MODE.WALL_CLEAR;
        }
        else
        {
            return E_DRAG_MODE.WALL_SET;
        }
    }
}