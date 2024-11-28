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

        pub fn push(self: *This, v: T) !void {
            try self.data.append(v);
        }

        pub fn pop(self: *This) ?T {
            if (self.isEmpty()) {
                // 空栈
                return null;
            }
            const lastIndex = self.top() - 1;
            const last = self.data.nth(lastIndex) catch unreachable;
            // 使用函数进行修改
            // self.data.removeNth(lastIndex);
            // 或者手动修改
            self.data.len -= 1;
            return last;
        }

        pub fn peek(self: *This) ?T {
            if (self.isEmpty()) {
                // 空栈
                return null;
            }
            const lastIndex = self.top() - 1;
            const last = self.data.nth(lastIndex) catch unreachable;
            return last;
        }

        pub fn top(self: This) usize {
            return self.data.len;
        }

        pub fn isEmpty(self: This) bool {
            return self.top() == 0;
        }

        pub fn deinit(self: *This) void {
            self.data.deinit();
        }
    };
}

pub fn errorIfZero(v: i32) !i32 {
    if (v == 0) {
        return error.Zero;
    } else {
        return v;
    }
}

pub fn main() !void {
    std.debug.print("Hello Stack!", .{});
    var stack = try Stack(i32).init(std.heap.page_allocator);
    std.debug.print("{}\n", .{stack.top()});
    defer stack.deinit();

    _ = errorIfZero(10085) catch {
        std.debug.print("I will not be printed.\n", .{});
    };

    _ = errorIfZero(0) catch {
        std.debug.print("I will be printed since you passed 0.\n", .{});
    };

    _ = errorIfZero(0) catch |err| {
        std.debug.print("Caught an error {!}\n", .{err});
    };
}
