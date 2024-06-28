const std = @import("std");

// player(?i2): connect of -1 or 1
// start of connect path(?u7): the shift amount to get to that position
// direction(?u7): shift amount to get to the next peice on path
// length of path: amount of shifts until shifts are no longer on the path
// index:(?u7) of last peice in connect
const Connect_Data = struct {
    player: i2,
    start: u7,
    dir: u7,
    len: u7,
    idx: u7,
};

const Board = struct {
    // Stores Data of the board as a u84 where every 2 bits repersents an i2
    // b00 -> 0 ->  Empty
    // b01 -> 1 -> Player Peice
    // b11 -> -1 -> Advisary Peice
    // Position of i2 is mapped as 6*col + row for every 2 bits

    data: u84,

    pub fn init() Board {
        return Board{ .data = 0 };
    }

    // non mutable setter
    // sets the data of an i2 in the proper col pushing it to the first zero
    // throws error if attempting to push to position that is already set or full column
    pub fn set(self: *Board, col: u7, player: i2) !void {
        if (col >= 7) return error.OutOfBounds;

        const col_bits = (self.data >> (12 * col)) & 0xFFF;
        const bit2: u84 = 0b11;
        var row: u7 = 0;
        while ((col_bits & (bit2 << (2 * row))) != 0) : (row += 1) {
            if (row > 5) return error.ColumnFull;
        }

        const uplayer: u2 = @bitCast(player);
        const setter: u84 = @intCast(uplayer);
        self.*.data |= setter << 12 * col + 2 * row;
    }

    // gets data at some col and row
    // errors if col or row are out of bounds
    pub fn get(self: Board, col: u7, row: u7) !i2 {
        if ((col >= 7) or (row >= 6)) return error.OutOfBounds;
        const bit2: u2 = @intCast((self.data >> (col * 12 + row * 2)) & 0b11);
        const val: i2 = @bitCast(bit2);
        return val;
    }

    // finds all connects of a specific size and returns all the info of all the connects
    pub fn all_connects(self: Board, a: std.mem.Allocator, sz: usize) !std.ArrayList(Connect_Data) {
        var connects = std.ArrayList(Connect_Data).init(a);
        //check columns
        var col_idx: u7 = 0;
        while (col_idx < 7) {
            var col_data: u84 = self.data >> col_idx * 12;
            var cnt: u8 = 0;
            var crnt_2bit: u84 = 0;
            for (0..6) |i| {
                const bit2 = col_data & 0b11;
                if (bit2 == 0) {
                    break;
                }

                if (crnt_2bit != bit2) {
                    crnt_2bit = bit2;
                    cnt = 1;
                } else {
                    cnt += 1;
                }

                if (cnt >= sz) {
                    const ubit2: u2 = @intCast(bit2);
                    const player: i2 = @bitCast(ubit2);
                    const idx: u7 = @intCast(i);
                    const con_data = Connect_Data{ 
                        .player = player, .start = col_idx * 12, 
                        .dir = 2, 
                        .len = 6, 
                        .idx = idx };
                    try connects.append(con_data);
                    break;
                }

                col_data >>= 2;
            }
            col_idx += 1;
        }

        //check rows
        var row_idx: u7 = 0;
        while (row_idx < 6) {
            var row_data: u84 = self.data >> row_idx * 2;
            var cnt: u8 = 0;
            var crnt_2bit: u84 = 0;
            for (0..7) |i| {
                const bit2 = row_data & 0b11;
                if (bit2 == 0) {
                    cnt = 0;
                    crnt_2bit = 0;
                    row_data >>= 12;
                    continue;
                }

                if (crnt_2bit != bit2) {
                    crnt_2bit = bit2;
                    cnt = 1;
                } else {
                    cnt += 1;
                }

                if (cnt >= sz) {
                    const ubit2: u2 = @intCast(bit2);
                    const player: i2 = @bitCast(ubit2);
                    const idx: u7 = @intCast(i);
                    const con_data = Connect_Data{ 
                        .player = player, 
                        .start = row_idx * 2, 
                        .dir = 12, 
                        .len = 7, 
                        .idx = idx };
                    try connects.append(con_data);
                    break;
                }

                row_data >>= 12;
            }

            row_idx += 1;
        }

        // check starting low diagonals
        // part 1
        var l_diag_idx_1: u7 = 0;
        while (l_diag_idx_1 < 3) {
            var diag_bits = self.data >> 2 * l_diag_idx_1;
            var cnt: u8 = 0;
            var crnt_2bit: u84 = 0;
            for (0..(6 - l_diag_idx_1)) |i| {
                const bit2 = diag_bits & 0b11;

                if (bit2 == 0) {
                    cnt = 0;
                    crnt_2bit = 0;
                    diag_bits >>= 14;
                    continue;
                }

                if (crnt_2bit != bit2) {
                    crnt_2bit = bit2;
                    cnt = 1;
                } else {
                    cnt += 1;
                }

                if (cnt >= sz) {
                    const ubit2: u2 = @intCast(bit2);
                    const player: i2 = @bitCast(ubit2);
                    const idx: u7 = @intCast(i);
                    const con_data =  Connect_Data{ 
                        .player = player, 
                        .start = 2 * l_diag_idx_1, 
                        .dir = 14, 
                        .len = 6 - l_diag_idx_1, 
                        .idx = idx };
                    try connects.append(con_data);
                    break;
                }

                diag_bits >>= 14;
            }

            l_diag_idx_1 += 1;
        }

        // check starting low diagonals
        // part 2
        var l_diag_idx_2: u7 = 1;
        while (l_diag_idx_2 < 4) {
            var diag_bits = self.data >> 12 * l_diag_idx_2;
            var cnt: u8 = 0;
            var crnt_2bit: u84 = 0;
            for (0..(7 - l_diag_idx_2)) |i| {
                const bit2 = diag_bits & 0b11;

                if (bit2 == 0) {
                    cnt = 0;
                    crnt_2bit = 0;
                    diag_bits >>= 14;
                    continue;
                }

                if (crnt_2bit != bit2) {
                    crnt_2bit = bit2;
                    cnt = 1;
                } else {
                    cnt += 1;
                }

                if (cnt >= sz) {
                    const ubit2: u2 = @intCast(bit2);
                    const player: i2 = @bitCast(ubit2);
                    const idx: u7 = @intCast(i);
                    const con_data = Connect_Data{ 
                        .player = player, 
                        .start = 12 * l_diag_idx_2, 
                        .dir = 14, 
                        .len = 7 - l_diag_idx_2, 
                        .idx = idx };
                    try connects.append(con_data);
                    break;
                }

                diag_bits >>= 14;
            }

            l_diag_idx_2 += 1;
        }

        // check starting high diagonals
        // part 1
        var h_diag_idx_1: u7 = 5;
        while (2 < h_diag_idx_1) {
            var diag_bits = self.data >> 2 * h_diag_idx_1;
            var cnt: u8 = 0;
            var crnt_2bit: u84 = 0;
            for (0..(h_diag_idx_1 + 1)) |i| {
                const bit2 = diag_bits & 0b11;

                if (bit2 == 0) {
                    cnt = 0;
                    crnt_2bit = 0;
                    diag_bits >>= 10;
                    continue;
                }

                if (crnt_2bit != bit2) {
                    crnt_2bit = bit2;
                    cnt = 1;
                } else {
                    cnt += 1;
                }

                if (cnt >= sz) {
                    const ubit2: u2 = @intCast(bit2);
                    const player: i2 = @bitCast(ubit2);
                    const idx: u7 = @intCast(i);
                    const con_data = Connect_Data{ 
                        .player = player, 
                        .start = 2 * h_diag_idx_1, 
                        .dir = 10, 
                        .len = h_diag_idx_1 + 1, 
                        .idx = idx };
                    try connects.append(con_data);
                    break;
                }

                diag_bits >>= 10;
            }

            h_diag_idx_1 -= 1;
        }

        // check starting high diagonals
        // part 2
        var h_diag_idx_2: u7 = 1;
        while (h_diag_idx_2 < 4) {
            var diag_bits = self.data >> 12 * h_diag_idx_1 + 10;
            var cnt: u8 = 0;
            var crnt_2bit: u84 = 0;
            for (0..(7 - h_diag_idx_2)) |i| {
                const bit2 = diag_bits & 0b11;

                if (bit2 == 0) {
                    cnt = 0;
                    crnt_2bit = 0;
                    diag_bits >>= 10;
                    continue;
                }

                if (crnt_2bit != bit2) {
                    crnt_2bit = bit2;
                    cnt = 1;
                } else {
                    cnt += 1;
                }

                if (cnt >= sz) {
                    const ubit2: u2 = @intCast(bit2);
                    const player: i2 = @bitCast(ubit2);
                    const idx: u7 = @intCast(i);
                    const con_data = Connect_Data{ 
                        .player = player, 
                        .start = 12 * h_diag_idx_1 + 10,
                        .dir =  10, 
                        .len = 7 - h_diag_idx_2,
                        .idx = idx };
                    try connects.append(con_data);
                    break;
                }

                diag_bits >>= 10;
            }

            h_diag_idx_2 += 1;
        }

        return connects;
    }

    // finds all columns that stop win in next move for human
    pub fn stop_wins(self: Board, connects: std.ArrayList(Connect_Data)) !?[7]bool {
        var cols = std.mem.zeroes([7]bool);
        var state = false;
        for (connects.items) |cd|{
            if (cd.player == -1) break;

            if (cd.idx >= 3) {
                const col = (cd.start + cd.dir * (cd.idx - 3)) / 12;
                const row = ((cd.start + cd.dir * (cd.idx - 3)) % 12) / 2;
                const val1: i2 = if (row == 0) 1 else try self.get(col, row - 1);
                const val2: i2 = try self.get(col, row);
                if ((val1 != 0) and (val2 == 0)) {
                    state = true;
                    cols[col] = true;
                }
            }

            if ((cd.idx + 1) < cd.len) {
                const col = (cd.start + cd.dir * (cd.idx + 1)) / 12;
                const row = ((cd.start + cd.dir * (cd.idx + 1)) % 12) / 2;
                const val1: i2 = if (row == 0) 1 else try self.get(col, row - 1);
                const val2: i2 = try self.get(col, row);
                if ((val1 != 0) and (val2 == 0)) {
                    state = true;
                    cols[col] = true;
                }
            }
        }

        if (state) return cols else return null;
    }

    // finds the first column that making a move at would result in a win and null if there is no such column
    pub fn find_win(self: Board, connects: std.ArrayList(Connect_Data), player: i2) !?u7 {
        for (connects.items) |cd|{
            if (cd.player != player) continue;

            if (cd.idx >= 3) {
                const col = (cd.start + cd.dir * (cd.idx - 3)) / 12;
                const row = ((cd.start + cd.dir * (cd.idx - 3)) % 12) / 2;
                const val1: i2 = if (row == 0) 1 else try self.get(col, row - 1);
                const val2: i2 = try self.get(col, row);
                if ((val1 != 0) and (val2 == 0)) {
                    return col;
                }
            }

            if ((cd.idx + 1) < cd.len) {
                const col = (cd.start + cd.dir * (cd.idx + 1)) / 12;
                const row = ((cd.start + cd.dir * (cd.idx + 1)) % 12) / 2;
                const val1: i2 = if (row == 0) 1 else try self.get(col, row - 1);
                const val2: i2 = try self.get(col, row);
                if ((val1 != 0) and (val2 == 0)) {
                    return col;
                }
            }
        }

        return null;
    }

    // finds all columns that result in a win
    pub fn find_all_wins(self: Board, connects: std.ArrayList(Connect_Data), player: i2) ![7]bool {
        var cols = std.mem.zeroes([7]bool);

        for (connects.items) |cd|{
            if (cd.player != player) continue;

            if (cd.idx >= 3) {
                const col = (cd.start + cd.dir * (cd.idx - 3)) / 12;
                const row = ((cd.start + cd.dir * (cd.idx - 3)) % 12) / 2;
                const val1: i2 = if (row == 0) 1 else try self.get(col, row - 1);
                const val2: i2 = try self.get(col, row);
                if ((val1 != 0) and (val2 == 0)) {
                    cols[col] = true;
                }
            }

            if ((cd.idx + 1) < cd.len) {
                const col = (cd.start + cd.dir * (cd.idx + 1)) / 12;
                const row = ((cd.start + cd.dir * (cd.idx + 1)) % 12) / 2;
                const val1: i2 = if (row == 0) 1 else try self.get(col, row - 1);
                const val2: i2 = try self.get(col, row);
                if ((val1 != 0) and (val2 == 0)) {
                    cols[col] = true;
                }
            }
        }

        return cols;
    }

    //returns all available columns to make a move
    pub fn available_col(self: Board) [7]bool {
        var out: [7]bool = undefined;
        var bits: u84 = self.data >> 10;
        for (0..7) |i| {
            const bit2: u84 = bits & 0b11;
            if (bit2 == 0) {
                out[i] = true;
            } else {
                out[i] = false;
            }
            bits >>= 12;
        }

        return out;
    }

    // displays bits as list of i2
    pub fn display_bits(self: Board) void {
        var bits: u84 = self.data;

        for (0..42) |_| {
            const bit2: u2 = @intCast(bits & 0b11);
            const val: i2 = @bitCast(bit2);
            std.debug.print("{} ", .{val});
            bits >>= 2;
        }
        std.debug.print("\n", .{});
    }

    // visually displays board
    pub fn display_board(self: Board) void {
        std.debug.print("\n\n", .{});
        var i: u7 = 1;
        while (i < 7) {
            var row: u84 = self.data >> (6 - i) * 2;
            for (0..7) |_| {
                const bit2: u2 = @intCast(row & 0b11);
                const val: i2 = @bitCast(bit2);
                if ((val == 0) or (val == 1)) {
                    std.debug.print("  {}", .{val});
                } else {
                    std.debug.print(" {}", .{val});
                }
                row >>= 12;
            }
            std.debug.print("\n", .{});
            i += 1;
        }
        std.debug.print("\n", .{});
    }
};

