const std = @import("std");
const Writer = std.io.Writer;

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

// is this needed?
// pub const Fmt = std.fmt.Alt(Vec3, format);
// fn format(v: Vec3, writer: *Writer) !void {
//     try writer.print("{}, {}, {}", .{ v[0], v[1], v[2] });
// }

pub const Color = std.fmt.Alt(Vec3, colorFormat);
fn colorFormat(v: Vec3, writer: *Writer) !void {
    const r: u8 = @intFromFloat(v[0] * 255.999);
    const g: u8 = @intFromFloat(v[1] * 255.999);
    const b: u8 = @intFromFloat(v[2] * 255.999);
    try writer.print("{d} {d} {d}\n", .{ r, g, b });
}
