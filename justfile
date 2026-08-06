# https://just.systems

default:
    echo 'Hello, world!'

[working-directory: 'nf_ziglibs_ai_pathfinder/nf_ziglibs_ai_pathfinder']
build-windows:
    zig build -Doptimize=ReleaseFast -Ddynamic -Dtarget=x86_64-windows-msvc
    mkdir -p ../../__BUILD/windows
    cp  zig-out/bin/nf_ziglibs_ai_pathfinder.dll ../../__BUILD/windows/

[working-directory: 'nf_ziglibs_ai_pathfinder/nf_ziglibs_ai_pathfinder']
build-wasm:
    # zig build -Doptimize=ReleaseFast -Dtarget=wasm32-freestanding -freference-trace=16
    zig build -Doptimize=ReleaseFast -Dtarget=wasm32-freestanding
    mkdir -p ../../__BUILD/wasm
    cp  zig-out/lib/libnf_ziglibs_ai_pathfinder.a ../../__BUILD/wasm/


[working-directory: 'nf_ziglibs_ai_pathfinder/nf_ziglibs_ai_pathfinder']
build-android:
    zig build -Doptimize=ReleaseFast  -Ddynamic -Dtarget=aarch64-linux-android
    mkdir -p ../../__BUILD/android/
    cp  zig-out/lib/libnf_ziglibs_ai_pathfinder.so ../../__BUILD/android/


[working-directory: 'nf_ziglibs_ai_pathfinder/nf_ziglibs_ai_pathfinder']
build-ios:
    zig build -Doptimize=ReleaseFast -Dtarget=aarch64-ios
    mkdir -p ../../__BUILD/iOs/
    cp  zig-out/lib/libnf_ziglibs_ai_pathfinder.a ../../__BUILD/iOs/

[working-directory: 'nf_ziglibs_ai_pathfinder/nf_ziglibs_ai_pathfinder']
build-linux:
    zig build -Doptimize=ReleaseFast -Ddynamic -Dtarget=x86_64-linux
    mkdir -p ../../__BUILD/linux/
    zig-out/lib/libnf_ziglibs_ai_pathfinder.so ../../__BUILD/linux/

[working-directory: 'nf_ziglibs_ai_pathfinder/nf_ziglibs_ai_pathfinder']
build-mac:
    zig build -Doptimize=ReleaseFast -Ddynamic -Dtarget=native-macos
    mkdir -p ../../__BUILD/macOs/
    cp  zig-out/lib/libnf_ziglibs_ai_pathfinder.dylib ../../__BUILD/macOs/







build-lib: build-windows


[working-directory: 'nf_ziglibs_ai_pathfinder/nf_ziglibs_ai_pathfinder']
test-zig:
    zig build test

[working-directory: 'interop/interop-dotnet/Dotnet_Test']
test-dotnet:
    dotnet test

test-all : test-zig test-dotnet

