const std = @import("std");
const Stack = @import("04_stack.zig").Stack;

const expect = std.testing.expect;
const allocator = std.testing.allocator;

test "test push" {
    var stack = try Stack(i32).init(allocator);
    defer stack.deinit();

    const expected = [_]i32{ 1, 3, 4, 9, 1, 0, 111, 19928, 31415, 8008820 };
    for (expected) |value| {
        try stack.push(value);
        // 测试元素是否正确地入栈
        try expect(stack.top() != 0);
        try expect(stack.data.items[stack.top() - 1] == value);
    }
    try expect(std.mem.eql(i32, &expected, stack.data.items));
}

test "test pop" {
    var stack = try Stack(i32).init(allocator);
    defer stack.deinit();

    var expected = [_]i32{ 1, 3, 4, 9, 1, 0, 111, 19928, 31415, 8008820 };
    for (expected) |value| {
        try stack.push(value);
    }

    // 出栈应该是先进后出
    std.mem.reverse(i32, &expected);
    // 一个个出栈并检查是否符合预期
    for (expected) |value| {
        const poped = stack.pop();
        try expect(poped != null and poped.? == value);
    }

    // 试图弹出空栈会返回空值
    try expect(stack.pop() == null);
}

test "test peek" {
    var stack = try Stack(i32).init(allocator);
    defer stack.deinit();

    // 试图peek空栈会返回空值
    try expect(stack.peek() == null);

    const expectedSource = [_]i32{ 1, 3, 4, 9, 1, 0, 111, 19928, 31415, 8008820 };
    for (expectedSource) |value| {
        try stack.push(value);
    }
    const expected = expectedSource[expectedSource.len - 1]; // 预期的peek结果

    // 无论peek几次，返回的总是栈顶元素
    for (expected) |_| {
        const peeked = stack.peek();
        try expect(peeked != null and peeked.? == expected);
    }
}
