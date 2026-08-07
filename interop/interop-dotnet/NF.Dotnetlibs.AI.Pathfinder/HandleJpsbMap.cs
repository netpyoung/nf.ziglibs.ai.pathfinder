using System.Runtime.InteropServices;

namespace NF.Dotnetlibs.AI.Pathfinder;

public sealed class HandleJpsbMap : SafeHandle, IMap
{
    public HandleJpsbMap() : base(invalidHandleValue: IntPtr.Zero, ownsHandle: true)
    {
    }

    public override bool IsInvalid => handle == IntPtr.Zero;

    protected override bool ReleaseHandle()
    {
        if (!IsInvalid)
        {
            Library.pf_jpsb_map_destroy(handle);
            handle = IntPtr.Zero;
        }
        return true;
    }

    internal static HandleJpsbMap? GetMap_Jpsb(int width, int height, out E_ERRORCODE outErr)
    {
        E_ERRORCODE r = Library.pf_jpsb_map_create(width, height, out HandleJpsbMap handle);
        outErr = r;

        if (r != E_ERRORCODE.NONE)
        {
            return null;
        }

        return handle;
    }

    public void SetWallAt(int x, int y, bool isWall)
    {
        Library.pf_jpsb_map_set_wall_at(this, x, y, isWall);
    }

    public void SetEmptyAt(int x, int y, bool isEmpty)
    {
        Library.pf_jpsb_map_set_empty_at(this, x, y, isEmpty);
    }
}
