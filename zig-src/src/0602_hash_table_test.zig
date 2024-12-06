const std = @import("std");
const HashTable = @import("06_hash_table.zig").HashTable;
const djb2 = @import("06_hash_table.zig").djb2;

pub fn selfAsKey(s: []const u8) []const u8 {
    return s;
}

pub fn stringEqual(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}

test "init and deinit hash table" {
    // 测试是否发生内存泄漏
    const allocator = std.testing.allocator;
    var hash_table = try HashTable([]const u8, []const u8).init(
        allocator,
        &djb2,
        &selfAsKey,
        &stringEqual,
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
        &stringEqual,
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

const Student = struct {
    name: []const u8,
    class: u8,
};

pub fn studentNameAccessor(student: Student) []const u8 {
    return student.name;
}

test "put and get some values" {
    // 初始化数据
    const allocator = std.testing.allocator;
    var hash_table = try HashTable([]const u8, Student).init(
        allocator,
        &djb2,
        &studentNameAccessor,
        &stringEqual,
        10,
    );
    defer hash_table.deinit();

    const students = [_]Student{
        Student{
            .name = "Alice",
            .class = 'A',
        },
        Student{
            .name = "Bob",
            .class = 'B',
        },
        Student{
            .name = "Coco",
            .class = 'A',
        },
        Student{
            .name = "Eric",
            .class = 'C',
        },
        Student{
            .name = "Frank",
            .class = 'C',
        },
        Student{
            .name = "Groot",
            .class = 'B',
        },
    };

    // 放入数据
    for (students) |student| {
        try hash_table.put(student);
    }

    // 拿出数据
    for (students) |student| {
        const stu = hash_table.get(studentNameAccessor(student));
        try std.testing.expect(stu != null and std.mem.eql(u8, student.name, stu.?.name));
    }

    // 尝试获取不存在的数据
    const not_exists = hash_table.get("Hugo");
    try std.testing.expect(not_exists == null);
}

test "put and remove some values" {
    // 初始化数据
    const allocator = std.testing.allocator;
    var hash_table = try HashTable([]const u8, Student).init(
        allocator,
        &djb2,
        &studentNameAccessor,
        &stringEqual,
        10,
    );
    defer hash_table.deinit();

    const students = [_]Student{
        Student{
            .name = "Alice",
            .class = 'A',
        },
        Student{
            .name = "Bob",
            .class = 'B',
        },
        Student{
            .name = "Coco",
            .class = 'A',
        },
        Student{
            .name = "Eric",
            .class = 'C',
        },
        Student{
            .name = "Frank",
            .class = 'C',
        },
        Student{
            .name = "Groot",
            .class = 'B',
        },
    };

    // 放入数据
    for (students) |student| {
        try hash_table.put(student);
    }

    for (students) |student| {
        const stu = hash_table.get(student.name);
        try std.testing.expect(stu != null); // 确保已经放入表中
        hash_table.remove(student.name); // 移除G
        try std.testing.expect(hash_table.get(student.name) == null); // 此时已被删除
    }
}
