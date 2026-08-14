using System.Runtime.InteropServices;

namespace NF.Dotnetlibs.AI.Pathfinder;

[StructLayout(LayoutKind.Sequential)]
public struct int2 : IEquatable<int2>
{
    public int x;
    public int y;

    public int2() { }
    public int2(int x, int y)
    {
        this.x = x;
        this.y = y;
    }
    public static bool operator ==(int2 left, int2 right)
    {
        return left.x == right.x && left.y == right.y;
    }

    public static bool operator !=(int2 left, int2 right)
    {
        return !(left == right);
    }

    public bool Equals(int2 other)
    {
        return x == other.x && y == other.y;
    }

    public override bool Equals(object? obj)
    {
        return obj is int2 other && Equals(other);
    }

    public override int GetHashCode()
    {
        return HashCode.Combine(x, y);
    }
}

public enum E_SMOOTHMETHOD : int
{
    NONE = 0,
    BRESENHAM_THICKLINE = 1,
    BRESENHAM_THINLINE = 2,
};

public enum E_ERRORCODE : int
{
    NONE = 0,
    ERR_ALLOCATOR_FAIL_TO_ALLOCATE = -1000, // errors.AllocatorError.OutOfMemory
    ERR_PRIORITY_QUEUE_INTERNAL_QUEUE_ERROR = -2000, // errors.PriorityQueueError.NodeNotFound

    ERR_SEARCHER_MAP_INVALID_WIDTH_OR_HEIGHT = -3000, // errors.SearcherError.ERR_INVALID_MAP_DATA
    ERR_SEARCHER_IS_WALL_ON_START = -3001, // errors.SearcherError.ERR_IS_WALL_ON_START
    ERR_SEARCHER_IS_WALL_ON_GOAL = -3002, // errors.SearcherError.ERR_IS_WALL_ON_GOAL
    ERR_SEARCHER_OUT_OF_BOUND_START = -3003, // errors.SearcherError.ERR_OUT_OF_BOUND_START
    ERR_SEARCHER_OUT_OF_BOUND_GOAL = -3004, // errors.SearcherError.ERR_OUT_OF_BOUND_GOAL
    ERR_SEARCHER_SAME_POSITION_START_AND_GOAL = -3005, // errors.SearcherError.ERR_SAME_POSITION_START_AND_GOAL
    ERR_SEARCHER_UNREACHABLE_GOAL = -3006, // errors.SearcherError.ERR_UNREACHABLE_GOAL

    ERR_DEBUGGER_ALLOCATOR_ALREADY_ENABLED = -4100,
    ERR_DEBUGGER_ALLOCATOR_NEED_TO_INIT = -4101,
    ERR_DEBUGGER_ALLOCATOR_DETECT_LEAK = -4103,

    ERR_PATHFINDER_INVALID_PTR_PATHFINDER = -4200,
    ERR_PATHFINDER_INVALID_PTR_OUTBUF = -4201,
    ERR_PATHFINDER_INVALID_PTR_MAP = -4202,
    ERR_PATHFINDER_FAIL_TO_SEARCH = -4203,
    ERR_PATHFINDER_NOT_ENOUGH_OUTBUF_SIZE = -4204,
};

public static partial class Library
{
#if UNITY_EDITOR
    const string DLL_NAME = "nf_ziglibs_ai_pathfinder";
#elif UNITY_STANDALONE
    const string DLL_NAME = "nf_ziglibs_ai_pathfinder";
#elif UNITY_WSA // define directive for Universal Windows Platform.
	const string DLL_NAME = "nf_ziglibs_ai_pathfinder";
#elif UNITY_ANDROID
	const string DLL_NAME = "nf_ziglibs_ai_pathfinder";
#elif UNITY_IOS
	const string DLL_NAME = "__Internal";
#elif UNITY_WEBGL
    const string DLL_NAME = "__Internal";
#else
    const string DLLNAME = "nf_ziglibs_ai_pathfinder";
#endif

    // =========================================
    // pf_debug_allocator_
    // =========================================

    [LibraryImport(DLLNAME)]
    // NOTE(pyoung): Omitted UnmanagedCallConv as it is only relevant on x86.
    // ref: https://learn.microsoft.com/en-us/dotnet/standard/native-interop/calling-conventions
    // [UnmanagedCallConv(CallConvs = new[] { typeof(CallConvCdecl) })]
    public static partial E_ERRORCODE pf_debug_allocator_init();

    [LibraryImport(DLLNAME)]
    public static partial E_ERRORCODE pf_debug_allocator_deinit();

    // =========================================
    // pf_jpsb_map_
    // =========================================
    [LibraryImport(DLLNAME)]
    public static partial E_ERRORCODE pf_jpsb_map_create(int width, int height, out HandleJpsbMap outHandleMap);

    [LibraryImport(DLLNAME)]
    public static partial E_ERRORCODE pf_jpsb_map_destroy(IntPtr ptr);

    [LibraryImport(DLLNAME)]
    public static partial void pf_jpsb_map_set_wall_at(HandleJpsbMap handleMap, int x, int y, [MarshalAs(UnmanagedType.U1)] bool isWall);

    [LibraryImport(DLLNAME)]
    public static partial void pf_jpsb_map_set_empty_at(HandleJpsbMap handleMap, int x, int y, [MarshalAs(UnmanagedType.U1)] bool isEmpty);

    [LibraryImport(DLLNAME)]
    [return: MarshalAs(UnmanagedType.U1)]
    public static partial bool pf_jpsb_map_is_wall_at(HandleJpsbMap handleMap, int x, int y);

    [LibraryImport(DLLNAME)]
    [return: MarshalAs(UnmanagedType.U1)]
    public static partial bool pf_jpsb_map_is_empty_at(HandleJpsbMap handleMap, int x, int y);

    [LibraryImport(DLLNAME)]
    public static partial int pf_jpsb_map_get_width(HandleJpsbMap handleMap);
    [LibraryImport(DLLNAME)]
    public static partial int pf_jpsb_map_get_height(HandleJpsbMap handleMap);


    // =========================================
    // pf_jpsb_pathfinder_
    // =========================================
    [LibraryImport(DLLNAME)]
    public static partial E_ERRORCODE pf_jpsb_pathfinder_create(HandleJpsbMap handleMap, out HandlePathfinderJpsb outHandlePathfinder);

    [LibraryImport(DLLNAME)]
    public static partial E_ERRORCODE pf_jpsb_pathfinder_destroy(IntPtr ptr);


    // =========================================
    // pf_pathfinder_
    // =========================================
    [LibraryImport(DLLNAME)]
    public static partial int pf_pathfinder_find_path_with_smoothmethod(AHandlePathfinder handlePathfinder, int startX, int startY, int endX, int endY, E_SMOOTHMETHOD smoothMethod, ref int2 outPathBuf, int maxBufLen);

    [LibraryImport(DLLNAME)]
    public static partial int pf_pathfinder_openlist_ensuretotalcapacity(AHandlePathfinder handlePathfinder, uint capacity);

    [LibraryImport(DLLNAME)]
    public static partial int pf_pathfinder_pathbuffer_ensuretotalcapacity(AHandlePathfinder handlePathfinder, uint capacity);

    // [LibraryImport("native_lib", CallingConvention = CallingConvention.Cdecl)]
    // private static partial void print_user_name([MarshalAs(UnmanagedType.LPUTF8Str)] string name);
    //    [LibraryImport(DLLNAME, StringMarshalling = StringMarshalling.Utf8)]
    //    private static partial void print_user_name(string name);
}
