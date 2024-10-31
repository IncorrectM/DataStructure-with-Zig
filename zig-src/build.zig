// Copyright (c) Ziglings - 2024
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
// Based on code from Ziglings under MIT License, modified by Zhihao Zhu.

const std = @import("std");
const print = std.debug.print;

const Chapter = struct {
    num: usize,
    filename: []const u8,

    /// Returns the name of the main file with .zig stripped.
    pub fn name(self: Chapter) []const u8 {
        return std.fs.path.stem(self.filename);
    }
};

const chapters = [_]Chapter{
    Chapter{
        .num = 0,
        .filename = "00_introduction.zig",
    },
    Chapter{
        .num = 1,
        .filename = "01_zig_basics.zig",
    },
    Chapter{
        .num = 2,
        .filename = "02_array.zig",
    },
    Chapter{
        .num = 3,
        .filename = "03_linked_list.zig",
    },
    Chapter{
        .num = 4,
        .filename = "04_stack.zig",
    },
    Chapter{
        .num = 5,
        .filename = "05_queue.zig",
    },
    Chapter{
        .num = 6,
        .filename = "06_hash_table.zig",
    },
};

pub fn build(b: *std.Build) void {
    // remove default behaviour
    b.top_level_steps = .{};

    // create compiler options
    const chapno = b.option(usize, "chapter", "Select which chapter's code to execute.");
    if (chapno) |n| {
        if (n >= chapters.len) {
            print("Unkown chapter num {d}.\n", .{n});
            std.process.exit(2);
        }
        const chapter = chapters[n];
        const chapter_step = b.step("chap", b.fmt(
            "Run code in chapter {d} in file {s}.",
            .{ n, chapter.filename },
        ));
        b.default_step = chapter_step;

        const run_step = DSwZStep.create(b, chapter, "src");
        chapter_step.dependOn(&run_step.step);

        return;
    }
}

// DSwZStep is based on ZiglingStep from
// https://codeberg.org/ziglings/exercises/src/branch/main/build.zig#L271
const Step = std.Build.Step;
const DSwZStep = struct {
    step: Step,
    chapter: Chapter,
    work_path: []const u8,

    pub fn create(
        b: *std.Build,
        chapter: Chapter,
        work_path: []const u8,
    ) *DSwZStep {
        const self = b.allocator.create(DSwZStep) catch @panic("OOM");
        self.* = .{
            .step = Step.init(.{
                .id = .custom,
                .name = chapter.filename,
                .owner = b,
                .makeFn = make,
            }),
            .chapter = chapter,
            .work_path = work_path,
        };
        return self;
    }

    fn make(step: *Step, options: Step.MakeOptions) !void {
        // NOTE: Using exit code 2 will prevent the Zig compiler to print the message:
        // "error: the following build command failed with exit code 1:..."
        const self: *DSwZStep = @alignCast(@fieldParentPtr("step", step));

        const exe_path = self.compile(options.progress_node) catch {
            self.printErrors();
            std.process.exit(2);
        };

        self.run(exe_path, options.progress_node) catch {
            self.printErrors();
            std.process.exit(2);
        };

        // Print possible warning/debug messages.
        self.printErrors();
    }

    fn run(self: *DSwZStep, exe_path: []const u8, _: std.Progress.Node) !void {
        print("$Running: {s}\n", .{self.chapter.filename});

        const b = self.step.owner;

        // Allow up to 1 MB of stdout capture.
        const max_output_bytes = 1 * 1024 * 1024;

        const result = std.process.Child.run(.{
            .allocator = b.allocator,
            .argv = &.{exe_path},
            .cwd = b.build_root.path.?,
            .cwd_dir = b.build_root.handle,
            .max_output_bytes = max_output_bytes,
        }) catch |err| {
            return self.step.fail("unable to spawn {s}: {s}", .{
                exe_path, @errorName(err),
            });
        };
        if (result.stdout.len != 0) {
            print("$stdout:\n{s}\n$stderr:\n{s}\n", .{ result.stdout, result.stderr });
        } else {
            print("$stdout returns nothing.\n", .{});
        }
        if (result.stderr.len != 0) {
            print("$stderr:\n{s}\n", .{result.stderr});
        } else {
            print("$stderr returns nothing.\n", .{});
        }
    }

    fn compile(self: *DSwZStep, prog_node: std.Progress.Node) ![]const u8 {
        print("$Compiling: {s}\n", .{self.chapter.filename});

        const b = self.step.owner;
        const code_path = self.chapter.filename;
        const path = std.fs.path.join(b.allocator, &.{ self.work_path, code_path }) catch
            @panic("OOM");

        var zig_args = std.ArrayList([]const u8).init(b.allocator);
        defer zig_args.deinit();

        zig_args.append(b.graph.zig_exe) catch @panic("OOM");

        zig_args.append("build-exe") catch @panic("OOM");

        zig_args.append(b.pathFromRoot(path)) catch @panic("OOM");
        zig_args.append("--cache-dir") catch @panic("OOM");
        zig_args.append(b.pathFromRoot(b.cache_root.path.?)) catch @panic("OOM");
        zig_args.append("--listen=-") catch @panic("OOM");

        //
        // NOTE: After many changes in zig build system, we need to create the cache path manually.
        // See https://github.com/ziglang/zig/pull/21115
        // Maybe there is a better way (in the future).
        const exe_dir = try self.step.evalZigProcess(zig_args.items, prog_node, false);
        const exe_name = self.chapter.name();
        const sep = std.fs.path.sep_str;
        const root_path = exe_dir.?.root_dir.path.?;
        const sub_path = exe_dir.?.subPathOrDot();
        const exe_path = b.fmt("{s}{s}{s}{s}{s}", .{ root_path, sep, sub_path, sep, exe_name });

        return exe_path;
    }

    fn printErrors(self: *DSwZStep) void {
        // Display error/warning messages.
        if (self.step.result_error_msgs.items.len > 0) {
            for (self.step.result_error_msgs.items) |msg| {
                print("error: {s}\n", .{msg});
            }
        }

        // Render compile errors at the bottom of the terminal.
        // TODO: use the same ttyconf from the builder.
        const ttyconf: std.io.tty.Config = .escape_codes;
        if (self.step.result_error_bundle.errorMessageCount() > 0) {
            self.step.result_error_bundle.renderToStdErr(.{ .ttyconf = ttyconf });
        }
    }
};

// https://codeberg.org/ziglings/exercises/src/branch/main/build.zig#L525
/// Removes trailing whitespace for each line in buf, also ensuring that there
/// are no trailing LF characters at the end.
pub fn trimLines(allocator: std.mem.Allocator, buf: []const u8) ![]const u8 {
    var list = try std.ArrayList(u8).initCapacity(allocator, buf.len);

    var iter = std.mem.splitSequence(u8, buf, " \n");
    while (iter.next()) |line| {
        // TODO: trimming CR characters is probably not necessary.
        const data = std.mem.trimRight(u8, line, " \r");
        try list.appendSlice(data);
        try list.append('\n');
    }

    const result = try list.toOwnedSlice(); // TODO: probably not necessary

    // Remove the trailing LF character, that is always present in the exercise
    // output.
    return std.mem.trimRight(u8, result, "\n");
}
