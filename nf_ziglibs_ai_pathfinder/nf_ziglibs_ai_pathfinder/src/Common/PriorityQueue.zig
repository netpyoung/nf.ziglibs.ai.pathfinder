const std = @import("std");
const Order = std.math.Order;

pub fn IndexedHeap_Binary(
    comptime T: type,
    comptime Context: type,
    comptime compareFn: fn (context: Context, a: T, b: T) Order,
    comptime getHeapIndexRefFn: fn (node: T) *u32,
) type {
    return struct {
        const Self = @This();
        _arraylist: std.ArrayList(T),
        context: Context,

        pub const INVALID_INDEX: u32 = std.math.maxInt(u32);

        pub const empty = Self{
            ._arraylist = .empty,
            .context = undefined,
        };

        pub fn Deinit(this: *Self, allocator: std.mem.Allocator) void {
            this._arraylist.deinit(allocator);
        }

        pub fn EnsureTotalCapacity(this: *Self, allocator: std.mem.Allocator, capacity: u32) !void {
            try this._arraylist.ensureTotalCapacity(allocator, capacity);
        }

        pub fn Push(this: *Self, allocator: std.mem.Allocator, node: T) !void {
            const heapIndex: u32 = @intCast(this._arraylist.items.len);
            try this._arraylist.append(allocator, node);
            getHeapIndexRefFn(node).* = heapIndex;
            this._SiftUp(this._arraylist.items.len - 1);
        }

        pub fn PopOrNull(this: *Self) ?T {
            if (this._arraylist.items.len == 0) {
                return null;
            }

            const result = this._arraylist.items[0];
            getHeapIndexRefFn(result).* = INVALID_INDEX;

            const last = this._arraylist.pop().?;

            if (this._arraylist.items.len > 0) {
                this._arraylist.items[0] = last;
                getHeapIndexRefFn(last).* = 0;

                this._SiftDown(0);
            }
            return result;
        }

        pub fn Clear(this: *Self) void {
            for (this._arraylist.items) |node| {
                getHeapIndexRefFn(node).* = INVALID_INDEX;
            }
            this._arraylist.clearRetainingCapacity();
        }

        pub fn TryDecreaseKey(this: *Self, node: T) !void {
            const heapIndex = getHeapIndexRefFn(node).*;

            if (heapIndex == INVALID_INDEX or heapIndex >= this._arraylist.items.len) {
                return error.NodeNotFound;
            }

            this._SiftUp(@intCast(heapIndex));
        }

        fn _SiftUp(this: *Self, start_index: usize) void {
            const items = this._arraylist.items;

            var idx = start_index;
            while (idx > 0) {
                const parent = (idx - 1) / 2;

                if (compareFn(this.context, items[idx], items[parent]) != .lt) {
                    break;
                }

                this._Swap(items[idx], items[parent]);

                idx = parent;
            }
        }

        fn _SiftDown(this: *Self, parent_idx: usize) void {
            var parent = parent_idx;
            const items = this._arraylist.items;
            const cbSize = items.len;

            while (true) {
                var left = parent * 2 + 1;
                if (left >= cbSize) {
                    break;
                }

                const right = left + 1;

                if (right < cbSize and compareFn(this.context, items[right], items[left]) == .lt) {
                    left = right;
                }

                if (compareFn(this.context, items[parent], items[left]) != .gt) {
                    break;
                }

                this._Swap(items[parent], items[left]);
                parent = left;
            }
        }

        inline fn _Swap(this: *Self, a: T, b: T) void {
            const ref_a = getHeapIndexRefFn(a);
            const ref_b = getHeapIndexRefFn(b);
            const idx_a = ref_a.*;
            const idx_b = ref_b.*;

            const items = this._arraylist.items;

            items[idx_a] = b;
            items[idx_b] = a;

            ref_a.* = idx_b;
            ref_b.* = idx_a;
        }
    };
}

