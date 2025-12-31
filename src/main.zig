const std = @import("std");
const vec = @import("vec.zig");
const Vec3 = vec.Vec3;
const Ray = @import("ray.zig").Ray;

// Image
const aspectRatio = 16.0 / 9.0;
const imageWidth = 800;
const imageHeight = @divTrunc(imageWidth, aspectRatio);

// Camera
const focalLength = 1.0;
const viewportHeight = 2.0;
const viewportWidth = aspectRatio * viewportHeight;
const cameraCenter = Vec3{ 0, 0, 0 };
const viewportU = Vec3{ viewportWidth, 0, 0 };
const viewportV = Vec3{ 0, -viewportHeight, 0 };
const pixelDeltaU = viewportU / vec.splat(imageWidth);
const pixelDeltaV = viewportV / vec.splat(imageHeight);
const viewportCenter = cameraCenter - Vec3{ 0, 0, focalLength };
const viewportUpperLeft = viewportCenter - (viewportU / vec.splat(2)) - (viewportV / vec.splat(2));
const pixel00Location = viewportUpperLeft + vec.splat(0.5) * (pixelDeltaU + pixelDeltaV);

fn hitSphere(center: Vec3, radius: f32, ray: Ray) bool {
    const oc: Vec3 = center - ray.origin;
    const a = vec.dot(ray.direction, ray.direction);
    const b = -2.0 * vec.dot(ray.direction, oc);
    const c = vec.dot(oc, oc) - radius * radius;
    const discriminant = b * b - 4.0 * a * c;
    return discriminant >= 0.0;
}

fn ray_color(r: Ray) Vec3 {
    if (hitSphere(Vec3{ 0, 0, -1 }, 0.5, r)) {
        return Vec3{ 1.0, 0.0, 0.0 };
    }

    const white = vec.one;
    const skyBlue = Vec3{ 0.5, 0.7, 1.0 };

    const unitDirection = vec.unit(r.direction);
    const a = 0.5 * (vec.y(unitDirection) + 1.0);
    return vec.splat(1.0 - a) * white + vec.splat(a) * skyBlue;
}

pub fn main() !void {
    var wbuf: [4096]u8 = undefined;
    var file_writer = std.fs.File.stdout().writer(&wbuf);
    const out = &file_writer.interface;

    // Progress Bar
    var pbuf: [1024]u8 = undefined;
    const progress = std.Progress.start(.{
        .draw_buffer = &pbuf,
        .root_name = "Generating Image",
        .estimated_total_items = imageWidth * imageHeight,
    });
    defer progress.end();

    try out.print("P3\n{} {}\n255\n", .{ imageWidth, imageHeight });

    for (0..imageHeight) |h| {
        progress.completeOne();

        for (0..imageWidth) |w| {
            const fh: f32 = @floatFromInt(h);
            const fw: f32 = @floatFromInt(w);
            const vh = vec.splat(fh);
            const vw = vec.splat(fw);

            const pixelCenter = pixel00Location +
                (vw * pixelDeltaU) +
                (vh * pixelDeltaV);
            const rayDirection = pixelCenter - cameraCenter;
            const r = Ray{ .origin = cameraCenter, .direction = rayDirection };

            const pixel: Vec3 = ray_color(r);

            try out.print("{f}", .{vec.Color{ .data = pixel }});
        }
        std.Thread.sleep(10000);
    }

    try out.flush();
}
