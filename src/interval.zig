const std = @import("std");
const inf64 = std.math.inf(f64);

pub const Interval = struct {
    min: f64,
    max: f64,

    pub const empty = Interval{ .min = inf64, .max = -inf64 };
    pub const universe = Interval{ .min = -inf64, .max = inf64 };

    pub fn size(i: Interval) f64 {
        return i.max - i.min;
    }

    pub fn contains(i: Interval, x: f64) bool {
        return i.min <= x and x <= i.max;
    }

    pub fn surrounds(i: Interval, x: f64) bool {
        return i.min < x and x < i.max;
    }

    pub fn clamp(i: Interval, x: f64) f64 {
        if (x < i.min) return i.min;
        if (x > i.max) return i.max;
        return x;
    }
};
