# 关于DSwZ

## 动机

在我的学习经验里，动手是掌握一个新技术比较快的方法。

这个项目是我在学习Zig的过程中的突发奇想，希望通过实现数据结构的方式加深对Zig语言的认识。

也希望能帮到你🥰🥰🥰。

## 内容简介

你可以完全不知道Zig是什么，也可以不熟悉数据结构。我们希望能在你打开新世界大门的过程中帮助你。

如果你熟悉Zig或数据结构，也欢迎你来和我们相互交流，帮助我们做出改进。

我们将分为数个章节来实现一些常见的数据结构，我们将尽可能的避免使用标准库中提供的实现。

目前，我们希望实现的数据结构包括：

1. 变长数组（或者说列表）
2. 链表
3. 栈
4. 队列
5. 哈希表

在这之前，我们也会简单的介绍如何使用Zig语言进行编程。

让我们从安装开始吧！

## 安装Zig

在[这个页面](https://ziglang.org/download/)下载你对应平台的压缩包，解压到合适的位置。

将解压出来的`zig`文件（Windows上应该是`zig.exe`）所在的文件夹的绝对地址添加的环境变量`Path`中。

### Windows

用管理员权限打开PowerShell,执行下面的命令：

```powershell
[Environment]::SetEnvironmentVariable(
   "Path",
   [Environment]::GetEnvironmentVariable("Path", "Machine") + ";绝对地址",
   "Machine"
)
```

然后重启终端。

### Linux, MacOS

打开终端，在你的shell的配置文件（比如.zshrc）中添加下面的一行：

```zsh
export PATH=$PATH:绝对地址
```

然后重启终端即可。

现在，在终端中输入`zig -h`,如果正确输出了帮助信息，就说明安装成功了，恭喜🎉🎉🎉。

## 安装还有问题？

可以访问[这个页面](https://ziglang.org/learn/getting-started/)查看更加详细的安装指南，如果你更喜欢中文的指南，可以访问[这个页面](https://ziglang.org/zh-CN/learn/getting-started/)。

打起精神，接下来我们简单认识一下如何使用Zig编写程序吧！
