# Hash Table 哈希表

到目前为止，哈希表是我们见到的第一个非线性的数据结构。你可以将哈希表视作快递柜，数据就是一个个快件，快递员通过快件单子上的信息提取一个编号并放置到对应地快递柜格子里。“提取编号”这个过程就被称为**哈希函数**。

放入柜子里后，用户只需根据编号找到柜子即可，不需要再一个柜子一个柜子找过来。

## 哈希函数

哈希函数是一种将不固定长度的数据转换为固定长度数据的函数，例如将字符串转换为整型等，它的输出通常可以作为数组的索引使用。

哈希函数的选择是一个很大的话题，我们不会过多的介绍。在这里我们介绍一种简单的，适用于字符串的哈希函数——DJB2。

### DJB2

DJB2是一种简单且高效地的哈希函数，他由一个初始值5381和一个简单的循环来计算给定字符串的哈希值。对于每个字符，它将被左移5为并加上其本身（左移5位相当于乘以32，再加上本身就相当于乘以33），然后将这个值加到最终结果中。下面是它的Zig实现：

```zig -singleFile
const std = @import("std");

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

pub fn main() void {
    std.debug.print("Hello HashTable!\n", .{});
    std.debug.print("DJB2 of 'Hello HashTable!' is {}.\n", .{djb2("Hello HashTable!")});
}
```

