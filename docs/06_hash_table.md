# Hash Table 哈希表

到目前为止，哈希表是我们见到的第一个非线性的数据结构。你可以将哈希表视作快递柜，数据就是一个个快件，快递员通过快件单子上的信息提取一个编号并放置到对应地快递柜格子里。“提取编号”这个过程就被称为**哈希函数**。

放入柜子里后，用户只需根据编号找到柜子即可，不需要再一个柜子一个柜子找过来。

## 哈希函数

哈希函数是一种将不固定长度的数据转换为固定长度数据的函数，例如将字符串转换为整型等，它的输出通常可以作为数组的索引使用。

哈希函数的选择是一个很大的话题，我们不会过多的介绍。在这里我们介绍一种简单的，适用于字符串的哈希函数——DJB2。

### DJB2

DJB2是一种简单且高效地的哈希函数，他由一个初始值5381和一个简单的循环来计算给定字符串的哈希值。对于每个字符，它将被左移5为并加上其本身（左移5位相当于乘以32，再加上本身就相当于乘以33），然后将这个值加到最终结果中。下面是它的Zig实现：

```zig
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

```ansi
$stdout returns nothing.
$stderr:
Hello HashTable!
DJB2 of 'Hello HashTable!' is 52934.
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

```zig {6}
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

```zig
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

```zig
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

```ansi
$stdout returns nothing.
$stderr:
0 % 2 = 0
1 % 2 = 1
2 % 2 = 0
3 % 2 = 1
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

```ansi
$stdout returns nothing.
$stderr:
@rem(-3, 2) = -1
@mod(-3, 2) = 1
@rem(-2, 2) = 0
@mod(-2, 2) = 0
@rem(-1, 2) = -1
@mod(-1, 2) = 1
@rem(0, 2) = 0
@mod(0, 2) = 0
@rem(1, 2) = 1
@mod(1, 2) = 1
@rem(2, 2) = 0
@mod(2, 2) = 0
@rem(3, 2) = 1
@mod(3, 2) = 1
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

```zig
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

```zig
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

```zig
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

```zig
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

```zig
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

首先，我们讨论需要的数据结构。我们的需求很明确，需要保存单词和词频，并且以单词为键，所以我们有这样的数据结构：

```zig
// 引入必要的函数
const std = @import("std");
const hash_table_lib = @import("lib/06_hash_table.zig");
const HashTable = hash_table_lib.HashTable;

// 保存词频
const WordFreq = struct {
    word: []const u8, // 单词
    freq: u32, // 词频
};

// key accessor
pub fn getWord(word_freq: WordFreq) []const u8 {
    return word_freq.word;
}
```

然后，我们考虑算法的流程。算法并不算难，只需要遍历一遍单词，对于每个单词，如果哈希表中已经有了，则令词频加一然后放回哈希表中，如果没有则放入一个词频为1的元素。

哈希表我们已经实现了，该如何获取单词呢？在Zig的标准库中实现了`std.mem.splitAny`函数可以满足我们的需求。这个函数接收三个输入：第一个输入为后两个输入的切片中元素的类型；第二个输入为buffer，是需要被分割的切片；第二个输入为delimiters，即分隔符。该函数返回一个**迭代器**，这个迭代器中的每个元素是被delimiters中的任意一个元素分割的buffer的一部分。在我们的例子中，这个迭代器返回单词。下面的示例使用这个函数分割了一个字符串：

```zig
var itr = std.mem.splitAny(u8, "Hello, this is DSwZ!", "., !?\"'");
while (itr.next()) |next| {
    std.debug.print("Next is {s}\n", .{next});
}
```

```ansi
$stdout returns nothing.
$stderr:
Next is Hello
Next is 
Next is this
Next is is
Next is DSwZ
Next is 
```

我们还需要考虑到，字符是区分大小写的，而单词一般不会因为大小写不同而变为另一个单词（单词一般是大小写不敏感的），所以我们需要统一将所有单词变为小写的。然而，实现这样的一个函数会大大地增加程序地复杂性，我们选择另辟蹊径，转而修改对比键值是否相等的过程，并修改计算哈希值的过程：

