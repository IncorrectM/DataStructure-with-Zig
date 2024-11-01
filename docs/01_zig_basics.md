# Zig 基础

我们先来简要的认识一下Zig语言。放心，我们不会走的很深。

## 第一印象

下面是一个最简单的`Hello World`程序。

```zig
const std = @import("std");

pub fn main() !void {
    std.debug.print("Hello Zig! from stderr\n", .{});
}
```

```shell
$stdout returns nothing.
$stderr:
Hello Zig! from stderr
```

这里我们进行约定文中的代码都由两个代码块组成：第一个代码块表示被执行的程序;第二个代码块表示执行的结果。

对于执行的结果，所有由`$`开头的行都是我们添加的说明性文字，其他行为程序的真实输出。
以上面的结果为例，`$stdout returns nothing.`是我们添加的说明性文字，说明标准输出没有输出任何东西;`$stderr:`也是我们添加的说明性文字，表示从下一行开始为标准错误的输出。最后`Hello Zig! from stderr`是程序真正的输出。

现在对上面的代码进行说明。
第一行的`const std = @import("std");`意为引入标准库，将标准库赋值给常量std，让我们详细看一下各个单词。

1. `const`：声明一个常量;
2. `std`：常量的名字，符合Zig标识符的命名规则（我们会在后面讨论这个）;
3. `=`：赋值操作符;
4. `@import("std")`：引入名为"std"的库，`@import()`是一个内置函数(builtin function)，我们将在后面讨论这个。
5. `;`：zig语句总是以一个`;`为结尾。

紧跟着是`pub fn main() !void {}`，这个语句声明了一个特殊的函数main，这是一个zig可执行文件的入口。我们将在后面讨论函数的声明。

在函数体中，我们执行了`std.debug.print("Hello Zig! from stderr\n", .{});`，这个语句调用了`std.debug.print()`这个函数，向标准错误输出了一个字符串。

你可以创建一个名为`hello_world.zig`的文件，然后输入上面的代码内容，在通过`zig run hello_world.zig`来运行上面的代码。

你可以修改`Hello Zig! from stderr\n`，然后重新运行，看看发生了什么。

## 基础数据类型

## 数组

## 条件语句

## 循环语句

## 函数

## 一个真正的Hello World
