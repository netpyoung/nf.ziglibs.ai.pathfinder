namespace NF.Dotnetlibs.AI.Pathfinder;

public static class Pathlib
{


    public static HandleJpsbMap? GetMap_Jpsb(int width, int height, out E_ERRORCODE outErr)
    {
        return HandleJpsbMap.GetMap_Jpsb(width, height, out outErr);
    }

    public static HandlePathfinderJpsb? GetPathfinder_Jpsb(HandleJpsbMap map, out E_ERRORCODE outErr)
    {
        return HandlePathfinderJpsb.GetPathfinder_Jpsb(map, out outErr);
    }


    public static DebugAllocatorGuard UsingDebugAllocatorGuard()
    {
        return new DebugAllocatorGuard();
    }

    public sealed class DebugAllocatorGuard : IDisposable
    {
        internal DebugAllocatorGuard()
        {
            E_ERRORCODE err = Library.pf_debug_allocator_init();
            if (err != E_ERRORCODE.NONE)
            {
                Console.Error.WriteLine($"err: {err}");
            }
        }

        public void Dispose()
        {
            E_ERRORCODE err = Library.pf_debug_allocator_deinit();
            if (err != E_ERRORCODE.NONE)
            {
                Console.Error.WriteLine($"err: {err}");
            }
        }
    }
}