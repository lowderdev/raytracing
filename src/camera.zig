const std = @import("std");
const vec = @import("vec.zig");
const Vec3 = vec.Vec3;
const Ray = @import("ray.zig").Ray;
const Hit = @import("objects.zig").Hit;

const cameraCenter = Vec3{ 0, 0, 0 };
const focalLength = 1.0;
const viewportHeight = 2.0;

pub const Camera = struct {
    imageWidth: u64,
    imageHeight: u64,
    pixel00Location: Vec3,
    pixelDeltaU: Vec3,
    pixelDeltaV: Vec3,

    pub fn init(imageWidth: u64, imageHeight: u64) Camera {
        const fw: f64 = @floatFromInt(imageWidth);
        const fh: f64 = @floatFromInt(imageHeight);
        const viewportWidth = viewportHeight * fw / fh;
        const viewportU = Vec3{ viewportWidth, 0, 0 };
        const viewportV = Vec3{ 0, -viewportHeight, 0 };
        const pixelDeltaU = viewportU / vec.splat(fw);
        const pixelDeltaV = viewportV / vec.splat(fh);
        const viewportCenter = cameraCenter - Vec3{ 0, 0, focalLength };
        const viewportUpperLeft = viewportCenter - (viewportU / vec.splat(2)) - (viewportV / vec.splat(2));
        const pixel00Location = viewportUpperLeft + vec.splat(0.5) * (pixelDeltaU + pixelDeltaV);

        return Camera{
            .imageWidth = imageWidth,
            .imageHeight = imageHeight,
            .pixel00Location = pixel00Location,
            .pixelDeltaU = pixelDeltaU,
            .pixelDeltaV = pixelDeltaV,
        };
    }

    pub fn render(c: Camera, out: *std.Io.Writer, objects: anytype, progress: std.Progress.Node) !void {
        for (0..c.imageHeight) |h| {
            progress.completeOne();

            for (0..c.imageWidth) |w| {
                const fh: f64 = @floatFromInt(h);
                const fw: f64 = @floatFromInt(w);
                const vh = vec.splat(fh);
                const vw = vec.splat(fw);

                const pixelCenter = c.pixel00Location +
                    (vw * c.pixelDeltaU) +
                    (vh * c.pixelDeltaV);
                const rayDirection = pixelCenter - cameraCenter;
                const r = Ray{ .origin = cameraCenter, .direction = rayDirection };

                const pixel: Vec3 = rayColor(r, objects);

                try out.print("{f}", .{vec.Color{ .data = pixel }});
            }
        }
    }

    fn rayColor(ray: Ray, objects: anytype) Vec3 {
        if (hitEverything(ray, objects)) |hit| {
            return vec.splat(0.5) * (hit.normal + vec.splat(1));
        }

        const white = vec.one;
        const skyBlue = Vec3{ 0.5, 0.7, 1.0 };
        const unitDirection = vec.unit(ray.direction);
        const a = 0.5 * (unitDirection[1] + 1.0);

        return vec.splat(1.0 - a) * white + vec.splat(a) * skyBlue;
    }

    fn hitEverything(ray: Ray, objects: anytype) ?Hit {
        const tMin = 0;
        var hit: ?Hit = null;
        var closest_so_far = std.math.inf(f64);

        inline for (objects) |obj| {
            const new_hit = obj.hit(ray, .{ .min = tMin, .max = closest_so_far });
            if (new_hit) |h| {
                closest_so_far = h.t;
                hit = h;
            }
        }

        return hit;
    }
};
