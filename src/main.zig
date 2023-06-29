const std = @import("std");
const testing = std.testing;

const LAType = f64;
const LASizeType = usize;

pub const Vector = struct {
    const Self = @This();
    values: []LAType,

    pub fn zeroes(vectorAllocator: std.mem.Allocator, vectorSize: LASizeType) !Vector {
        const vectorSlice: []LAType = try vectorAllocator.alloc(LAType, vectorSize);
        for (vectorSlice) |*value| {
            value.* = 0;
        }
        return Vector {
            .values = vectorSlice,
        };
    }

    pub fn get(self: Self, index: LASizeType) anyerror!LAType {
        if (index > self.values.len) {
            return error.VectorSizeError;
        }
        return self.values[index - 1];
    }

    pub fn set(self: Self, index: LASizeType, value: LAType) anyerror!void {
        if (index > self.values.len) {
            return error.VectorSizeError;
        }
        self.values[index - 1] = value;
    }

    pub fn print(self: Self, writer: anytype) anyerror!void {
        var i: u8 = 0;
        while (i < self.values.len) : (i += 1) {
            try writer.print("{} ", .{self.values[i]});
        }
        try writer.print("\n", .{});
    }

    pub fn size(self: Self) LASizeType {
        return self.values.len;
    }
};

pub const Matrix = struct {

    const Self = @This();

    values: []LAType, // Array of values
    m: LASizeType, // Number of rows
    n: LASizeType, // Number of columns

    pub fn zeroes(matrixAllocator: std.mem.Allocator, numOfRows: LASizeType, numOfCols: LASizeType) Matrix {
        const matrixSlice: []LAType = matrixAllocator.alloc(LAType, numOfRows * numOfCols) catch @panic("... i ate too much memory sorry");
        // Set LAType to all zeroes
        var i: LASizeType = 0;
        while (i < numOfRows * numOfCols) : (i += 1) {
            matrixSlice[i] = 0.0;
        }

        return Matrix{
            .values = matrixSlice,
            .m = numOfRows,
            .n = numOfCols,
        };
    }

    pub fn identity(matrixAllocator: std.mem.Allocator, dimension: LASizeType) Matrix {
        const matrixSlice: []LAType = matrixAllocator.alloc(LAType, dimension * dimension) catch @panic("... i ate too much memory sorry");
        // Set LAType to all zeroes
        var i: LASizeType = 0;
        while (i < dimension * dimension) : (i += 1) {
            if (i % (dimension + 1) == 0) {
                matrixSlice[i] = 1;
            } else {
                matrixSlice[i] = 0;
            }
        }

        return Matrix{
            .values = matrixSlice,
            .m = dimension,
            .n = dimension,
        };
    }

    pub fn getRowNum(self: Self) LASizeType {
        return self.m;
    }

    pub fn getColNum(self: Self) LASizeType {
        return self.n;
    }

    pub fn get(self: Self, rowNum: LASizeType, colNum: LASizeType) anyerror!LAType {
        if (rowNum > self.getRowNum()) {
            return error.MatrixRowSizeError;
        }
        if (colNum > self.getColNum()) {
            return error.MatrixColSizeError;
        }
        return self.values[(rowNum - 1) * self.getColNum() + (colNum - 1)];
    }

    pub fn set(self: Self, rowNum: LASizeType, colNum: LASizeType, value: LAType) anyerror!void {
        if (rowNum > self.getRowNum()) {
            return error.MatrixRowSizeError;
        }
        if (colNum > self.getColNum()) {
            return error.MatrixColSizeError;
        }
        self.values[(rowNum - 1) * self.getColNum() + (colNum - 1)] = value;
    }

    pub fn print(self: Self, writer: anytype) anyerror!void {

        // var buffer: [100]u8 = undefined;

        var m: u8 = 1;
        while (m <= self.getRowNum()) : (m += 1) {
            var n: u8 = 1;
            while (n <= self.getColNum()) : (n += 1) {

                // _ = try std.fmt.bufPrint(&buffer, "{:2}", .{self.get(m, n) catch unreachable});
                try writer.print("{d:.2} ", .{self.get(m, n) catch unreachable});
            }
            try writer.print("\n", .{});
        }
    }
};


pub fn getRow(A: *Matrix, rowNum: LASizeType, allocator: std.mem.Allocator) anyerror!Vector {
    if (rowNum > A.getRowNum()) {
        return error.MatrixRowSize;
    }

    var row = Vector.zeroes(allocator, A.getColNum()) catch unreachable;    
    for (row.values) |*value, i| {
        value.* = A.get(rowNum, i + 1) catch unreachable;
    }

    return row;
}

