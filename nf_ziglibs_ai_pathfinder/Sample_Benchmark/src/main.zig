const std = @import("std");

const pf = @import("nf_ziglibs_ai_pathfinder");
const int2 = pf.int2;
const Jpsb = pf.Jpsb;

const Timer = @import("./Timer.zig");
const print = std.debug.print;

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const cwd_path = try std.process.currentPathAlloc(io, allocator);
    defer allocator.free(cwd_path);

    const base_path_sc1 = try std.fs.path.join(allocator, &.{ cwd_path, "../../", "__MAP/sc1" });
    defer allocator.free(base_path_sc1);

    const scene_filenames = [_][]const u8{
        "AcrosstheCape.map.scen",
        "Aftershock.map.scen",
        "Archipelago.map.scen",
        "ArcticStation.map.scen",
        "Aurora.map.scen",
        "Backwoods.map.scen",
        "BigGameHunters.map.scen",
        "BlackLotus.map.scen",
        "BlastFurnace.map.scen",
        "BrokenSteppes.map.scen",
        "Brushfire.map.scen",
        "Caldera.map.scen",
        "CatwalkAlley.map.scen",
        "Cauldron.map.scen",
        "CrashSites.map.scen",
        "CrescentMoon.map.scen",
        "Crossroads.map.scen",
        "DarkContinent.map.scen",
        "Desolation.map.scen",
        "EbonLakes.map.scen",
        "Elderlands.map.scen",
        "Enigma.map.scen",
        "Entanglement.map.scen",
        "Eruption.map.scen",
        "Expedition.map.scen",
        "FireWalker.map.scen",
        "FloodedPlains.map.scen",
        "GhostTown.map.scen",
        "GladiatorPits.map.scen",
        "GreenerPastures.map.scen",
        "Hellfire.map.scen",
        "HotZone.map.scen",
        "IceFloes.map.scen",
        "IceMountain.map.scen",
        "Inferno.map.scen",
        "Isolation.map.scen",
        "JungleSiege.map.scen",
        "Labyrinth.map.scen",
        "LakeShore.map.scen",
        "Legacy.map.scen",
        "Medusa.map.scen",
        "Nightshade.map.scen",
        "NovaStation.map.scen",
        "Octopus.map.scen",
        "OrbitalGully.map.scen",
        "Predators.map.scen",
        "PrimevalIsles.map.scen",
        "Ramparts.map.scen",
        "RedCanyons.map.scen",
        "RiverLethe.map.scen",
        "Rosewood.map.scen",
        "Sanctuary.map.scen",
        "Sandstorm.map.scen",
        "SapphireIsles.map.scen",
        "ShroudPlatform.map.scen",
        "Sirocco.map.scen",
        "SpaceAtoll.map.scen",
        "SpaceDebris.map.scen",
        "SpringThaw.map.scen",
        "SteppingStones.map.scen",
        "TaleofTwoCities.map.scen",
        "TheatreofWar.map.scen",
        "TheFrozenSea.map.scen",
        "TheHighway.map.scen",
        "ThinIce.map.scen",
        "Tribes.map.scen",
        "Triskelion.map.scen",
        "Turbo.map.scen",
        "Typhoon.map.scen",
        "ValleyofRe.map.scen",
        "WarpGates.map.scen",
        "WatersEdge.map.scen",
        "WaypointJunction.map.scen",
        "WheelofWar.map.scen",
        "WinterConquest.map.scen",
    };

    const names: [4][]const u8 = .{
        "astar  ",
        "jps    ",
        "jps+   ",
        "jps(B) ",
    };

    var resultNodesArr: [4]std.ArrayList(int2) = .{ .empty, .empty, .empty, .empty };
    defer {
        for (0..resultNodesArr.len) |i| {
            resultNodesArr[i].deinit(allocator);
        }
    }

    var searchers: [4]pf.ISearcher = .{ undefined, undefined, undefined, undefined };

    var times: [4]i64 = .{ 1, 1, 1, 1 };

    for (scene_filenames[0..3]) |scene_filename| {
        const scene_path = try std.fs.path.join(allocator, &.{ base_path_sc1, scene_filename });
        defer allocator.free(scene_path);

        var scenario = try pf.Loader.Loader_Scenario.LoadScenario(allocator, io, scene_path);
        defer scenario.Deinit(allocator);

        const fst = scenario.experiments.items[0];
        const joined = try std.fs.path.join(allocator, &.{ base_path_sc1, fst.mapfile_path });
        defer allocator.free(joined);

        var map_jpsb = try Jpsb.JpsbMap.Init(allocator, fst.width, fst.height);
        defer map_jpsb.Deinit(allocator);

        var map_bool = try pf.Common.Map_bool.Init(allocator, fst.width, fst.height);
        defer map_bool.Deinit(allocator);

        try pf.Loader.Loader_BenchmarkMap.LoadMapFromBenchmarkMapFile(allocator, io, map_jpsb.ToIMap(), joined);
        try pf.Loader.Loader_BenchmarkMap.LoadMapFromBenchmarkMapFile(allocator, io, map_bool.ToIMap(), joined);

        var searcher_astar = try pf.Searcher.Searcher_Astar.Init(allocator, &map_bool);
        defer searcher_astar.Deinit(allocator);

        var searcher_jpsb = try pf.Searcher.Searcher_Jpsb.Init(allocator, &map_jpsb);
        defer searcher_jpsb.Deinit(allocator);

        var searcher_jps = try pf.Searcher.Searcher_Jps.Init(allocator, &map_bool);
        defer searcher_jps.Deinit(allocator);
        
        var baker: pf.Jpsplus.JpsplusMapBaker = .empty;
        defer baker.Deinit(allocator);

        var bakedmap: pf.Jpsplus.JpsplusBakedMap = .empty;
        try baker.Bake(allocator, &map_bool, &bakedmap);
        defer bakedmap.Deinit(allocator);

        var searcher_jpsplus = try pf.Searcher.Searcher_Jpsplus.Init(allocator, &bakedmap);
        defer searcher_jpsplus.Deinit(allocator);

        searchers[0] = searcher_astar.ToISearcher();
        searchers[1] = searcher_jps.ToISearcher();
        searchers[2] = searcher_jpsplus.ToISearcher();
        searchers[3] = searcher_jpsb.ToISearcher();

        std.debug.print("{s} {}x{} {}\n", .{ fst.mapfile_path, fst.width, fst.height, scenario.experiments.items.len });

        for (1..2) |i| {
            const name = names[i];
            var timer = Timer.Init(name, init.io);
            timer.Start();
            for (scenario.experiments.items, 0..) |experiment, idx| {
                const sx: i32 = experiment.start_x;
                const sy: i32 = experiment.start_y;
                const ex: i32 = experiment.goal_x;
                const ey: i32 = experiment.goal_y;
                const isSuccess = try searchers[i].Search(allocator, sx, sy, ex, ey, &resultNodesArr[i]);
                if (!isSuccess) {
                    std.log.err("{f}", .{experiment});
                    std.log.err("WTF!!! name:{s} idx:{} \n", .{ name, idx });
                }
            }
            const elapsed_ms = timer.Stop();
            times[i] = elapsed_ms;
        }

        std.debug.print("------------------------------------\n", .{});
//        const base_time: f64 = @floatFromInt(times[0]);
//        for (0..4) |i| {
//            const name = names[i];
//            const ftime: f64 = @floatFromInt(times[i]);
//            const multiplier = base_time / ftime;
//            std.debug.print("{s} | {d:.2}\n", .{ name, multiplier });
//        }
//
        std.debug.print("==============================================================================\n", .{});
    }
}

pub fn main2(init: std.process.Init) !void {
    const allocator = init.gpa;

    var map = try pf.Jpsb.JpsbMap.Init(allocator, 100, 100);
    defer map.Deinit(allocator);

    var imap = map.ToIMap();
    imap.LoadFromCollisionsStr("1,2,3");

    var searcher = try pf.Searcher.Searcher_Jpsb.Init(allocator, &map);

    var pathBuffer = std.ArrayList(int2).empty;
    defer pathBuffer.deinit(allocator);

    const isSuccess = try searcher.Search(allocator, 0, 0, 99, 99, &pathBuffer);
    std.debug.assert(isSuccess);
}
