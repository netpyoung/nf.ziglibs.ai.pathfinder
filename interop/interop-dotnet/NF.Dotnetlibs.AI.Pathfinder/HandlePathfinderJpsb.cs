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

    public static HandlePathfinderJpsb Init(HandleJpsbMap handleMap)
    {
        var result = Library.pf_jpsb_pathfinder_create(handleMap, out HandlePathfinderJpsb handle);
        Console.WriteLine($"pf_jpsb_create_pathfinder={result}");
        return handle;
    }
}
