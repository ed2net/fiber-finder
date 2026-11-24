import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data.dart';
import 'state.dart';

/// Подбор одного размера шрифта, чтобы самый длинный текст влез в ширину
double fitFont(Iterable<String> texts, double maxW, double maxSize, FontWeight w, {double min = 8}) {
  if (maxW <= 0) return min;
  double widest = 0;
  for (final t in texts) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: TextStyle(fontSize: 100, fontWeight: w, letterSpacing: -0.3)),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    if (tp.width > widest) widest = tp.width;
  }
  if (widest == 0) return maxSize;
  final s = 100 * maxW / widest * 0.97;
  if (s < min) return min;
  if (s > maxSize) return maxSize;
  return s;
}

double textWidth(String t, double size, FontWeight w) {
  final tp = TextPainter(
    text: TextSpan(text: t, style: TextStyle(fontSize: size, fontWeight: w)),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  return tp.width;
}

/// Панель с рамкой
class Panel extends StatelessWidget {
  final Widget child;
  final Pal pal;
  final EdgeInsets padding;
  final double radius;
  const Panel({super.key, required this.child, required this.pal, this.padding = const EdgeInsets.all(8), this.radius = 18});
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: pal.panel,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: pal.panelBorder),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(pal.dark ? 0.25 : 0.06), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: child,
      );
}

/// Выпуклая стальная кнопка
class SteelButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double height;
  final double radius;
  final EdgeInsets padding;
  const SteelButton({super.key, required this.child, this.onTap, this.height = 40, this.radius = 13, this.padding = const EdgeInsets.symmetric(horizontal: 12)});
  @override
  State<SteelButton> createState() => _SteelButtonState();
}

class _SteelButtonState extends State<SteelButton> {
  bool down = false;
  @override
  Widget build(BuildContext context) {
    final edge = down ? 1.0 : 4.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => down = true),
      onTapCancel: () => setState(() => down = false),
      onTapUp: (_) => setState(() => down = false),
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          height: widget.height,
          margin: EdgeInsets.only(top: down ? 3 : 0, bottom: down ? 1 : 4),
          padding: widget.padding,
          decoration: BoxDecoration(
            gradient: Pal.accGrad,
            borderRadius: BorderRadius.circular(widget.radius),
            border: Border.all(color: Pal.accBorder),
            boxShadow: [
              BoxShadow(color: Pal.accEdge, offset: Offset(0, edge)),
              BoxShadow(color: const Color(0x4D14203A), blurRadius: down ? 4 : 12, offset: Offset(0, edge + 2)),
            ],
          ),
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            child: IconTheme.merge(data: const IconThemeData(color: Colors.white), child: Center(child: widget.child)),
          ),
        ),
      ),
    );
  }
}

/// Белый кружок со стрелкой вниз
class ChevronDot extends StatelessWidget {
  final double size;
  const ChevronDot({super.key, this.size = 24});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: Color(0xF2FFFFFF), shape: BoxShape.circle),
        child: Icon(Icons.keyboard_arrow_down_rounded, size: size * 0.85, color: Pal.accBot),
      );
}

/// Значок «трубка» (кольцо)
class TubeIcon extends StatelessWidget {
  final double size;
  final Color color;
  final bool glow;
  final Color fill;
  const TubeIcon({super.key, this.size = 24, this.color = const Color(0xFF29B6FF), this.glow = true, this.fill = Colors.transparent});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fill,
          border: Border.all(color: color, width: size * 0.2),
          boxShadow: glow ? [BoxShadow(color: color.withOpacity(0.7), blurRadius: 10)] : null,
        ),
      );
}

/// Значок «№» в рамке
class NoIcon extends StatelessWidget {
  final double size;
  final Color color;
  const NoIcon({super.key, this.size = 15, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(border: Border.all(color: color, width: 2), borderRadius: BorderRadius.circular(7)),
        child: Text('№', style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: color, height: 1.1)),
      );
}

