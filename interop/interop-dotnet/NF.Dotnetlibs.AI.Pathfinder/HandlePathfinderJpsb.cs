namespace NF.Dotnetlibs.AI.Pathfinder;

public sealed class HandlePathfinderJpsb : AHandlePathfinder
{
    public HandlePathfinderJpsb() : base(invalidHandleValue: IntPtr.Zero, ownsHandle: true)
    {
    }

    protected override bool ReleaseHandle()
    {
        if (!IsInvalid)
        {
            Library.pf_jpsb_pathfinder_destroy(handle);
            handle = IntPtr.Zero;
        }
        return true;
    }

    internal static HandlePathfinderJpsb? GetPathfinder_Jpsb(HandleJpsbMap handleMap, out E_ERRORCODE outErr)
    {
        E_ERRORCODE r = Library.pf_jpsb_pathfinder_create(handleMap, out HandlePathfinderJpsb outHandle);
        outErr = r;

        if (r != E_ERRORCODE.NONE)
        {
            return null;
        }

        return outHandle;
    }
}
