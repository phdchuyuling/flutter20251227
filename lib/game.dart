class Game {
  static const int size = 8;
  List<int> board = List.filled(size * size, 0);
  int currentPlayer = 1; // 1 = black (human), -1 = white (AI)

  // move history for undo
  final List<Map<String, dynamic>> _history = [];

  Game() {
    reset();
  }

  void reset() {
    board = List.filled(size * size, 0);
    // initial four pieces
    board[3 * size + 3] = -1;
    board[3 * size + 4] = 1;
    board[4 * size + 3] = 1;
    board[4 * size + 4] = -1;
    currentPlayer = 1;
    _history.clear();
  }

  Map<String, int> score() {
    int black = board.where((v) => v == 1).length;
    int white = board.where((v) => v == -1).length;
    return {'black': black, 'white': white};
  }

  bool isOnBoard(int r, int c) => r >= 0 && r < size && c >= 0 && c < size;

  List<int> flipsForMove(int idx, int player) {
    if (idx < 0 || idx >= board.length) return [];
    if (board[idx] != 0) return [];
    int r = idx ~/ size;
    int c = idx % size;
    List<int> flipped = [];
    final dirs = [
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
      List<int> line = [];
      while (isOnBoard(rr, cc) && board[rr * size + cc] == -player) {
        line.add(rr * size + cc);
        rr += d[0];
        cc += d[1];
      }
      if (isOnBoard(rr, cc) && board[rr * size + cc] == player && line.isNotEmpty) {
        flipped.addAll(line);
      }
    }
    return flipped;
  }

  List<int> legalMoves(int player) {
    List<int> moves = [];
    for (int i = 0; i < board.length; i++) {
      if (board[i] == 0 && flipsForMove(i, player).isNotEmpty) moves.add(i);
    }
    return moves;
  }

  bool makeMove(int idx, int player) {
    var flips = flipsForMove(idx, player);
    if (flips.isEmpty) return false;
    board[idx] = player;
    for (var f in flips) board[f] = player;
    _history.add({'idx': idx, 'player': player, 'flipped': List<int>.from(flips)});
    // toggle player
    currentPlayer = -player;
    // if opponent has no moves, keep currentPlayer as player (pass)
    if (legalMoves(currentPlayer).isEmpty) {
      if (legalMoves(-currentPlayer).isNotEmpty) {
        // pass back
        currentPlayer = -currentPlayer;
      }
    }
    return true;
  }

  bool undoTwoMoves() {
    if (_history.length < 2) return false;
    for (int k = 0; k < 2; k++) {
      var last = _history.removeLast();
      int idx = last['idx'];
      int player = last['player'];
      List<int> flipped = List<int>.from(last['flipped']);
      // remove placed piece
      board[idx] = 0;
      // flip back
      for (var f in flipped) board[f] = -player;
    }
    currentPlayer = 1; // return to human's turn
    return true;
  }

  bool isGameOver() {
    return legalMoves(1).isEmpty && legalMoves(-1).isEmpty;
  }

  List<int> getBoard() => List<int>.from(board);

  List<int> lastFlips() {
    if (_history.isEmpty) return [];
    return List<int>.from(_history.last['flipped'] as List<int>);
  }
}
