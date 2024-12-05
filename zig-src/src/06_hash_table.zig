const std = @import("std");
const LinkedList = @import("03_linked_list.zig").LinkedList;

/// 计算给定字符串的 djb2 哈希值。
///
/// djb2 是一种非加密哈希函数，常用于哈希表等数据结构中。它由 Dan J. Bernstein 提出，
/// 以其计算速度快和冲突率低而著称。该算法通过将每个字符左移5位然后加上原字符的 ASCII 值，
/// 并与之前的哈希值相加来生成最终的哈希值。
///
/// @param str 被哈希的字符串。
/// @return
///   - 返回一个无符号整数作为字符串的哈希值。
///
pub fn djb2(str: []const u8) usize {
    var hash: usize = 5381;

    for (str) |c| {
        // 直接对C进行左移5位的操作可能会超出u8的表示范围，
        //    因此需要显式地转换为更大的数据类型
        const larger_c: usize = @intCast(c);
        hash += (larger_c << 5) + larger_c;
    }

    return hash;
}

pub fn HashTable(K: type, V: type) type {
    return struct {
        const This = @This();
        const List = LinkedList(V);
        allocator: std.mem.Allocator,
        hash_func: *const fn (V) usize,
        key_accessor: *const fn (V) K,
        lists: []List,

        pub fn init(
            allocator: std.mem.Allocator,
            hash_func: *const fn (K) usize,
            key_accessor: *const fn (V) K,
            data_length: usize,
        ) !This {
            var lists = try allocator.alloc(List, data_length);
            for (0..lists.len) |i| {
                lists[i] = List.init(allocator);
            }
            return .{
                .allocator = allocator,
                .lists = lists,
                .hash_func = hash_func,
                .key_accessor = key_accessor,
            };
        }

        pub fn put(self: *This, value: V) !void {
            const key = self.key_accessor(value);
            const hash = self.hash_func(key) % self.lists.len; // 哈希值可能会很大，通过取余的方式避免越界
            _ = try self.lists[hash].append(value);
        }

        pub fn deinit(self: *This) void {
            for (0..self.lists.len) |i| {
                self.lists[i].deinit();
            }
            self.allocator.free(self.lists);
        }
    };
}

pub fn main() void {
    std.debug.print("Hello HashTable!\n", .{});
    std.debug.print("DJB2 of 'Hello HashTable!' is {}.\n", .{djb2("Hello HashTable!")});
}

pub fn selfAsKey(s: []const u8) []const u8 {
    return s;
}

test "init and deinit hash table" {
    // 测试是否发生内存泄漏
    const allocator = std.testing.allocator;
    var hash_table = try HashTable([]const u8, []const u8).init(
        allocator,
        &djb2,
        &selfAsKey,
        10,
    );
    defer hash_table.deinit();
}

test "put some values" {
    // 初始化数据
    const allocator = std.testing.allocator;
    var hash_table = try HashTable([]const u8, []const u8).init(
        allocator,
        &djb2,
        &selfAsKey,
        10,
    );
    defer hash_table.deinit();

    const strings = [_][]const u8{
        "Hello World!",
        "This is DSwZ!",
        "Have a good day!",
        "Goodbye~",
    };

    // 预先计算好的哈希值（DJB2）
    const expected_hash = [_]usize{
        41186,
        41186,
        50162,
        33068,
    };

    // 放置元素
    for (strings) |str| {
        try hash_table.put(str);
    }

    // 查看是否正确放置
    for (strings, expected_hash) |str, exp_hash| {
        const calc_hash = hash_table.hash_func(hash_table.key_accessor(str));
        try std.testing.expect(calc_hash == exp_hash);
        // 查看添加的元素有没有在对应的链表中
        const list = hash_table.lists[calc_hash % hash_table.lists.len];
        var cur = list.head;
        while (cur) |c| {
            if (std.mem.eql(u8, c.data, str)) {
                // 确实在链表中
                break;
            }
            cur = c.next;
        }
        if (cur == null) {
            // 没有在对应链表中找到
            return error.ElementNotAppened;
        }
    }
}
