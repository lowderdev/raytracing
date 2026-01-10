const std = @import("std");
const vec = @import("vec.zig");
const Vec3 = vec.Vec3;
const Ray = @import("ray.zig").Ray;
const Hit = @import("objects.zig").Hit;
const Interval = @import("interval.zig").Interval;

const cameraCenter = Vec3{ 0, 0, 0 };
const focalLength = 1.0;
const viewportHeight = 2.0;
const samplesPerPixel = 20;
const pixelSamplesScale = 1.0 / (samplesPerPixel + 0.0);
const maxRecursionDepth = 50;

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

    pub fn render(c: Camera, out: *std.Io.Writer, world: anytype, rand: std.Random, progress: std.Progress.Node) !void {
        const gpa = std.heap.smp_allocator;
        var out_buf: [][3]u8 = try gpa.alloc([3]u8, c.imageWidth * c.imageHeight);
        var pool: std.Thread.Pool = undefined;
        try pool.init(.{ .allocator = gpa });

        var wg: std.Thread.WaitGroup = .{};

        for (0..c.imageHeight) |h| {
            pool.spawnWg(&wg, computeRow, .{
                c,
                h,
                world,
                out_buf[h * c.imageWidth ..][0..c.imageWidth],
                rand,
                progress,
            });
        }

        pool.waitAndWork(&wg);

        try out.writeSliceEndian(u8, std.mem.sliceAsBytes(out_buf), .little);
    }

    fn computeRow(c: Camera, h: u64, world: anytype, out: [][3]u8, rand: std.Random, progress: std.Progress.Node) void {
        defer progress.completeOne();

        for (0..c.imageWidth) |w| {
            const fh: f64 = @floatFromInt(h);
            const fw: f64 = @floatFromInt(w);

            var pixel_color = vec.splat(0.0);
            for (0..samplesPerPixel) |_| {
                const ray: Ray = c.getRay(fw, fh, rand);
                pixel_color += rayColor(rand, maxRecursionDepth, ray, world);
            }

            const pixel = vec.splat(pixelSamplesScale) * pixel_color;
            const intensity = Interval{ .min = 0.000, .max = 0.999 };
            const r: u8 = @intFromFloat(256 * intensity.clamp(pixel[0]));
            const g: u8 = @intFromFloat(256 * intensity.clamp(pixel[1]));
            const b: u8 = @intFromFloat(256 * intensity.clamp(pixel[2]));
            out[w] = .{ r, g, b };
        }
    }

    /// Construct a camera ray originating from the origin and directed at randomly
    /// sampled point around the pixel location w, h.
    fn getRay(c: Camera, w: f64, h: f64, rand: std.Random) Ray {
        const offset = sampleSquare(rand);
        const wOffset = vec.splat(w + offset[0]);
        const hOffset = vec.splat(h + offset[1]);
        const pixelSample = c.pixel00Location + (wOffset * c.pixelDeltaU) + (hOffset * c.pixelDeltaV);

        const rayOrigin = cameraCenter;
        const rayDirection = pixelSample - rayOrigin;

        return .{ .origin = rayOrigin, .direction = rayDirection };
    }

    /// Returns the vector to a random point in the [-.5, -.5]-[+.5, +.5] unit square.
    fn sampleSquare(rand: std.Random) Vec3 {
        const x = std.Random.float(rand, f64);
        const y = std.Random.float(rand, f64);

        return .{ x - 0.5, y - 0.5, 0 };
    }

    fn rayColor(rand: std.Random, depth: u32, ray: Ray, world: anytype) Vec3 {
        // if max depth exceeded, return black
        if (depth <= 0) return vec.zero;

        if (hitEverything(ray, world)) |hit| {
            // // Simple normal-based coloring
            // return vec.splat(0.5) * (hit.normal + vec.splat(1));

            const direction = vec.randomOnHemisphere(rand, hit.normal);
            const scattered = Ray{ .origin = hit.point, .direction = direction };
            return vec.splat(0.5) * rayColor(rand, depth - 1, scattered, world);
        }

        const white = vec.one;
        const skyBlue = Vec3{ 0.5, 0.7, 1.0 };
        const unitDirection = vec.unit(ray.direction);
        const a = 0.5 * (unitDirection[1] + 1.0);

        return vec.splat(1.0 - a) * white + vec.splat(a) * skyBlue;
    }

    fn hitEverything(ray: Ray, world: anytype) ?Hit {
        const tMin = 0.001;
        var hit: ?Hit = null;
        var closest_so_far = std.math.inf(f64);

        inline for (world) |obj| {
            const new_hit = obj.hit(ray, .{ .min = tMin, .max = closest_so_far });
            if (new_hit) |h| {
                closest_so_far = h.t;
                hit = h;
            }
        }

        return hit;
    }
};
