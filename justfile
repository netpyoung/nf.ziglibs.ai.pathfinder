# https://just.systems

[private]
default:
    @just --list

[group('build')]
[working-directory: 'nf_ziglibs_ai_pathfinder/nf_ziglibs_ai_pathfinder']
build-windows:
    zig build windows -Doptimize=ReleaseFast
    mkdir -p ../../__BUILD/
    cp  -r zig-out/* ../../__BUILD/

[group('build')]
[working-directory: 'nf_ziglibs_ai_pathfinder/nf_ziglibs_ai_pathfinder']
build-linux:
    zig build linux -Doptimize=ReleaseFast
    mkdir -p ../../__BUILD/
    cp  -r zig-out/* ../../__BUILD/

[group('build')]
[working-directory: 'nf_ziglibs_ai_pathfinder/nf_ziglibs_ai_pathfinder']
build-macos:
    zig build macos -Doptimize=ReleaseFast
    mkdir -p ../../__BUILD/
    cp  -r zig-out/* ../../__BUILD/

[group('build')]
[working-directory: 'nf_ziglibs_ai_pathfinder/nf_ziglibs_ai_pathfinder']
build-all:
    zig build all -Doptimize=ReleaseFast
    mkdir -p ../../__BUILD/
    cp  -r zig-out/* ../../__BUILD/

[group('test')]
[working-directory: 'nf_ziglibs_ai_pathfinder/nf_ziglibs_ai_pathfinder']
test-zig:
    zig build test

[group('test')]
[working-directory: 'interop/interop-dotnet/Dotnet_Test']
test-dotnet:
    dotnet test

[group('test')]
test-all : test-zig test-dotnet