```zig
pub fn stringEql(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) {
        return false;
    }
    for (a, b) |c1, c2| {
        if (std.ascii.toLower(c1) != std.ascii.toLower(c2)) {
            return false;
        }
    }
    return true;
}

pub fn special_djb2(str: []const u8) usize {
    var hash: usize = 5381;

    for (str) |c| {
        // 直接对C进行左移5位的操作可能会超出u8的表示范围，
        //    因此需要显式地转换为更大的数据类型
        const larger_c: usize = @intCast(std.ascii.toLower(c));
        hash += (larger_c << 5) + larger_c;
    }

    return hash;
}
```

解决了这些问题，我们就可以开始实现了！

```zig
pub fn countWordFreq(sentence: []const u8, hash_table: *HashTable([]const u8, WordFreq)) !void {
    var word_itr = std.mem.splitAny(u8, sentence, " ,./;'[]\\—-=<>?:\"{}|_+`~!@#$%^&*()");
    // 遍历单词
    while (word_itr.next()) |word| {
        if (std.mem.eql(u8, word, "")) {
            // 忽略空字符串
            continue;
        }
        const record = hash_table.get(word);
        if (record) |r| {
            // 已有的词频加1
            hash_table.remove(word);
            try hash_table.put(.{
                .word = word,
                .freq = r.freq + 1,
            });
        } else {
            // 没有的词频设置为1
            try hash_table.put(.{
                .word = word,
                .freq = 1,
            });
        }
    }
}
```

有一点需要注意，调用`std.mem.splitAny`时提供的`delimiters`会很大程度上影响计数的效果。

我们可以对其进行测试：

```zig
test "count word freqs" {
    const allocator = std.testing.allocator;

    const sentence: []const u8 = "The Time Traveller (for so it will be convenient to speak of him) was expounding a recondite matter to us. His pale grey eyes shone and twinkled, and his usually pale face was flushed and animated. The fire burnt brightly, and the soft radiance of the incandescent lights in the lilies of silver caught the bubbles that flashed and passed in our glasses. Our chairs, being his patents, embraced and caressed us rather than submitted to be sat upon, and there was that luxurious after-dinner atmosphere, when thought runs gracefully free of the trammels of precision. And he put it to us in this way—marking the points with a lean forefinger—as we sat and lazily admired his earnestness over this new paradox (as we thought it) and his fecundity.";
    const expected = [_]WordFreq{
        .{ .word = "and", .freq = 10 },
        .{ .word = "the", .freq = 8 },
        .{ .word = "of", .freq = 5 },
        .{ .word = "his", .freq = 5 },
        .{ .word = "to", .freq = 4 },
        .{ .word = "it", .freq = 3 },
        .{ .word = "was", .freq = 3 },
        .{ .word = "us", .freq = 3 },
        .{ .word = "in", .freq = 3 },
        .{ .word = "be", .freq = 2 },
        .{ .word = "a", .freq = 2 },
        .{ .word = "pale", .freq = 2 },
        .{ .word = "that", .freq = 2 },
        .{ .word = "our", .freq = 2 },
        .{ .word = "sat", .freq = 2 },
        .{ .word = "thought", .freq = 2 },
        .{ .word = "this", .freq = 2 },
        .{ .word = "as", .freq = 2 },
        .{ .word = "we", .freq = 2 },
        .{ .word = "time", .freq = 1 },
        .{ .word = "traveller", .freq = 1 },
        .{ .word = "for", .freq = 1 },
        .{ .word = "so", .freq = 1 },
        .{ .word = "will", .freq = 1 },
        .{ .word = "convenient", .freq = 1 },
        .{ .word = "speak", .freq = 1 },
        .{ .word = "him", .freq = 1 },
        .{ .word = "expounding", .freq = 1 },
    };
    var hash_table = try HashTable([]const u8, WordFreq).init(
        allocator,
        &special_djb2,
        &getWord,
        &stringEql,
        10,
    );
    defer hash_table.deinit();

    try countWordFreq(sentence, &hash_table);

    for (expected) |exp| {
        const actual = hash_table.get(exp.word);
        try std.testing.expect(actual != null);
        std.debug.print("{s}: actual freq: {}, exp freq: {}\n", .{ exp.word, actual.?.freq, exp.freq });
        try std.testing.expect(actual.?.freq == exp.freq);
    }
}
```

```ansi
$stdout returns nothing.
$stderr:
1/1 tmp-156355.test.count word freqs...and: actual freq: 10, exp freq: 10
the: actual freq: 8, exp freq: 8
of: actual freq: 5, exp freq: 5
his: actual freq: 5, exp freq: 5
to: actual freq: 4, exp freq: 4
it: actual freq: 3, exp freq: 3
was: actual freq: 3, exp freq: 3
us: actual freq: 3, exp freq: 3
in: actual freq: 3, exp freq: 3
be: actual freq: 2, exp freq: 2
a: actual freq: 2, exp freq: 2
pale: actual freq: 2, exp freq: 2
that: actual freq: 2, exp freq: 2
our: actual freq: 2, exp freq: 2
sat: actual freq: 2, exp freq: 2
thought: actual freq: 2, exp freq: 2
this: actual freq: 2, exp freq: 2
as: actual freq: 2, exp freq: 2
we: actual freq: 2, exp freq: 2
time: actual freq: 1, exp freq: 1
traveller: actual freq: 1, exp freq: 1
for: actual freq: 1, exp freq: 1
so: actual freq: 1, exp freq: 1
will: actual freq: 1, exp freq: 1
convenient: actual freq: 1, exp freq: 1
speak: actual freq: 1, exp freq: 1
him: actual freq: 1, exp freq: 1
expounding: actual freq: 1, exp freq: 1
OK
All 1 tests passed.
```

为了简洁，在`expected`中我们删去了一些只出现了1次的单词。

::: tip
我们这里实现的词频统计函数只支持能使用ASCII表示的字符，这是因为我们用来计算哈希值的djb2算法只支持能使用ASCII表示的字符。这些字符中包括了全部的英文字母及其大小写，但是不包括中文。

::: details 部分ASCII表

这里的ASCII表只保留了可以看见的部分，这部分被称为**可打印字符**。
| 十进制 | 十六进制 | 字符 | 描述                       |
|--------|----------|------|----------------------------|
| 32     | 0x20     |      | 空格 (space)               |
| 33     | 0x21     | !    | 感叹号                     |
| 34     | 0x22     | "    | 引号                       |
| 35     | 0x23     | #    | 井号                       |
| 36     | 0x24     | $    | 美元符号                   |
| 37     | 0x25     | %    | 百分号                     |
| 38     | 0x26     | &    | 和号                       |
| 39     | 0x27     | '    | 单引号                     |
| 40     | 0x28     | (    | 左圆括号                   |
| 41     | 0x29     | )    | 右圆括号                   |
| 42     | 0x2A     | *    | 星号                       |
| 43     | 0x2B     | +    | 加号                       |
| 44     | 0x2C     | ,    | 逗号                       |
| 45     | 0x2D     | -    | 减号                       |
| 46     | 0x2E     | .    | 句号                       |
| 47     | 0x2F     | /    | 斜杠                       |
| 48     | 0x30     | 0    | 数字0                      |
| 49     | 0x31     | 1    | 数字1                      |
| 50     | 0x32     | 2    | 数字2                      |
| 51     | 0x33     | 3    | 数字3                      |
| 52     | 0x34     | 4    | 数字4                      |
| 53     | 0x35     | 5    | 数字5                      |
| 54     | 0x36     | 6    | 数字6                      |
| 55     | 0x37     | 7    | 数字7                      |
| 56     | 0x38     | 8    | 数字8                      |
| 57     | 0x39     | 9    | 数字9                      |
| 58     | 0x3A     | :    | 冒号                       |
| 59     | 0x3B     | ;    | 分号                       |
| 60     | 0x3C     | <    | 小于号                     |
| 61     | 0x3D     | =    | 等号                       |
| 62     | 0x3E     | >    | 大于号                     |
| 63     | 0x3F     | ?    | 问号                       |
| 64     | 0x40     | @    | 商业at符号                 |
| 65     | 0x41     | A    | 大写字母A                  |
| 66     | 0x42     | B    | 大写字母B                  |
| 67     | 0x43     | C    | 大写字母C                  |
| 68     | 0x44     | D    | 大写字母D                  |
| 69     | 0x45     | E    | 大写字母E                  |
| 70     | 0x46     | F    | 大写字母F                  |
| 71     | 0x47     | G    | 大写字母G                  |
| 72     | 0x48     | H    | 大写字母H                  |
| 73     | 0x49     | I    | 大写字母I                  |
| 74     | 0x4A     | J    | 大写字母J                  |
| 75     | 0x4B     | K    | 大写字母K                  |
| 76     | 0x4C     | L    | 大写字母L                  |
| 77     | 0x4D     | M    | 大写字母M                  |
| 78     | 0x4E     | N    | 大写字母N                  |
| 79     | 0x4F     | O    | 大写字母O                  |
| 80     | 0x50     | P    | 大写字母P                  |
| 81     | 0x51     | Q    | 大写字母Q                  |
| 82     | 0x52     | R    | 大写字母R                  |
| 83     | 0x53     | S    | 大写字母S                  |
| 84     | 0x54     | T    | 大写字母T                  |
| 85     | 0x55     | U    | 大写字母U                  |
| 86     | 0x56     | V    | 大写字母V                  |
| 87     | 0x57     | W    | 大写字母W                  |
| 88     | 0x58     | X    | 大写字母X                  |
| 89     | 0x59     | Y    | 大写字母Y                  |
| 90     | 0x5A     | Z    | 大写字母Z                  |
| 91     | 0x5B     | [    | 左方括号                   |
| 92     | 0x5C     | \    | 反斜杠                     |
| 93     | 0x5D     | ]    | 右方括号                   |
| 94     | 0x5E     | ^    | 上划线                     |
| 95     | 0x5F     | _    | 下划线                     |
| 96     | 0x60     | `    | 波浪号                     |
| 97     | 0x61     | a    | 小写字母a                  |
| 98     | 0x62     | b    | 小写字母b                  |
| 99     | 0x63     | c    | 小写字母c                  |
| 100    | 0x64     | d    | 小写字母d                  |
| 101    | 0x65     | e    | 小写字母e                  |
| 102    | 0x66     | f    | 小写字母f                  |
| 103    | 0x67     | g    | 小写字母g                  |
| 104    | 0x68     | h    | 小写字母h                  |
| 105    | 0x69     | i    | 小写字母i                  |
| 106    | 0x6A     | j    | 小写字母j                  |
| 107    | 0x6B     | k    | 小写字母k                  |
| 108    | 0x6C     | l    | 小写字母l                  |
| 109    | 0x6D     | m    | 小写字母m                  |
| 110    | 0x6E     | n    | 小写字母n                  |
| 111    | 0x6F     | o    | 小写字母o                  |
| 112    | 0x70     | p    | 小写字母p                  |
| 113    | 0x71     | q    | 小写字母q                  |
| 114    | 0x72     | r    | 小写字母r                  |
| 115    | 0x73     | s    | 小写字母s                  |
| 116    | 0x74     | t    | 小写字母t                  |
| 117    | 0x75     | u    | 小写字母u                  |
| 118    | 0x76     | v    | 小写字母v                  |
| 119    | 0x77     | w    | 小写字母w                  |
| 120    | 0x78     | x    | 小写字母x                  |
| 121    | 0x79     | y    | 小写字母y                  |
| 122    | 0x7A     | z    | 小写字母z                  |
| 123    | 0x7B     | {    | 左花括号                   |
| 124    | 0x7C     | |    | 竖线                       |
| 125    | 0x7D     | }    | 右花括号                   |
| 126    | 0x7E     | ~    | 波浪线                     |
:::
:::

