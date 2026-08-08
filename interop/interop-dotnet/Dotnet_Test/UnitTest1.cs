using NF.Dotnetlibs.AI.Pathfinder;

namespace Dotnet_Test;

public class UnitTest1
{
    [Fact]
    public void Test1()
    {
        E_ERRORCODE r;

        HandleJpsbMap? mapOrNull = Pathlib.GetMap_Jpsb(100, 100, out r);
        Assert.NotNull(mapOrNull);
        Assert.Equal(E_ERRORCODE.NONE, r);

        HandleJpsbMap map = mapOrNull;

        HandlePathfinderJpsb? pathfinderOrNull = Pathlib.GetPathfinder_Jpsb(map, out r);
        Assert.NotNull(pathfinderOrNull);
        Assert.Equal(E_ERRORCODE.NONE, r);

        HandlePathfinderJpsb pathfinder = pathfinderOrNull;

        using (map)
        using (pathfinder)
        {
            map.SetWallAt(0, 1, true);
            map.SetWallAt(1, 2, true);


            ReadOnlySpan<int2> points = pathfinder.FindPath(0, 0, 99, 99, E_SMOOTHMETHOD.NONE, out r);
            Assert.NotNull(pathfinderOrNull);
            Assert.Equal(E_ERRORCODE.NONE, r);


            points = pathfinder.FindPath(0, 0, 99, 99, E_SMOOTHMETHOD.BRESENHAM_THICKLINE, out r);
            Assert.NotNull(pathfinderOrNull);
            Assert.Equal(E_ERRORCODE.NONE, r);
        }
    }

    [Fact]
    public void Test2()
    {
        E_ERRORCODE r;

        HandleJpsbMap? mapOrNull = Pathlib.GetMap_Jpsb(-1, 100, out r);
        Assert.Null(mapOrNull);
        Assert.Equal(E_ERRORCODE.ERR_SEARCHER_MAP_INVALID_WIDTH_OR_HEIGHT, r);
    }

    [Fact]
    public void Test3()
    {
        E_ERRORCODE r;


        HandleJpsbMap? mapOrNull = Pathlib.GetMap_Jpsb(3, 1, out r);
        Assert.NotNull(mapOrNull);
        HandleJpsbMap map = mapOrNull;

        HandlePathfinderJpsb? pathfinderOrNull = Pathlib.GetPathfinder_Jpsb(map, out r);
        Assert.NotNull(pathfinderOrNull);
        HandlePathfinderJpsb pathfinder = pathfinderOrNull;

        using (map)
        using (pathfinder)
        {
            int sx = 0;
            int sy = 0;
            int gx = 2;
            int gy = 0;

            ReadOnlySpan<int2> points;

            // # # # # #
            // # s . g #
            // # # # # #
            points = pathfinder.FindPath(sx, sy, gx, gy, E_SMOOTHMETHOD.NONE, out r);
            Assert.NotNull(pathfinderOrNull);
            Assert.Equal(E_ERRORCODE.NONE, r);

            // % % % % %
            // % # . g %
            // % % % % %
            map.SetWallAt(sx, sy, true);
            points = pathfinder.FindPath(sx, sy, gx, gy, E_SMOOTHMETHOD.NONE, out r);
            Assert.NotNull(pathfinderOrNull);
            Assert.Equal(E_ERRORCODE.ERR_SEARCHER_IS_WALL_ON_START, r);

            // % % % % %
            // % s . # %
            // % % % % %
            map.SetWallAt(sx, sy, false);
            map.SetWallAt(gx, gy, true);
            points = pathfinder.FindPath(sx, sy, gx, gy, E_SMOOTHMETHOD.NONE, out r);
            Assert.NotNull(pathfinderOrNull);
            Assert.Equal(E_ERRORCODE.ERR_SEARCHER_IS_WALL_ON_GOAL, r);

            // % % % % %
            // % s # g %
            // % % % % %
            map.SetWallAt(gx, gy, false);
            map.SetWallAt(1, 0, true);
            points = pathfinder.FindPath(sx, sy, gx, gy, E_SMOOTHMETHOD.NONE, out r);
            Assert.NotNull(pathfinderOrNull);
            Assert.Equal(E_ERRORCODE.ERR_SEARCHER_UNREACHABLE_GOAL, r);
        }
    }
}
