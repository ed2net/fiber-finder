import 'package:flutter/material.dart';

/// Цвет волокна/трубки: цвет, название трубки (RU, ж.р.), волокна (RU, ср.р.), иврит
class FiberColor {
  final Color color;
  final String ruTube, ruFiber, he;
  const FiberColor(this.color, this.ruTube, this.ruFiber, this.he);
}

const fiberColors = <FiberColor>[
  FiberColor(Color(0xFF1677FF), 'Синяя', 'Синее', 'כחול'),
  FiberColor(Color(0xFFFF9500), 'Оранжевая', 'Оранжевое', 'כתום'),
  FiberColor(Color(0xFF27C22F), 'Зелёная', 'Зелёное', 'ירוק'),
  FiberColor(Color(0xFF8A4A1E), 'Коричневая', 'Коричневое', 'חום'),
  FiberColor(Color(0xFFA3ABB5), 'Серая', 'Серое', 'אפור'),
  FiberColor(Color(0xFFF4F6F9), 'Белая', 'Белое', 'לבן'),
  FiberColor(Color(0xFFE5202A), 'Красная', 'Красное', 'אדום'),
  FiberColor(Color(0xFF151515), 'Чёрная', 'Чёрное', 'שחור'),
  FiberColor(Color(0xFFFFD60A), 'Жёлтая', 'Жёлтое', 'צהוב'),
  FiberColor(Color(0xFF8A2CF5), 'Фиолетовая', 'Фиолетовое', 'סגול'),
  FiberColor(Color(0xFFFF4FB8), 'Розовая', 'Розовое', 'ורוד'),
  FiberColor(Color(0xFF26D0E4), 'Бирюзовая', 'Бирюзовое', 'טורקיז'),
];

String colorName(int i, String lang, {required bool tube}) {
  final c = fiberColors[i % 12];
  if (lang == 'he') return c.he;
  return tube ? c.ruTube : c.ruFiber;
}

/// Кабель: t — трубок, f — волокон в трубке
class Cable {
  final int t, f;
  const Cable(this.t, this.f);
  int get total => t * f;
  String get id => 'F${t * f}_${t}x$f';
  String get name => 'F${t * f} ${f}x$t';
}

// 6 в трубке → до 72; 12 в трубке → до 288; 24 в трубке → только 288
final List<Cable> cables = [
  for (var t = 1; t <= 12; t++) Cable(t, 6),
  for (var t = 1; t <= 24; t++) Cable(t, 12),
  const Cable(12, 24),
];
const defaultCable = {6: 'F72_12x6', 12: 'F144_12x12', 24: 'F288_12x24'};

Cable cableById(String id) =>
    cables.firstWhere((c) => c.id == id, orElse: () => cables.firstWhere((c) => c.id == 'F144_12x12'));

// ===== Расчёт потерь GPON (постоянные) =====
const double oltPowerDefault = 5.0; // выход OLT, dBm
const double attPerKm = 0.25; // dB / км
const double threshold = -23.9; // порог у клиента, dBm

class Splitter {
  final String name;
  final double loss;
  const Splitter(this.name, this.loss);
  int get ratio => int.parse(name.split('x')[1]);
}

const splClosure = [Splitter('1x2', 3.5), Splitter('1x4', 7), Splitter('1x8', 10.5), Splitter('1x16', 14)];
const splBuilding = [Splitter('1x4', 7), Splitter('1x8', 10.5), Splitter('1x16', 14.5), Splitter('1x32', 18)];

// ===== Тексты =====
const i18n = <String, Map<String, String>>{
  'ru': {
    'title': 'Оптические волокна',
    'tab1': 'Таблица волокон',
    'tab2': 'Расчёт потерь',
    'struct': 'Структура кабеля',
    's6': '6 волокон',
    's12': '12 волокон',
    's24': '24 волокна',
    'inTube': 'в трубке',
    'tube': 'Трубка',
    'fiber': 'Волокно',
    'result': 'Результат:',
    'cable': 'Кабель',
    'oltS': 'Выход сигнала',
    'len': 'Расстояние',
    'km': 'км',
    'spC': 'Сплиттер в муфте',
    'spB': 'Сплиттер в здании',
    'in': 'Вход',
    'out': 'Выход',
    'lrx': 'У клиента, dBm',
    'thr': 'Порог, dBm',
    'lmar': 'запас',
    'need': 'не хватает',
    'ok': 'В норме',
    'bad': 'Ниже порога',
    'pCin': 'Вход сплиттера в муфте',
    'pCout': 'Выход сплиттера в муфте',
    'pBin': 'Вход сплиттера в здании',
    'pBout': 'Сигнал у клиента',
    'hint': 'Нажмите на любое значение, чтобы ввести замер',
    'num': 'Номер волокна',
  },
  'he': {
    'title': 'סיבים אופטיים',
    'tab1': 'טבלת סיבים',
    'tab2': 'חישוב הפסדים',
    'struct': 'מבנה הכבל',
    's6': '6 סיבים',
    's12': '12 סיבים',
    's24': '24 סיבים',
    'inTube': 'בצינורית',
    'tube': 'צינורית',
    'fiber': 'סיב',
    'result': 'תוצאה:',
    'cable': 'כבל',
    'oltS': 'יציאת אות',
    'len': 'מרחק',
    'km': 'ק״מ',
    'spC': 'מפצל קלוז\'ר',
    'spB': 'מפצל בניין',
    'in': 'כניסה',
    'out': 'יציאה',
    'lrx': 'אצל הלקוח, dBm',
    'thr': 'סף, dBm',
    'lmar': 'מרווח',
    'need': 'חסר',
    'ok': 'תקין',
    'bad': 'מתחת לסף',
    'pCin': 'כניסה למפצל קלוז\'ר',
    'pCout': 'יציאה ממפצל קלוז\'ר',
    'pBin': 'כניסה למפצל בניין',
    'pBout': 'אות אצל הלקוח',
    'hint': 'לחץ על ערך כלשהו כדי להזין מדידה',
    'num': 'מספר סיב',
  },
};

int mod(int a, int n) => ((a % n) + n) % n;

String fmtSigned(double v, [int d = 1]) {
  final s = v.abs().toStringAsFixed(d);
  if (v > 0.0001) return '+$s';
  if (v < -0.0001) return '−$s';
  return s;
}
