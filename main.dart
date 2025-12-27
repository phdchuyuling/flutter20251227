import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const YiLinApp());
}

// ================== 卦辭資料 ==================

const Map<String, String> hexagramDefinitions = {
  "AS": "坤為地",
  "BS": "山地剝",
  "CS": "水地比",
  "DS": "風地觀",
  "ES": "雷地豫",
  "FS": "火地晉",
  "GS": "澤地萃",
  "HS": "天地否",
  "AT": "地山謙",
  "BT": "山地剝",
  "CT": "水山蹇",
  "DT": "風地觀",
  "ET": "雷山小過",
  "FT": "火山旅",
  "GT": "澤山咸",
  "HT": "天山遯",
  "AU": "地水師",
  "BU": "山水蒙",
  "CU": "坎為水",
  "DU": "風水渙",
  "EU": "雷水解",
  "FU": "火水未濟",
  "GU": "澤水困",
  "HU": "天水訟",
  "AV": "地風升",
  "BV": "山風蠱",
  "CV": "水風井",
  "DV": "巽為風",
  "EV": "雷風恆",
  "FV": "火風鼎",
  "GV": "澤風大過",
  "HV": "天風姤",
  "AW": "地雷復",
  "BW": "山雷頤",
  "CW": "水雷屯",
  "DW": "風雷益",
  "EW": "震為雷",
  "FW": "火雷噬嗑",
  "GW": "澤雷隨",
  "HW": "天雷無妄",
  "AX": "地火明夷",
  "BX": "山火賁",
  "CX": "水火既濟",
  "DX": "風火家人",
  "EX": "雷火豐",
  "FX": "離為火",
  "GX": "澤火革",
  "HX": "天火同人",
  "AY": "地澤臨",
  "BY": "山澤損",
  "CY": "水澤節",
  "DY": "風澤中孚",
  "EY": "雷澤歸妹",
  "FY": "火澤睽",
  "GY": "兌為澤",
  "HY": "天澤履",
  "AZ": "地天泰",
  "BZ": "山天大畜",
  "CZ": "水天需",
  "DZ": "風天小畜",
  "EZ": "雷天大壯",
  "FZ": "火天大有",
  "GZ": "澤天夬",
  "HZ": "乾為天",
};

const String _map1Chars = "ABCDEFGH";
const String _map2Chars = "STUVWXYZ";
final Random _rand = Random();

// ================== App（明暗 + 4 色佈景：ValueNotifier） ==================

class YiLinApp extends StatefulWidget {
  const YiLinApp({super.key});

  @override
  State<YiLinApp> createState() => _YiLinAppState();
}

class _YiLinAppState extends State<YiLinApp> {
  final ValueNotifier<bool> _dark = ValueNotifier<bool>(false);
  final ValueNotifier<Color> _seed = ValueNotifier<Color>(Colors.pink);

  @override
  void dispose() {
    _dark.dispose();
    _seed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_dark, _seed]),
      builder: (context, _) {
        final light = ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: _seed.value,
            brightness: Brightness.light,
          ),
        );

        final dark = ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: _seed.value,
            brightness: Brightness.dark,
          ),
        );

        return MaterialApp(
          title: '易林卜卦',
          debugShowCheckedModeBanner: false,
          theme: light,
          darkTheme: dark,
          themeMode: _dark.value ? ThemeMode.dark : ThemeMode.light,
          home: SplashGate(
            next: YiLinHomePage(
              dark: _dark,
              seed: _seed,
            ),
          ),
        );
      },
    );
  }
}

// ================== 開場 Splash（轉圖 + 5 秒疊加特效） ==================

class SplashGate extends StatefulWidget {
  final Widget next;

