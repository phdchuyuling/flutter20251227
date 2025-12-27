<<<<<<< HEAD
import 'package:flutter/material.dart';

void main() => runApp(const BMICalculator());

class BMICalculator extends StatelessWidget {
  const BMICalculator({super.key});
=======
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game.dart';
import 'ai.dart';

void main() {
  runApp(const ReversiApp());
}

class ReversiApp extends StatelessWidget {
  const ReversiApp({Key? key}) : super(key: key);
>>>>>>> 3a33b57 (Add files from Project_2025-1210)

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
<<<<<<< HEAD
      home: const BMIScreen(),
      debugShowCheckedModeBanner: false,
=======
      title: 'Reversi 奧賽羅黑白棋',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ReversiPage(),
>>>>>>> 3a33b57 (Add files from Project_2025-1210)
    );
  }
}

<<<<<<< HEAD
class BMIScreen extends StatefulWidget {
  const BMIScreen({super.key});

  @override
  State<BMIScreen> createState() => _BMIScreenState();
}

class _BMIScreenState extends State<BMIScreen> {
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  String result = "";

  void calculateBMI() {
    final double height = double.tryParse(heightController.text) ?? 0;
    final double weight = double.tryParse(weightController.text) ?? 0;
    if (height > 0 && weight > 0) {
      final bmi = weight / ((height / 100) * (height / 100));
      setState(() {
        result = "你的 BMI 為：${bmi.toStringAsFixed(2)}";
      });
    } else {
      setState(() {
        result = "請輸入正確的身高與體重";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("BMI 計算器")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "身高 (cm)"),
            ),
            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "體重 (kg)"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: calculateBMI, child: const Text("計算")),
            const SizedBox(height: 20),
            Text(result, style: const TextStyle(fontSize: 20)),
=======
class ReversiPage extends StatefulWidget {
  const ReversiPage({Key? key}) : super(key: key);

  @override
  State<ReversiPage> createState() => _ReversiPageState();
}

/// Intent used for undo keyboard shortcut (Ctrl+Z)
class UndoIntent extends Intent {
  const UndoIntent();
}

class _ReversiPageState extends State<ReversiPage> {
  final Game _game = Game();
  SimpleAI _ai = SimpleAI();
  late FocusNode _mainFocusNode;
  String _status = '你的回合（黑）';
  bool _aiThinking = false;
  int _aiSpeed = 3; // 1 (fastest) .. 5 (slowest)
  int _aiDifficulty =
      3; // 1 (easiest) .. 5 (hardest), default 3 = current behaviour
  // highlight state for AI moves
  Set<int> _highlightCells = {};
  Timer? _highlightTimer;
  bool _highlightVisible = true;
  int _highlightBlinkCount = 0;

  void _newGame() {
    setState(() {
      _game.reset();
      _status = '你的回合（黑）';
      _aiThinking = false;
    });
  }

  void _onUndo() async {
    // If AI is thinking, don't allow undo
    if (_aiThinking) return;
    bool ok = _game.undoTwoMoves();
    if (!ok) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: const Text('無法悔棋（沒有足夠的步數）'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('確認'),
            ),
          ],
        ),
      );
      return;
    }

    // clear highlights and update status
    setState(() {
      _highlightTimer?.cancel();
      _highlightTimer = null;
      _highlightCells.clear();
      _highlightVisible = true;
      _status = '已悔棋，請下你的棋（黑）';
      _aiThinking = false;
    });
  }

  void _onTapCell(int idx) {
    if (_aiThinking) return;
    if (_game.currentPlayer != 1) return; // not human's turn
    if (!_game.makeMove(idx, 1)) return;
    _afterHumanMove();
  }

  void _afterHumanMove() {
    setState(() {
      _status = '電腦思考中...';
      _aiThinking = true;
    });
    // small delay to show move; duration controlled by _aiSpeed
    Future.delayed(_aiDelayDuration(), () {
      _doAIMoveIfAny();
    });
  }

  Future<void> _doAIMoveIfAny() async {
    if (_game.isGameOver()) {
      _finishGame();
      return;
    }
    var moves = _game.legalMoves(-1);
    if (moves.isEmpty) {
      // AI has no move -> show dialog then back to human
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: const Text('無子可下，請繼續'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('確認'),
            ),
          ],
        ),
      );
      setState(() {
        _game.currentPlayer = 1;
        _status = '你的回合（黑）';
        _aiThinking = false;
      });
      return;
    }
    int aiMove = _ai.chooseMove(_game);
    if (aiMove >= 0) {
      // compute flips first so we can highlight them
      var flipped = _game.flipsForMove(aiMove, -1);
      _game.makeMove(aiMove, -1);
      // include the placed piece and flipped pieces
      _startHighlight({aiMove, ...flipped});
    }
    if (_game.isGameOver()) {
      _finishGame();
      return;
    }
    setState(() {
      _status = '你的回合（黑）';
      _aiThinking = false;
    });
  }

  void _startHighlight(Set<int> cells) {
    // cancel previous timer if any
    _highlightTimer?.cancel();
    _highlightCells = cells;
    _highlightVisible = true;
    _highlightBlinkCount = 0;
    // blink a few times then clear
    _highlightTimer = Timer.periodic(const Duration(milliseconds: 300), (t) {
      setState(() {
        _highlightVisible = !_highlightVisible;
      });
      _highlightBlinkCount++;
      if (_highlightBlinkCount >= 6) {
        t.cancel();
        _highlightTimer = null;
        setState(() {
          _highlightCells.clear();
          _highlightVisible = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _mainFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // ensure AI gets the initial difficulty
    _ai.difficulty = _aiDifficulty;
    _mainFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mainFocusNode.requestFocus();
    });
  }

  void _finishGame() {
    var sc = _game.score();
    String result;
    if (sc['black']! > sc['white']!)
      result = '你贏了！';
    else if (sc['black']! < sc['white']!)
      result = '電腦贏了';
    else
      result = '平手';
    setState(() {
      _status = '遊戲結束：$result（黑:${sc['black']} 白:${sc['white']}）';
      _aiThinking = false;
    });
  }

  Widget _buildCell(int idx) {
    int v = _game.board[idx];
    Color bg = Colors.green[700]!;
    Widget content = const SizedBox.shrink();
    if (v == 1)
      content = const CircleAvatar(backgroundColor: Colors.black);
    else if (v == -1)
      content = const CircleAvatar(backgroundColor: Colors.white);

    bool isLegal = _game.board[idx] == 0 &&
        _game.flipsForMove(idx, _game.currentPlayer).isNotEmpty &&
        _game.currentPlayer == 1 &&
        !_aiThinking;

    return GestureDetector(
      onTap: () => _onTapCell(idx),
      child: Container(
        margin: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: Colors.black),
        ),
        child: Stack(
          children: [
            Center(child: SizedBox(width: 34, height: 34, child: content)),
            if (isLegal)
              // show legal move indicator at the center of the cell
              Positioned.fill(
                child: Center(
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.yellow,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black26),
                    ),
                  ),
                ),
              ),
            // highlight overlay for AI changes (smooth fade, red color)
            if (_highlightCells.contains(idx))
              Positioned.fill(
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _highlightVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.withOpacity(0.22),
                        border: Border.all(color: Colors.redAccent, width: 2.5),
                      ),
                    ),
                  ),
                ),
              ),
