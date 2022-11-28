const std = @import("std");

const stdin = std.io.getStdIn();
const stdout = std.io.getStdOut();

pub fn maxAtomicNumberWithOrbitalNames(orbital_names: []const []const u8) u32 {
    return @intCast(u32, (4 * orbital_names.len * (orbital_names.len + 1) * (2 * orbital_names.len + 1)) / 6);
}

pub fn printElectronConfigWithOrbitalNames(orbital_names: []const []const u8, writer: anytype, atomic_number: u32) !void {
    if (atomic_number > maxAtomicNumberWithOrbitalNames(orbital_names)) {
        return error.AtomicNumberOutOfRange;
    }
    const element = data.elements[if (atomic_number < data.elements.len) atomic_number else 0];
    try writer.print("{} {s} ({s}): ", .{ atomic_number, element.name, element.symbol });
    if (atomic_number <= 2) {
        try writer.print("1{s}{}\n", .{ orbital_names[0], atomic_number });
        try writer.print("    (1, 0, 0, {c}1/2)\n", .{if (atomic_number & 1 == 0) @as(u8, '-') else @as(u8, '+')});
    } else {
        try writer.print("1{s}2", .{orbital_names[0]});
        var remaining_electrons = atomic_number - 2;
        var principal = @as(u32, 2);
        var orbital = @as(u32, 0);
        while (true) {
            const electron_count = 4 * orbital + 2;
            if (remaining_electrons <= electron_count) {
                try writer.print(" {}{s}{}", .{ principal, orbital_names[orbital], remaining_electrons });
                break;
            }
            try writer.print(" {}{s}{}", .{ principal, orbital_names[orbital], electron_count });
            remaining_electrons -= electron_count;
            if (orbital == 0) {
                orbital += principal / 2;
                principal -= (principal / 2) - 1;
            } else if (orbital == 1) {
                orbital = 0;
                principal += 1;
            } else {
                orbital -= 1;
                principal += 1;
            }
        }
        try writer.print("\n", .{});
        try writer.print("    ({}, {}, {}, {c}1/2)\n", .{
            principal,
            orbital,
            @divFloor(@as(i64, remaining_electrons) - 1, 2) - @as(i64, orbital),
            if (atomic_number & 1 == 0) @as(u8, '-') else @as(u8, '+'),
        });
    }
}

pub fn maxAtomicNumber() usize {
    return maxAtomicNumberWithOrbitalNames(&data.orbital_names);
}

pub fn printElectronConfig(writer: anytype, atomic_number: u32) !void {
    return printElectronConfigWithOrbitalNames(&data.orbital_names, writer, atomic_number);
}

fn parseAtomicNumber(buf: []const u8) !u32 {
    const x = try std.fmt.parseInt(u32, buf, 10);
    return if (x == 0) error.ZeroNotAllowed else x;
}

pub fn printUsage(writer: anytype, arg0: []const u8) !void {
    try writer.print("Usage \"{s} <atomic num> [atomic nums...]\" or \"{s}\" for interactive mode.\n", .{ arg0, arg0 });
}

pub fn runInteractively(allocator: std.mem.Allocator) !void {
    const reader = stdin.reader();
    const writer = stdout.writer();
    var error_times = @as(u32, 0);
    try writer.print("Enter the atomic number of an element to get its electron config.\n", .{});
    try writer.print(">> ", .{});
    while (try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', 1024)) |buf| {
        defer allocator.free(buf);
        const number = parseAtomicNumber(buf) catch {
            error_times += 1;
            if (error_times < 3) {
                try writer.print("Invalid atomic number \"{s}\".\n", .{buf});
            } else if (error_times < 6) {
                try writer.print("Invalid atomic number \"{s}\". You stupid or something?\n", .{buf});
            } else {
                try writer.print("Invalid atomic number \"{s}\". Examples (cuz you're dumb): try \"1\" or \"69\".\n", .{buf});
            }
            try writer.print(">> ", .{});
            continue;
        };
        error_times = 0;
        printElectronConfig(writer, number) catch |err| {
            switch (err) {
                error.AtomicNumberOutOfRange => try writer.print("Number too big, max is {}.\n", .{maxAtomicNumber()}),
                else => return err,
            }
        };
        try writer.print(">> ", .{});
    }
    try writer.print("\n", .{});
}