  const SplashGate({super.key, required this.next});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> with TickerProviderStateMixin {
  late final AnimationController _spin; // 每秒一圈
  late final AnimationController _fx; // 5 秒特效
  Timer? _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();

    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _fx = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      _seconds += 1;
      if (_seconds >= 5) {
        t.cancel();
        _spin.stop();
        _fx.stop();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => widget.next),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _spin.dispose();
    _fx.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Stack(
          children: [
            // 背景疊加特效（5 秒）
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _fx,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _SplashAuraPainter(
                      progress: _fx.value,
                      isDark: Theme.of(context).brightness == Brightness.dark,
                    ),
                  );
                },
              ),
            ),

            // 主體：旋轉 Logo + 光暈
            Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([_spin, _fx]),
                builder: (context, _) {
                  final t = _fx.value; // 0..1（5 秒）
                  final glow = 10 + 18 * (0.5 + 0.5 * sin(t * 2 * pi * 2));
                  final angle = _spin.value * 2 * pi;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: glow,
                              spreadRadius: 2,
                              color: cs.primary.withOpacity(0.22),
                            ),
                            BoxShadow(
                              blurRadius: glow * 0.85,
                              spreadRadius: 1,
                              color: cs.tertiary.withOpacity(0.14),
                            ),
                          ],
                        ),
                        child: Transform.rotate(
                          angle: angle,
                          child: SizedBox(
                            width: 260,
                            height: 260,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: Image.asset("Yeeling.png", fit: BoxFit.contain),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        "焦式易林",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "啟動中…",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.outline,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================== 主畫面 ==================

class YiLinHomePage extends StatefulWidget {
  final ValueNotifier<bool> dark;
  final ValueNotifier<Color> seed;

  const YiLinHomePage({
    super.key,
    required this.dark,
    required this.seed,
  });

  @override
  State<YiLinHomePage> createState() => _YiLinHomePageState();
}

class _YiLinHomePageState extends State<YiLinHomePage>
    with TickerProviderStateMixin {
  final TextEditingController _left1 = TextEditingController();
  final TextEditingController _left2 = TextEditingController();
  final TextEditingController _right1 = TextEditingController();
  final TextEditingController _right2 = TextEditingController();

  String? _leftImg;
  String? _rightImg;

  String _yilin = "";
  String _leftSymbol = "";
  String _rightSymbol = "";

  bool _isAnimating = false;

  bool _showUse = true;
  String _useText = "";

  // 再次卜卦：5 秒「絢麗重啟」效果
  bool _restarting = false;
  late final AnimationController _restartFx;
  Timer? _restartTimer;

  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _restartFx = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _loadUse();
  }

  Future<void> _loadUse() async {
    try {
      final t = await rootBundle.loadString("use.txt");
      if (!mounted) return;
      setState(() => _useText = t);
    } catch (_) {
      if (!mounted) return;
      setState(() => _useText = "（找不到 use.txt）");
    }
  }

  @override
  void dispose() {
    _restartTimer?.cancel();
    _restartFx.dispose();
    _tab.dispose();
    _left1.dispose();
    _left2.dispose();
    _right1.dispose();
    _right2.dispose();
    super.dispose();
  }

  String _map1(int n) => _map1Chars[n % 8];
  String _map2(int n) => _map2Chars[n % 8];

  String _randomSymbol() {
    return "${_map1(_rand.nextInt(8))}${_map2(_rand.nextInt(8))}";
  }

  // ================== 取卦動畫 ==================

  Future<void> _animateImages({required bool isLeft}) async {
    setState(() => _isAnimating = true);

    for (int i = 0; i < 30; i++) {
      final sym = _randomSymbol();
      final path = "$sym.jpg";

      if (!mounted) return;
      setState(() {
        if (isLeft) {
          _leftImg = path;
        } else {
          _rightImg = path;
        }
      });

      await Future.delayed(const Duration(milliseconds: 150));
    }

    if (!mounted) return;
    setState(() => _isAnimating = false);
  }

  // ================== 取卦 ==================

  Future<void> _getHex({required bool isLeft}) async {
    if (_isAnimating || _restarting) return;

    await _animateImages(isLeft: isLeft);

    try {
      final n1 = int.parse(isLeft ? _left1.text : _right1.text);
      final n2 = int.parse(isLeft ? _left2.text : _right2.text);

      final key = "${_map1(n1)}${_map2(n2)}";

      setState(() {
        if (isLeft) {
          _leftSymbol = key;
          _leftImg = "$key.jpg";
        } else {
          _rightSymbol = key;
          _rightImg = "$key.jpg";
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("請輸入三位數（例如 123）")),
      );
    }
  }

  // ================== 亂數 ==================

  Future<void> _randomGet({required bool isLeft}) async {
    if (_restarting) return;

    final a = 100 + _rand.nextInt(900);
    final b = 100 + _rand.nextInt(900);

    setState(() {
      if (isLeft) {
        _left1.text = a.toString();
        _left2.text = b.toString();
      } else {
        _right1.text = a.toString();
        _right2.text = b.toString();
      }
    });

    await _getHex(isLeft: isLeft);
  }

  // ================== 時間取值 ==================

  Future<void> _timeGet({required bool isLeft}) async {
    if (_restarting) return;

    final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final a = (ts ~/ 60) % 900 + 100;
    final b = (ts ~/ 3600) % 900 + 100;

    setState(() {
      if (isLeft) {
        _left1.text = a.toString();
        _left2.text = b.toString();
      } else {
        _right1.text = a.toString();
        _right2.text = b.toString();
      }
    });

    await _getHex(isLeft: isLeft);
  }

  // ================== 易林文字 ==================

  Future<void> _loadYilin() async {
    if (_showUse) {
      setState(() => _showUse = false);
    }

    if (_leftSymbol.isEmpty || _rightSymbol.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("請先完成一次取卦與二次取卦")),
      );
      return;
    }

    final path = "txt/${_leftSymbol}${_rightSymbol}.txt";

    try {
      final content = await rootBundle.loadString(path);
      setState(() => _yilin = content);
    } catch (_) {
      setState(() => _yilin = "找不到：$path");
    }
  }

  // ================== 再次卜卦：絢麗 5 秒特效 -> 回到片頭 Splash ==================

  void _restartWithFx() {
    if (_restarting) return;

    setState(() => _restarting = true);
    _restartFx
      ..reset()
      ..forward();

    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;

      _left1.clear();
      _left2.clear();
      _right1.clear();
      _right2.clear();
      _leftImg = null;
      _rightImg = null;
      _leftSymbol = "";
      _rightSymbol = "";
      _yilin = "";
      _showUse = true;

      setState(() => _restarting = false);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SplashGate(
            next: YiLinHomePage(
              dark: widget.dark,
              seed: widget.seed,
            ),
          ),
        ),
      );
    });
  }

  // ================== UI 共用元件 ==================

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).colorScheme.secondaryContainer,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _imageBox(String? img, {required double size}) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Container(
        key: ValueKey(img ?? "empty"),
        width: size,
        height: size,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: img == null
            ? const SizedBox.expand()
            : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(img, fit: BoxFit.contain),
              ),
      ),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(3),
      ],
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  ButtonStyle _compactButtonStyle(BuildContext context) {
    return ButtonStyle(
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _shadowWrap(Widget child) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      elevation: 2.8,
      shadowColor: cs.shadow.withOpacity(0.25),
      borderRadius: BorderRadius.circular(999),
      child: child,
    );
  }

  Widget _actionRow({
    required VoidCallback onGet,
    required VoidCallback onRandom,
    required VoidCallback onTime,
  }) {
    final style = _compactButtonStyle(context);

    Widget btn(String text, VoidCallback onTap) {
      return _shadowWrap(
        FilledButton(
          style: style,
          onPressed: onTap,
          child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        btn("自己取卦", onGet),
        btn("亂數取卦", onRandom),
        btn("時間取卦", onTime),
        if (_isAnimating)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: cs.tertiaryContainer,
            ),
            child: Text(
              "取卦中…",
              style: TextStyle(
                color: cs.onTertiaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }

  Widget _sidePanel({
    required String title,
    required TextEditingController c1,
    required TextEditingController c2,
    required String? img,
    required String symbol,
    required VoidCallback onGet,
    required VoidCallback onRandom,
    required VoidCallback onTime,
    required double imageSize,
  }) {
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxByHeight = (constraints.maxHeight - 220).clamp(140.0, imageSize);
        final finalImageSize = maxByHeight;

        return Card(
          elevation: 0,
          color: cs.surfaceContainerHighest,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: cs.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    if (symbol.isNotEmpty) _chip("卦象：$symbol"),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _numberField(controller: c1, label: "第一組三位數"),
                            const SizedBox(height: 8),
                            _numberField(controller: c2, label: "第二組三位數"),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _actionRow(
                                onGet: onGet,
                                onRandom: onRandom,
                                onTime: onTime,
                              ),
                            ),
                            if (symbol.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  hexagramDefinitions[symbol] ?? "",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: cs.primary,
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Align(
                        alignment: Alignment.topRight,
                        child: _imageBox(img, size: finalImageSize),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ 這裡已依需求修改：
  // 1) use.txt：不加粗，靠左對齊
  // 2) 卦詞檔：加粗顯示
  Widget _yilinPanel() {
    final cs = Theme.of(context).colorScheme;

    Widget content;
    if (_showUse) {
      content = Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              _useText.isEmpty ? "（載入 use.txt 中…）" : _useText,
              textAlign: TextAlign.left, // ✅ 靠左對齊
              style: TextStyle(
                fontSize: 16,
                height: 1.7,
                fontWeight: FontWeight.w400, // ✅ 不加粗
                color: cs.onSurface,
              ),
            ),
          ),
        ),
      );
    } else {
      content = Scrollbar(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(right: 6),
          child: Text(
            _yilin.isEmpty ? "" : _yilin,
            // ✅ 卦詞檔（txt/ASAS.txt 之類）加粗顯示
            style: const TextStyle(
              fontSize: 15,
              height: 1.55,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: content,
      ),
    );
  }

  Widget _bottomActions() {
    final style = _compactButtonStyle(context);

    return Wrap(
      spacing: 12,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        _shadowWrap(
          FilledButton(
            style: style,
            onPressed: _loadYilin,
            child: const Text("易林卜卦", style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
        _shadowWrap(
          FilledButton(
            style: style,
            onPressed: _restartWithFx,
            child: const Text("再次卜卦", style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }

  // ================== 主題控制列（AppBar actions） ==================

  Widget _themeControlsInline() {
    final palette = <Color>[
      Colors.pink,
      Colors.deepOrange,
      Colors.green,
      Colors.lightBlue,
    ];

    Widget dot(Color c) {
      final selected = widget.seed.value.value == c.value;
      return InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => widget.seed.value = c,
        child: Container(
          width: 20,
          height: 20,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c,
            border: Border.all(
              width: selected ? 3 : 2,
              color: selected
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: AnimatedBuilder(
        animation: Listenable.merge([widget.dark, widget.seed]),
        builder: (context, _) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("明", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(width: 6),
                Switch(
                  value: widget.dark.value,
                  onChanged: (v) => widget.dark.value = v,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 6),
                const Text("暗", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(width: 10),
                ...palette.map(dot),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================== Panels（手機/寬螢幕） ==================

  Widget _compactPortraitPanels({required double imageSize}) {
    return Column(
      children: [
        TabBar(
          controller: _tab,
          tabs: const [Tab(text: "一次取卦"), Tab(text: "二次取卦")],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _sidePanel(
                title: "一次取卦",
                c1: _left1,
                c2: _left2,
                img: _leftImg,
                symbol: _leftSymbol,
                onGet: () => _getHex(isLeft: true),
                onRandom: () => _randomGet(isLeft: true),
                onTime: () => _timeGet(isLeft: true),
                imageSize: imageSize,
              ),
              _sidePanel(
                title: "二次取卦",
                c1: _right1,
                c2: _right2,
                img: _rightImg,
                symbol: _rightSymbol,
                onGet: () => _getHex(isLeft: false),
                onRandom: () => _randomGet(isLeft: false),
                onTime: () => _timeGet(isLeft: false),
                imageSize: imageSize,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _widePanels({required double imageSize}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _sidePanel(
            title: "一次取卦",
            c1: _left1,
            c2: _left2,
            img: _leftImg,
            symbol: _leftSymbol,
            onGet: () => _getHex(isLeft: true),
            onRandom: () => _randomGet(isLeft: true),
            onTime: () => _timeGet(isLeft: true),
            imageSize: imageSize,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _sidePanel(
            title: "二次取卦",
            c1: _right1,
            c2: _right2,
            img: _rightImg,
            symbol: _rightSymbol,
            onGet: () => _getHex(isLeft: false),
            onRandom: () => _randomGet(isLeft: false),
            onTime: () => _timeGet(isLeft: false),
            imageSize: imageSize,
          ),
        ),
      ],
    );
  }

  // ================== 絢麗重啟遮罩（5 秒：全畫面佔滿，不再是方框旋轉） ==================

  Widget _restartOverlay() {
    final cs = Theme.of(context).colorScheme;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _restartFx,
        builder: (context, _) {
          final t = _restartFx.value; // 0..1

          final fade = Curves.easeInOut.transform(
            t < 0.10 ? (t / 0.10) : (t > 0.94 ? ((1 - t) / 0.06) : 1.0),
          );

          return Opacity(
            opacity: fade.clamp(0.0, 1.0),
            child: Stack(
              children: [
                // ✅ 白色蓋底：完全遮住主程式
                const Positioned.fill(
                  child: ColoredBox(color: Colors.white),
                ),

                // ✅ 全畫面動態背景（取代「方框旋轉」）
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RestartNebulaPainter(progress: t),
                  ),
                ),

                // 粒子光點（保留你喜歡的視覺）
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SparklePainter(progress: t),
                  ),
                ),

                // 中央訊息：呼吸縮放
                Center(
                  child: Transform.scale(
                    scale: 1.0 + 0.06 * sin(t * 6 * pi),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: cs.surface.withOpacity(0.78),
                        border: Border.all(color: cs.outlineVariant),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 26,
                            spreadRadius: 2,
                            color: Colors.black.withOpacity(0.10),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.6,
                              valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "正在重啟…",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================== UI ==================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("《焦氏易林》"),
        centerTitle: true,
        actions: [
          _themeControlsInline(),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, c) {
                final width = c.maxWidth;
                final isWide = width >= 900;
                final contentMaxWidth = isWide ? 1100.0 : 760.0;
                final baseImageSize = isWide ? 220.0 : 190.0;

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          Expanded(
                            flex: 6,
                            child: isWide
                                ? _widePanels(imageSize: baseImageSize)
                                : _compactPortraitPanels(imageSize: baseImageSize),
                          ),
                          const SizedBox(height: 10),
                          _bottomActions(),
                          const SizedBox(height: 10),
                          Expanded(
                            flex: 5,
                            child: _yilinPanel(),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            if (_restarting) _restartOverlay(),
          ],
        ),
      ),
    );
  }
}

// ================== 重啟粒子（光點旋轉） ==================

class _SparklePainter extends CustomPainter {
  final double progress; // 0..1
  _SparklePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseR = min(size.width, size.height) * 0.42;
    final t = progress;

    const n = 46;
    for (int i = 0; i < n; i++) {
      final fi = i / n;
      final a = (t * 2 * pi) + fi * 2 * pi * 2;
      final wobble = 0.10 * sin((t * 6 * pi) + fi * 10 * pi);
      final r = baseR * (0.55 + 0.45 * fi + wobble);

      final p = Offset(
        center.dx + cos(a) * r,
        center.dy + sin(a) * r,
      );

      final s = 1.2 + 2.8 * (0.5 + 0.5 * sin(a * 3 + t * 4 * pi));
      final alpha = (0.10 + 0.55 * (0.5 + 0.5 * sin(a + t * 2 * pi)))
          .clamp(0.0, 0.65);

      final cMix = (0.5 + 0.5 * sin(fi * 6 * pi + t * 2 * pi));
      final color = Color.lerp(
        const Color(0xFFFF4FD8),
        const Color(0xFF4DFFFF),
        cMix,
      )!
          .withOpacity(alpha);

      final paint = Paint()..color = color;
      canvas.drawCircle(p, s, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ================== ✅ 重啟全畫面背景（霓虹雲霧 + 流動波紋，取代方框旋轉） ==================

class _RestartNebulaPainter extends CustomPainter {
  final double progress; // 0..1
  _RestartNebulaPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.clamp(0.0, 1.0);
    final center = Offset(size.width / 2, size.height / 2);

    // 1) 全畫面霓虹雲霧（多層 radial 疊加）
    void blob(Offset c, double r, Color a, Color b, double alpha) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            a.withOpacity(alpha),
            b.withOpacity(alpha * 0.70),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r));
      canvas.drawCircle(c, r, paint);
    }

    final diag = sqrt(size.width * size.width + size.height * size.height);
    final drift = 0.08 * diag;
    final dx = drift * sin(t * 2 * pi);
    final dy = drift * cos(t * 2 * pi * 0.9);

    blob(
      Offset(center.dx - diag * 0.18 + dx, center.dy - diag * 0.12 + dy),
      diag * (0.42 + 0.05 * sin(t * 2 * pi)),
      const Color(0xFFFF4FD8),
      const Color(0xFF4DFFFF),
      0.32,
    );

    blob(
      Offset(center.dx + diag * 0.22 - dx * 0.8, center.dy - diag * 0.08 + dy * 0.6),
      diag * (0.38 + 0.06 * cos(t * 2 * pi)),
      const Color(0xFF4DFFFF),
      const Color(0xFFFFC84D),
      0.26,
    );

    blob(
      Offset(center.dx + dx * 0.5, center.dy + diag * 0.18 - dy * 0.7),
      diag * (0.46 + 0.04 * sin(t * 2 * pi * 1.3)),
      const Color(0xFFFFC84D),
      const Color(0xFFFF4FD8),
      0.20,
    );

    // 2) 全畫面流動光帶（線性漸層，角度隨時間轉）
    final sweepAngle = t * 2 * pi;
    final band = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          const Color(0xFFFF4FD8).withOpacity(0.12),
          const Color(0xFF4DFFFF).withOpacity(0.14),
          const Color(0xFFFFC84D).withOpacity(0.12),
          Colors.transparent,
        ],
        stops: const [0.22, 0.40, 0.55, 0.68, 0.86],
        transform: GradientRotation(sweepAngle),
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, band);

    // 3) 柔和波紋（用大量細線圈製造流動感）
    final rings = 22;
    for (int i = 0; i < rings; i++) {
      final fi = i / rings;
      final rr = (min(size.width, size.height) * (0.18 + 0.62 * fi)) *
          (0.98 + 0.03 * sin(t * 2 * pi * 2 + fi * 8 * pi));
      final a = (0.02 + 0.06 * (1 - fi)) * (0.55 + 0.45 * sin(t * 2 * pi));
      final color = Color.lerp(
        const Color(0xFFFF4FD8),
        const Color(0xFF4DFFFF),
        0.5 + 0.5 * sin(fi * 6 * pi + t * 2 * pi),
      )!
          .withOpacity(a.clamp(0.0, 0.10));

      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 + 0.4 * (1 - fi)
        ..color = color;

      canvas.drawCircle(center, rr, p);
    }
  }

  @override
  bool shouldRepaint(covariant _RestartNebulaPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ================== Splash 背景特效（5 秒光暈 + 流動 + 星點環繞） ==================

class _SplashAuraPainter extends CustomPainter {
  final double progress; // 0..1
  final bool isDark;

  _SplashAuraPainter({
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.clamp(0.0, 1.0);
    final center = Offset(size.width / 2, size.height / 2);

    // 背景基底（讓特效更乾淨）
    final basePaint = Paint()
      ..color = (isDark ? Colors.black : Colors.white).withOpacity(0.02);
    canvas.drawRect(Offset.zero & size, basePaint);

    // 光暈脈動
    final pulse = 0.5 + 0.5 * sin(t * 2 * pi * 2); // 兩次脈動
    final r0 = min(size.width, size.height) * (0.22 + 0.05 * pulse);
    final r1 = min(size.width, size.height) * (0.55 + 0.06 * pulse);

    final aura = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF4FD8).withOpacity(0.14 + 0.08 * pulse),
          const Color(0xFF4DFFFF).withOpacity(0.10 + 0.06 * pulse),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r1));

    canvas.drawCircle(center, r1, aura);

    // 霓虹流動光帶（斜向 sweep）
    final sweepAngle = t * 2 * pi;
    final band = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          const Color(0xFFFF4FD8).withOpacity(0.08),
          const Color(0xFF4DFFFF).withOpacity(0.10),
          Colors.transparent,
        ],
        stops: const [0.35, 0.50, 0.65, 0.80],
        transform: GradientRotation(sweepAngle),
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, band);

    // 星點環繞（圍繞中心，淡入淡出）
    final alphaGate = (t < 0.12)
        ? (t / 0.12)
        : (t > 0.92)
            ? ((1 - t) / 0.08)
            : 1.0;

    const n = 40;
    for (int i = 0; i < n; i++) {
      final fi = i / n;
      final a = sweepAngle + fi * 2 * pi * 1.8;
      final rr = r0 + (r1 - r0) * (0.55 + 0.45 * sin(fi * 6 * pi + t * 2 * pi));
      final p = Offset(center.dx + cos(a) * rr, center.dy + sin(a) * rr);

      final s = 0.9 + 2.4 * (0.5 + 0.5 * sin(a * 3 + t * 4 * pi));
      final alpha = (0.05 + 0.22 * (0.5 + 0.5 * sin(a + t * 2 * pi))) * alphaGate;

      final cMix = (0.5 + 0.5 * sin(fi * 6 * pi + t * 2 * pi));
      final color = Color.lerp(
        const Color(0xFFFF4FD8),
        const Color(0xFF4DFFFF),
        cMix,
      )!
          .withOpacity(alpha.clamp(0.0, 0.35));

      canvas.drawCircle(p, s, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _SplashAuraPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}