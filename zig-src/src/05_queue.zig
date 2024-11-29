const std = @import("std");

const LinkedList = @import("03_linked_list.zig").LinkedList;

pub fn Queue(T: type) type {
    return struct {
        const This = @This();
        const List = LinkedList(T);
        allocator: std.mem.Allocator,
        data: This.List,

        pub fn init(allocator: std.mem.Allocator) This {
            return .{
                .allocator = allocator,
                .data = This.List.init(allocator),
            };
        }

        pub fn enqueue(self: *This, v: T) !void {
            _ = try self.data.append(v);
        }

        pub fn dequeue(self: *This) ?T {
            const node = self.data.popFirst();
            if (node) |n| {
                const result = n.data;
                self.allocator.destroy(n);
                return result;
            }
            return null;
        }

        pub fn deinit(self: *This) void {
            self.data.deinit();
        }
    };
}

pub fn main() !void {
    std.debug.print("Hello Queue!\n", .{});
}
