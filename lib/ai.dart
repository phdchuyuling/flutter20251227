import 'dart:math';
import 'game.dart';

class SimpleAI {
  final Random _rng = Random();

  /// difficulty: 1 (easiest) .. 5 (hardest). Default 3 = current behaviour.
  int difficulty = 3;

  void setDifficulty(int d) {
    if (d < 1) d = 1;
    if (d > 5) d = 5;
    difficulty = d;
  }

  // 選擇走法，根據 difficulty 採用不同策略
  int chooseMove(Game game) {
    var moves = game.legalMoves(-1);
    if (moves.isEmpty) return -1;

    switch (difficulty) {
      case 1:
        // easiest: purely random
        return moves[_rng.nextInt(moves.length)];
      case 2:
        // weak: choose move with minimal flips (usually bad)
        int best = moves.first;
        int bestCount = game.flipsForMove(best, -1).length;
        List<int> bestList = [best];
        for (var m in moves.skip(1)) {
          int cnt = game.flipsForMove(m, -1).length;
          if (cnt < bestCount) {
            bestCount = cnt;
            bestList = [m];
          } else if (cnt == bestCount) {
            bestList.add(m);
          }
        }
        return bestList[_rng.nextInt(bestList.length)];
      case 3:
        // default: choose move that flips most pieces (現有行為)
        int best = moves.first;
        int bestCount = game.flipsForMove(best, -1).length;
        List<int> bestList = [best];
        for (var m in moves.skip(1)) {
          int cnt = game.flipsForMove(m, -1).length;
          if (cnt > bestCount) {
            bestCount = cnt;
            bestList = [m];
          } else if (cnt == bestCount) {
            bestList.add(m);
          }
        }
        return bestList[_rng.nextInt(bestList.length)];
      case 4:
        // medium-strong: positional weights + flips
        var weights = _positionWeights();
        double bestScore = double.negativeInfinity;
        List<int> bestMoves = [];
        for (var m in moves) {
          int flips = game.flipsForMove(m, -1).length;
          double score = weights[m] + flips * 2;
          if (score > bestScore) {
            bestScore = score;
            bestMoves = [m];
          } else if (score == bestScore) {
            bestMoves.add(m);
          }
        }
        return bestMoves[_rng.nextInt(bestMoves.length)];
      case 5:
        // hardest: one-ply lookahead (simulate move, consider opponent best reply)
        var weights5 = _positionWeights();
        double bestScore5 = double.negativeInfinity;
        List<int> best5 = [];
        for (var m in moves) {
          // simulate on a copy
          var g2 = Game();
          g2.board = List.from(game.board);
          g2.currentPlayer = game.currentPlayer;
          g2.makeMove(m, -1);

          // opponent's best immediate flips
          var oppMoves = g2.legalMoves(1);
          int oppBest = 0;
          for (var om in oppMoves) {
            int flips = g2.flipsForMove(om, 1).length;
            if (flips > oppBest) oppBest = flips;
          }

          int myFlips = game.flipsForMove(m, -1).length;
          double score = weights5[m] * 3 + myFlips * 2 - oppBest * 1.5;
          if (score > bestScore5) {
            bestScore5 = score;
            best5 = [m];
          } else if (score == bestScore5) {
            best5.add(m);
          }
        }
        return best5[_rng.nextInt(best5.length)];
      default:
        return moves[_rng.nextInt(moves.length)];
    }
  }

  List<int> _positionWeights() {
    // 常用的 Reversi 權重表：角落很重要，角周危險
    return [
      120,
      -20,
      20,
      5,
      5,
      20,
      -20,
      120,
      -20,
      -40,
      -5,
      -5,
      -5,
      -5,
      -40,
      -20,
      20,
      -5,
      15,
      3,
      3,
      15,
      -5,
      20,
      5,
      -5,
      3,
      3,
      3,
      3,
      -5,
      5,
      5,
      -5,
      3,
      3,
      3,
      3,
      -5,
      5,
      20,
      -5,
      15,
      3,
      3,
      15,
      -5,
      20,
      -20,
      -40,
      -5,
      -5,
      -5,
      -5,
      -40,
      -20,
      120,
      -20,
      20,
      5,
      5,
      20,
      -20,
      120,
    ];
  }
}