## 挑战 —— 开放寻址法 { #Open Addressing }

开放寻址法的基本思路为：发生冲突时，重新找一个哈希值，常见的方法有：

1. 线性探测：每次重新寻找哈希值就在原来的哈希值的基础上加1；
2. 二次探测：哈希值为$hash+t^2$，其中$hash$为原来的哈希值，$t$为重新寻找哈希值的次数。

你可以挑选一个你喜欢的进行实现。

## 完整代码

::: details 06_hash_table.zig
```zig
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
```zig
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

::: details 0603_hash_table_appliance.zig
```zig
const std = @import("std");
const hash_table_lib = @import("06_hash_table.zig");
const HashTable = hash_table_lib.HashTable;

const WordFreq = struct {
    word: []const u8, // 单词
    freq: u32, // 词频
};

pub fn getWord(word_freq: WordFreq) []const u8 {
    return word_freq.word;
}

pub fn stringEql(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) {
        return false;
    }
    for (a, b) |c1, c2| {
        if (std.ascii.toLower(c1) != std.ascii.toLower(c2)) {
            return false;
        }
    }
    return true;
}

pub fn special_djb2(str: []const u8) usize {
    var hash: usize = 5381;

    for (str) |c| {
        // 直接对C进行左移5位的操作可能会超出u8的表示范围，
        //    因此需要显式地转换为更大的数据类型
        const larger_c: usize = @intCast(std.ascii.toLower(c));
        hash += (larger_c << 5) + larger_c;
    }

    return hash;
}

pub fn countWordFreq(sentence: []const u8, hash_table: *HashTable([]const u8, WordFreq)) !void {
    var word_itr = std.mem.splitAny(u8, sentence, " ,./;'[]\\—-=<>?:\"{}|_+`~!@#$%^&*()");
    // 遍历单词
    while (word_itr.next()) |word| {
        if (std.mem.eql(u8, word, "")) {
            // 忽略空字符串
            continue;
        }
        const record = hash_table.get(word);
        if (record) |r| {
            // 已有的词频加1
            hash_table.remove(word);
            try hash_table.put(.{
                .word = word,
                .freq = r.freq + 1,
            });
        } else {
            // 没有的词频设置为1
            try hash_table.put(.{
                .word = word,
                .freq = 1,
            });
        }
    }
}

