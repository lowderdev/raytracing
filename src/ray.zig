const vec = @import("vec.zig");
const Vec3 = vec.Vec3;

pub const Ray = struct {
    origin: Vec3,
    direction: Vec3,

    pub fn at(r: Ray, t: f64) Vec3 {
        return r.origin + vec.splat(t) * r.direction;
    }
};
