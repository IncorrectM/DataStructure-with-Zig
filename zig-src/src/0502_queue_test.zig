const std = @import("std");
const Queue = @import("05_queue.zig").Queue;
const expect = std.testing.expect;

test "test enqueue" {
    const allocator = std.testing.allocator;
    var queue = Queue(i32).init(allocator);
    defer queue.deinit();

    const expected = [_]i32{ 1, 88, 43, 0, -10, 100 };
    for (expected) |value| {
        try queue.enqueue(value);
    }

    // 我们借助链表的方法来检查元素
    for (0..expected.len) |value| {
        const first = queue.data.popFirst();
        try expect(first != null);
        try expect(first.?.data == expected[value]);
        allocator.destroy(first.?); // 在LinkedList的实现中我们提到过，这个方法会把节点的内存管理权交给使用者
    }

    const empty = queue.data.popFirst();
    try expect(empty == null);
}

test "test dequeue" {
    const allocator = std.testing.allocator;
    var queue = Queue(i32).init(allocator);
    defer queue.deinit();

    const expected = [_]i32{ 1, 88, 43, 0, -10, 100 };
    for (expected) |value| {
        // 我们借助链表的方法来插入元素
        _ = try queue.data.append(value);
    }

    for (0..expected.len) |value| {
        const first = queue.dequeue();
        try expect(first != null);
        try expect(first.? == expected[value]);
    }

    const empty = queue.dequeue();
    try expect(empty == null);
}

test "use enqueu and dequeue together" {
    const allocator = std.testing.allocator;
    var queue = Queue(i32).init(allocator);
    defer queue.deinit();

    const expected = [_]i32{ 1, 88, 43, 0, -10, 100 };
    for (expected) |value| {
        try queue.enqueue(value);
    }

    for (0..expected.len) |value| {
        const first = queue.dequeue();
        try expect(first != null);
        try expect(first.? == expected[value]);
    }

    const empty = queue.dequeue();
    try expect(empty == null);
}
