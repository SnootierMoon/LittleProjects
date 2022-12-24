const std = @import("std");

const BinaryOpKind = enum {
    @"or",
    @"and",

    fn apply(self: BinaryOpKind, lhs: bool, rhs: bool) bool {
        return switch (self) {
            .@"or" => lhs or rhs,
            .@"and" => lhs and rhs,
        };
    }
};

const BinaryOpNode = struct {
    kind: BinaryOpKind,
    lhs: *AstNode,
    rhs: *AstNode,
};

const TerminalNode = enum {
    zero,
    one,

    fn eval(self: TerminalNode) bool {
        return self == .one;
    }
};

const ParseContext = struct {
    allocator: std.mem.Allocator,
    pos: usize,
    buf: []const u8,

    fn next(self: *ParseContext) ?u8 {
        if (self.pos < self.buf.len) {
            defer self.pos += 1;
            return self.buf[self.pos];
        } else {
            return null;
        }
    }
};

const AstNode = union(enum) {
    binary_op: BinaryOpNode,
    terminal: TerminalNode,

    const ParseError = std.mem.Allocator.Error || error{InvalidExpression};

    fn parse(allocator: std.mem.Allocator, expression: []const u8) ParseError!*AstNode {
        var ctx = ParseContext{ .allocator = allocator, .pos = 0, .buf = expression };
        return try parse_expr(&ctx, .eol);
    }

    fn parse_expr(ctx: *ParseContext, comptime end_condition: enum { eol, paren }) ParseError!*AstNode {
        var current = try parse_atom(ctx);
        while (ctx.next()) |c| {
            switch (c) {
                '&' => {
                    var new_current = try ctx.allocator.create(AstNode);
                    new_current.* = .{ .binary_op = .{
                        .kind = .@"and",
                        .lhs = current,
                        .rhs = try parse_atom(ctx),
                    } };
                    current = new_current;
                },
                '|' => {
                    var new_current = try ctx.allocator.create(AstNode);
                    new_current.* = .{ .binary_op = .{
                        .kind = .@"or",
                        .lhs = current,
                        .rhs = try parse_atom(ctx),
                    } };
                    current = new_current;
                },
                ')' => {
                    return if (end_condition == .paren) current else error.InvalidExpression;
                },
                else => return error.InvalidExpression,
            }
        }

        return if (end_condition == .eol) current else error.InvalidExpression;
    }

    fn parse_atom(ctx: *ParseContext) ParseError!*AstNode {
        if (ctx.next()) |c| {
            switch (c) {
                '0' => {
                    var node = try ctx.allocator.create(AstNode);
                    node.* = .{ .terminal = .zero };
                    return node;
                },
                '1' => {
                    var node = try ctx.allocator.create(AstNode);
                    node.* = .{ .terminal = .one };
                    return node;
                },
                '(' => {
                    return try parse_expr(ctx, .paren);
                },
                else => return error.InvalidExpression,
            }
        } else {
            return error.InvalidExpression;
        }
    }

    fn evaluate_cost(node: *AstNode) struct { eval: bool, cost: usize } {
        switch (node.*) {
            .terminal => |t| return .{ .eval = t.eval(), .cost = 1 },
            .binary_op => |op| {
                const lhs = op.lhs.evaluate_cost();
                const rhs = op.rhs.evaluate_cost();

                const eval = op.kind.apply(lhs.eval, rhs.eval);
                const cost = if (lhs.eval != rhs.eval)
                    1
                else if (lhs.eval and op.kind == .@"and" or !lhs.eval and op.kind == .@"or")
                    @min(lhs.cost, rhs.cost)
                else
                    1 + @min(lhs.cost, rhs.cost);

                return .{ .eval = eval, .cost = cost };
            },
        }
    }
};

fn min_operations_to_flip(allocator: std.mem.Allocator, expression: []const u8) AstNode.ParseError!usize {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    const root_node = try AstNode.parse(arena.allocator(), expression);
    const eval_cost = root_node.evaluate_cost();

    return eval_cost.cost;
}

fn testCase(expected: usize, expression: []const u8) !void {
    const actual = try min_operations_to_flip(std.testing.allocator, expression);
    try std.testing.expectEqual(expected, actual);
}

test "Basic LeetCode tests" {
    try testCase(1, "1&(0|1)");
    try testCase(3, "(0&0)&(0&0&0)");
    try testCase(1, "(0|(1|0&1))");
    try testCase(3, "((0&(0&0)&(0|(0)&1&0)))");
    try testCase(1, std.mem.trim(u8, @embedFile("min_op_flip/big_test_case"), &std.ascii.whitespace));
}
