using NF.Dotnetlibs.AI.Pathfinder;

Console.WriteLine("Hello, World!");

//using (Pathlib.UsingDebugAllocatorGuard())
{
    //    var map = Pathlib.CreateMap_Jpsb(100, 100);
    using (var map = Pathlib.CreateMap_Jpsb(100, 100))
    {
        map.SetWallAt(1, 1, true);
        map.SetWallAt(1, 2, true);

        var pathfinder = Pathlib.CreatePathfinder_Jpsb(map);
        //        using (var pathfinder = Pathlib.CreatePathfinder_Jpsb(map))
        {
            //            Console.WriteLine(pathfinder.EnsurePathbufferTotalCapacity(10));
            //        Console.WriteLine(pathfinder.EnsureOpenlistTotalCapacity(10));
            //

            var points = pathfinder.FindPath(0, 0, 99, 99, E_SMOOTHMETHOD.NONE);
            Console.WriteLine($"points.Length={points.Length}");


            points = pathfinder.FindPath(0, 0, 99, 99, E_SMOOTHMETHOD.BRESENHAM_THICKLINE);
            Console.WriteLine($"points.Length={points.Length}");
        }
    }
}