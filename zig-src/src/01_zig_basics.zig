const std = @import("std");

pub fn main() !void {
    // 输出到标准输出
    const stdout = std.io.getStdOut();
    _ = try stdout.write("Hello Zig! from stdout\n");
    // 输出到标准错误
    std.debug.print("Hello Zig! from stderr\n", .{});
    // 同样也是输出到标准错误
    const stderr = std.io.getStdErr();
    _ = try stderr.write("Hello Zig! from stderr again\n");

    var i: usize = 0;
    while (i < 10) {
        std.debug.print("{d},", .{i});
        i += 1;
    }
    std.debug.print("\n", .{});

    i = 0;
    while (i < 10) : (i += 1) {
        std.debug.print("{d},", .{i});
    }
    std.debug.print("\n", .{});

    for (0..10) |value| {
        std.debug.print("{d},", .{value});
    }
    std.debug.print("\n", .{});
}