/// Квадратик цвета (13–24 — с чёрной меткой)
class Swatch extends StatelessWidget {
  final int index;
  final double size;
  const Swatch({super.key, required this.index, this.size = 16});
  @override
  Widget build(BuildContext context) {
    final ci = index % 12;
    final mark = index >= 12;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fiberColors[ci].color,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 0, spreadRadius: 0.6)],
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(fiberColors[ci].color, Colors.white, 0.25)!, fiberColors[ci].color, Color.lerp(fiberColors[ci].color, Colors.black, 0.2)!],
        ),
      ),
      child: mark
          ? Center(child: Container(height: size * 0.22, color: ci == 7 ? Colors.white : const Color(0xFF111111)))
          : null,
    );
  }
}

/// Барабан: 3D-колесо с инерцией, по кругу
class DrumWheel extends StatefulWidget {
  final int count;
  final int value;
  final Pal pal;
  final ValueChanged<int> onChanged;

  /// itemBuilder(context, index, selected, rowWidth, rowHeight)
  final Widget Function(BuildContext, int, bool, double, double) itemBuilder;
  const DrumWheel({super.key, required this.count, required this.value, required this.pal, required this.onChanged, required this.itemBuilder});
  @override
  State<DrumWheel> createState() => _DrumWheelState();
}

class _DrumWheelState extends State<DrumWheel> {
  late FixedExtentScrollController ctl;
  late int sel;
  bool prog = false;
  int tok = 0;
  double ext = 48;
  Timer? snapTimer;

  @override
  void initState() {
    super.initState();
    sel = widget.value;
    ctl = FixedExtentScrollController(initialItem: widget.value);
  }

