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

[group('macos')]
postprocess-apple:
    #!/usr/bin/env bash
    set -euo pipefail
    
    # macOs - rename .dylib => .bundle
    DIR_BUILD_MACOS="__BUILD/macos_aarch64"
    cp -r "${DIR_BUILD_MACOS}/libnf_ziglibs_ai_pathfinder.dylib" "${DIR_BUILD_MACOS}/nf_ziglibs_ai_pathfinder.bundle"
    otool -L "${DIR_BUILD_MACOS}/nf_ziglibs_ai_pathfinder.bundle"
    install_name_tool -id @loader_path/nf_ziglibs_ai_pathfinder.bundle "${DIR_BUILD_MACOS}/nf_ziglibs_ai_pathfinder.bundle"
    otool -L "${DIR_BUILD_MACOS}/nf_ziglibs_ai_pathfinder.bundle"

    # ios/tvos - xcframework
    DIR_BUILD="__BUILD"
    xcodebuild -create-xcframework \
      -library ${DIR_BUILD}/ios_aarch64/libnf_ziglibs_ai_pathfinder.a \
      -library ${DIR_BUILD}/ios_aarch64_simulator/libnf_ziglibs_ai_pathfinder.a \
      -library ${DIR_BUILD}/tvos_aarch64/libnf_ziglibs_ai_pathfinder.a \
      -library ${DIR_BUILD}/tvos_aarch64_simulator/libnf_ziglibs_ai_pathfinder.a \
      -output ${DIR_BUILD}/libnf_ziglibs_ai_pathfinder.xcframework
    plutil -p ${DIR_BUILD}/libnf_ziglibs_ai_pathfinder.xcframework/Info.plist