关于5381和33这两个数字的选择，可以参考[这个问题](https://stackoverflow.com/questions/1579721/why-are-5381-and-33-so-important-in-the-djb2-algorithm)。

### 冲突

哈希函数有可能会对不同的两个输入给出相同的输出，这种情况称为**冲突**。常见的处理冲突的方法包括：

1. 链地址法；
2. 开放寻址法；

## 链地址法

在使用链地址法的哈希表中，每个表项对应一个链表，具有相同哈希表的数据被存放在对应的链表中。

在这里，我们将借助在第三章中实现的链表来实现基于链地址法的哈希表。我们将基于开放寻址法的哈希表的实现交由读者作为挑战，对开放寻址法的介绍见[挑战](#open-addressing)。

## 初始化和反初始化

我们整理一下我们需要什么吧。

首先，我们需要一个哈希函数来处理输入的数据。因为我们无法提前确定输入的数据会是什么类型，所以我们要让调用者提供哈希函数，然后保存起来以便后续使用。同时，为了计算哈希值，我们还需要用户提供一个获取关键字的函数，我们根据关键字的哈希值来存放和查找数据。因为key的种类多种多样，我们还需要传入一个函数来对比key是否相等。

::: tip
等等，为什么前面的那些实现不需要传入判断是否相等的函数？

在前面的实现中，我们没有需要对比存储的数据的地方。只有判断索引是否相等和判断指针是否相等的需求，而这些是不需要单独传入函数的。

如果你添加了其他按值查找的方法，那你确实需要传入判断元素是否相等的函数。
:::

然后，我们需要一个数组来保存数据。因为我们会使用到链表，所以需要调用者传入一个allocator，我们可以用这个allocator来创建数组。

最后，因为我们使用链地址法来处理冲突，所以我们需要给数组的每个元素赋予一个链表。

由此，我们可以得到一个基本的初始化函数：

```zig -skip {6}
pub fn HashTable(K: type, V: type) type {
    return struct {
        const This = @This();
        const List = LinkedList(V);
        allocator: std.mem.Allocator,
        hash_func: *const fn (K) usize,
        key_accessor: *const fn (V) K,
        key_euqal: *const fn (K, K) bool,
        lists: []List,

        pub fn init(
            allocator: std.mem.Allocator,
            hash_func: *const fn (K) usize,
            key_accessor: *const fn (V) K,
            key_euqal: *const fn (K, K) bool,
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
                .key_euqal = key_euqal,
            };
        }
    };
}
```

注意这里的第6行，我们遇到了一个没见过的数据类型：`*const fn (T) usize`。我们可以将其分为三个部分：

1. `fn (T) usize`：这个类型表示一个函数，这个函数接收一个T类型的输入参数，然后返回一个usize值；
2. `const fn (T) usize`：`const`修饰后面的类型，说明后面的数据是不可变的；
3. `*const fn (T) usize`： `*`表示指针；

组合起来，这个类型就表示一个指向不可变的函数类型的数据的指针。

在反初始化函数中，我们必须释放所有申请来的内存，包括链表、数组等：

```zig -skip
pub fn deinit(self: *This) void {
    for (0..self.lists.len) |i| {
        self.lists[i].deinit();
    }
    self.allocator.free(self.lists);
}
```

## 常用方法

哈希表最常用的方法是添加元素`put`和查找元素`get`，然后我们还希望删除元素`remove`。

### put

添加元素到哈希表的过程包括：

1. 计算哈希值；
2. 根据哈希值找到链表；
3. 向链表中添加元素；

于是我们有这样的实现：

```zig -skip
pub fn put(self: *This, value: V) !void {
    const key = self.key_accessor(value);
    const hash = self.hash_func(key) % self.lists.len; // 哈希值可能会很大，通过取余的方式避免越界
    _ = try self.lists[hash].append(value);
}
```

在这里，我们通过**模运算**操作符限制了`hash`的值。模运算会计算两个数相除所得到的余数：

```zig
const numbers = [_]u32{ 0, 1, 2, 3 };
const number: u32 = 2;
for (numbers) |num| {
    std.debug.print("{} % {} = {}\n", .{ num, number, num % number });
}
```

和其他语言中不同，Zig中的模运算只能作用于**无符号数**，也就是以u开头的整数的类型，比如u8，u32，usize等。如果要对其他类型进行模运算，必须要使用内置函数`@rem`或`@mod`，其中，前者会保留被除数的符号，后者则不会，两者的除数都必须大于0。

```zig
const numbers = [_]i32{ -3, -2, -1, 0, 1, 2, 3 };
const number: i32 = 2;
for (numbers) |num| {
    std.debug.print("@rem({}, {}) = {}\n", .{ num, number, @rem(num, number) });
    std.debug.print("@mod({}, {}) = {}\n", .{ num, number, @mod(num, number) });
}
```

因为我们存储链表的数组的长度是固定的，因此在使用哈希值获取索引时，必须以这种方式避免索引过大。

### get

`get`方法是这样工作的：

1. 用户输入一个关键字；
2. 计算该关键字的哈希值；
3. 根据该哈希值找到对应的链表；
4. 遍历链表来寻找关键字等于给定关键字的元素；
5. 如果链表中不存在此元素，则返回空值；

我们可以这样实现它：

```zig -skip
pub fn get(self: *This, key: K) ?V {
    const hash = self.hash_func(key) % self.lists.len;
    const list = self.lists[hash];
    var cur = list.head;
    // 逐个节点查找
    while (cur) |c| {
        if (self.key_euqal(self.key_accessor(c.*.data), key)) {
            return c.data;
        }
        cur = c.next;
    }
    return null;
}
```

### remove

最后一个是`remove`，这个方法的功能是从哈希表中移除给定关键字对应的元素，它是这样工作的：

1. 计算哈希值；
2. 根据哈希值找到链表；
3. 在链表中找到节点；
4. 从链表中移除节点；

于是有这样的实现：

```zig -skip
pub fn remove(self: *This, key: K) void {
    const hash = self.hash_func(key) % self.lists.len;
    const list = &self.lists[hash];

    var cur = list.head;
    // 逐个节点查找
    while (cur) |c| {
        if (self.key_euqal(self.key_accessor(c.*.data), key)) {
            break;
        }
        cur = c.next;
    }
    // 删除找到的节点
    if (cur) |c| {
        list.remove(c);
    }
}
```
::: tip
在Zig中，赋值操作总会创建一个副本。也就是说，当执行`const list = self.lists[hash];`时，赋给变量`list`的值是数组中的链表的副本，在list上的操作不会影响数组中的链表。

我们关注第三行的`const list = &self.lists[hash];`，这里我们创建了一个指针，这样在后续删除节点时才能正确的影响到数组中的链表。

你可尝试把`const list = &self.lists[hash];`换成`var list = self.lists[hash];`，看看会发生什么。
:::

## 测试

### put

让我们尝试放置一些数据，然后在链表中寻找他们。

```zig -skip
pub fn selfAsKey(s: []const u8) []const u8 {
    return s;
}

pub fn stringEqual(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
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
```

### get

我们尝试存入一些数据，然后让我们新写的方法来寻找这些数据。

```zig -skip
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
```

### remove

让我们尝试放置和删除一些元素：

```zig -skip
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
```

## 应用示例

我们将使用哈希表来实现**词频统计**，也就是计算一篇文章中各个单词都出现了几次。

## 挑战 —— 开放寻址法 { #Open Addressing }

开放寻址法的基本思路为：发生冲突时，重新找一个哈希值，常见的方法有：

1. 线性探测：每次重新寻找哈希值就在原来的哈希值的基础上加1；
2. 二次探测：哈希值为$hash+t^2$，其中$hash$为原来的哈希值，$t$为重新寻找哈希值的次数。

你可以挑选一个你喜欢的进行实现。

## 完整代码

::: details 06_hash_table.zig
```zig -skip
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
        hash_func: *const fn (K) usize,
        key_accessor: *const fn (V) K,
        key_euqal: *const fn (K, K) bool,
        lists: []List,

        pub fn init(
            allocator: std.mem.Allocator,
            hash_func: *const fn (K) usize,
            key_accessor: *const fn (V) K,
            key_euqal: *const fn (K, K) bool,
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
                .key_euqal = key_euqal,
            };
        }

        pub fn put(self: *This, value: V) !void {
            const key = self.key_accessor(value);
            const hash = self.hash_func(key) % self.lists.len; // 哈希值可能会很大，通过取余的方式避免越界
            _ = try self.lists[hash].append(value);
        }

        pub fn get(self: *This, key: K) ?V {
            const hash = self.hash_func(key) % self.lists.len;
            const list = self.lists[hash];

            var cur = list.head;
            // 逐个节点查找
            while (cur) |c| {
                if (self.key_euqal(self.key_accessor(c.*.data), key)) {
                    return c.data;
                }
                cur = c.next;
            }
            return null;
        }

        pub fn remove(self: *This, key: K) void {
            const hash = self.hash_func(key) % self.lists.len;
            const list = &self.lists[hash];

            var cur = list.head;
            // 逐个节点查找
            while (cur) |c| {
                if (self.key_euqal(self.key_accessor(c.*.data), key)) {
                    break;
                }
                cur = c.next;
            }
            // 删除找到的节点
            if (cur) |c| {
                list.remove(c);
            }
        }

        pub fn deinit(self: *This) void {
            for (0..self.lists.len) |i| {
                self.lists[i].deinit();
            }
            self.allocator.free(self.lists);
        }
    };
}
```
:::

::: details 0602_hash_table_test.zig
```zig -skip
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
```
:::