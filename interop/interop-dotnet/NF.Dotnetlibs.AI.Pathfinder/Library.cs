using System.Runtime.InteropServices;

namespace NF.Dotnetlibs.AI.Pathfinder;

[StructLayout(LayoutKind.Sequential)]
public struct int2
{
    public int x;
    public int y;
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

    INVALID_OUTPUT_PTR = -1,
    FAIL_TO_ALLOCATE = -2,

    DEBUGGER_ALLOCATOR_ALREADY_ENABLED = -100,
    DEBUGGER_ALLOCATOR_NEED_TO_INIT = -101,
    DEBUGGER_ALLOCATOR_DETECT_LEAK = -103,

    ERR_PATHFINDER_INVALID_PATHFINDER_PTR = -1000,
    ERR_PATHFINDER_INVALID_OUTBUF_PTR = -1001,
    ERR_PATHFINDER_FAIL_TO_SEARCH = -1002,
    ERR_PATHFINDER_NOT_ENOUGH_OUTBUF_SIZE = -1003,
};

public static class Library
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

    [DllImport(DLLNAME, CallingConvention = CallingConvention.Cdecl)]
    public static extern E_ERRORCODE pf_debug_allocator_init();

    [DllImport(DLLNAME, CallingConvention = CallingConvention.Cdecl)]
    public static extern E_ERRORCODE pf_debug_allocator_deinit();

    // =========================================
    // pf_jpsb_map_
    // =========================================
    [DllImport(DLLNAME, CallingConvention = CallingConvention.Cdecl)]
    public static extern E_ERRORCODE pf_jpsb_map_create(int width, int height, out HandleJpsbMap outHandleMap);

    [DllImport(DLLNAME, CallingConvention = CallingConvention.Cdecl)]
    public static extern E_ERRORCODE pf_jpsb_map_destroy(IntPtr ptr);

    [DllImport(DLLNAME, CallingConvention = CallingConvention.Cdecl)]
    public static extern void pf_jpsb_map_set_wall_at(HandleJpsbMap handleMap, int x, int y, bool isWall);

    [DllImport(DLLNAME, CallingConvention = CallingConvention.Cdecl)]
    public static extern void pf_jpsb_map_set_empty_at(HandleJpsbMap handleMap, int x, int y, bool isEmpty);


    // =========================================
    // pf_jpsb_pathfinder_
    // =========================================
    [DllImport(DLLNAME, CallingConvention = CallingConvention.Cdecl)]
    public static extern E_ERRORCODE pf_jpsb_pathfinder_create(HandleJpsbMap handleMap, out HandlePathfinderJpsb outHandlePathfinder);

    [DllImport(DLLNAME, CallingConvention = CallingConvention.Cdecl)]
    public static extern E_ERRORCODE pf_jpsb_pathfinder_destroy(IntPtr ptr);


    // =========================================
    // pf_pathfinder_
    // =========================================
    [DllImport(DLLNAME, CallingConvention = CallingConvention.Cdecl)]
    public static extern int pf_pathfinder_find_path_with_smoothmethod(AHandlePathfinder handlePathfinder, int startX, int startY, int endX, int endY, E_SMOOTHMETHOD smoothMethod, ref int2 outPathBuf, int maxBufLen);

    [DllImport(DLLNAME, CallingConvention = CallingConvention.Cdecl)]
    public static extern int pf_pathfinder_openlist_ensuretotalcapacity(AHandlePathfinder handlePathfinder, uint capacity);

    [DllImport(DLLNAME, CallingConvention = CallingConvention.Cdecl)]
    public static extern int pf_pathfinder_pathbuffer_ensuretotalcapacity(AHandlePathfinder handlePathfinder, uint capacity);

    // [DllImport("native_lib", CallingConvention = CallingConvention.Cdecl)]
    // private static extern void print_user_name([MarshalAs(UnmanagedType.LPUTF8Str)] string name);
}
