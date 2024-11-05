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

    std.debug.print("{}, {}, {}, {}, {}\n", .{ isPrime(2), isPrime(3), isPrime(4), isPrime(100), isPrime(101) });
}

/// 判断一个数是不是质数
pub fn isPrime(num: u128) bool {
    // 质数是除了1和它本身外，没有其他因数的自然数
    if (num <= 1) {
        return false;
    }
    const bound = @as(usize, @intFromFloat(@sqrt(@as(f64, @floatFromInt(num)))));
    var i: usize = 2;
    while (i <= bound) : (i += 1) {
        if (num % i == 0) {
            return false;
        }
    } else {
        return true;
    }
}
