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

    const a: u32 = 42;
    const b: u32 = 42;
    if (a > b) {
        std.debug.print("{d} is greater than {d}.\n", .{ a, b });
    } else if (a == b) {
        std.debug.print("{d} equals {d}.\n", .{ a, b });
    } else {
        std.debug.print("{d} is lesser than {d}.\n", .{ a, b });
    }

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

    const someNumers = [_]u8{ 1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21 };
    for (someNumers) |value| {
        std.debug.print("{d},", .{value});
    }
    std.debug.print("\n", .{});

    for (someNumers, 0..) |value, index| {
        std.debug.print("{}: {d}, ", .{ index, value });
    }
    std.debug.print("\n", .{});

    const someEvenNumers = [_]u8{ 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22 };
    for (someNumers, someEvenNumers, 0..) |odd, even, index| {
        std.debug.print("{d}: {d} and {d}\n", .{ index, odd, even });
    }
}
