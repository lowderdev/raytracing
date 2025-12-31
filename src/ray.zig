const Vec3 = @import("vec.zig").Vec3;

pub const Ray = struct {
    origin: Vec3,
    direction: Vec3,

    pub fn at(v: Vec3, t: f32) Vec3 {
        return v.origin + t * v.direction;
    }
};
