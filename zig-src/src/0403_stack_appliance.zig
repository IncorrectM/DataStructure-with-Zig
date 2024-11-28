const std = @import("std");
const Stack = @import("04_stack.zig").Stack;

/// 检查括号（包括小括号、中括号以及大括号）是否匹配。
///
/// @param source 被检查的字符串。
/// @return
///   - `true` 如果所有括号都正确匹配。
///   - `false` 如果括号不匹配。
///   - 抛出错误（例如 OOM）。
///
/// @example
/// ```zig
/// const result = try checkParentness("()");
/// assert(result == true);
///
/// const result2 = try checkParentness("([)]");
/// assert(result2 == false);
/// ```
pub fn checkParentness(source: []const u8) !bool {
    // 准备分配器
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();
    defer arena.deinit(); // 通过ArenaAllocator，我们可以一口气释放所有分配的内存

    // 准备一个栈用于匹配
    var stack = try Stack(u8).init(allocator);
    // defer stack.deinit(); // 因为可以使用ArenaAllocator统一释放，所以我们可以不调用deinit

    // 遍历源字符串
    for (source) |c| {
        switch (c) {
            '(', '[', '{' => {
                try stack.push(c);
            },
            ')', ']', '}' => {
                const top = stack.pop();
                if (top) |t| {
                    const expected: u8 = switch (c) {
                        ')' => '(',
                        ']' => '[',
                        '}' => '{',
                        else => unreachable,
                    };
                    if (t != expected) {
                        return false;
                    }
                } else {
                    return false;
                }
            },
            else => {},
        }
    }
    return stack.isEmpty();
}

const TestCase = struct {
    source: []const u8,
    expected: bool,
};

pub fn main() !void {
    const cases = [_]TestCase{
        .{
            .source = "[({})]",
            .expected = true,
        },
        .{
            .source = "He[ll(o{Wo}rl)d]!",
            .expected = true,
        },
        .{
            .source = "[({})",
            .expected = false,
        },
        .{
            .source = "[({}]",
            .expected = false,
        },
        .{
            .source = "[({)]",
            .expected = false,
        },
        .{
            .source = "[(})]",
            .expected = false,
        },
        .{
            .source = "[{})]",
            .expected = false,
        },
        .{
            .source = "({})]",
            .expected = false,
        },
        .{
            .source = "})]",
            .expected = false,
        },
        .{
            .source = "[({",
            .expected = false,
        },
    };

    for (cases) |case| {
        const actual = try checkParentness(case.source);
        std.debug.assert(actual == case.expected);
    }
}

test "test checkParentness" {
    const cases = [_]TestCase{
        .{
            .source = "[({})]",
            .expected = true,
        },
        .{
            .source = "He[ll(o{Wo}rl)d]!",
            .expected = true,
        },
        .{
            .source = "[({})",
            .expected = false,
        },
        .{
            .source = "[({}]",
            .expected = false,
        },
        .{
            .source = "[({)]",
            .expected = false,
        },
        .{
            .source = "[(})]",
            .expected = false,
        },
        .{
            .source = "[{})]",
            .expected = false,
        },
        .{
            .source = "({})]",
            .expected = false,
        },
        .{
            .source = "})]",
            .expected = false,
        },
        .{
            .source = "[({",
            .expected = false,
        },
    };

    for (cases) |case| {
        const actual = try checkParentness(case.source);
        try std.testing.expect(actual == case.expected);
    }
}
