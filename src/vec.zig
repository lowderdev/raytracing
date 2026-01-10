const std = @import("std");
const Writer = std.io.Writer;
const Interval = @import("interval.zig").Interval;

pub const Vec3 = @Vector(3, f64);
pub const zero = splat(0.0);
pub const one = splat(1.0);

pub fn splat(f: f64) Vec3 {
    return @splat(f);
}

pub fn magnitude(v: Vec3) f64 {
    return @sqrt(magnitude2(v));
}

pub fn magnitude2(v: Vec3) f64 {
    return @reduce(.Add, v * v);
}

pub fn dot(u: Vec3, v: Vec3) f64 {
    return @reduce(.Add, u * v);
}

pub fn cross(u: Vec3, v: Vec3) Vec3 {
    return .{
        u[1] * v[2] - u[2] * v[1],
        u[2] * v[0] - u[0] * v[2],
        u[0] * v[1] - u[1] * v[0],
    };
}

pub fn unit(v: Vec3) Vec3 {
    const mag = magnitude(v);
    if (mag == 0.0) return zero;

    const mag3 = splat(mag);
    return v / mag3;
}

pub fn random(r: std.Random) Vec3 {
    return Vec3{
        r.float(f64),
        r.float(f64),
        r.float(f64),
    };
}

pub fn randomRange(r: std.Random, min: f64, max: f64) Vec3 {
    std.debug.assert(max >= min);

    return .{
        r.float(f64) * (max - min) + min,
        r.float(f64) * (max - min) + min,
        r.float(f64) * (max - min) + min,
    };
}
