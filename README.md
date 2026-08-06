# nf.ziglibs.ai.pathfinder



## Benchmark

- https://www.movingai.com/benchmarks/grids.html


``` log
CPU: AMD Ryzen 5700G
SSD: SHGP31-2000GM


AcrosstheCape.map 768x768 3150
astar   | elapsed_ms: 71998 ms
jps     | elapsed_ms: 11830 ms
jps+    | elapsed_ms: 9858 ms
jps(B)  | elapsed_ms: 4255 ms
------------------------------------
astar   | 1.00
jps     | 6.09
jps+    | 7.30
jps(B)  | 16.92
==============================================================================
Aftershock.map 512x512 1920
astar   | elapsed_ms: 16050 ms
jps     | elapsed_ms: 2939 ms
jps+    | elapsed_ms: 1901 ms
jps(B)  | elapsed_ms: 731 ms
------------------------------------
astar   | 1.00
jps     | 5.46
jps+    | 8.44
jps(B)  | 21.96
==============================================================================
Archipelago.map 512x512 2310
astar   | elapsed_ms: 16871 ms
jps     | elapsed_ms: 2857 ms
jps+    | elapsed_ms: 1900 ms
jps(B)  | elapsed_ms: 865 ms
------------------------------------
astar   | 1.00
jps     | 5.91
jps+    | 8.88
jps(B)  | 19.50

...

==============================================================================
Sanctuary.map 512x512 2240
astar   | elapsed_ms: 18349 ms
jps     | elapsed_ms: 2614 ms
jps+    | elapsed_ms: 1502 ms
jps(B)  | elapsed_ms: 562 ms
------------------------------------
astar   | 1.00
jps     | 7.02
jps+    | 12.22
jps(B)  | 32.65
```