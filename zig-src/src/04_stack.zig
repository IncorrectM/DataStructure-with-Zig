const std = @import("std");

const ArrayList = @import("02_array.zig").SimpleArrayList;

pub fn Stack(T: type) type {
    return struct {
        const This = @This();
        const List = ArrayList(T);
        allocator: std.mem.Allocator,
        data: This.List,

        pub fn init(allocator: std.mem.Allocator) !This {
            return .{
                .allocator = allocator,
                .data = try This.List.init(allocator),
            };
        }

        pub fn top(self: This) usize {
            return self.data.len;
        }

        pub fn isEmpty(self: This) usize {
            return self.top() == 0;
        }

        pub fn deinit(self: *This) void {
            self.data.deinit();
        }
    };
}

pub fn main() !void {
    std.debug.print("Hello Stack!", .{});
    var stack = try Stack(i32).init(std.heap.page_allocator);
    std.debug.print("{}\n", .{stack.top()});
    defer stack.deinit();
}
