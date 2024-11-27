# About DSwZ

## Motivation

From my learning experiences, hands-on practice is the faster way to master a new technology.

This project sprouted from a sudden inspiration during my journey of learning Zig. I aimed to deepen my understanding of the Zig language by implementing data structures.

And I hope it can help you out too🥰🥰🥰.

## Overview

You might be completely clueless about what Zig is or unfamiliar with data structures, and that’s perfectly fine. We aspire to assist you in opening the door to a new world.

If you're already familiar with Zig or data structures, we warmly welcome your participation to exchange ideas and help us improve.

We will divide our exploration into several chapters, each dedicated to implementing common data structures, striving to avoid using the implementations provided by the standard library as much as possible.

For now, the data structures we aim to implement include:

- Dynamic Arrays (or Lists)

- Linked Lists

- Stacks

- Queues

- Hash Tables

Before diving in, we'll also give a brief introduction on how to program using the Zig language.

Let's start with installation!

## Installing Zig

Head over to [this page](https://ziglang.org/download/) to download the compressed package for your platform and extract it to a suitable location.

Add the absolute path of the folder containing the extracted `zig` file (or `zig.exe` on Windows) to the `Path` environment variable.

### Windows

Open PowerShell as an administrator and execute the following command:

```powershell
[Environment]::SetEnvironmentVariable(
   "Path",
   [Environment]::GetEnvironmentVariable("Path", "Machine") + ";绝对地址",
   "Machine"
)
```

Then, restart your terminal.

### Linux, MacOS

Open your terminal and add the following line to your shell configuration file (e.g., `.zshrc`):

```zsh
export PATH=$PATH:absolute path
```

Remember to replace `absolute path` with your path.

Afterwards, just restart your terminal.

Now, type `zig -` in your terminal. If it prints out the help information correctly, congratulations 🎉🎉🎉, you've successfully installed Zig.

## Still Having Installation Issues?

Feel free to visit [this apge](https://ziglang.org/learn/getting-started/)for a more detailed installation guide.

Buckle up, it's time to get a quick glimpse of how to write programs using Zig!