  @override
  void dispose() {
    snapTimer?.cancel();
    _spin?.cancel();
    ctl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DrumWheel old) {
    super.didUpdateWidget(old);
    if (widget.value != sel) {
      final v = widget.value;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) animateTo(v);
      });
    }
  }

  void animateTo(int v) {
    if (!ctl.hasClients) return;
    final n = widget.count;
    final cur = ctl.selectedItem;
    var d = mod(v - mod(cur, n), n);
    if (d > n / 2) d -= n;
    if (d == 0) return;
    prog = true;
    final my = ++tok;
    final ms = (220 + d.abs() * 6).clamp(220, 650);
    ctl.animateToItem(cur + d, duration: Duration(milliseconds: ms), curve: Curves.easeOutCubic).whenComplete(() {
      if (my == tok) prog = false;
    });
  }

  void step(int d) {
    if (!ctl.hasClients) return;
    prog = false;
    tok++;
    ctl.animateToItem(ctl.selectedItem + d, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }

  void snap() {
    if (!ctl.hasClients) return;
    final off = ctl.offset;
    final idx = (off / ext).round();
    if ((off - idx * ext).abs() > 0.5) {
      ctl.animateToItem(idx, duration: const Duration(milliseconds: 160), curve: Curves.easeOut);
    }
  }

  // Колесо мыши: каждый щелчок добавляет скорость — барабан крутится по инерции,
  // пока не остановится сам или его не остановят кликом
  // Колесо мыши: каждый щелчок разгоняет барабан, он крутится по инерции и плавно
  // останавливается; клик по барабану останавливает сразу
  double _spinV = 0; // строк в секунду
  Timer? _spin;
  DateTime _lastSig = DateTime(2000);
  DateTime _lastTick = DateTime.now();

  void _onSignal(PointerSignalEvent e) {
    if (e is! PointerScrollEvent) return;
    GestureBinding.instance.pointerSignalResolver.register(e, (ev) {
      final se = ev as PointerScrollEvent;
      if (!ctl.hasClients || se.scrollDelta.dy == 0) return;
      prog = false;
      tok++;
      final now = DateTime.now();
      final quick = now.difference(_lastSig).inMilliseconds < 300;
      _lastSig = now;
      final dir = se.scrollDelta.dy.sign;
      if (_spinV.sign != dir || !quick) _spinV = 0;
      _spinV += dir * (quick ? 5.0 : 3.5);
      if (_spinV.abs() > 80) _spinV = 80 * dir;
      _startSpin();
    });
  }

  void _startSpin() {
    if (_spin != null) return;
    _lastTick = DateTime.now();
    _spin = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted || !ctl.hasClients) return _stopSpin();
      final now = DateTime.now();
      final dt = now.difference(_lastTick).inMicroseconds / 1e6;
      _lastTick = now;
      ctl.jumpTo(ctl.offset + _spinV * ext * dt);
      _spinV *= 1 - (dt / 0.9).clamp(0.0, 1.0); // плавное затухание (~1 с)
      if (_spinV.abs() < 1.2) {
        _stopSpin();
        ctl.animateToItem((ctl.offset / ext).round(), duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
      }
    });
  }

  void _stopSpin() {
    _spin?.cancel();
    _spin = null;
    _spinV = 0;
  }

  void onSelected(int i) {
    final m = mod(i, widget.count);
    if (m != sel) setState(() => sel = m);
    if (!prog) widget.onChanged(m);
  }

  Widget arrow(IconData ic, int d) => SizedBox(
        height: 26,
        child: InkWell(
          onTap: () => step(d),
          child: Center(child: Icon(ic, size: 26, color: widget.pal.arrow)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final pal = widget.pal;
    return Container(
      decoration: BoxDecoration(
        gradient: pal.inner,
        borderRadius: BorderRadius.circular(13),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(pal.dark ? 0.5 : 0.15), blurRadius: 6, spreadRadius: -2)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        arrow(Icons.keyboard_arrow_up_rounded, -1),
        Expanded(
          child: LayoutBuilder(builder: (context, c) {
            final e0 = c.maxHeight / 4.7;
            ext = e0 < 30 ? 30.0 : (e0 > 70 ? 70.0 : e0);
            final rowH = ext - 5;
            final rowW = c.maxWidth - 4;
            final shade = pal.dark ? const Color(0xCC030A16) : const Color(0xCCC4D4E8);
            return Stack(children: [
              Listener(
                onPointerSignal: _onSignal,
                onPointerDown: (_) {
                  if (_spin != null) {
                    _stopSpin();
                    ctl.animateToItem((ctl.offset / ext).round(), duration: const Duration(milliseconds: 150), curve: Curves.easeOut);
                  }
                },
                child: NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n is ScrollStartNotification && n.dragDetails != null) {
                      prog = false;
                      tok++;
                    }
                    return false;
                  },
                  child: ListWheelScrollView.useDelegate(
                    controller: ctl,
                    itemExtent: ext,
                    diameterRatio: 1.45,
                    perspective: 0.0035,
                    physics: const FixedExtentScrollPhysics(parent: ClampingScrollPhysics()),
                    onSelectedItemChanged: onSelected,
                    childDelegate: ListWheelChildLoopingListDelegate(
                      children: List.generate(
                        widget.count,
                        (i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2.5),
                          child: Listener(onPointerSignal: _onSignal, child: widget.itemBuilder(context, i, i == sel, rowW, rowH)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // затемнение сверху и снизу — эффект барабана
              IgnorePointer(
                child: Column(children: [
                  Container(height: c.maxHeight * 0.28, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [shade, shade.withOpacity(0)]))),
                  const Spacer(),
                  Container(height: c.maxHeight * 0.28, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [shade, shade.withOpacity(0)]))),
                ]),
              ),
            ]);
          }),
        ),
        arrow(Icons.keyboard_arrow_down_rounded, 1),
      ]),
    );
  }
}

/// Строка барабана (фон, рамка выделения)
class WheelRow extends StatelessWidget {
  final bool selected;
  final Pal pal;
  final Widget child;
  final EdgeInsets padding;
  const WheelRow({super.key, required this.selected, required this.pal, required this.child, this.padding = const EdgeInsets.symmetric(horizontal: 5)});
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: selected ? pal.on : pal.row,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? pal.onBorder : Colors.transparent, width: 2),
          boxShadow: selected
              ? [BoxShadow(color: pal.onBorder.withOpacity(0.6), blurRadius: 10)]
              : [BoxShadow(color: Colors.black.withOpacity(pal.dark ? 0.35 : 0.15), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: DefaultTextStyle.merge(style: TextStyle(color: selected ? pal.onText : pal.rowText), child: child),
      );
}

