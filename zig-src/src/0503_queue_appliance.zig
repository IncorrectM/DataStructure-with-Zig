const std = @import("std");
const Queue = @import("05_queue.zig").Queue;
const Stack = @import("04_stack.zig").Stack;

/// 给定字符串是否为回文。
///
/// @param source 被检查的字符串。
/// @return
///   - `true` 如果是回文。
///   - `false` 如果不是回文。
///   - 抛出错误（例如 OOM）。
pub fn testPalindrome(str: []const u8) !bool {
    // 初始化需要使用的结构
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();
    defer arena.deinit(); // 借助于ArenaAllocator，我们可以统一释放分配的内存

    var queue = Queue(u8).init(allocator);
    var stack = try Stack(u8).init(allocator);

    // 逐个入队入栈
    for (str) |c| {
        try queue.enqueue(c);
        try stack.push(c);
    }

    // 逐个出队出栈并对比
    while (!stack.isEmpty()) {
        const a = queue.dequeue();
        const b = stack.pop();
        if (a != b) {
            // 只要有一个不相等，就说明不是回文
            return false;
        }
    }
    // 全部相等，说明是回文
    return true;
}

const TestCase = struct {
    source: []const u8,
    expected: bool,
};
const expect = std.testing.expect;

test "palindrome" {
    const cases = [_]TestCase{
        .{
            .source = "a",
            .expected = true,
        },
        .{
            .source = "aba",
            .expected = true,
        },
        .{
            .source = "12321",
            .expected = true,
        },
        .{
            .source = "abcba",
            .expected = true,
        },
        .{
            .source = "ab",
            .expected = false,
        },
        .{
            .source = "ba",
            .expected = false,
        },
        .{
            .source = "123",
            .expected = false,
        },
        .{
            .source = "HelloWorld!",
            .expected = false,
        },
    };

    for (cases) |case| {
        const result = try testPalindrome(case.source);
        try expect(result == case.expected);
    }
}
