const std = @import("std");
const builtin = @import("builtin");
const vec = @import("vec.zig");
const Vec3 = vec.Vec3;
const Ray = @import("ray.zig").Ray;
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
};

pub const Hit = struct {
    point: Vec3,
    normal: Vec3,
    t: f64,
    frontFace: bool,

    pub fn init(t: f64, ray: Ray, point: Vec3, outwardNormal: Vec3) Hit {
        if (builtin.mode == .Debug) {
            // NOTE: the parameter `outward_normal` is assumed to have unit length.
            const one = vec.magnitude2(outwardNormal);
            std.debug.assert(std.math.approxEqAbs(f64, one, 1, 0.001));
        }

        const frontFace = vec.dot(ray.direction, outwardNormal) < 0;
        return .{
            .t = t,
            .point = point,
            .normal = if (frontFace) outwardNormal else -outwardNormal,
            .frontFace = frontFace,
        };
    }
};

pub const Sphere = struct {
    radius: f64,
    center: Vec3,

    pub fn init(center: Vec3, radius: f64) Sphere {
        std.debug.assert(radius >= 0);
        return .{ .radius = radius, .center = center };
    }

    pub fn hit(s: Sphere, ray: Ray, interval: Interval) ?Hit {
        const oc: Vec3 = s.center - ray.origin;
        const a = vec.magnitude2(ray.direction);
        const h = vec.dot(ray.direction, oc);
        const c = vec.magnitude2(oc) - s.radius * s.radius;
        const discriminant = h * h - a * c;

        if (discriminant < 0) return null;

        const sqrtd = @sqrt(discriminant);

        // Find the nearest root that lies in the acceptable range.
        var root = (h - sqrtd) / a;
        if (!interval.surrounds(root)) {
            root = (h + sqrtd) / a;
            if (!interval.surrounds(root)) return null;
        }

        const point = ray.at(root);
        const outwardNormal = (point - s.center) / vec.splat(s.radius);

        return .init(root, ray, point, outwardNormal);
    }
};
