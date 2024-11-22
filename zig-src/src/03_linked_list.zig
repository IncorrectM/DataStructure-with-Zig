const std = @import("std");

pub fn LinkedListNode(comptime T: type) type {
    return struct {
        const This = @This();
        data: T,
        next: ?*This,

        pub fn init(data: T) This {
            return .{
                .data = data,
                .next = null,
            };
        }
    };
}

pub fn LinkedList(comptime T: type) type {
    return struct {
        const Node = LinkedListNode(T);
        const This = @This();
        allocator: std.mem.Allocator,
        head: ?*Node,
        length: usize,

        pub fn init(allocator: std.mem.Allocator) This {
            return .{
                .allocator = allocator,
                .head = null,
                .length = 0,
            };
        }

        pub fn nth(self: This, n: usize) ?*This.Node {
            if (n >= self.length) {
                return null;
            }
            var next = self.head;
            var i: usize = 0;
            while (next != null and next.?.next != null and i != n) : (i += 1) {
                next = next.?.next;
            }
            return next;
        }

        pub fn append(self: *This, v: T) !*This.Node {
            // 2. 创建新节点
            const new_node = try self.allocator.create(This.Node);
            new_node.data = v;
            new_node.next = null;
            if (self.head == null) {
                self.head = new_node;
                self.length += 1;
                return new_node;
            }
            // 1. 找到最后一个节点
            var last: ?*This.Node = self.head.?;
            while (true) {
                if (last.?.next == null) {
                    break;
                } else {
                    last = last.?.next;
                }
            }
            // 3. 让最后一个节点指向新节点
            last.?.next = new_node;
            self.length += 1;
            return new_node;
        }

        pub fn remove(self: *This, node: *This.Node) void {
            if (self.head == null) {
                // 空链表，不删除
                return;
            }
            // 判断头节点是不是要移除的节点
            if (self.head == node) {
                const cur = self.head;
                self.head = self.head.?.next;
                self.allocator.destroy(cur.?); // 由链表来管理内存的创建和销毁
                return;
            }
            if (self.head.?.next == null) {
                // 只有一个节点，并且这个节点不是要被删除的节点，那么不删除
                return;
            }
            // 在后续的节点中找一个删除
            var cur = self.head;
            var next = self.head.?.next;
            while (cur != null and next != null) {
                if (next == node) {
                    cur.?.next = next.?.next;
                    self.allocator.destroy(next.?);
                    return;
                }
                cur = next;
                next = next.?.next;
            }
        }

        pub fn deinit(self: *This) void {
            var next = self.head;
            while (next != null) {
                const cur = next.?;
                next = cur.next;
                switch (@typeInfo(T)) {
                    .@"struct", .@"enum", .@"union" => {
                        if (@hasDecl(T, "deinit")) {
                            // 反初始化节点里的数据
                            cur.data.deinit();
                        }
                    },
                    else => {},
                }
                // 释放节点
                self.allocator.destroy(cur);
            }
        }
    };
}

pub fn main() void {
    std.debug.print("Hello LinkedList!", .{});
}

const expect = std.testing.expect;

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
}
