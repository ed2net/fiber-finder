import 'package:flutter/material.dart';
import 'data.dart';
import 'state.dart';
import 'widgets.dart';

/// Экран «Расчёт потерь» (GPON, 1:64)
/// Точки: OLT → (кабель) → вход муфты → [сплиттер] → выход муфты = вход здания → [сплиттер] → клиент
class LossPage extends StatelessWidget {
  final AppState s;
  final Pal pal;
  const LossPage({super.key, required this.s, required this.pal});

  static const _orange = Color(0xFFF5A623);

  Widget _icon(IconData ic, Color color) => Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(gradient: pal.inner, borderRadius: BorderRadius.circular(11)),
        child: Icon(ic, size: 26, color: color),
      );

  Widget _node({required Widget child}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(gradient: pal.btn, borderRadius: BorderRadius.circular(14), border: Border.all(color: pal.btnBorder)),
        child: child,
      );

  Widget _link() => Center(
        child: Container(
          width: 4,
          height: 10,
          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_orange, Color(0xFFF8D34A)])),
        ),
      );

  Widget _title(String t) => Text(t, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: pal.text));

  Widget _loss(String t) => Text(t, textDirection: TextDirection.ltr, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: pal.bad));

  /// Кнопка-значение (нажать → ввести замер)
  Widget _val(BuildContext context, String key, {String? title, double fontSize = 18, bool unit = true, Color? color, double height = 36}) {
    final v = s.points[key]!;
    final isAnchor = s.anchor == key;
    return GestureDetector(
      onTap: () async {
        final r = await showKeypad(context, title: title ?? (key == 'olt' ? 'OLT' : s.tr(_names[key]!)), initial: v, unit: 'dBm', pal: pal);
        if (r != null) s.setPoint(key, r);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            gradient: isAnchor ? pal.on : pal.panel,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isAnchor ? Pal.accTop : pal.btnBorder, width: 1.5),
            boxShadow: isAnchor ? [BoxShadow(color: Pal.accTop.withOpacity(0.45), spreadRadius: 2)] : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(mainAxisSize: MainAxisSize.min, textDirection: TextDirection.ltr, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              Text(fmtSigned(v), style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800, color: color ?? pal.text)),
              if (unit) Padding(padding: const EdgeInsets.only(left: 4), child: Text('dBm', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: pal.muted))),
            ]),
          ),
        ),
      ),
    );
  }

  static const _names = {'cin': 'pCin', 'cout': 'pCout', 'bout': 'pBout'};

  Widget _io(BuildContext context, String inKey, String outKey, {String? inTitle}) => Row(children: [
        Expanded(
          child: Column(children: [
            Text(s.tr('in'), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: pal.muted)),
            const SizedBox(height: 2),
            _val(context, inKey, title: inTitle),
          ]),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(6, 14, 6, 0), child: Icon(Icons.arrow_forward_rounded, size: 20, color: pal.muted)),
        Expanded(
          child: Column(children: [
            Text(s.tr('out'), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: pal.muted)),
            const SizedBox(height: 2),
            _val(context, outKey),
          ]),
        ),
      ]);

  void _pickSplitter(BuildContext context, List<Splitter> list, int cur, ValueChanged<int> onPick) {
    showModalBottomSheet(
      context: context,
      backgroundColor: pal.dark ? const Color(0xFF0D2546) : const Color(0xFFF4F8FD),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          for (var i = 0; i < list.length; i++)
            ListTile(
              title: Text('${list[i].name}   (−${_n(list[i].loss)} dB)',
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 19, fontWeight: i == cur ? FontWeight.w800 : FontWeight.w500, color: i == cur ? Pal.accBot : pal.text)),
              onTap: () {
                Navigator.pop(ctx);
                onPick(i);
              },
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  static String _n(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  Widget _splitterButton(BuildContext context, Splitter sp, VoidCallback onTap) => Center(
        child: FractionallySizedBox(
          widthFactor: 0.62,
          child: SteelButton(
            height: 36,
            radius: 12,
            onTap: onTap,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(sp.name, textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 19, letterSpacing: 0.5)),
              const SizedBox(width: 10),
              const ChevronDot(size: 22),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final p = s.points;
    final fib = s.km * attPerKm;
    final lc = splClosure[s.spC], lb = splBuilding[s.spB];
    final mar = p['bout']! - threshold;
    final ok = mar >= 0;
    final okColor = pal.dark ? const Color(0xFF3FE08A) : const Color(0xFF1FA760);
    final badColor = pal.dark ? const Color(0xFFFF6B6B) : const Color(0xFFE5484D);
    final stateColor = ok ? okColor : badColor;
    final kmText = s.km == s.km.roundToDouble() ? s.km.toStringAsFixed(0) : s.km.toStringAsFixed(1);

    return Panel(
      pal: pal,
      child: LayoutBuilder(
        builder: (context, c) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight),
            child: IntrinsicHeight(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                // OLT
                _node(
                  child: Row(children: [
                    _icon(Icons.router_rounded, Pal.accTop),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, children: [
                        _title('OLT'),
                        Text(s.tr('oltS'), style: TextStyle(fontSize: 12, color: pal.muted)),
                      ]),
                    ),
                    SizedBox(width: 120, child: _val(context, 'olt')),
                  ]),
                ),
                _link(),
                // Расстояние
                _node(
                  child: Row(children: [
                    _icon(Icons.radio_button_checked_rounded, _orange),
                    const SizedBox(width: 9),
                    Expanded(child: _title(s.tr('len'))),
                    GestureDetector(
                      onTap: () async {
                        final r = await showKeypad(context, title: s.tr('len'), initial: s.km, unit: s.tr('km'), pal: pal);
                        if (r != null) s.setKm(r.abs());
                      },
                      child: Container(
                        height: 36,
                        constraints: const BoxConstraints(minWidth: 76),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(gradient: pal.panel, borderRadius: BorderRadius.circular(10), border: Border.all(color: pal.btnBorder, width: 1.5)),
                        child: Center(
                          child: Text('$kmText ${s.tr('km')}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: pal.text)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _loss('−${fib.toStringAsFixed(2)} dB'),
                  ]),
                ),
                _link(),
                // Сплиттер в муфте
                _node(
                  child: Column(children: [
                    Row(children: [
                      _icon(Icons.call_split_rounded, _orange),
                      const SizedBox(width: 9),
                      Expanded(child: _title(s.tr('spC'))),
                      _loss('−${_n(lc.loss)} dB'),
                    ]),
                    const SizedBox(height: 4),
                    _splitterButton(context, lc, () => _pickSplitter(context, splClosure, s.spC, s.setSpC)),
                    const SizedBox(height: 2),
                    _io(context, 'cin', 'cout'),
                  ]),
                ),
                _link(),
                // Сплиттер в здании
                _node(
                  child: Column(children: [
                    Row(children: [
                      _icon(Icons.apartment_rounded, Pal.accTop),
                      const SizedBox(width: 9),
                      Expanded(child: _title(s.tr('spB'))),
                      _loss('−${_n(lb.loss)} dB'),
                    ]),
                    const SizedBox(height: 4),
                    _splitterButton(context, lb, () => _pickSplitter(context, splBuilding, s.spB, s.setSpB)),
                    const SizedBox(height: 2),
                    _io(context, 'cout', 'bout', inTitle: s.tr('pBin')),
                  ]),
                ),
                _link(),
                const Spacer(),
                // Итог
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ok ? const Color(0xFF2FBF71) : const Color(0xFFE5484D), width: 2),
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [stateColor.withOpacity(0.16), stateColor.withOpacity(0.05)]),
                  ),
                  child: Column(children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Expanded(
                        child: Column(children: [
                          Text(s.tr('lrx'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: pal.muted)),
                          const SizedBox(height: 2),
                          _val(context, 'bout', fontSize: 28, unit: false, color: stateColor, height: 46),
                        ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                        child: Text(ok ? '≥' : '<', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: pal.muted)),
                      ),
                      Expanded(
                        child: Column(children: [
                          Text(s.tr('thr'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: pal.muted)),
                          const SizedBox(height: 2),
                          SizedBox(
                            height: 46,
                            child: Center(
                              child: Text(fmtSigned(threshold), textDirection: TextDirection.ltr, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: pal.text)),
                            ),
                          ),
                        ]),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      ok ? '${s.tr('ok')} · ${s.tr('lmar')} ${fmtSigned(mar)} dB' : '${s.tr('bad')} · ${s.tr('need')} ${mar.abs().toStringAsFixed(1)} dB',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: pal.text),
                    ),
                  ]),
                ),
                const SizedBox(height: 5),
                Text(s.tr('hint'), textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: pal.muted)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
