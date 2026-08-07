using System.Runtime.InteropServices;

namespace NF.Dotnetlibs.AI.Pathfinder;

public abstract class AHandlePathfinder : SafeHandle
{
    protected AHandlePathfinder(IntPtr invalidHandleValue, bool ownsHandle) : base(invalidHandleValue: IntPtr.Zero, ownsHandle: true)
    {

    }

    public override bool IsInvalid => handle == IntPtr.Zero;

    private readonly int2[] _pathBuffer = new int2[1024];

    public ReadOnlySpan<int2> FindPath(int startX, int startY, int endX, int endY, E_SMOOTHMETHOD smoothMethod, out E_ERRORCODE outErr)
    {
        Span<int2> bufferSpan = _pathBuffer;

        ref int2 firstElementRef = ref MemoryMarshal.GetReference(bufferSpan);

        int pathLengthOrErr = Library.pf_pathfinder_find_path_with_smoothmethod(this, startX, startY, endX, endY, smoothMethod, ref firstElementRef, _pathBuffer.Length);
        if (pathLengthOrErr <= 0)
        {
            outErr = (E_ERRORCODE)pathLengthOrErr;
            return ReadOnlySpan<int2>.Empty;
        }

        outErr = E_ERRORCODE.NONE;
        return bufferSpan.Slice(0, pathLengthOrErr);
    }

    public int EnsureOpenlistTotalCapacity(uint capacity)
    {
        return Library.pf_pathfinder_openlist_ensuretotalcapacity(this, capacity);
    }

    public int EnsurePathbufferTotalCapacity(uint capacity)
    {
        return Library.pf_pathfinder_pathbuffer_ensuretotalcapacity(this, capacity);
    }

}
