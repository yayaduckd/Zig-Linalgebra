const std = @import("std");

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("🦆!\n", .{});
}
