# Zig 基础

我们先来简要的认识一下Zig语言。放心，我们不会走的很深。

开始前，我先要说明一下，Zig是个正在快速发展的语言，随时有可能会发生大的改动，如果这一系列文章中的代码无法运行，欢迎发Issue。

## 第一印象

下面是一个最简单的Hello World程序。

```zig
const std = @import("std");

pub fn main() !void {
    std.debug.print("Hello Zig! from stderr\n", .{});
}
```

```ansi
$stdout returns nothing.
$stderr:
Hello Zig! from stderr
```

这里我们进行约定文中的代码都由两个代码块组成：第一个代码块表示被执行的程序;第二个代码块表示执行的结果。

对于执行的结果，所有由$开头的行都是我们添加的说明性文字，其他行为程序的真实输出。
以上面的结果为例，`$stdout returns nothing.`是我们添加的说明性文字，说明标准输出没有输出任何东西;`$stderr:`也是我们添加的说明性文字，表示从下一行开始为标准错误的输出。最后`Hello Zig! from stderr`是程序真正的输出。

现在对上面的代码进行说明。
第一行的`const std = @import("std");`意为引入标准库，将标准库赋值给常量`std`，让我们详细看一下各个单词。

1. `const`：声明一个常量;
2. `std`：常量的名字，符合Zig标识符的命名规则（我们会在后面讨论这个）;
3. `=`：赋值操作符;
4. `@import("std")`：引入名为"std"的库，@import()是一个内置函数(builtin function)，我们将在后面讨论这个。
5. `;`：zig语句总是以一个;为结尾。

紧跟着是`pub fn main() !void {}`，这个语句声明了一个特殊的函数main，这是一个zig可执行文件的入口。我们将在后面讨论函数的声明。

在函数体中，我们执行了`std.debug.print("Hello Zig! from stderr\n", .{});`，这个语句调用了std.debug.print()这个函数，向标准错误输出了一个字符串。

你可以创建一个名为`hello_world.zig`的文件，然后输入上面的代码内容，再通过`zig run hello_world.zig`来运行上面的代码。

你可以修改`Hello Zig! from stderr\n`，然后重新运行，看看发生了什么。

## 基础数据类型

像其他的语言一样，Zig提供了一些基础的数据类型，包括：

1. 无符号整数：ux，其中x可以是2、4、8、16、32直到65535，表示x位的无符号整数，例如u32表示32位无符号整数，这里的位表示二进制位数；
2. 有符号整数：ix，类似于无符号整数，但是能表示负数，例如i32；
3. 浮点数：fx，同理，但表示的是浮点数，例如f32；
4. 布尔值：bool，逻辑值，只有true和false两种取值，分别表示“是”和“否”；

除此之外，Zig还提供了一些特殊的类型，包括：

1. 可选值：在基础类型的前面加上?即可表示可选值，举个例子，类型为?u32的变量既可以取u32类型的合法值，也可以取null；
2. 未定义值：所有类型的变量都可以取值undefined；

## 数组

数组在 Zig 中是一种基本的数据结构，表示为固定大小的同类型元素集合。数组在定义时需要指定长度，长度在编译时就需要确定。

下面的代码定义了一个数组，并以两种形式打印：

```zig
const message = [_]u8{ 'h', 'e', 'l', 'l', 'o' };
std.debug.print("{s}\n", .{message});   // 打印为字符串
std.debug.print("{d}\n", .{message});   // 打印为数字
```

```ansi
$stdout returns nothing.
$stderr:
hello
{ 104, 101, 108, 108, 111 }
```
::: tip
事实上，Zig语言中，字符串也是以u8数组的形式存储的。
:::

## 条件语句

前面我们提到了布尔值，条件语句与布尔值息息相关。顾名思义，条件语句是用来判断一个条件的：

```zig
const a: u32 = 42;
const b: u32 = 42;
if (a > b) {
    std.debug.print("{d} is greater than {d}.\n", .{ a, b });
} else if (a == b) {
    std.debug.print("{d} equals {d}.\n", .{ a, b });
} else {
    std.debug.print("{d} is lesser than {d}.\n", .{ a, b });
}
```

