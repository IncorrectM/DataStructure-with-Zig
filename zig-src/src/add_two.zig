const std = @import("std");

pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "test adding" {
    try std.testing.expect(add(1, 1) == 2);
}
