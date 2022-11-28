const std = @import("std");
const BitCombinationIterator = @import("combination_iterator.zig").BitCombinationIterator;

pub fn Booleanomial(comptime n: u16) type {
    const Int = std.meta.Int(.unsigned, n);
    const N = 1 << n;
    return struct {
        const Self = @This();

        coeffs: [N]i32,

        pub fn init_false() Self {
            return Self{
                .coeffs = [1]i32{0} ** N,
            };
        }

        pub fn init_true() Self {
            var ret = init_false();
            ret.coeffs[0] = 1;
            return ret;
        }

        pub fn init(comptime z: u16) Self {
            comptime std.debug.assert(z < n);
            var ret = init_false();
            ret.coeffs[1 << z] = 1;
            return ret;
        }

        fn mul(self: Self, other: Self) Self {
            var ret = init_false();
            var x: Int = 0;
            while (true) : (x += 1) {
                var y: Int = 0;
                while (true) : (y += 1) {
                    ret.coeffs[x | y] += self.coeffs[x] * other.coeffs[y];
                    if (y == N - 1) {
                        break;
                    }
                }
                if (x == N - 1) {
                    break;
                }
            }
            return ret;
        }

        pub fn logicalNot(self: Self) Self {
            var ret = init_false();
            ret.coeffs[0] = 1 - self.coeffs[0];
            var x: Int = 1;
            while (true) : (x += 1) {
                ret.coeffs[x] = -self.coeffs[x];
                if (x == N - 1) {
                    break;
                }
            }
            return ret;
        }

        pub fn logicalAnd(self: Self, other: Self) Self {
            return self.mul(other);
        }

        pub fn logicalOr(self: Self, other: Self) Self {
            var ret = self.mul(other);
            var x: Int = 0;
            while (true) : (x += 1) {
                ret.coeffs[x] = -ret.coeffs[x] + self.coeffs[x] + other.coeffs[x];
                if (x == N - 1) {
                    break;
                }
            }
            return ret;
        }

        pub fn logicalXor(self: Self, other: Self) Self {
            var ret = self.mul(other);
            var x: Int = 0;
            while (true) : (x += 1) {
                ret.coeffs[x] = -2 * ret.coeffs[x] + self.coeffs[x] + other.coeffs[x];
                if (x == N - 1) {
                    break;
                }
            }
            return ret;
        }

        pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
            _ = options;
            comptime std.debug.assert(fmt.len == n);
            var iter = BitCombinationIterator(n){};
            var leading = true;

            while (iter.next()) |bitset| {
                var c = self.coeffs[bitset.mask];

                if (c == 0) {
                    continue;
                }

                var mag = std.math.absInt(c) catch unreachable;
                if (c < 0) {
                    if (leading) {
                        try writer.print("-", .{});
                    } else {
                        try writer.print(" - ", .{});
                    }
                } else if (!leading) {
                    try writer.print(" + ", .{});
                }
                if (mag != 1 or bitset.mask == 0) {
                    try writer.print("{}", .{mag});
                }
                leading = false;

                var x: usize = 0;
                while (x < n) : (x += 1) {
                    if (bitset.isSet(x)) {
                        try writer.print("{c}", .{fmt[x]});
                    }
                }
            }

            if (leading) {
                try writer.print("0", .{});
            }
        }
    };
}