pub fn runOnArgs(args: []const []const u8) !void {
    const writer = stdout.writer();
    var success = false;
    for (args[1..]) |arg| {
        const number = parseAtomicNumber(arg) catch {
            try writer.print("Invalid atomic number \"{s}\".\n", .{arg});
            continue;
        };
        success = true;
        printElectronConfig(writer, number) catch |err| {
            switch (err) {
                error.AtomicNumberOutOfRange => try writer.print("Number too big, max is {}.\n", .{maxAtomicNumber()}),
                else => return err,
            }
        };
    }
    if (!success) try printUsage(writer, args[0]);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    if (args.len == 1) {
        try runInteractively(allocator);
    } else {
        try runOnArgs(args);
    }
}

const data = struct {
    const orbital_names = [_][]const u8{
        "s", "p", "d", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o",
        "q", "r", "t", "u", "v", "w", "x", "y", "z", "a", "b", "c", "e",
        "S", "P", "D", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O",
        "Q", "R", "T", "U", "V", "W", "X", "Y", "Z", "A", "B", "C", "E",
    };

    const elements = [_]struct { symbol: []const u8, name: []const u8 }{
        .{ .name = "Nonexistium", .symbol = "Nx" }, .{ .name = "Hydrogen", .symbol = "H" },      .{ .name = "Helium", .symbol = "He" },
        .{ .name = "Lithium", .symbol = "Li" },     .{ .name = "Beryllium", .symbol = "Be" },    .{ .name = "Boron", .symbol = "B" },
        .{ .name = "Carbon", .symbol = "C" },       .{ .name = "Nitrogen", .symbol = "N" },      .{ .name = "Oxygen", .symbol = "O" },
        .{ .name = "Fluorine", .symbol = "F" },     .{ .name = "Neon", .symbol = "Ne" },         .{ .name = "Sodium", .symbol = "Na" },
        .{ .name = "Magnesium", .symbol = "Mg" },   .{ .name = "Aluminum", .symbol = "Al" },     .{ .name = "Silicon", .symbol = "Si" },
        .{ .name = "Phosphorus", .symbol = "P" },   .{ .name = "Sulfur", .symbol = "S" },        .{ .name = "Chlorine", .symbol = "Cl" },
        .{ .name = "Argon", .symbol = "Ar" },       .{ .name = "Potassium", .symbol = "K" },     .{ .name = "Calcium", .symbol = "Ca" },
        .{ .name = "Scandium", .symbol = "Sc" },    .{ .name = "Titanium", .symbol = "Ti" },     .{ .name = "Vanadium", .symbol = "V" },
        .{ .name = "Chromium", .symbol = "Cr" },    .{ .name = "Manganese", .symbol = "Mn" },    .{ .name = "Iron", .symbol = "Fe" },
        .{ .name = "Cobalt", .symbol = "Co" },      .{ .name = "Nickel", .symbol = "Ni" },       .{ .name = "Copper", .symbol = "Cu" },
        .{ .name = "Zinc", .symbol = "Zn" },        .{ .name = "Gallium", .symbol = "Ga" },      .{ .name = "Germanium", .symbol = "Ge" },
        .{ .name = "Arsenic", .symbol = "As" },     .{ .name = "Selenium", .symbol = "Se" },     .{ .name = "Bromine", .symbol = "Br" },
        .{ .name = "Krypton", .symbol = "Kr" },     .{ .name = "Rubidium", .symbol = "Rb" },     .{ .name = "Strontium", .symbol = "Sr" },
        .{ .name = "Yttrium", .symbol = "Y" },      .{ .name = "Zirconium", .symbol = "Zr" },    .{ .name = "Niobium", .symbol = "Nb" },
        .{ .name = "Molybdenum", .symbol = "Mo" },  .{ .name = "Technetium", .symbol = "Tc" },   .{ .name = "Ruthenium", .symbol = "Ru" },
        .{ .name = "Rhodium", .symbol = "Rh" },     .{ .name = "Palladium", .symbol = "Pd" },    .{ .name = "Silver", .symbol = "Ag" },
        .{ .name = "Cadmium", .symbol = "Cd" },     .{ .name = "Indium", .symbol = "In" },       .{ .name = "Tin", .symbol = "Sn" },
        .{ .name = "Antimony", .symbol = "Sb" },    .{ .name = "Tellurium", .symbol = "Te" },    .{ .name = "Iodine", .symbol = "I" },
        .{ .name = "Xenon", .symbol = "Xe" },       .{ .name = "Cesium", .symbol = "Cs" },       .{ .name = "Barium", .symbol = "Ba" },
        .{ .name = "Lanthanum", .symbol = "La" },   .{ .name = "Cerium", .symbol = "Ce" },       .{ .name = "Praseodymium", .symbol = "Pr" },
        .{ .name = "Neodymium", .symbol = "Nd" },   .{ .name = "Promethium", .symbol = "Pm" },   .{ .name = "Samarium", .symbol = "Sm" },
        .{ .name = "Europium", .symbol = "Eu" },    .{ .name = "Gadolinium", .symbol = "Gd" },   .{ .name = "Terbium", .symbol = "Tb" },
        .{ .name = "Dysprosium", .symbol = "Dy" },  .{ .name = "Holmium", .symbol = "Ho" },      .{ .name = "Erbium", .symbol = "Er" },
        .{ .name = "Thulium", .symbol = "Tm" },     .{ .name = "Ytterbium", .symbol = "Yb" },    .{ .name = "Lutetium", .symbol = "Lu" },
        .{ .name = "Hafnium", .symbol = "Hf" },     .{ .name = "Tantalum", .symbol = "Ta" },     .{ .name = "Tungsten", .symbol = "W" },
        .{ .name = "Rhenium", .symbol = "Re" },     .{ .name = "Osmium", .symbol = "Os" },       .{ .name = "Iridium", .symbol = "Ir" },
        .{ .name = "Platinum", .symbol = "Pt" },    .{ .name = "Gold", .symbol = "Au" },         .{ .name = "Mercury", .symbol = "Hg" },
        .{ .name = "Thallium", .symbol = "Tl" },    .{ .name = "Lead", .symbol = "Pb" },         .{ .name = "Bismuth", .symbol = "Bi" },
        .{ .name = "Polonium", .symbol = "Po" },    .{ .name = "Astatine", .symbol = "At" },     .{ .name = "Radon", .symbol = "Rn" },
        .{ .name = "Francium", .symbol = "Fr" },    .{ .name = "Radium", .symbol = "Ra" },       .{ .name = "Actinium", .symbol = "Ac" },
        .{ .name = "Thorium", .symbol = "Th" },     .{ .name = "Protactinium", .symbol = "Pa" }, .{ .name = "Uranium", .symbol = "U" },
        .{ .name = "Neptunium", .symbol = "Np" },   .{ .name = "Plutonium", .symbol = "Pu" },    .{ .name = "Americium", .symbol = "Am" },
        .{ .name = "Curium", .symbol = "Cm" },      .{ .name = "Berkelium", .symbol = "Bk" },    .{ .name = "Californium", .symbol = "Cf" },
        .{ .name = "Einsteinium", .symbol = "Es" }, .{ .name = "Fermium", .symbol = "Fm" },      .{ .name = "Mendelevium", .symbol = "Md" },
        .{ .name = "Nobelium", .symbol = "No" },    .{ .name = "Lawrencium", .symbol = "Lr" },   .{ .name = "Rutherfordium", .symbol = "Rf" },
        .{ .name = "Dubnium", .symbol = "Db" },     .{ .name = "Seaborgium", .symbol = "Sg" },   .{ .name = "Bohrium", .symbol = "Bh" },
        .{ .name = "Hassium", .symbol = "Hs" },     .{ .name = "Meitnerium", .symbol = "Mt" },   .{ .name = "Darmstadtium", .symbol = "Ds" },
        .{ .name = "Roentgenium", .symbol = "Rg" }, .{ .name = "Copernicium", .symbol = "Cn" },  .{ .name = "Nihonium", .symbol = "Nh" },
        .{ .name = "Flerovium", .symbol = "Fl" },   .{ .name = "Moscovium", .symbol = "Mc" },    .{ .name = "Livermorium", .symbol = "Lv" },
        .{ .name = "Tennessine", .symbol = "Ts" },  .{ .name = "Oganesson", .symbol = "Og" },
    };
};
