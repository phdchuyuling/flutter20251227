// 簡單的 Reversi 遊戲邏輯
// board: 8x8，索引 0..63
// 0 = empty, 1 = black (human), -1 = white (computer)

class Game {
  static const int size = 8;
  List<int> board = List.filled(size * size, 0);
  int currentPlayer = 1; // 1 = human(black), -1 = computer(white)
  // history stacks: store snapshots of board and currentPlayer before each move
  final List<List<int>> _historyBoards = [];
  final List<int> _historyPlayers = [];

  Game() {
    reset();
  }

  void reset() {
    board = List.filled(size * size, 0);
    int mid = size ~/ 2;
    // standard initial four
    board[(mid - 1) * size + (mid - 1)] = -1;
    board[(mid - 1) * size + mid] = 1;
    board[mid * size + (mid - 1)] = 1;
    board[mid * size + mid] = -1;
    currentPlayer = 1;
    // clear history on reset
    _historyBoards.clear();
    _historyPlayers.clear();
  }

  int _index(int r, int c) => r * size + c;

  bool inBounds(int r, int c) => r >= 0 && r < size && c >= 0 && c < size;

  // 返回 (是否合法, 翻轉的位置 list)
  List<int> flipsForMove(int idx, int player) {
    if (board[idx] != 0) return [];
    int r = idx ~/ size;
    int c = idx % size;
    List<int> res = [];
    List<List<int>> dirs = [
      [-1, -1],
      [-1, 0],
      [-1, 1],
      [0, -1],
      [0, 1],
      [1, -1],
      [1, 0],
      [1, 1],
    ];
    for (var d in dirs) {
      int rr = r + d[0];
      int cc = c + d[1];
      List<int> candidates = [];
      while (inBounds(rr, cc) && board[_index(rr, cc)] == -player) {
        candidates.add(_index(rr, cc));
        rr += d[0];
        cc += d[1];
      }
      if (candidates.isNotEmpty &&
          inBounds(rr, cc) &&
          board[_index(rr, cc)] == player) {
        res.addAll(candidates);
      }
    }
    return res;
  }

  List<int> legalMoves(int player) {
    List<int> moves = [];
    for (int i = 0; i < board.length; i++) {
      if (board[i] == 0) {
        if (flipsForMove(i, player).isNotEmpty) moves.add(i);
      }
    }
    return moves;
  }

  bool makeMove(int idx, int player) {
    var flips = flipsForMove(idx, player);
    if (flips.isEmpty) return false;
    // push snapshot before applying move so we can undo later
    _historyBoards.add(List.from(board));
    _historyPlayers.add(currentPlayer);
    board[idx] = player;
    for (var f in flips) board[f] = player;
    currentPlayer = -player;
    return true;
  }

  /// Undo a single move (restore the most recent snapshot).
  /// Returns true if an undo was performed.
  bool undoOne() {
    if (_historyBoards.isEmpty) return false;
    board = _historyBoards.removeLast();
    currentPlayer = _historyPlayers.removeLast();
    return true;
  }

  /// Undo two moves (used for "我要悔棋": human moved one step, computer moved one step)
  /// Returns true if two undos were successful; otherwise no change and returns false.
  bool undoTwoMoves() {
    if (_historyBoards.length < 2) return false;
    // perform two undos
    undoOne();
    undoOne();
    return true;
  }

  Map<String, int> score() {
    int black = 0, white = 0;
    for (var v in board) {
      if (v == 1)
        black++;
      else if (v == -1) white++;
    }
    return {'black': black, 'white': white};
  }

  bool isGameOver() {
    return legalMoves(1).isEmpty && legalMoves(-1).isEmpty;
  }
}
