const std = @import("std");

pub const PathCostEvaluator_u32_2_3 = PathCostEvaluator_u32_Fn(2, 3);
pub const PathCostEvaluator_u32_10 = PathCostEvaluator_u32_Fn(10, 14);
pub const PathCostEvaluator_u32_100 = PathCostEvaluator_u32_Fn(100, 141);
pub const PathCostEvaluator_u32_1000 = PathCostEvaluator_u32_Fn(1000, 1414);
pub const PathCostEvaluator_u32_1000_w_110 = PathCostEvaluator_u32_w_Fn(1000, 1414, 110, 100);

pub fn PathCostEvaluator_u32_Fn(comptime fixedPointMultiplier: u32, sqrt2: u32) type {
    return struct {
        const FIXED_POINT_MULTIPLIER = fixedPointMultiplier;
        const SQRT_2 = sqrt2;
        const SQRT_2_MINUS_ONE = SQRT_2 - FIXED_POINT_MULTIPLIER;

        pub inline fn calc_g(px: i32, py: i32, nx: i32, ny: i32) u32 {
            return if (px == nx or py == ny) FIXED_POINT_MULTIPLIER else SQRT_2;
        }

        pub inline fn calc_h(px: i32, py: i32, gy: i32, gx: i32) u32 {
            const abs_dx: u32 = @abs(gx - px);
            const abs_dy: u32 = @abs(gy - py);

            // ex)
            //  FIXED_POINT_MULTIPLIER = 10;
            //  SQRT_2 = 14
            // H = (14 * min) + 10 * (max - min)
            // H = (4 * min) + (10 * max);
            if (abs_dx < abs_dy) {
                return SQRT_2_MINUS_ONE * abs_dx + FIXED_POINT_MULTIPLIER * abs_dy;
            } else {
                return SQRT_2_MINUS_ONE * abs_dy + FIXED_POINT_MULTIPLIER * abs_dx;
            }
        }

        pub const ForJump = struct {
            pub inline fn calc_g_straight(step: u32) u32 {
                return FIXED_POINT_MULTIPLIER * step;
            }

            pub inline fn calc_g_diagonal(step: u32) u32 {
                return SQRT_2 * step;
            }
        };
    };
}

pub fn PathCostEvaluator_u32_w_Fn(
    comptime fixedPointMultiplier: u32,
    comptime sqrt2: u32,
    comptime weightNumerator: u32,
    comptime weightDenominator: u32,
) type {
    return struct {
        const FIXED_POINT_MULTIPLIER = fixedPointMultiplier;
        const SQRT_2 = sqrt2;

        // ex)
        //   fixedPointMultiplier = 1000
        //   sqrt2                = 1414
        //   weightNumerator      = 110
        //   weightDenominator    = 100
        //
        // WEIGHTED_STRAIGHT = 1000 * 110 / 100 = 1100
        // WEIGHTED_SQRT_2   = 1414 * 110 / 100 = 1555
        // WEIGHTED_DIAG_DIFF = 1555 - 1100 = 455
        const WEIGHTED_STRAIGHT: u32 = @divTrunc(FIXED_POINT_MULTIPLIER * weightNumerator, weightDenominator);
        const WEIGHTED_SQRT_2: u32 = @divTrunc(SQRT_2 * weightNumerator, weightDenominator);
        const WEIGHTED_DIAG_DIFF: u32 = WEIGHTED_SQRT_2 - WEIGHTED_STRAIGHT;

        pub inline fn calc_g(px: i32, py: i32, nx: i32, ny: i32) u32 {
            return if (px == nx or py == ny) FIXED_POINT_MULTIPLIER else SQRT_2;
        }

        pub inline fn calc_h(px: i32, py: i32, gy: i32, gx: i32) u32 {
            const abs_dx: u32 = @abs(gx - px);
            const abs_dy: u32 = @abs(gy - py);

            if (abs_dx < abs_dy) {
                return WEIGHTED_DIAG_DIFF * abs_dx + WEIGHTED_STRAIGHT * abs_dy;
            } else {
                return WEIGHTED_DIAG_DIFF * abs_dy + WEIGHTED_STRAIGHT * abs_dx;
            }
        }

        pub const ForJump = struct {
            pub inline fn calc_g_straight(step: u32) u32 {
                return FIXED_POINT_MULTIPLIER * step;
            }

            pub inline fn calc_g_diagonal(step: u32) u32 {
                return SQRT_2 * step;
            }
        };
    };
}
