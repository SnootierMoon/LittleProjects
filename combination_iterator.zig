const std = @import("std");

pub const BitSet = std.bit_set.IntegerBitSet;

/// Order two bitsets firstly by the number of 1 bits, and by value if equal.
pub fn order(comptime n: u16, x: BitSet(n), y: BitSet(n)) std.math.Order {
    return switch (std.math.order(x.count(), y.count())) {
        .eq => std.math.order(x.mask, y.mask),
        else => |o| o,
    };
}

/// Iterator that yields bitsets least-to-greatest ordered firstly by the
/// number of 1 bits, and second by integer value.
pub fn BitCombinationIterator(comptime n: u16) type {
    return struct {
        bitset: ?BitSet(n) = BitSet(n).initEmpty(),

        pub fn next(self: *@This()) ?BitSet(n) {
            var ret = self.bitset;
            if (self.bitset) |*bitset| {
                var i: usize = 1;
                var b: usize = 0;
                while (i < n) : (i += 1) {
                    var last = bitset.isSet(i - 1);
                    var curr = bitset.isSet(i);

                    if (last and !curr) {
                        bitset.set(i);
                        bitset.setRangeValue(.{ .start = 0, .end = b }, true);
                        bitset.setRangeValue(.{ .start = b, .end = i }, false);
                        break;
                    } else if (last) {
                        b += 1;
                    }
                } else {
                    var c = bitset.count();

                    if (c == n) {
                        self.bitset = null;
                    } else {
                        bitset.setRangeValue(.{ .start = 0, .end = c + 1 }, true);
                        bitset.setRangeValue(.{ .start = c + 1, .end = n }, false);
                    }
                }
            }
            return ret;
        }
    };
}

test "order" {
    const test_cases = .{
        .{ 2, 0b10, 0b01, .gt },
        .{ 2, 0b01, 0b11, .lt },
        .{ 3, 0b011, 0b100, .gt },
        .{ 3, 0b010, 0b010, .eq },
        .{ 5, 0b01101, 0b10101, .lt },
        .{ 5, 0b11011, 0b10111, .gt },
    };
    inline for (test_cases) |test_case| {
        const n = test_case.@"0";
        const lhs = BitSet(n){ .mask = test_case.@"1" };
        const rhs = BitSet(n){ .mask = test_case.@"2" };
        const expected = @as(std.math.Order, test_case.@"3");
        try std.testing.expectEqual(expected, order(n, lhs, rhs));
    }
}

test "each elt greater than all previous elts" {
    inline for (.{ 0, 1, 6, 12, 20, 25 }) |n| {
        var it = BitCombinationIterator(n){};
        if (it.next()) |first| {
            var count: u64 = 1;
            var prev = first;
            while (it.next()) |current| {
                // Each element should be greater than the last
                try std.testing.expectEqual(std.math.Order.gt, order(n, current, prev));
                prev = current;
                count += 1;
            }
            // the count of elements should be 2^n
            try std.testing.expectEqual(@as(u64, 1 << n), count);
        } else {
            try std.testing.expectEqual(0, n);
        }
    }
}
