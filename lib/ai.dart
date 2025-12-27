import 'dart:math';
import 'game.dart';

class SimpleAI {
  int difficulty = 3; // 1 easiest, 5 hardest
  final Random _rnd = Random();

  void setDifficulty(int d) {
    difficulty = d.clamp(1, 5);
  }

  int chooseMove(Game g) {
    var moves = g.legalMoves(-1);
    if (moves.isEmpty) return -1;
    // difficulty controls randomness vs greedy (higher = more greedy)
    if (difficulty <= 2) {
      // random
      return moves[_rnd.nextInt(moves.length)];
    }
    // choose move maximizing flips
    int best = moves.first;
    int bestCount = g.flipsForMove(best, -1).length;
    for (var m in moves.skip(1)) {
      int c = g.flipsForMove(m, -1).length;
      if (c > bestCount) {
        best = m;
        bestCount = c;
      } else if (c == bestCount && _rnd.nextDouble() < 0.1) {
        // small tie-break randomness
        best = m;
      }
    }
    // small chance to pick a suboptimal move on medium difficulty
    if (difficulty == 3 && _rnd.nextDouble() < 0.12) {
      return moves[_rnd.nextInt(moves.length)];
    }
    return best;
  }
}
