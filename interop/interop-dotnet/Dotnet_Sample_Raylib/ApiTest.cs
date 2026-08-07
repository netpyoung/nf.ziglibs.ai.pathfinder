using NF.Dotnetlibs.AI.Pathfinder;

namespace Dotnet_Sample_Raylib;

internal class ApiTest
{
    public void Run()
    {
        using (Pathlib.UsingDebugAllocatorGuard())
        {
            E_ERRORCODE r;

            HandleJpsbMap? mapOrNull = Pathlib.GetMap_Jpsb(100, 100, out r);
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
                map.SetWallAt(0, 1, true);
                map.SetWallAt(1, 2, true);


                ReadOnlySpan<int2> points = pathfinder.FindPath(0, 0, 99, 99, E_SMOOTHMETHOD.NONE, out r);
                if (r != E_ERRORCODE.NONE)
                {
                    Console.Error.WriteLine($"r: {r}");
                    return;
                }
                Console.WriteLine($"points.Length={points.Length}");


                points = pathfinder.FindPath(0, 0, 99, 99, E_SMOOTHMETHOD.BRESENHAM_THICKLINE, out r);
                if (r != E_ERRORCODE.NONE)
                {
                    Console.Error.WriteLine($"r: {r}");
                    return;
                }
                Console.WriteLine($"points.Length={points.Length}");
            }
        }
    }
}
