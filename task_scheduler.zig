//! Small hobby project: task scheduler based on a LeetCode problem implemented
//! in Zig. Designed to handle entire range of input: avoids overflow and other
//! edge cases. All methods should have deterministic and well-defined output
//! for any input.

const std = @import("std");

/// A task represents a unit of work that has a certain profit and needs to be
/// done over a certain time interval. The profit represents the relative
/// importance of the task. The time interval is defined by its start time and
/// duration. A set of tasks can be done if for any two tasks in the set, their
/// time intervals do not overlap. The time interval of two tasks, t1 and t2,
/// do not overlap if `t1.start_time + t1.duration <= t2.start_time or
/// t2.start_time + t2.duration <= t1.start_time`.
pub const Task = struct {
    profit: u32,
    start_time: u32,
    duration: u32,

    /// Return true if two tasks overlap.
    pub fn overlap(t1: Task, t2: Task) bool {
        return if (t1.start_time < t2.start_time)
            t2.start_time - t1.start_time < t1.duration
        else if (t1.start_time > t2.start_time)
            t1.start_time - t2.start_time < t2.duration
        else
            t1.duration != 0 and t2.duration != 0;
    }

    /// Return true if two tasks overlap.
    /// Assert that `t_before.start_time <= t_after.start_time`.
    pub fn overlapOrdered(t_before: Task, t_after: Task) bool {
        std.debug.assert(t_before.start_time <= t_after.start_time);
        return t_before.overlap(t_after);
    }

    /// Given a list of tasks, find the schedule (list of non-overlapping
    /// tasks) with the maximum profit, and return the indices of the tasks in
    /// the schedule in chronological order. If multiple schedules have the
    /// same profit, pick the one with the smallest duration. If multiple
    /// schedules have the same profit and duration, pick the one with the
    /// smallest count of tasks. If multiple schedules have the same profit,
    /// duration, and task count, pick the one which is smallest when ordered
    /// lexicographically by the chronological indices.
    /// O(n*log(n)) time, O(n) additional space.
    /// On success, caller owns the returned memory.
    pub fn schedule(allocator: std.mem.Allocator, tasks: []const Task) ![]usize {
        const ScheduleResult = struct {
            profit: u64,
            duration: u64,
            len: usize,
        };

        const TaskRef = struct {
            /// index into tasks slice
            index: usize,

            /// pointer to next task in the schedule, forms a linked list
            next: ?*const @This(),

            /// result of performing this task if taken and following taken
            /// tasks
            result: ScheduleResult,

            /// whether or not this task should be taken for the optimal
            /// schedule
            taken: bool,
        };

        if (tasks.len == 0) {
            return &.{};
        }

        // dp data
        var refs = try allocator.alloc(TaskRef, tasks.len);
        defer allocator.free(refs);

        // initialize indices into tasks slice
        for (refs) |*elt, i| {
            elt.index = i;
        }

        // sort task refs by the start time of the task
        std.sort.sort(TaskRef, refs, tasks, struct {
            fn lt(ts: []const Task, lhs: TaskRef, rhs: TaskRef) bool {
                const tl = ts[lhs.index];
                const tr = ts[rhs.index];

                return if (tl.start_time != tr.start_time)
                    tl.start_time < tr.start_time
                else
                    tl.duration == 0 and tr.duration != 0;
            }
        }.lt);

        // calculate result of chronologically last task ref
        const last_ref = &refs[refs.len - 1];
        last_ref.next = null;
        if (tasks[last_ref.index].profit != 0) {
            last_ref.result.profit = tasks[last_ref.index].profit;
            last_ref.result.duration = tasks[last_ref.index].duration;
            last_ref.result.len = 1;
            last_ref.taken = true;
        } else {
            last_ref.result.profit = 0;
            last_ref.result.duration = 0;
            last_ref.result.len = 0;
            last_ref.taken = false;
        }

        // calculate result of tasks refs in reverse chronological order
        var i: usize = 1;
        while (i < refs.len) : (i += 1) {
            // curr task is `ref`, remaining tasks is `first_ref`..`last_ref`
            const ref = &refs[refs.len - i - 1];
            const first_ref = &refs[refs.len - i];

            // fast path for zero-profit tasks
            if (tasks[ref.index].profit == 0) {
                ref.next = first_ref;
                ref.result = first_ref.result;
                ref.taken = false;
                continue;
            }

            // binary search for earliest task that succeeds the current one
            const next_ref = blk: {
                if (tasks[ref.index].overlapOrdered(tasks[last_ref.index])) {
                    break :blk null;
                } else if (!tasks[ref.index].overlapOrdered(tasks[first_ref.index])) {
                    break :blk first_ref;
                } else {
                    var low = refs.len - i;
                    var high = refs.len - 1;
                    while (high - low > 1) {
                        const mid = low + (high - low) / 2;
                        if (tasks[ref.index].overlapOrdered(tasks[refs[mid].index])) {
                            low = mid;
                        } else {
                            high = mid;
                        }
                    }
                    break :blk &refs[high];
                }
            };

            // the result of taking the curr task, calculated using the
            // earliest next task if it exists
            const take_result: ScheduleResult = if (next_ref) |n| .{
                .profit = tasks[ref.index].profit + n.result.profit,
                .duration = tasks[ref.index].duration + n.result.duration,
                .len = 1 + n.result.len,
            } else .{
                .profit = tasks[ref.index].profit,
                .duration = tasks[ref.index].duration,
                .len = 1,
            };

            // whether the curr task should be taken or skipped
            const should_take = if (take_result.profit != first_ref.result.profit)
                take_result.profit > first_ref.result.profit
            else if (take_result.duration != first_ref.result.duration)
                take_result.duration < first_ref.result.duration
            else
                take_result.len <= first_ref.result.len;

            // if the task should be taken, set `taken` to true and initialize
            // the next task reference
            if (should_take) {
                ref.next = next_ref;
                ref.result = take_result;
                ref.taken = true;
            } else {
                ref.next = first_ref;
                ref.result = first_ref.result;
                ref.taken = false;
            }
        }

        // build the result in an ArrayList
        var list = try std.ArrayList(usize).initCapacity(allocator, refs[0].result.len);
        defer list.deinit();

        // traverse the linked list starting from the first task, adding tasks
        // that are marked as taken
        var cur_ref: ?*const TaskRef = &refs[0];
        while (cur_ref) |ref| : (cur_ref = ref.next) {
            if (ref.taken) {
                list.appendAssumeCapacity(ref.index);
            }
        }

        return list.toOwnedSlice();
    }
};

