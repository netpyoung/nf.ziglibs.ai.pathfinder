const std = @import("std");

pub const int2 = @import("./Common/int2.zig").int2;
pub const Pathfinder_Jpsb = @import("./Pathfinder_Jpsb.zig");

pub const IMap = @import("IMap.zig");
pub const ISearcher = @import("ISearcher.zig");

pub const Jpsb = struct {
    pub const JpsbMap = @import("./Jpsb/JpsbMap.zig");
};

pub const Jpsplus = struct {
    pub const JpsplusMapBaker = @import("./Jpsplus/JpsplusMapBaker.zig");
    pub const JpsplusBakedMap = @import("./Jpsplus/JpsplusBakedMap.zig");
};

pub const Searcher = struct {
    pub const Searcher_Astar = @import("./Astar/Searcher_Astar.zig");
    pub const Searcher_Jps = @import("./Jps/Searcher_Jps.zig");
    pub const Searcher_Jpsb = @import("./Jpsb/Searcher_Jpsb.zig");
    pub const Searcher_Jpsplus = @import("./Jpsplus/Searcher_Jpsplus.zig");
};

pub const Common = struct {
    pub const Map_bool = @import("./Common/SimpleMap.zig").Map_bool;
    pub const BresenhamPathSmoother = @import("./Common/BresenhamPathSmoother.zig").BresenhamPathSmoother;
    pub const BresenhamPathSmoother_WithoutAlloc = @import("./Common/BresenhamPathSmoother.zig").BresenhamPathSmoother_WithoutAlloc;
};

pub const Loader = struct {
    pub const Loader_Scenario = @import("./Loader/Loader_Scenario.zig");
    pub const Loader_BenchmarkMap = @import("./Loader/Loader_BenchmarkMap.zig");
};

pub const exports = @import("./exports.zig");

pub const E_SMOOTHMETHOD = exports.E_SMOOTHMETHOD;

test {
    _ = @import("./Common/PriorityQueue.zig");
    _ = @import("./Common/E_DIR.zig");

    std.testing.refAllDecls(@This());
}
