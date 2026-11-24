import 'package:flutter/material.dart';
import 'data.dart';
import 'state.dart';
import 'widgets.dart';

/// Экран «Таблица волокон»
class FiberPage extends StatelessWidget {
  final AppState s;
  final Pal pal;
  const FiberPage({super.key, required this.s, required this.pal});

  // кэш размеров шрифта названий (один размер на всё колесо)
  static final Map<String, double> _fontCache = {};

  double _nameFont(int count, bool tube, double w, double h) {
    final key = '$count|$tube|${s.lang}|${w.toStringAsFixed(0)}|${h.toStringAsFixed(0)}';
    return _fontCache.putIfAbsent(key, () {
      final numF = _numFont(h, w);
      final numW = textWidth('$count', numF, FontWeight.w800);
      final avail = w - 10 - 4 - numW - 16 - 9;
      final names = [for (var i = 0; i < count; i++) colorName(i, s.lang, tube: tube)];
      final cap = h * 0.42;
      return fitFont(names, avail, cap < 10 ? 10.0 : (cap > 19 ? 19.0 : cap), FontWeight.w500, min: 8);
    });
  }

  double _numFont(double h, double w) {
    var a = h * 0.52;
    if (a < 12) a = 12;
    if (a > 24) a = 24;
    final b = w * 0.16 + 6;
    if (a > b) a = b < 10 ? 10 : b;
    return a;
  }

