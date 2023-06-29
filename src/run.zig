const std = @import("std");

var gpallocator = std.heap.GeneralPurposeAllocator(.{}){};
var allocator = gpallocator.allocator();
const stdout = std.io.getStdOut().writer();

const Vector = std.ArrayList(f64);

const Matrix = struct {

    const Self = @This();

    rows: std.ArrayList(Vector),

    pub fn zeroes(matrixAllocator: std.mem.Allocator, numOfRows: u32, numOfCols: u32) !Matrix {
        var rows = std.ArrayList(Vector).init(allocator);

        // Append Vectors to rows
        var i: u32 = 0;
        while (i < numOfRows) : (i += 1) {
            var vector = Vector.init(matrixAllocator);
            // Append 0.0 to the Vector numOfCols times
            var j: usize = 0;
            while (j < numOfCols) : (j += 1) {
                try vector.append(0.0);
            }
            try rows.append(vector);
        }

        return Matrix{
            .rows = rows,
        };
    }

    pub fn print(self: Self) anyerror!void {
        var m: u8 = 0;
        for (self.rows.items) |row| {
            m += 1;
            var n: u8 = 0;
            for (row.items) |element| {
                n += 1;
                try stdout.print("{}", .{element});
            }
            try stdout.print("\n", .{});
        }
    }
};


pub fn main() anyerror!void {
    
    

    var av = Vector.init(allocator);

    var Am = try Matrix.zeroes(allocator, 7, 3);
    // try Am.sayHi();

    var m: u8 = 0;
    for (Am.rows.items) |row| {
        m += 1;
        var n: u8 = 0;
        for (row.items) |element| {
            if (element > 1000) {
                return;
            }
            n += 1;
            if (m == n) {
                Am.rows.items[m - 1].items[n - 1] = 7.77777;
            }
            
        }
    }

    try Am.print();

    try av.append(6.9);
    try av.append(3.14169265358979323626433);

    var nya: usize = av.items.len;
    var mwrrp: u8 = 0;
    while (mwrrp < nya) {
        try stdout.print("{}\n", .{av.items[mwrrp]});
        mwrrp += 1;
    }
}
