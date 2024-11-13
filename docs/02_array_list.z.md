# ArrayList 列表

## 内存是一种资源

Zig不会代替程序员管理内存，因此，使用Zig进行编程的人必须知道怎么管理内存。

当然，就我们的主题而言，你并不需要非常熟悉怎么进行管理，我们也不会在这方面深入太多。

在这里，我们只介绍一种简单的内存管理方式，有关内存的详细可见[这个网站](https://ziglang.org/documentation/master/#Memory)。

### ArenaAllocator

在本书中，我们实现的数据结构并不会被投入到实际的生产开发中（我不建议这么做），所有的数据结构的实例都只会存在很短的一段时间，因此，完全可以使用ArenaAllocator来分配内存。这样，我们可以一次性施放申请的所有内存。如果你想知道ArenaAllocator是怎么工作的，可以查看[这个网站](https://www.huy.rocks/everyday/01-12-2022-zig-how-arenaallocator-works)。

让我们来分配点东西吧！

```zig
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const allocator = arena.allocator();
const a_number = try allocator.create(u32);
a_number.* = 100;
std.debug.print("We allocated {p} which stores {d}!\n", .{ a_number, a_number.* });
arena.deinit();
```

让我们来逐行看看有什么吧！

1. `var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);`：通过传入一个其他的Allocator，我们初始化了一个ArenaAllocator。ArenaAllocator会用这个分配器来实际分配内存；
2. `const allocator = arena.allocator();`：我们从arena中要了一个Allocator，这是我们用它来分配内存；
3. `const a_number = try allocator.create(u32);`：我们从内存中要来了一块能放下u32类型的空间，create函数返回的是一个错误联合类型，通过try我们拿出了实际的值——一个指向分配的内存区域的指针。如果你忘了错误联合类型，可以看看[上一章](./01_zig_basics)。
4. `a_number.* = 100;`：我们向刚才分配的内存写了100这个数字；
5. `std.debug.print("We allocated {p} which stores {d}!\n", .{ a_number, a_number.* });`： 打印它！
6. `arena.deinit();`：当我们不再使用arena后，一定要反初始化（deinit）它，来施放所有的内存。

在后面的章节中，我们将经常见到类似的片段。

## 结构体

为了实现一种数据结构，我们需要一个地方存储数据，在这里我们有“结构”。

如果你有使用C的经验，你应该对下面的代码不会陌生：

```zig -collect_1
const Point = struct {
    // 结构体
    x: f32, // 成员
    y: f32, // 成员
};
```

如果你觉得陌生也没关系，我们慢慢解释。

首先，在`const Point = struc {};`这里我们声明了一个名为Point的变量，并为其赋值为一个结构体。在Zig中，类型是“一等公民”，它可以像值、指针一样被赋予变量。

在两个花括号之间的部分，被称为结构体。在结构体内可以声明这个结构的成员。在这里，我们声明了两个类型为f32的成员——x和y。

有了结构体，我们可以把它用起来。

```zig -execute_1 {3}
const std = @import("std");
pub fn main() void {
    const point = Point{
        .x = 1.0,
        .y = 1.80086,
    };

    std.debug.print("We got a point ({}, {}).\n", .{ point.x, point.y });
}
```

有两个点需要解释一下。

首先，在第3行，我们声明了一个point变量，然后初始化了一个Point结构并赋值给它。初始化语句也和C里面非常相似。

其次，我们打印了point里存储的值。这里的`point.x`和`point.y`分别访问了两个成员，`.`叫作成员访问运算符。

## 数组

数组（Array）是一种线性数据结构，它由相同类型的数据元素组成，这些元素存储在连续的区域内，并且可以通过下标进行访问。

下面的图片是一个数组示例，这个数组中存储了5个类型为i8的整型数字，因此长度为5。同时，箭头指向了第一个元素，这个元素的下标是0。

![数组示例](./imgs/02/0201_Array.png)

我们已经见过在Zig怎么创建和访问一样的数组：

```zig
const number = [5]i8{ 2, -1, 5, 6, 3 };
for (number, 0..) |value, i| {
    std.debug.print("Index={}, Value={}\n", .{ i, value });
}
std.debug.print("number.len={}\n", .{number.len});
```

在大多数编程语言中，数组的长度都是固定的，必须要编译的时候就确定长度。

## 变长的数组 —— 列表

如果我们想要动态地调整数组长度呢？在Python中，常用的列表可以自动调整长度；在Rust中，我们可以使用向量Vec。在这里，我们使用**列表**这个称呼，将我们实现的版本命名为SimpleArrayList。

::: tip
Zig语言的标准库提供了一个列表的实现[std.ArrayList](https://ziglang.org/documentation/master/std/#std.ArrayList)，我们跟随标准库称之为列表（List）。
:::

正如其名，SimpleArrayList使用普通的数组存储数据。同时，我们需要知道存储了多少个元素，并且需要能在需要时扩大内部存储用的数组。由此，我们可以得到下面的基本的定义：

```zig -skip
const SimpleArrayList = struct {
    allocator: std.mem.Allocator,   // 内存分配器，用于动态分配内存
    items: []???,                  // 列表内元素
    len: usize,                     // 列表内元素的数量
};
```

### 实现**泛型**

这里还有一个问题，`items`应该是什么类型的呢？为了能使列表适用于不同类型的数据，我们需要**泛型**。简单来说，泛型就是通过某种方式，使得函数或是结构体可以接收不同的类型作为参数或成员。

我们前面说过，在Zig中类型是一等公民，这意味着我们可以将类型作为参数传给函数，也可以作为返回值返回。我们可以通过这种方式实现泛型。我们可以声明一个函数，接收一个类型T，然后返回存储类型T的元素的列表。

```zig -skip
pub fn SimpleArrayList(comptime T: type) type {
    return struct {
        allocator: std.mem.Allocator,
        items: []T,
        len: usize,
    };
}
```

在这里，我们遇到了几个没见过的东西：

1. 关键词`comptime`：这是Zig的一个重要属性，它有很多用处，在这里，它意味着T是一个在编译的时候就已知的值；
2. 类型`type`：这个类型是“类型的类型”；

通过这种方式返回的结构体的名字比较复杂，不方便使用，我们可以用Zig的内建函数来构建一个别名来。

```zig -skip {3}
pub fn SimpleArrayList(comptime T: type) type {
    return struct {
        const This = @This();
        allocator: std.mem.Allocator,
        items: []T,
        len: usize,
    };
}
```

在第3行中，我们使用`@This()`函数获得了当前结构的类型。

::: tip
在所有内建函数中，以大写字母开头的函数都返回`type`类型的值，例如这里的`@This()`。

这里的成员被命名为`This`，但这不是强制的，用你喜欢的就行。
:::

### 初始化和反初始化

让我们找一个地方来初始化数据结构。

按照约定俗成，一般声明一个名为`init`的函数作为初始化函数，一个名为`deinit`的函数作为反初始化函数。

函数应该放在哪里呢？在C中，我们把成员定义在结构体内，然后在结构体外用一个很长的前缀来区分，比如：

```c
typedef struct {
    int *items;
    int len;
} SimpleArrayListInt;

void simple_array_list_int_init(SimpleArrayListInt*);
```

在Python中，我们会直接在类的定义内定义一个特殊的函数，比如：

```python
class SimpleArrayInit():
    def __init__(self):
        pass
```

在Zig中，我们结合这两种形式：在结构体内声明函数，比如：

```zig -skip {9}
pub fn SimpleArrayList(comptime T: type) type {
    return struct {
        const DefaultCapacity: usize = 10;
        const This = @This();
        allocator: std.mem.Allocator,
        items: []T,
        len: usize,

        pub fn init(allocator: std.mem.Allocator) !This {
            return .{
                .allocator = allocator,
                .items = try allocator.alloc(T, This.DefaultCapacity),
                .len = 0,
            };
        }
    };
}
```

除了`init`，我们还需要一个对应的`deinit`，以便在需要的时候释放申请的内存。在这里，我们需要释放`items`这个成员。

```zig -skip
        pub fn deinit(self: This) void {
            self.allocator.free(self.items);
        }
```

组装起来，我们就有了一个SimpleArrayList的基本框架：

```zig -singleFile
const std = @import("std");

pub fn SimpleArrayList(comptime T: type) type {
    return struct {
        const DefaultCapacity: usize = 10;
        const This = @This();
        allocator: std.mem.Allocator,
        items: []T,
        len: usize,

        pub fn init(allocator: std.mem.Allocator) !This {
            return .{
                .allocator = allocator,
                .items = try allocator.alloc(T, This.DefaultCapacity),
                .len = 0,
            };
        }

        pub fn deinit(self: This) void {
            self.allocator.free(self.items);
        }
    };
}

pub fn main() !void {
    const a = try SimpleArrayList(i8).init(std.heap.page_allocator);
    defer a.deinit();
    std.debug.print("{} of {}\n", .{ a.len, a.items.len });
}
```

从运行结果我们可以看出，我们成功地分配了10个元素的空间，不过暂时还没有存储任何元素进去。

- 动态数组的简单实现（扩容策略）
- 基础内存管理示例

🚧施工中🚧
