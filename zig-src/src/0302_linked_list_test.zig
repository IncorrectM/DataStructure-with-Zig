const std = @import("std");
const expect = std.testing.expect;
const LinkedList = @import("03_linked_list.zig").LinkedList;

test "test append" {
    // 初始化链表
    const allocator = std.testing.allocator;
    var list = LinkedList(i32).init(allocator);
    defer list.deinit();

    // 测试插入一些数据
    for (0..17) |value| {
        const v: i32 = @intCast(value);
        _ = try list.append(v);
    }
    try expect(list.head != null);
    try expect(list.head.?.data == 0);
    try expect(list.length == 17);
}

test "test nth" {
    // 初始化链表
    const allocator = std.testing.allocator;
    var list = LinkedList(i32).init(allocator);
    defer list.deinit();

    // 测试插入一些数据
    for (0..17) |value| {
        const v: i32 = @intCast(value);
        _ = try list.append(v);
    }

    // 开头
    const first = list.nth(0);
    try expect(first != null and first.?.data == 0);
    // 中间
    var middle = list.nth(9);
    try expect(middle != null and middle.?.data == 9);
    middle = list.nth(5);
    try expect(middle != null and middle.?.data == 5);
    //末尾
    const last = list.nth(16);
    try expect(last != null and last.?.data == 16);
    // 超出范围
    const outOfPlace = list.nth(100);
    try expect(outOfPlace == null);
}

test "test remove first" {
    // 初始化链表
    const allocator = std.testing.allocator;
    var list = LinkedList(i32).init(allocator);
    defer list.deinit();

    const node = try list.append(1);
    _ = try list.append(2);
    _ = try list.append(3);

    list.remove(node);

    const head = list.head;
    try expect(head != null and head.?.data == 2);

    const next = head.?.next;
    try expect(next != null and next.?.data == 3);

    try expect(list.length == 2);
}

test "test remove second" {
    // 初始化链表
    const allocator = std.testing.allocator;
    var list = LinkedList(i32).init(allocator);
    defer list.deinit();

    _ = try list.append(1);
    const node = try list.append(2);
    _ = try list.append(3);

    list.remove(node);

    const head = list.head;
    try expect(head != null and head.?.data == 1);

    const next = head.?.next;
    try expect(next != null and next.?.data == 3);

    try expect(list.length == 2);
}

test "test remove third" {
    // 初始化链表
    const allocator = std.testing.allocator;
    var list = LinkedList(i32).init(allocator);
    defer list.deinit();

    _ = try list.append(1);
    _ = try list.append(2);
    const node = try list.append(3);

    list.remove(node);

    const head = list.head;
    try expect(head != null and head.?.data == 1);

    const next = head.?.next;
    try expect(next != null and next.?.data == 2);

    try expect(list.length == 2);
}

test "test prepend" {
    // 初始化链表
    const allocator = std.testing.allocator;
    var list = LinkedList(i32).init(allocator);
    defer list.deinit();

    const first = try list.append(1);
    const second = try list.append(2);
    const third = try list.append(3);

    const neo = try list.prepend(0);

    var neo_node = list.nth(0);
    try expect(neo_node != null and neo_node.?.data == neo.data and neo_node.?.next == neo.next);

    neo_node = list.nth(1);
    try expect(neo_node != null and neo_node.?.data == first.data and neo_node.?.next == first.next);

    neo_node = list.nth(2);
    try expect(neo_node != null and neo_node.?.data == second.data and neo_node.?.next == second.next);

    neo_node = list.nth(3);
    try expect(neo_node != null and neo_node.?.data == third.data and neo_node.?.next == third.next);
}

test "test popFirst" {
    // 初始化链表
    const allocator = std.testing.allocator;
    var list = LinkedList(i32).init(allocator);
    defer list.deinit();

    const first = try list.append(1);
    const second = try list.append(2);
    const third = try list.append(3);

    var removed_node = list.popFirst();
    try expect(removed_node != null and removed_node.?.data == first.data and removed_node.?.next == null);
    try expect(list.length == 2);
    removed_node.?.deinit();
    allocator.destroy(removed_node.?);

    removed_node = list.popFirst();
    try expect(removed_node != null and removed_node.?.data == second.data and removed_node.?.next == null);
    try expect(list.length == 1);
    removed_node.?.deinit();
    allocator.destroy(removed_node.?);

    removed_node = list.popFirst();
    try expect(removed_node != null and removed_node.?.data == third.data and removed_node.?.next == null);
    try expect(list.length == 0);
    removed_node.?.deinit();
    allocator.destroy(removed_node.?);

    try std.testing.expect(list.popFirst() == null);
}
