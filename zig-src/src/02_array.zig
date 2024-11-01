const std = @import("std");

pub fn main() !void {
    const IntArray = SimpleArray(u64);
    const allocator = std.heap.page_allocator;

    var array = IntArray.init(allocator);
    defer array.deinit();

    try array.append(1);
    printArray(u64, array);

    for (0..10) |value| {
        try array.append(@as(u64, value));
    }
    printArray(u64, array);

    for (1000..1010) |value| {
        try array.append(@as(u64, value));
    }
    printArray(u64, array);
}

/// 工具函数，打印我们的数组
pub fn printArray(T: type, array: SimpleArray(T)) void {
    var i: usize = 0;
    while (i < array.len) : (i += 1) {
        std.debug.print("{}, ", .{array.items[i]});
    }
    std.debug.print("\n", .{});
}

/// 一个能够自动调整容量的数组
/// 通过init初始化
/// 不再使用时通过deinit释放
pub fn SimpleArray(comptime T: type) type {
    return struct {
        const Self = @This();
        items: []T,
        len: usize,
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .items = &[_]T{},
                .len = 0,
                .allocator = allocator,
            };
        }

        pub fn capacity(self: *const Self) usize {
            return self.items.len;
        }

        /// 在数组末尾添加一个元素
        pub fn append(self: *Self, item: T) !void {
            if (self.len >= self.capacity()) {
                try self.enlarge();
            }
            self.items[self.len] = item;
            self.len += 1;
        }

        /// 扩充数组容量
        pub fn enlarge(self: *Self) !void {
            const cap = self.capacity();

            // 分配新的内存并复制数据
            const source = self.items;
            const new = try self.allocator.alloc(T, if (cap == 0) 10 else cap * 2);
            std.mem.copyForwards(T, new, source);
            self.items = new;

            // 先前分配的内存
            if (source.len > 0) {
                self.allocator.free(source);
            }
        }

        pub fn deinit(self: *Self) void {
            if (self.capacity() > 0) {
                self.allocator.free(self.items);
            }
            // 如果容量为0，说明没有初始化过,则没有必要释放
        }
    };
}
