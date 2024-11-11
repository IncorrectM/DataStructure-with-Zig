const Point = struct {
    x: f32,
    y: f32,
};

const std = @import("std");
pub fn struct_main() void {
    const point = Point{
        .x = 1.0,
        .y = 1.80086,
    };

    std.debug.print("We got a point ({}, {}).\n", .{ point.x, point.y });
}