/// Клавиатура для ввода числа (телефон: кнопки; компьютер: ещё и с клавиатуры)
Future<double?> showKeypad(BuildContext context, {required String title, required double initial, String unit = '', required Pal pal, int decimals = 1}) {
  return showDialog<double>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => _Keypad(title: title, initial: initial, unit: unit, pal: pal, decimals: decimals),
  );
}

class _Keypad extends StatefulWidget {
  final String title, unit;
  final double initial;
  final Pal pal;
  final int decimals;
  const _Keypad({required this.title, required this.initial, required this.unit, required this.pal, required this.decimals});
  @override
  State<_Keypad> createState() => _KeypadState();
}

class _KeypadState extends State<_Keypad> {
  late String s;
  bool fresh = true;
  final focus = FocusNode();

  @override
  void initState() {
    super.initState();
    s = widget.decimals == 0 ? widget.initial.round().toString() : widget.initial.toStringAsFixed(widget.decimals);
  }

  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  void press(String k) {
    if (k == 'ok') {
      Navigator.of(context).pop(double.tryParse(s));
      return;
    }
    if (k == 'x') {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      switch (k) {
        case 'bs':
          if (s.isNotEmpty) s = s.substring(0, s.length - 1);
          fresh = false;
          break;
        case 'pm':
          if (fresh) {
            s = '-';
            fresh = false;
          } else {
            s = s.startsWith('-') ? s.substring(1) : '-$s';
          }
          break;
        default:
          if (fresh) {
            s = s.startsWith('-') ? '-' : '';
            fresh = false;
          }
          if (k == '.' && s.contains('.')) return;
          if (s.replaceAll('-', '').length >= 6) return;
          s += k;
      }
    });
  }

  KeyEventResult onKey(FocusNode n, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      press('ok');
    } else if (k == LogicalKeyboardKey.escape) {
      press('x');
    } else if (k == LogicalKeyboardKey.backspace) {
      press('bs');
    } else {
      final ch = e.character;
      if (ch == null) return KeyEventResult.ignored;
      if (RegExp(r'^[0-9]$').hasMatch(ch)) {
        press(ch);
      } else if (ch == '.' || ch == ',') {
        press('.');
      } else if (ch == '-' || ch == '+') {
        press('pm');
      } else {
        return KeyEventResult.ignored;
      }
    }
    return KeyEventResult.handled;
  }

  Widget key(String label, String k, {bool acc = false, int flex = 1, IconData? icon}) => Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: acc
              ? SteelButton(height: 52, onTap: () => press(k), child: Text(label, style: const TextStyle(fontSize: 22)))
              : Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => press(k),
                    child: Ink(
                      height: 52,
                      decoration: BoxDecoration(gradient: widget.pal.btn, borderRadius: BorderRadius.circular(12), border: Border.all(color: widget.pal.btnBorder)),
                      child: Center(child: icon != null ? Icon(icon, size: 26, color: widget.pal.text) : Text(label, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: widget.pal.text))),
                    ),
                  ),
                ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final pal = widget.pal;
    final shown = s.isEmpty || s == '-' ? (s == '-' ? '−' : '0') : s.replaceAll('-', '−');
    return Focus(
      autofocus: true,
      focusNode: focus,
      onKeyEvent: onKey,
      child: Dialog(
        backgroundColor: pal.dark ? const Color(0xFF0D2546) : const Color(0xFFF4F8FD),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: pal.panelBorder)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(widget.title, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: pal.muted)),
              const SizedBox(height: 4),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                  Text(shown, style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: pal.text)),
                  if (widget.unit.isNotEmpty) Padding(padding: const EdgeInsets.only(left: 6), child: Text(widget.unit, style: TextStyle(fontSize: 16, color: pal.muted))),
                ]),
              ),
              const SizedBox(height: 8),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Column(children: [
                  Row(children: [key('7', '7'), key('8', '8'), key('9', '9'), key('', 'bs', icon: Icons.backspace_outlined)]),
                  Row(children: [key('4', '4'), key('5', '5'), key('6', '6'), key('±', 'pm')]),
                  Row(children: [key('1', '1'), key('2', '2'), key('3', '3'), key('.', '.')]),
                  Row(children: [key('', 'x', icon: Icons.close_rounded), key('0', '0'), key('OK', 'ok', acc: true, flex: 2)]),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