```ansi
$stdout returns nothing.
$stderr:
42 equals 42.
```

这里我们看到了3个未曾见过的语句：

1. `if (a > b) {}`：最基本的条件语句，括号中的是条件，花括号中的是条件语句的“体”。当条件为true的时候，执行“体”里的语句；
2. `else if (a == b) {}`： 附加的可选的语句，只有在if语句的条件为false的时候才会执行到这，除去前面的else，其他的基本和if语句相同；`else if`可以有很多个；
3. `else {}`：另一个附加的可选的语句，只有在前面的`if`和`else if`都为false时才会执行它的“体”里的语句。

通过这些条件语句，我们可以使程序更加灵活。

## 循环语句

我们在这里简单介绍两个基础的循环语法：for循环和while循环。

### while循环

如果你有使用其他编程语言的经历，下面的代码你可能会感到熟悉：

```zig
var i: usize = 0;
while (i < 10) {
    std.debug.print("{d},", .{i});
    i += 1;
}
std.debug.print("\n", .{});
```

```ansi
$stdout returns nothing.
$stderr:
0,1,2,3,4,5,6,7,8,9,
```

我们稍微解释一下上面的语句吧。

1. `var i: usize = 0;`：声明一个名为`i`的变量，并为其赋值0;
2. `while(i < 10) {}`：当`i`小于10时，执行`{}`内的语句；
3. `std.debug.print("{d},", .{i});`：打印i；
4. `i += 1;`：等价于`i = i + 1;`，也就是将i加上1，然后赋值给i；
5. `std.debug.print("\n", .{});`：打印一个换行符；

事实上，在Zig中，我们有更方便的方法，我们可以将`i += 1`移动到一个更加神秘的地方。

```zig
var i: usize = 0;
//               看这里👇
while (i < 10) : (i += 1) {
    std.debug.print("{d},", .{i});
}
std.debug.print("\n", .{});
```

```ansi
$stdout returns nothing.
$stderr:
0,1,2,3,4,5,6,7,8,9,
```

可以看到，这两个代码段输出的结果是一样的。我们一般使用第二种。

### for循环

接下来让我们看看另一种循环——for循环。

```zig
for (0..10) |value| {
    std.debug.print("{d},", .{value});
}
std.debug.print("\n", .{});
```

```ansi
$stdout returns nothing.
$stderr:
0,1,2,3,4,5,6,7,8,9,
```

其他和while里是一样的，我们只需要看不一样的`for (0..10) |value| {}`：遍历`0..10`这个序列（包括0，但是不包括10），`value`表示当前迭代到哪一个数字。

在这里`0..10`也可以替换为数组，例如下面的示例：

```zig
const someNumbers = [_]u8{ 1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21 };
for (someNumbers) |value| {
    std.debug.print("{d},", .{value});
}
std.debug.print("\n", .{});
```

```ansi
$stdout returns nothing.
$stderr:
1,3,5,7,9,11,13,15,17,19,21,
```

在这个示例中，我们初始化了一个名为`someNumbers`的数组，并为它赋值，然后通过for循环遍历了它。

这个时候你可能会想知道正在被遍历的这个数是第几个数，Zig也有遍历的方法。

```zig
const someNumbers = [_]u8{ 1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21 };
for (someNumbers, 0..) |value, index| {
    std.debug.print("{}: {d}, ", .{ index, value });
}
std.debug.print("\n", .{});
```

```ansi
$stdout returns nothing.
$stderr:
0: 1, 1: 3, 2: 5, 3: 7, 4: 9, 5: 11, 6: 13, 7: 15, 8: 17, 9: 19, 10: 21, 
```

Voila!

我来解释一下，这里的`0..`是一个特殊的语法，它自动生成了一个从0开始的，长度与`someNumbers`相同的，元素的类型为usize的数组。