  Widget _colorRow(BuildContext ctx, int i, bool sel, double w, double h, {required bool tube, required int count}) {
    final nf = _numFont(h, w);
    final namef = _nameFont(count, tube, w, h);
    return WheelRow(
      selected: sel,
      pal: pal,
      child: Row(children: [
        Text('${i + 1}', maxLines: 1, softWrap: false, style: TextStyle(fontSize: sel ? nf * 1.08 : nf, fontWeight: FontWeight.w800)),
        const SizedBox(width: 4),
        Swatch(index: i, size: 16),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            colorName(i, s.lang, tube: tube),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.clip,
            style: TextStyle(fontSize: namef, fontWeight: sel ? FontWeight.w500 : FontWeight.w400, letterSpacing: -0.3),
          ),
        ),
      ]),
    );
  }

  Widget _numRow(BuildContext ctx, int i, bool sel, double w, double h) {
    var f = h * (sel ? 0.66 : 0.6);
    if (f < 12) f = 12;
    if (f > 34) f = 34;
    final maxByW = _fontCache.putIfAbsent('num|${s.cable.total}|${w.toStringAsFixed(0)}', () => fitFont(['${s.cable.total}'], w - 10, 40, FontWeight.w800));
    return WheelRow(
      selected: sel,
      pal: pal,
      padding: EdgeInsets.zero,
      child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text('${i + 1}', maxLines: 1, softWrap: false, style: TextStyle(fontSize: f < maxByW ? f : maxByW, fontWeight: FontWeight.w800)))),
    );
  }

  void _pickCable(BuildContext context) {
    final list = cables.where((c) => c.f == s.cable.f).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: pal.dark ? const Color(0xFF0D2546) : const Color(0xFFF4F8FD),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              for (final c in list)
                ListTile(
                  title: Text(c.name,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 19, fontWeight: c.id == s.cable.id ? FontWeight.w800 : FontWeight.w500, color: c.id == s.cable.id ? Pal.accBot : pal.text)),
                  selected: c.id == s.cable.id,
                  onTap: () {
                    Navigator.pop(ctx);
                    s.setCable(c.id);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _enterNumber(BuildContext context) async {
    final n = s.cable.total;
    final v = await showKeypad(context, title: '${s.tr('num')}  (1–$n)', initial: s.number + 1.0, pal: pal, decimals: 0);
    if (v == null) return;
    final k = v.abs().round().clamp(1, n) - 1;
    s.setNumber(k);
  }

  Widget _structButton(int n) {
    final on = s.cable.f == n;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: GestureDetector(
          onTap: () => s.setStructure(n),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              gradient: on ? Pal.accGrad : pal.btn,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: on ? Pal.accBorder : pal.btnBorder),
              boxShadow: on ? const [BoxShadow(color: Color(0x40000000), blurRadius: 6, offset: Offset(0, 3))] : null,
            ),
            child: Column(children: [
              Text(s.tr('s$n'), style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: on ? Colors.white : pal.text, height: 1.15)),
              Text(s.tr('inTube'), style: TextStyle(fontSize: 12.5, color: on ? Colors.white : pal.text, height: 1.15)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _column({required Widget header, required Widget wheel}) => Container(
        padding: const EdgeInsets.fromLTRB(2, 0, 2, 4),
        decoration: BoxDecoration(gradient: pal.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: pal.panelBorder)),
        child: Column(children: [SizedBox(height: 42, child: Center(child: header)), Expanded(child: wheel)]),
      );

  @override
  Widget build(BuildContext context) {
    final c = s.cable;
    final tubeColor = fiberColors[s.t % 12].color;
    final fibColor = fiberColors[s.f % 12].color;
    return Column(children: [
      Expanded(
        child: Panel(
          pal: pal,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
              child: Text(s.tr('struct'), style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: pal.text)),
            ),
            Row(children: [_structButton(6), _structButton(12), _structButton(24)]),
            const SizedBox(height: 8),
            Center(
              child: FractionallySizedBox(
                widthFactor: 0.76,
                child: SteelButton(
                  height: 42,
                  onTap: () => _pickCable(context),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.blur_circular_rounded, size: 22),
                    const SizedBox(width: 10),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(c.name, textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 21, letterSpacing: 0.5)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const ChevronDot(),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Expanded(
                  flex: 114,
                  child: _column(
                    header: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(children: [
                        TubeIcon(size: 24, fill: pal.dark ? Colors.white : Colors.transparent),
                        const SizedBox(width: 7),
                        Text(s.tr('tube'), style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: pal.text)),
                      ]),
                    ),
                    wheel: DrumWheel(
                      key: ValueKey('T${c.id}'),
                      count: c.t,
                      value: s.t,
                      pal: pal,
                      onChanged: s.setTube,
                      itemBuilder: (ctx, i, sel, w, h) => _colorRow(ctx, i, sel, w, h, tube: true, count: c.t),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 114,
                  child: _column(
                    header: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(children: [
                        Container(width: 32, height: 9, decoration: BoxDecoration(color: pal.dark ? Colors.white : const Color(0xFF0A3A7A), borderRadius: BorderRadius.circular(9))),
                        const SizedBox(width: 7),
                        Text(s.tr('fiber'), style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: pal.text)),
                      ]),
                    ),
                    wheel: DrumWheel(
                      key: ValueKey('F${c.id}'),
                      count: c.f,
                      value: s.f,
                      pal: pal,
                      onChanged: s.setFiber,
                      itemBuilder: (ctx, i, sel, w, h) => _colorRow(ctx, i, sel, w, h, tube: false, count: c.f),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 42,
                  child: _column(
                    header: SteelButton(
                      height: 32,
                      radius: 9,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      onTap: () => _enterNumber(context),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(children: [NoIcon(size: 13, color: Colors.white), SizedBox(width: 3), Icon(Icons.edit_rounded, size: 15)]),
                      ),
                    ),
                    wheel: DrumWheel(
                      key: ValueKey('N${c.id}'),
                      count: c.total,
                      value: s.number,
                      pal: pal,
                      onChanged: s.setNumber,
                      itemBuilder: _numRow,
                    ),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 7),
      // ===== Результат =====
      Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          gradient: pal.dark
              ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0A2036), Color(0xFF06172A)])
              : const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFF2F7FD)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: pal.resBorder, width: 2),
          boxShadow: [BoxShadow(color: pal.dark ? const Color(0x732FE0A8) : const Color(0x1F143C78), blurRadius: 16)],
        ),
        child: IntrinsicHeight(
          child: Row(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Center(child: Text(s.tr('result'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: pal.resLabel))),
            ),
            _divider(),
            _resCell(
              head: Row(mainAxisSize: MainAxisSize.min, children: [TubeIcon(size: 15, glow: false), const SizedBox(width: 4), Text(s.tr('tube'))]),
              value: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('${s.t + 1}'),
                const SizedBox(width: 6),
                TubeIcon(size: 30, color: tubeColor, fill: pal.dark ? Colors.transparent : Colors.white),
              ]),
            ),
            _divider(),
            _resCell(
              flex: 115,
              head: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 18, height: 6, decoration: BoxDecoration(color: pal.dark ? Colors.white : const Color(0xFF0A3A7A), borderRadius: BorderRadius.circular(6))),
                const SizedBox(width: 4),
                Text(s.tr('fiber')),
              ]),
              value: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('${s.f + 1}'),
                const SizedBox(width: 6),
                Container(
                  width: 50,
                  height: 17,
                  decoration: BoxDecoration(color: fibColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xE6A0AAB9), width: 2)),
                ),
              ]),
            ),
            _divider(),
            _resCell(
              flex: 85,
              head: NoIcon(size: 12, color: pal.text),
              value: Text('${s.number + 1}', style: TextStyle(fontSize: 40, color: pal.resBig)),
            ),
          ]),
        ),
      ),
    ]);
  }

  Widget _divider() => Container(width: 1.5, margin: const EdgeInsets.symmetric(vertical: 2), color: pal.text.withOpacity(0.18));

  Widget _resCell({required Widget head, required Widget value, int flex = 100}) => Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            FittedBox(fit: BoxFit.scaleDown, child: DefaultTextStyle.merge(style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: pal.text), child: head)),
            const SizedBox(height: 6),
            SizedBox(
              height: 42,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: DefaultTextStyle.merge(style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: pal.resNum), child: value),
              ),
            ),
          ]),
        ),
      );
}