comptime {
    _ = tests;
}

const tests = struct {
    fn expectOverlapResult(
        comptime N: usize,
        expected: *const [N][N]bool,
        tasks: *const [N]Task,
    ) !void {
        for (tasks) |t1, i| {
            for (tasks) |t2, j| {
                try std.testing.expectEqual(expected[i][j], t1.overlap(t2));
            }
        }
    }

    fn expectScheduleResult(
        comptime N: usize,
        expected: []const usize,
        tasks: *const [N]Task,
    ) !void {
        const actual = try Task.schedule(std.testing.allocator, tasks);
        defer std.testing.allocator.free(actual);

        try std.testing.expectEqualSlices(usize, expected, actual);
    }

    test "Task.overlap basic behavior" {
        const tasks = &.{
            .{ .start_time = 30, .duration = 20, .profit = 15 },
            .{ .start_time = 40, .duration = 30, .profit = 25 },
            .{ .start_time = 60, .duration = 10, .profit = 20 },
            .{ .start_time = 65, .duration = 0, .profit = 30 },
        };

        const expected = &.{
            .{ true, true, false, false },
            .{ true, true, true, true },
            .{ false, true, true, true },
            .{ false, true, true, false },
        };

        try expectOverlapResult(4, expected, tasks);
    }

    test "Task.overlap kissing tasks do not overlap" {
        const tasks = &.{
            .{ .start_time = 5, .duration = 5, .profit = 15 },
            .{ .start_time = 10, .duration = 0, .profit = 15 },
            .{ .start_time = 10, .duration = 5, .profit = 15 },
        };

        const expected = &.{
            .{ true, false, false },
            .{ false, false, false },
            .{ false, false, true },
        };

        try expectOverlapResult(3, expected, tasks);
    }

    test "Task.overlap does not overflow" {
        const tasks = &.{
            .{ .start_time = 4294967295, .duration = 1000, .profit = 4294967295 },
            .{ .start_time = 2147483648, .duration = 4294967295, .profit = 4294967295 },
            .{ .start_time = 2147483648, .duration = 2147483647, .profit = 2147483648 },
            .{ .start_time = 100, .duration = 4294967295, .profit = 4294967295 },
            .{ .start_time = 4294967295, .duration = 0, .profit = 2147483648 },
            .{ .start_time = 0, .duration = 0, .profit = 4294967295 },
        };

        const expected = &.{
            .{ true, true, false, true, false, false },
            .{ true, true, true, true, true, false },
            .{ false, true, true, true, false, false },
            .{ true, true, true, true, true, false },
            .{ false, true, false, true, false, false },
            .{ false, false, false, false, false, false },
        };

        try expectOverlapResult(6, expected, tasks);
    }

    test "Task.schedule works for no tasks" {
        try expectScheduleResult(0, &.{}, &.{});
    }

    test "Task.schedule finds most profitable schedule" {
        const tasks = &.{
            .{ .start_time = 10, .duration = 60, .profit = 450 },
            .{ .start_time = 45, .duration = 20, .profit = 200 },
            .{ .start_time = 40, .duration = 25, .profit = 300 },
            .{ .start_time = 30, .duration = 15, .profit = 250 },
            .{ .start_time = 80, .duration = 10, .profit = 50 },
            .{ .start_time = 20, .duration = 20, .profit = 200 },
        };

        try expectScheduleResult(6, &.{ 5, 2, 4 }, tasks);
    }

    test "Task.schedule finds least duration when multiple have max profit" {
        const tasks = &.{
            .{ .start_time = 40, .duration = 20, .profit = 50 },
            .{ .start_time = 100, .duration = 15, .profit = 50 },
            .{ .start_time = 85, .duration = 15, .profit = 50 },
            .{ .start_time = 20, .duration = 20, .profit = 50 },
            .{ .start_time = 15, .duration = 45, .profit = 100 },
            .{ .start_time = 80, .duration = 25, .profit = 100 },
        };

        try expectScheduleResult(6, &.{ 3, 0, 5 }, tasks);
    }

    test "Task.schedule finds least count when multiple have max profit and same duration" {
        const tasks = &.{
            .{ .start_time = 60, .duration = 20, .profit = 20 },
            .{ .start_time = 20, .duration = 70, .profit = 60 },
            .{ .start_time = 40, .duration = 20, .profit = 20 },
            .{ .start_time = 20, .duration = 30, .profit = 30 },
            .{ .start_time = 20, .duration = 20, .profit = 20 },
            .{ .start_time = 50, .duration = 30, .profit = 30 },
        };

        try expectScheduleResult(6, &.{ 3, 5 }, tasks);
    }

    test "Task.schedule with zero duration tasks" {
        const tasks = &.{
            .{ .start_time = 15, .duration = 0, .profit = 10 },
            .{ .start_time = 35, .duration = 20, .profit = 10 },
            .{ .start_time = 30, .duration = 0, .profit = 30 },
            .{ .start_time = 25, .duration = 10, .profit = 25 },
            .{ .start_time = 15, .duration = 20, .profit = 10 },
            .{ .start_time = 10, .duration = 5, .profit = 10 },
        };

        try expectScheduleResult(6, &.{ 5, 0, 2, 1 }, tasks);
    }

    test "Task.schedule zero duration mania" {
        const tasks = &.{
            .{ .start_time = 30, .duration = 0, .profit = 10 },
            .{ .start_time = 20, .duration = 0, .profit = 10 },
            .{ .start_time = 30, .duration = 0, .profit = 10 },
            .{ .start_time = 20, .duration = 10, .profit = 10 },
            .{ .start_time = 40, .duration = 0, .profit = 10 },
            .{ .start_time = 20, .duration = 0, .profit = 10 },
        };

        try expectScheduleResult(6, &.{ 1, 5, 3, 0, 2, 4 }, tasks);
    }

    test "Task.schedule does not overflow" {
        const tasks = &.{
            .{ .start_time = 4294967295, .duration = 1000, .profit = 100 },
            .{ .start_time = 0, .duration = 0, .profit = 100 },
            .{ .start_time = 100, .duration = 4294967295, .profit = 100 },
            .{ .start_time = 4294967295, .duration = 0, .profit = 100 },
            .{ .start_time = 2147483648, .duration = 2147483647, .profit = 100 },
            .{ .start_time = 2147483648, .duration = 4294967295, .profit = 100 },
        };

        try expectScheduleResult(6, &.{ 1, 4, 3, 0 }, tasks);
    }

    test "Task.schedule with zero profit tasks" {
        const tasks = &.{
            .{ .start_time = 30, .duration = 10, .profit = 0 },
            .{ .start_time = 20, .duration = 10, .profit = 75 },
            .{ .start_time = 10, .duration = 10, .profit = 75 },
            .{ .start_time = 40, .duration = 10, .profit = 75 },
        };

        try expectScheduleResult(4, &.{ 2, 1, 3 }, tasks);
    }

    test "Task.schedule zeroes" {
        const tasks = &.{
            .{ .start_time = 0, .duration = 0, .profit = 0 },
            .{ .start_time = 0, .duration = 0, .profit = 0 },
            .{ .start_time = 0, .duration = 0, .profit = 0 },
        };

        try expectScheduleResult(3, &.{}, tasks);
    }

    test "Task.schedule first overlaps best: fix #1" {
        const tasks = &.{
            .{ .start_time = 30, .duration = 30, .profit = 60 },
            .{ .start_time = 0, .duration = 100, .profit = 100 },
            .{ .start_time = 10, .duration = 20, .profit = 60 },
        };

        try expectScheduleResult(3, &.{ 2, 0 }, tasks);
    }

    test "Task.schedule with zero duration tasks: fix #2" {
        const tasks = &.{
            .{ .start_time = 10, .duration = 10, .profit = 100 },
            .{ .start_time = 10, .duration = 0, .profit = 100 },
        };

        try expectScheduleResult(2, &.{ 1, 0 }, tasks);
    }
};
