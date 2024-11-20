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

        pub fn deinit(self: *This) void {
            var next = self.head;
            while (next != null) {
                const cur = next.?;
                next = cur.next;
                if (@hasDecl(T, "deinit")) {
                    // 反初始化节点里的数据
                    cur.data.deinit();
                }
                // 释放节点
                self.allocator.free(cur);
            }
        }
    };
}

pub fn main() void {
    std.debug.print("Hello LinkedLIst!", .{});
}