:::tip
事实上，只要长度相同，Zig的for循环语句可以同时循环多个数组，看下面的示例：
```zig
const someNumbers = [_]u8{ 1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21 };
const someEvenNumbers = [_]u8{ 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22 };
for (someNumbers, someEvenNumbers, 0..) |odd, even, index| {
    std.debug.print("{d}: {d} and {d}\n", .{ index, odd, even });
}
```

```ansi
$stdout returns nothing.
$stderr:
0: 1 and 2
1: 3 and 4
2: 5 and 6
3: 7 and 8
4: 9 and 10
5: 11 and 12
6: 13 and 14
7: 15 and 16
8: 17 and 18
9: 19 and 20
10: 21 and 22
```
这里的`someNumbers`，`someEvenNumbers`和通过`0..`生成的数组具有相同的长度，所以我们可以一起遍历它们。
:::

## 函数

让我们用前面讲的东西实现一个`函数`吧！

你可以把`函数`视作一个菜谱，每次你想吃菜的时候，只要准备好原材料（`输入`），拿出菜谱，按照菜谱做就可以得到一道好菜（`输出`）。

在下面的示例里，我们定义了一个函数，用来判断给定的数是不是质数：

```zig
/// 判断一个数是不是质数
pub fn isPrime(num: u128) bool {
    // 质数是除了1和它本身外，没有其他因数的自然数
    if (num <= 1) {
        return false;
    }
    const bound = @as(usize, @intFromFloat(@sqrt(@as(f64, @floatFromInt(num)))));
    var i: usize = 2;
    while (i <= bound) : (i += 1) {
        if (num % i == 0) {
            return false;
        }
    } else {
        return true;
    }
}
```

这里我们来看一下这几个特殊的函数：`@as`,`@intFromFloat`,`@sqrt`,`@floatFromInt`，这些函数和前面见过的`@import`一样，是编译器提供的内建函数。

这一长串的符合函数调用可能比较混乱，我们一个一个看，注意，下面的列表中，所有的`^`都表示上一个函数的结果：

1. `@floatFromInt(num)`将u128类型的num转换为一个浮点数，但这里并没有指定转换为哪种浮点数；
2. `@as(f64, ^)`明确地将上一个函数的结果转换为f64类型；
3. `@sqrt(^)`对上一个函数的结果开平方，这里的输入必须是浮点数，所以我们在前面将num转换为浮点数。Zig不会偷偷地改变你的数据的类型；
4. `@as(usize, @intFromFloat(^))`和1，2一样，不过这次是转换为usize类型的整数；

随后，我们一个数一个数试过来，看看有没有其他因数，如果有就返回false，没有就返回true。

:::tip
诶？怎么`while`语句也有`else`？

如果你使用过Python语言，可能会比较眼熟。这里的`else`会在正常退出while时被执行，也就是当`i > bound`时执行。但如果出于某种原因中间退出了，就不会执行。

下面的代码就不会执行，因为通过`break`退出循环不会出发`else`里的语句，就会导致函数没有返回值。
```zig
/// 判断一个数是不是质数
pub fn isPrime(num: u128) bool {
    // 质数是除了1和它本身外，没有其他因数的自然数
    if (num <= 1) {
        return false;
    }
    const bound = @as(usize, @intFromFloat(@sqrt(@as(f64, @floatFromInt(num)))));
    var i: usize = 2;
    while (i <= bound) : (i += 1) {
        if (num % i == 0) {
            return false;
        }
        // 👇这里会导致函数没有正确的返回值，无法通过编译器的检查
        break;
    } else {
        return true;
    }
}
```
:::

我们可以调用这个函数。

```zig
std.debug.print("{}, {}, {}, {}, {}\n", .{ isPrime(2), isPrime(3), isPrime(4), isPrime(100), isPrime(101) });
```

```ansi
$stdout returns nothing.
$stderr:
true, true, false, false, true
```

## 一个真正的Hello World

Zig语言还有一些其他特性，我们将在实现数据结构的过程中一一讨论。