pub fn IndexedHeap_4ary(
    comptime T: type,
    comptime Context: type,
    comptime compareFn: fn (context: Context, a: T, b: T) Order,
    comptime getHeapIndexRefFn: fn (node: T) *u32,
) type {
    return struct {
        const Self = @This();
        _arraylist: std.ArrayList(T),
        context: Context,

        pub const INVALID_INDEX: u32 = std.math.maxInt(u32);

        pub const empty = Self{
            ._arraylist = .empty,
            .context = undefined,
        };

        pub fn Init(context: Context) Self {
            return Self{
                ._arraylist = .empty,
                .context = context,
            };
        }

        pub fn Deinit(this: *Self, allocator: std.mem.Allocator) void {
            this._arraylist.deinit(allocator);
        }

        pub fn EnsureTotalCapacity(this: *Self, allocator: std.mem.Allocator, capacity: u32) !void {
            try this._arraylist.ensureTotalCapacity(allocator, capacity);
        }

        pub fn Push(this: *Self, allocator: std.mem.Allocator, node: T) !void {
            const heapIndex: u32 = @intCast(this._arraylist.items.len);
            try this._arraylist.append(allocator, node);
            getHeapIndexRefFn(node).* = heapIndex;
            this._SiftUp(this._arraylist.items.len - 1);
        }

        pub fn PopOrNull(this: *Self) ?T {
            if (this._arraylist.items.len == 0) {
                return null;
            }

            const result = this._arraylist.items[0];
            getHeapIndexRefFn(result).* = INVALID_INDEX;

            const last = this._arraylist.pop().?;

            if (this._arraylist.items.len > 0) {
                this._arraylist.items[0] = last;
                getHeapIndexRefFn(last).* = 0;

                this._SiftDown(0);
            }
            return result;
        }

        pub fn Clear(this: *Self) void {
            for (this._arraylist.items) |node| {
                getHeapIndexRefFn(node).* = INVALID_INDEX;
            }

            this._arraylist.clearRetainingCapacity();
        }

        pub fn TryDecreaseKey(this: *Self, node: T) !void {
            const heapIndex = getHeapIndexRefFn(node).*;

            if (heapIndex == INVALID_INDEX or heapIndex >= this._arraylist.items.len) {
                return error.NodeNotFound;
            }

            this._SiftUp(@intCast(heapIndex));
        }

        fn _SiftUp(this: *Self, start_index: usize) void {
            const items = this._arraylist.items;

            var idx = start_index;
            while (idx > 0) {
                const parent = (idx - 1) >> 2;

                if (compareFn(this.context, items[idx], items[parent]) != .lt) {
                    break;
                }

                this._Swap(items[idx], items[parent]);
                idx = parent;
            }
        }

        fn _SiftDown(this: *Self, parent_idx: usize) void {
            const items = this._arraylist.items;
            const len = items.len;

            var parent = parent_idx;
            while (true) {
                const first_child = (parent << 2) + 1;
                if (first_child >= len) {
                    break;
                }

                var smallest_child = first_child;
                const last_child = @min(first_child + 4, len);

                var child = first_child + 1;
                while (child < last_child) : (child += 1) {
                    if (compareFn(this.context, items[child], items[smallest_child]) == .lt) {
                        smallest_child = child;
                    }
                }

                if (compareFn(this.context, items[parent], items[smallest_child]) != .gt) {
                    break;
                }

                this._Swap(items[parent], items[smallest_child]);
                parent = smallest_child;
            }
        }

        inline fn _Swap(this: *Self, a: T, b: T) void {
            const ref_a = getHeapIndexRefFn(a);
            const ref_b = getHeapIndexRefFn(b);
            const idx_a = ref_a.*;
            const idx_b = ref_b.*;

            const items = this._arraylist.items;

            items[idx_a] = b;
            items[idx_b] = a;

            ref_a.* = idx_b;
            ref_b.* = idx_a;
        }
    };
}

test "sample queue" {
    const Node = struct {
        const Self = @This();
        val: u32,
        Priority: u32,
        heapIndex: u32,

        pub const empty: Self = .{};

        pub fn GetHeapIndexRef(x: *Self) *u32 {
            return &x.heapIndex;
        }
        pub fn CompareFn(_: void, a: *Self, b: *Self) std.math.Order {
            return std.math.order(a.Priority, b.Priority);
        }
    };

    const PriorityQueue_PathNode = IndexedHeap_4ary(*Node, void, Node.CompareFn, Node.GetHeapIndexRef);

    const allocator = std.testing.allocator;

    var pq = PriorityQueue_PathNode.empty;
    defer pq.Deinit(allocator);

    var nodes: std.ArrayList(*Node) = .empty;
    defer {
        for (nodes.items) |node| {
            allocator.destroy(node);
        }
        nodes.deinit(allocator);
    }

    for ([_]u32{ 5, 2, 1, 8, 10 }) |i| {
        var node = try allocator.create(Node);
        node.val = i;
        node.Priority = i;
        try nodes.append(allocator, node);
    }

    {
        var lst = std.ArrayList(u32).empty;
        defer lst.deinit(allocator);

        pq.Clear();

        for (nodes.items) |node| {
            try pq.Push(allocator, node);
        }

        while (pq.PopOrNull()) |node| {
            try lst.append(allocator, node.val);
            try std.testing.expectEqual(PriorityQueue_PathNode.INVALID_INDEX, node.heapIndex);
        }

        try std.testing.expectEqualSlices(u32, &[_]u32{ 1, 2, 5, 8, 10 }, lst.items);
    }

    {
        var lst = std.ArrayList(u32).empty;
        defer lst.deinit(allocator);

        pq.Clear();

        for (nodes.items) |node| {
            try pq.Push(allocator, node);
        }

        nodes.items[4].Priority = 0;

        try pq.TryDecreaseKey(nodes.items[4]);

        while (pq.PopOrNull()) |node| {
            try lst.append(allocator, node.val);
        }

        try std.testing.expectEqualSlices(u32, &[_]u32{ 10, 1, 2, 5, 8 }, lst.items);
    }

    pq.Clear();
}