pub fn getCol(A: *Matrix, colNum: LASizeType, allocator: std.mem.Allocator) anyerror!Vector {
    if (colNum > A.getColNum()) {
        return error.MatrixColSize;
    }

    var col = Vector.zeroes(allocator, A.getRowNum()) catch unreachable;
    for (col.values) |*value, i| {
        value.* = A.get(i + 1, colNum) catch unreachable;
    }
    return col;
}

test "basic matrix functionality" {
    var gpallocator = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpallocator.allocator();

    var testMatrix = Matrix.zeroes(allocator, 3, 3);

    try testing.expect(testMatrix.getRowNum() == 3);
    try testing.expect(testMatrix.getColNum() == 3);

    try testing.expect(testMatrix.get(2, 2) catch unreachable == 0);

    try testMatrix.set(2, 2, 1); // Set the value at row 2, column 2 to 1.0
    
    try testing.expect(testMatrix.get(2, 2) catch unreachable == 1);
}

test "get row and column" {
    var gpallocator = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpallocator.allocator();

    var testMatrix = Matrix.zeroes(allocator, 4, 2);
    try testMatrix.set(1, 1, 1.0);
    try testMatrix.set(1, 2, 2.0);
    try testMatrix.set(2, 1, 3.0);
    try testMatrix.set(2, 2, 4.0);
    try testMatrix.set(3, 1, 5.0);
    try testMatrix.set(3, 2, 6.0);
    try testMatrix.set(4, 1, 7.0);
    try testMatrix.set(4, 2, 8.0);

    var expectedRowVector = Vector.zeroes(allocator, 2) catch unreachable;
    try expectedRowVector.set(1, 5.0);
    try expectedRowVector.set(2, 6.0);
    var gottenRow = getRow(&testMatrix, 3, allocator) catch unreachable;
    try testing.expect(vectorEquals(gottenRow, expectedRowVector));

    var expectedColVector = Vector.zeroes(allocator, 4) catch unreachable;
    try expectedColVector.set(1, 2.0);
    try expectedColVector.set(2, 4.0);
    try expectedColVector.set(3, 6.0);
    try expectedColVector.set(4, 8.0);
    var gottenCol = getCol(&testMatrix, 2, allocator) catch unreachable;
    try testing.expect(vectorEquals(gottenCol, expectedColVector));
}

pub fn vectorEquals(a: Vector, b: Vector) bool {
    if (a.size() != b.size()) {
        return false;
    }
    var i: LASizeType = 1;
    while (i <= a.size()) : (i += 1) {
        if (a.get(i) catch unreachable != b.get(i) catch unreachable) {
            return false;
        }
    }
    return true;
}

pub fn matrixEquals(a: Matrix, b: Matrix) bool {
    if (a.getRowNum() != b.getRowNum()) {
        return false;
    }
    if (a.getColNum() != b.getColNum()) {
        return false;
    }
    var i: LASizeType = 1;
    while (i <= a.getRowNum()) : (i += 1) {
        var j: LASizeType = 1;
        while (j <= a.getColNum()) : (j += 1) {
            if (!std.math.approxEqAbs(LAType, (a.get(i, j) catch unreachable), (b.get(i, j)) catch unreachable, 0.005)) {
                return false;
            }
        }
    }
    return true;
}

pub fn add(A: *Matrix, B: *Matrix, allocator: std.mem.Allocator) anyerror!Matrix {
    if (A.getRowNum() != B.getRowNum()) {
        return error.MatrixRowSize;
    }
    if (A.getColNum() != B.getColNum()) {
        return error.MatrixColSize;
    }
    var resultMatrix = Matrix.zeroes(allocator, A.getRowNum(), A.getColNum());
    var i: LASizeType = 1;
    while (i <= A.getRowNum()) : (i += 1) {
        var j: LASizeType = 1;
        while (j <= A.getColNum()) : (j += 1) {
            try resultMatrix.set(i, j, (A.get(i, j) catch unreachable) + (B.get(i, j) catch unreachable));
        }
    }
    return resultMatrix;
}

pub fn dot(a: *Vector, b: *Vector) !LAType {
    if (a.size() != b.size()) {
        return error.VectorMismatch;
    }
    var result: LAType = 0;
    for (a.values) |value, i| {
        result += (value * (b.get(i + 1) catch unreachable));
    }
    return result;
}

pub fn multiply(A: *Matrix, B: *Matrix, allocator: std.mem.Allocator) anyerror!Matrix {
    if (A.getColNum() != B.getRowNum()) {
        return error.MatrixMismatch;
    }
    var resultMatrix = Matrix.zeroes(allocator, A.getRowNum(), B.getColNum());
    var i: LASizeType = 1;
    while (i <= resultMatrix.getRowNum()) : (i += 1) {
        var j: LASizeType = 1;
        while (j <= resultMatrix.getColNum()) : (j += 1) {
            var rowVec: Vector = try getRow(A, i, allocator);
            // defer allocator.free(rowVec);
            var colVec: Vector = try getCol(B, j, allocator);
            // defer allocator.free(colVec);
            try resultMatrix.set(i, j, dot(&rowVec, &colVec) catch unreachable);
        }
    }
    return resultMatrix;
}