test "count word freqs" {
    const allocator = std.testing.allocator;

    const sentence: []const u8 = "The Time Traveller (for so it will be convenient to speak of him) was expounding a recondite matter to us. His pale grey eyes shone and twinkled, and his usually pale face was flushed and animated. The fire burnt brightly, and the soft radiance of the incandescent lights in the lilies of silver caught the bubbles that flashed and passed in our glasses. Our chairs, being his patents, embraced and caressed us rather than submitted to be sat upon, and there was that luxurious after-dinner atmosphere, when thought runs gracefully free of the trammels of precision. And he put it to us in this way—marking the points with a lean forefinger—as we sat and lazily admired his earnestness over this new paradox (as we thought it) and his fecundity.";
    const expected = [_]WordFreq{
        .{ .word = "and", .freq = 10 },
        .{ .word = "the", .freq = 8 },
        .{ .word = "of", .freq = 5 },
        .{ .word = "his", .freq = 5 },
        .{ .word = "to", .freq = 4 },
        .{ .word = "it", .freq = 3 },
        .{ .word = "was", .freq = 3 },
        .{ .word = "us", .freq = 3 },
        .{ .word = "in", .freq = 3 },
        .{ .word = "be", .freq = 2 },
        .{ .word = "a", .freq = 2 },
        .{ .word = "pale", .freq = 2 },
        .{ .word = "that", .freq = 2 },
        .{ .word = "our", .freq = 2 },
        .{ .word = "sat", .freq = 2 },
        .{ .word = "thought", .freq = 2 },
        .{ .word = "this", .freq = 2 },
        .{ .word = "as", .freq = 2 },
        .{ .word = "we", .freq = 2 },
        .{ .word = "time", .freq = 1 },
        .{ .word = "traveller", .freq = 1 },
        .{ .word = "for", .freq = 1 },
        .{ .word = "so", .freq = 1 },
        .{ .word = "will", .freq = 1 },
        .{ .word = "convenient", .freq = 1 },
        .{ .word = "speak", .freq = 1 },
        .{ .word = "him", .freq = 1 },
        .{ .word = "expounding", .freq = 1 },
    };
    var hash_table = try HashTable([]const u8, WordFreq).init(
        allocator,
        &special_djb2,
        &getWord,
        &stringEql,
        10,
    );
    defer hash_table.deinit();

    try countWordFreq(sentence, &hash_table);

    for (expected) |exp| {
        const actual = hash_table.get(exp.word);
        try std.testing.expect(actual != null);
        std.debug.print("{s}: actual freq: {}, exp freq: {}\n", .{ exp.word, actual.?.freq, exp.freq });
        try std.testing.expect(actual.?.freq == exp.freq);
    }
}
```
:::
