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

        pub fn deinit(self: *This) void {
            switch (@typeInfo(T)) {
                .@"struct", .@"enum", .@"union" => {
                    if (@hasDecl(T, "deinit")) {
                        // 反初始化节点里的数据
                        self.data.deinit();
                    }
                },
                else => {},
            }
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
                self.length -= 1;
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
                    self.length -= 1;
                    self.allocator.destroy(next.?);
                    return;
                }
                cur = next;
                next = next.?.next;
            }
        }

        pub fn prepend(self: *This, v: T) !*This.Node {
            const new_node = try self.allocator.create(This.Node);
            new_node.data = v;
            new_node.next = null;
            if (self.head == null) {
                // 没有头节点，就成为头节点
                self.head = new_node;
            } else {
                // 让新节点的next指向原来的头节点
                new_node.next = self.head.?;
                // 成为新的头节点
                self.head = new_node;
            }
            self.length += 1;
            return new_node;
        }

        pub fn popFirst(self: *This) ?*This.Node {
            if (self.head == null) {
                return null;
            }
            const removed = self.head.?;
            self.head = removed.next;
            removed.next = null;
            self.length -= 1;
            return removed;
        }

        pub fn deinit(self: *This) void {
            var next = self.head;
            while (next != null) {
                const cur = next.?;
                next = cur.next;
                cur.deinit(); // 修改了这里
                // 释放节点
                self.allocator.destroy(cur);
            }
        }
    };
}

pub fn main() void {
    std.debug.print("Hello LinkedList!", .{});
}