pub fn Queue(comptime Child: type) type {
    return struct {
        const This = @This();
        const Node = struct {
            data: Child,
            next: ?*Node,
        };
        a: *std.mem.Allocator,
        start: ?*Node,
        end: ?*Node,
        len: usize,

        pub fn init(a: *std.mem.Allocator) This {
            return This{
                .a = a,
                .start = null,
                .end = null,
                .len = 0,
            };
        }

        pub fn deinit(this: *This) void {
            var current = this.start;
            while (current) |node| {
                const next = node.next;
                this.a.destroy(node);
                current = next;
            }
            this.start = null;
            this.end = null;
            this.len = 0;
        }

        pub fn in(this: *This, value: Child) !void {
            const node = try this.a.create(Node);
            node.* = .{ .data = value, .next = null };
            if (this.end) |end| end.next = node else this.start = node;
            this.end = node;
            this.len += 1;
        }

        pub fn out(this: *This) !Child {
            const start = this.start orelse return error.QueueIsEmpty;
            defer this.a.destroy(start);
            if (start.next) |next|
                this.start = next
            else {
                this.start = null;
                this.end = null;
            }
            this.len -= 1;
            return start.data;
        }
    };
}

const GameTree = struct {
    const Node = struct {
        baord: Board,
        parent: ?*Node,
        children: std.ArrayList(*Node),

        pub fn init(a: *std.mem.Allocator, board: Board, parent: ?*Node) !*Node {
            const node_ptr = try a.create(Node);
            node_ptr.* = Node{
                .baord = board,
                .parent = parent,
                .children = std.ArrayList(*Node).init(a.*),
            };
            return node_ptr;
        }

        pub fn deinit(self: *Node, a: *std.mem.Allocator) void {
            for (self.children.items) |child| {
                child.deinit(a);
            }
            self.children.deinit();
            a.destroy(self);
        }
    };

    root: *Node,
    a: *std.mem.Allocator,

    pub fn init(a: *std.mem.Allocator) !GameTree {
        return GameTree{
            .root = try Node.init(a, Board.init(), null),
            .a = a,
        };
    }

    pub fn deinit(self: *GameTree) void {
        self.root.deinit(self.a);
    }

    pub fn make(self: *GameTree, max_order: usize) !void {
        var q = Queue(*Node).init(self.a);
        defer q.deinit();
        try q.in(self.root);

        var order_cnt = q.len; // decrementing count till next level of tree
        var order: usize = 0; // level of the tree
        var player: i2 = 1; // player making moves
        std.debug.print("level || # of nodes\n______||___________\n------||-----------\n", .{});
        while ((q.len != 0) and (order < max_order)) {
            if (order_cnt == 0) {
                order_cnt = q.len;
                order += 1;
                player *= -1;
                std.debug.print("{}     || {}\n", .{ order, order_cnt });
            }
            var crnt = try q.out();
            order_cnt -= 1;

            // Control flow for different constructions at different levels
            if (order < 5) { // No columns will be filled nor wins or almost wins in the first 5 orders
                // control flow for who is moving
                if (player == 1) { // human can make any move
                    for (0..7) |i| {
                        var new_board = crnt.baord;
                        try new_board.set(@intCast(i), player);
                        const child = try Node.init(self.a, new_board, crnt);
                        try crnt.children.append(child);
                        try q.in(child);
                    }
                } else { // limit early AI moves to middle three columns
                    for (2..5) |i| {
                        var new_board = crnt.baord;
                        try new_board.set(@intCast(i), player);
                        const child = try Node.init(self.a, new_board, crnt);
                        try crnt.children.append(child);
                        try q.in(child);
                    }
                }
            } else { // checks for wins, almost wins, and available columns
                const connects = try crnt.baord.all_connects(self.a.*, 3);
                defer connects.deinit();

                // control flow for who is moving
                if (player == 1) {
                    const win_cols = try crnt.baord.find_all_wins( connects, player);
                    const avail_cols = crnt.baord.available_col();
                    for (0..7) |i| {
                        if (avail_cols[i]) { // check if col is available
                            var new_board = crnt.baord;
                            try new_board.set(@intCast(i), player);
                            const child = try Node.init(self.a, new_board, crnt);
                            try crnt.children.append(child);
                            if (!win_cols[i]) { // no need to add to queue if the board is a winner
                                try q.in(child);
                            }
                        }
                    }
                } else {
                    // check if there is a winning col
                    const win_col = try crnt.baord.find_win(connects, player);
                    if (win_col != null) { // check if there is a winning move
                        var new_board = crnt.baord;
                        try new_board.set(win_col.?, player);
                        const child = try Node.init(self.a, new_board, crnt);
                        try crnt.children.append(child);
                        continue;
                    }

                    // check for moves that stop human from winning
                    const stop_win_cols_opt = try crnt.baord.stop_wins(connects);
                    if (stop_win_cols_opt != null) {
                        const stop_win_cols = stop_win_cols_opt.?;
                        for (0..7) |i|{
                            if (stop_win_cols[i]){
                                var new_board = crnt.baord;
                                try new_board.set(@intCast(i), player);
                                const child = try Node.init(self.a, new_board, crnt);
                                try crnt.children.append(child);
                                try q.in(child);
                            }
                        }
                        continue;
                    }

                    //no winner or blockers
                    const avail_cols = crnt.baord.available_col();
                    for (0..7) |i| {
                        if (avail_cols[i]) { // check if col is available
                            var new_board = crnt.baord;
                            try new_board.set(@intCast(i), player);
                            const child = try Node.init(self.a, new_board, crnt);
                            try crnt.children.append(child);
                            try q.in(child);
                        }
                    }
                }
            }
        }
    }
};

pub fn main() !void {
    var allocator = std.heap.page_allocator;
    var tree = try GameTree.init(&allocator);
    defer tree.deinit();
    try tree.make(9);
}
