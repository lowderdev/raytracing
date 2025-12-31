const std = @import("std");
const raytrace = @import("raytrace");

pub fn main() !void {
    var wbuf: [4096]u8 = undefined;
    var file_writer = std.fs.File.stdout().writer(&wbuf);
    const out = &file_writer.interface;

    const image_width = 256;
    const image_height = 256;

    var pbuf: [1024]u8 = undefined;
    const progress = std.Progress.start(.{
        .draw_buffer = &pbuf,
        .root_name = "Generating Image",
        .estimated_total_items = image_width * image_height,
    });
    defer progress.end();

    try out.print("P3\n{} {}\n255\n", .{ image_width, image_height });

    for (0..image_height) |h| {
        progress.completeOne();
        for (0..image_width) |w| {
            const fh: f32 = @floatFromInt(h);
            const fw: f32 = @floatFromInt(w);

            const r = @trunc(255.999 * (fw / (image_width - 1.0)));
            const g = @trunc(255.999 * (fh / (image_height - 1.0)));
            const b = 0.0;

            try out.print("{d} {d} {d}\n", .{ r, g, b });
        }
        std.Thread.sleep(10000);
    }

    try out.flush();
}
