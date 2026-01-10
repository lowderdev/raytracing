const std = @import("std");
const vec = @import("vec.zig");
const Vec3 = vec.Vec3;
const Ray = @import("ray.zig").Ray;
const Sphere = @import("objects.zig").Sphere;
const Hit = @import("objects.zig").Hit;
const Camera = @import("camera.zig").Camera;

// Image
const aspectRatio = 16.0 / 9.0;
const imageWidth = 1000;
const imageHeight = @divTrunc(imageWidth, aspectRatio);

// RNG
const seed = 0;
var prng: std.Random.DefaultPrng = .init(seed);
const rand = prng.random();

pub fn main() !void {
    var wbuf: [4096]u8 = undefined;
    var file_writer = std.fs.File.stdout().writer(&wbuf);
    const out = &file_writer.interface;

    // Progress Bar
    var pbuf: [1024]u8 = undefined;
    const progress = std.Progress.start(.{
        .draw_buffer = &pbuf,
        .root_name = "Generating Image",
        .estimated_total_items = imageWidth,
    });
    defer progress.end();

    try out.print("P6\n{d} {d}\n255\n", .{ imageWidth, imageHeight });

    const world = .{
        Sphere.init(Vec3{ 0, 0, -1 }, 0.5),
        Sphere.init(Vec3{ 0, -100.5, -1 }, 100),
    };

    const camera = Camera.init(imageWidth, imageHeight);
    try camera.render(out, world, rand, progress);

    try out.flush();
}
