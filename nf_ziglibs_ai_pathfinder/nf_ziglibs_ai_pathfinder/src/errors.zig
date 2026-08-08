const std = @import("std");
pub const AllocatorError = std.mem.Allocator.Error;
pub const PriorityQueueError = @import("./Common/PriorityQueue.zig").Error;

pub const SearchError = error{
    ERR_IS_WALL_ON_START,
    ERR_IS_WALL_ON_GOAL,
    ERR_OUT_OF_BOUND_START,
    ERR_OUT_OF_BOUND_GOAL,
    ERR_SAME_POSITION_START_AND_GOAL,
    ERR_UNREACHABLE_GOAL,
    ERR_INVALID_MAP_DATA, // when .Init (width <= 0 or height <= 0)
} ||
    AllocatorError ||
    PriorityQueueError;
