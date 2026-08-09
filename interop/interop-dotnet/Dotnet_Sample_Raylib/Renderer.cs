using NF.Dotnetlibs.AI.Pathfinder;
using Raylib_cs;
using System.Numerics;

internal class Renderer
{
    static readonly Color COLOR_LINE = Color.Yellow;

    private Handler _handler;
    private Camera2D _camera;
    private Material _material;
    private float _tileSize;

    public Renderer(Handler handler, float tileSize)
    {
        _handler = handler;
        Vector2 dpi_scale = Raylib.GetWindowScaleDPI();
        _camera.Zoom = dpi_scale.X;
        
        _material = Raylib.LoadMaterialDefault();
        _tileSize = tileSize;
    }

    internal void Render()
    {
        Raylib.BeginMode2D(_camera);
        Raylib.DrawMesh(_handler._mesh, _material, Matrix4x4.Identity);
        Raylib.EndMode2D();
        RenderLine(_handler._resultNodes);
    }

    private void RenderLine(List<int2> resultNodes)
    {
        if (resultNodes.Count < 2)
        {
            return;
        }

        Vector2 a;
        Vector2 b;
        for (int i = 0; i < resultNodes.Count - 1; ++i)
        {
            var p1 = resultNodes[i];
            var p2 = resultNodes[i + 1];
            a.X = p1.x * _tileSize + _tileSize / 2;
            a.Y = p1.y * _tileSize + _tileSize / 2;
            b.X = p2.x * _tileSize + _tileSize / 2;
            b.Y = p2.y * _tileSize + _tileSize / 2;
            Raylib.DrawLineEx(a, b, 2, COLOR_LINE);
        }
    }
}