pub fn transpose(A: *Matrix, allocator: std.mem.Allocator) Matrix {
    var AT = Matrix.zeroes(allocator, A.getColNum(), A.getRowNum());
    var i: LASizeType = 1;
    while (i <= AT.getRowNum()) : (i += 1) {
        var j: LASizeType = 1;
        while (j <= AT.getColNum()) : (j += 1) {
            AT.set(i, j, A.get(j, i) catch unreachable) catch unreachable;
        }
    }
    return AT;
}

test "matrix addition" {
    var gpallocator = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpallocator.allocator();
    var testMatrixA = Matrix.zeroes(allocator, 3, 3);
    try testMatrixA.set(2, 2, 1.0);
    try testMatrixA.set(2, 1, 7.6);
    try testMatrixA.set(1, 2, 3.2);
    var testMatrixB = Matrix.zeroes(allocator, 3, 3);
    try testMatrixB.set(2, 2, 1.0);
    try testMatrixB.set(2, 1, 6.7);
    try testMatrixB.set(1, 1, 9.6);

    var resultMatrix = try add(&testMatrixA, &testMatrixB, allocator);
    
    var expectedMatrix = Matrix.zeroes(allocator, 3, 3);
    try expectedMatrix.set(2, 2, 2.0);
    try expectedMatrix.set(2, 1, 14.3);
    try expectedMatrix.set(1, 2, 3.2);
    try expectedMatrix.set(1, 1, 9.6);
    
    try testing.expect(matrixEquals(resultMatrix, expectedMatrix));
}

test "matrix multiplication" {

    // credit: https://www.khanacademy.org/math/precalculus/x9e81a4f98389efdf:matrices/x9e81a4f98389efdf:multiplying-matrices-by-matrices/e/multiplying_a_matrix_by_a_matrix
    var gpallocator = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpallocator.allocator();

    var E = Matrix.zeroes(allocator, 2, 2);
    try E.set(1, 1, 3);
    try E.set(1, 2, 5);
    try E.set(2, 1, -1);
    try E.set(2, 2, 1);

    var A = Matrix.zeroes(allocator, 2, 3);
    try A.set(1, 1, -2);
    try A.set(1, 2, 2);
    try A.set(1, 3, 3);
    try A.set(2, 1, 3);
    try A.set(2, 2, 5);
    try A.set(2, 3, -2);

    var H = Matrix.zeroes(allocator, 2, 3);
    try H.set(1, 1, 9);
    try H.set(1, 2, 31);
    try H.set(1, 3, -1);
    try H.set(2, 1, 5);
    try H.set(2, 2, 3);
    try H.set(2, 3, -5);
    try testing.expect(matrixEquals(multiply(&E, &A, allocator) catch unreachable, H));

    var A2 = Matrix.zeroes(allocator, 3, 1);
    try A2.set(1, 1, -1);
    try A2.set(2, 1, 4);
    try A2.set(3, 1, 4);
    var F = Matrix.zeroes(allocator, 1, 2);
    try F.set(1, 1, 0);
    try F.set(1, 2, -2);
    H = Matrix.zeroes(allocator, 3, 2);
    try H.set(1, 1, 0);
    try H.set(1, 2, 2);
    try H.set(2, 1, 0);
    try H.set(2, 2, -8);
    try H.set(3, 1, 0);
    try H.set(3, 2, -8);
    try testing.expect(matrixEquals(multiply(&A2, &F, allocator) catch unreachable, H));
    

}

test "matrix transpose" {
    var gpallocator = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpallocator.allocator();
    var A = Matrix.zeroes(allocator, 2, 3);
    try A.set(1, 1, 1);
    try A.set(1, 2, 2);
    try A.set(1, 3, 3);
    try A.set(2, 1, 4);
    try A.set(2, 2, 5);
    try A.set(2, 3, 6);
    var AT = Matrix.zeroes(allocator, 3, 2);
    try AT.set(1, 1, 1);
    try AT.set(1, 2, 4);
    try AT.set(2, 1, 2);
    try AT.set(2, 2, 5);
    try AT.set(3, 1, 3);
    try AT.set(3, 2, 6);
    try testing.expect(matrixEquals(transpose(&A, allocator), AT));

    var B = Matrix.identity(allocator, 700);
    try testing.expect(matrixEquals(B, transpose(&B, allocator)));
}