>>>>>>> 3a33b57 (Add files from Project_2025-1210)
          ],
        ),
      ),
    );
  }
<<<<<<< HEAD
=======

  @override
  Widget build(BuildContext context) {
    var sc = _game.score();
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        // Ctrl+Z for undo
        SingleActivator(LogicalKeyboardKey.keyZ, control: true):
            const UndoIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          UndoIntent: CallbackAction<UndoIntent>(onInvoke: (intent) {
            _onUndo();
            return null;
          }),
        },
        child: Focus(
          focusNode: _mainFocusNode,
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              title: Text('Reversi 奧賽羅黑白棋 (難度: $_aiDifficulty)'),
              actions: [
                IconButton(onPressed: _onUndo, icon: const Icon(Icons.undo)),
                IconButton(
                    onPressed: _newGame, icon: const Icon(Icons.refresh)),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Text(_status, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Chip(label: Text('黑: ${sc['black']}')),
                      const SizedBox(width: 12),
                      Chip(label: Text('白: ${sc['white']}')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: GridView.builder(
                        itemCount: Game.size * Game.size,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: Game.size),
                        itemBuilder: (context, index) => _buildCell(index),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 第一行：重新開始、悔棋，置中並支援換行以避免溢出
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _newGame,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('重新開始'),
                        style: ElevatedButton.styleFrom(
                          elevation: 6,
                          shadowColor: Colors.black54,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _onUndo,
                        icon: const Icon(Icons.undo, size: 18),
                        label: const Text('悔棋'),
                        style: ElevatedButton.styleFrom(
                          elevation: 6,
                          shadowColor: Colors.black54,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 第二行：速度與難度，置中並支援換行
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 24,
                    runSpacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('電腦速度：', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          DropdownButton<int>(
                            value: _aiSpeed,
                            items: [1, 2, 3, 4, 5]
                                .map((v) => DropdownMenuItem<int>(
                                    value: v, child: Text('$v')))
                                .toList(),
                            onChanged: (val) {
                              if (val == null) return;
                              setState(() {
                                _aiSpeed = val;
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('電腦難度：', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          DropdownButton<int>(
                            value: _aiDifficulty,
                            items: [1, 2, 3, 4, 5]
                                .map((v) => DropdownMenuItem<int>(
                                    value: v, child: Text('$v')))
                                .toList(),
                            onChanged: (val) {
                              if (val == null) return;
                              setState(() {
                                _aiDifficulty = val;
                                // apply to AI instance (field assignment)
                                try {
                                  _ai.setDifficulty(val);
                                } catch (e) {
                                  // fallback: if method not present, ignore
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('提示：黃色圓點表示可下的位置（僅在人類回合顯示）',
                      style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Duration _aiDelayDuration() {
    // Map speed level to milliseconds. 1 = fastest, 5 = slowest
    switch (_aiSpeed) {
      case 1:
        return const Duration(milliseconds: 100);
      case 2:
        return const Duration(milliseconds: 500);
      case 3:
        return const Duration(milliseconds: 1000);
      case 4:
        return const Duration(milliseconds: 3000);
      case 5:
        return const Duration(milliseconds: 5000);
      default:
        return const Duration(milliseconds: 500);
    }
  }
>>>>>>> 3a33b57 (Add files from Project_2025-1210)
}
