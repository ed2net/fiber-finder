import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data.dart';

/// Всё состояние приложения + сохранение между запусками
class AppState extends ChangeNotifier {
  SharedPreferences? _p;

  String lang = 'ru';
  bool dark = false;
  Cable cable = cableById('F144_12x12');
  int t = 2, f = 11; // 0-based трубка / волокно
  final Map<int, String> lastCable = {};

  // расчёт потерь
  double km = 1;
  int spC = 2, spB = 1; // 1x8 + 1x8
  String anchor = 'olt'; // olt / cin / cout / bout
  double aval = oltPowerDefault;

  String tr(String k) => i18n[lang]![k] ?? k;
  bool get rtl => lang == 'he';
  int get number => t * cable.f + f; // 0-based

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    final p = _p!;
    lang = p.getString('lang') ?? 'ru';
    dark = p.getBool('dark') ?? false;
    cable = cableById(p.getString('cable') ?? 'F144_12x12');
    t = (p.getInt('t') ?? 2).clamp(0, cable.t - 1);
    f = (p.getInt('f') ?? 11).clamp(0, cable.f - 1);
    for (final n in [6, 12, 24]) {
      final v = p.getString('last$n');
      if (v != null) lastCable[n] = v;
    }
    km = p.getDouble('km') ?? 1;
    spC = (p.getInt('spC') ?? 2).clamp(0, splClosure.length - 1);
    spB = (p.getInt('spB') ?? 1).clamp(0, splBuilding.length - 1);
    anchor = p.getString('anchor') ?? 'olt';
    aval = p.getDouble('aval') ?? oltPowerDefault;
    _pairFrom('c');
  }

  void _save() {
    final p = _p;
    if (p == null) return;
    p.setString('lang', lang);
    p.setBool('dark', dark);
    p.setString('cable', cable.id);
    p.setInt('t', t);
    p.setInt('f', f);
    lastCable.forEach((k, v) => p.setString('last$k', v));
    p.setDouble('km', km);
    p.setInt('spC', spC);
    p.setInt('spB', spB);
    p.setString('anchor', anchor);
    p.setDouble('aval', aval);
  }

  void _changed() {
    _save();
    notifyListeners();
  }

  void setLang(String l) {
    lang = l;
    _changed();
  }

  void toggleTheme() {
    dark = !dark;
    _changed();
  }

  void setCable(String id) {
    cable = cableById(id);
    lastCable[cable.f] = cable.id;
    t = t.clamp(0, cable.t - 1);
    f = f.clamp(0, cable.f - 1);
    _changed();
  }

  void setStructure(int perTube) {
    if (perTube == cable.f) return;
    setCable(lastCable[perTube] ?? defaultCable[perTube]!);
  }

  void setTube(int v) {
    t = v;
    _changed();
  }

  void setFiber(int v) {
    f = v;
    _changed();
  }

  void setNumber(int n) {
    t = n ~/ cable.f;
    f = n % cable.f;
    _changed();
  }

  // ===== потери =====
  Map<String, double> get points {
    final fib = km * attPerKm, lc = splClosure[spC].loss, lb = splBuilding[spB].loss;
    final off = {'olt': 0.0, 'cin': -fib, 'cout': -fib - lc, 'bout': -fib - lc - lb};
    final olt = aval - off[anchor]!;
    return off.map((k, v) => MapEntry(k, olt + v));
  }

  void setPoint(String key, double v) {
    anchor = key;
    aval = v;
    _changed();
  }

  void setKm(double v) {
    km = v < 0 ? 0 : v;
    _changed();
  }

  // GPON: общее деление всегда 1:64
  void _pairFrom(String changed) {
    if (changed == 'c') {
      final r = splClosure[spC].ratio;
      final j = splBuilding.indexWhere((s) => s.ratio * r == 64);
      if (j >= 0) spB = j;
    } else {
      final r = splBuilding[spB].ratio;
      final j = splClosure.indexWhere((s) => s.ratio * r == 64);
      if (j >= 0) spC = j;
    }
  }

  void setSpC(int i) {
    spC = i;
    _pairFrom('c');
    _changed();
  }

  void setSpB(int i) {
    spB = i;
    _pairFrom('b');
    _changed();
  }
}

/// Палитра (светлая / тёмная), стальной цвет кнопок
class Pal {
  final bool dark;
  const Pal(this.dark);

  static const accTop = Color(0xFF6B8FB8), accBot = Color(0xFF466C96), accEdge = Color(0xFF2D4B6D), accBorder = Color(0xFF8FB0D4);
  static const accGrad = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [accTop, accBot]);

  Gradient get bg => dark
      ? const RadialGradient(center: Alignment(0, -1), radius: 1.4, colors: [Color(0xFF0B2546), Color(0xFF04101F), Color(0xFF020A15)])
      : const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF4F8FD), Color(0xFFE8F0FA)]);
  Gradient get panel => dark
      ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xEB0E284C), Color(0xEB081A34)])
      : const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF7FAFF), Color(0xFFEDF3FB)]);
  Color get panelBorder => dark ? const Color(0xFF1C4A82) : const Color(0xFFD3E0F0);
  Gradient get btn => dark
      ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF123766), Color(0xFF0B2547)])
      : const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFEAF1FA)]);
  Color get btnBorder => dark ? const Color(0xFF24538D) : const Color(0xFFD5E1EF);
  Color get text => dark ? Colors.white : const Color(0xFF0D2342);
  Color get muted => dark ? const Color(0xFFC9DBF3) : const Color(0xFF33507A);
  Gradient get inner => dark
      ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0A1C37), Color(0xFF071429)])
      : const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFDFE9F6), Color(0xFFCFDCEE)]);
  Gradient get row => dark
      ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFA9BAD0), Color(0xFF7B90AD)])
      : const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF1F6FC), Color(0xFFE1EAF5)]);
  Color get rowText => const Color(0xFF0F1E35);
  Gradient get on => dark
      ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0E4A8F), Color(0xFF0A3266)])
      : const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFD4ECFF), Color(0xFFBFE1FF)]);
  Color get onBorder => dark ? const Color(0xFF43C6FF) : const Color(0xFF1A8CFF);
  Color get onText => dark ? Colors.white : const Color(0xFF0A2448);
  Color get resBorder => dark ? const Color(0xFF2FE0A8) : const Color(0xFFD5E1EF);
  Color get resLabel => dark ? const Color(0xFF3FE6B2) : const Color(0xFF1663D6);
  Color get resNum => dark ? Colors.white : const Color(0xFF0D3F8F);
  Color get resBig => dark ? const Color(0xFFFFD51A) : const Color(0xFF0D3F8F);
  Color get arrow => dark ? Colors.white : const Color(0xFF0D2342);
  Color get bad => dark ? const Color(0xFFFF8A80) : const Color(0xFFE0564C);
}
