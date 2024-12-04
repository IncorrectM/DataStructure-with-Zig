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

首先，我们需要一个哈希函数来处理输入的数据。因为我们无法提前确定输入的数据会是什么类型，所以我们要让调用者提供哈希函数，然后保存起来以便后续使用。

然后，我们需要一个数组来保存数据。因为我们会使用到链表，所以需要调用者传入一个allocator，我们可以用这个allocator来创建数组。

最后，因为我们使用链地址法来处理冲突，所以我们需要给数组的每个元素赋予一个链表。

由此，我们可以得到一个基本的初始化函数：

```zig -skip {6}
pub fn HashTable(T: type) type {
    return struct {
        const This = @This();
        const List = LinkedList(T);
        allocator: std.mem.Allocator,
        hash_func: *const fn (T) usize,
        lists: []List,

        pub fn init(allocator: std.mem.Allocator, hash_func: *const fn (T) usize, data_length: usize) !This {
            var lists = try allocator.alloc(List, data_length);
            for (0..lists.len) |i| {
                lists[i] = List.init(allocator);
            }
            return .{
                .allocator = allocator,
                .lists = lists,
                .hash_func = hash_func,
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

## 测试

## 应用示例

我们将使用哈希表来实现**词频统计**，也就是计算一篇文章中各个单词都出现了几次。

## 挑战 —— 开放寻址法 { #Open Addressing }

开放寻址法的基本思路为：发生冲突时，重新找一个哈希值，常见的方法有：

1. 线性探测：每次重新寻找哈希值就在原来的哈希值的基础上加1；
2. 二次探测：哈希值为$hash+t^2$，其中$hash$为原来的哈希值，$t$为重新寻找哈希值的次数。

你可以挑选一个你喜欢的进行实现。

## 完整代码