namespace NF.Dotnetlibs.AI.Pathfinder;

public static class Pathlib
{
    public static HandleJpsbMap CreateMap_Jpsb(int width, int height)
    {
        return HandleJpsbMap.Init(width, height);
    }

    public static HandlePathfinderJpsb CreatePathfinder_Jpsb(HandleJpsbMap map)
    {
        return HandlePathfinderJpsb.Init(map);
    }

    public static DebugAllocatorGuard UsingDebugAllocatorGuard()
    {
        return new DebugAllocatorGuard();
    }

    public sealed class DebugAllocatorGuard : IDisposable
    {
        internal DebugAllocatorGuard()
        {
            Library.pf_debug_allocator_init();
        }

        public void Dispose()
        {
            Library.pf_debug_allocator_deinit();
        }
    }

}