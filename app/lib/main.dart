import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'fiber_page.dart';
import 'loss_page.dart';
import 'state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final s = AppState();
  await s.load();
  runApp(FiberApp(s: s));
}

/// Перетаскивание мышью тоже крутит барабаны и листает экраны
class AppScroll extends MaterialScrollBehavior {
  const AppScroll();
  @override
  Set<PointerDeviceKind> get dragDevices => {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad, PointerDeviceKind.stylus};
}

class FiberApp extends StatelessWidget {
  final AppState s;
  const FiberApp({super.key, required this.s});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: s,
        builder: (context, _) => MaterialApp(
          title: 'Оптические волокна',
          debugShowCheckedModeBanner: false,
          scrollBehavior: const AppScroll(),
          theme: ThemeData(
            useMaterial3: true,
            brightness: s.dark ? Brightness.dark : Brightness.light,
            colorSchemeSeed: const Color(0xFF466C96),
          ),
          builder: (context, child) => Directionality(textDirection: s.rtl ? TextDirection.rtl : TextDirection.ltr, child: child!),
          home: HomePage(s: s),
        ),
      );
}

class HomePage extends StatefulWidget {
  final AppState s;
  const HomePage({super.key, required this.s});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final pc = PageController();
  int tab = 0;

  @override
  void dispose() {
    pc.dispose();
    super.dispose();
  }

  AppState get s => widget.s;

  Widget _segment({required List<String> labels, required int selected, required ValueChanged<int> onTap, required Pal pal, double height = 40, List<Widget?>? icons, double font = 15}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(gradient: pal.btn, borderRadius: BorderRadius.circular(13), border: Border.all(color: pal.btnBorder)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < labels.length; i++)
          _flex(
            icons != null,
            GestureDetector(
              onTap: () => onTap(i),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    gradient: i == selected ? Pal.accGrad : null,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: i == selected ? const [BoxShadow(color: Color(0x40000000), blurRadius: 6, offset: Offset(0, 2))] : null,
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (icons != null && icons[i] != null) ...[
                          IconTheme(data: IconThemeData(color: i == selected ? Colors.white : pal.text, size: 20), child: icons[i]!),
                          const SizedBox(width: 8),
                        ],
                        Text(labels[i], style: TextStyle(fontSize: font, fontWeight: i == selected ? FontWeight.w700 : FontWeight.w500, color: i == selected ? Colors.white : pal.text)),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _flex(bool expand, Widget child) => expand ? Expanded(child: child) : child;

  void _goTab(int i) {
    setState(() => tab = i);
    if (pc.hasClients) pc.animateToPage(i, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final pal = Pal(s.dark);
    SystemChrome.setSystemUIOverlayStyle(s.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: pal.bg),
        child: SafeArea(
          child: LayoutBuilder(builder: (context, c) {
            final wide = c.maxWidth >= 900 && c.maxHeight >= 520;
            final header = Row(children: [
              GestureDetector(
                onTap: s.toggleTheme,
                child: ClipRRect(borderRadius: BorderRadius.circular(9), child: Image.asset('assets/icon.png', width: wide ? 40 : 34, height: wide ? 40 : 34)),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(s.tr('title'), style: TextStyle(fontSize: wide ? 26 : 22, fontWeight: FontWeight.w800, color: pal.text)),
                ),
              ),
              const SizedBox(width: 8),
              _segment(
                labels: const ['Русский', 'עברית'],
                selected: s.lang == 'he' ? 1 : 0,
                onTap: (i) => s.setLang(i == 1 ? 'he' : 'ru'),
                pal: pal,
                height: 38,
                font: 14,
              ),
            ]);
            final fiber = FiberPage(s: s, pal: pal);
            final loss = LossPage(s: s, pal: pal);
            return Padding(
              padding: EdgeInsets.fromLTRB(wide ? 18 : 8, 6, wide ? 18 : 8, 8),
              child: Column(children: [
                header,
                const SizedBox(height: 7),
                if (!wide) ...[
                  SizedBox(
                    width: double.infinity,
                    child: _segment(
                      labels: [s.tr('tab1'), s.tr('tab2')],
                      selected: tab,
                      onTap: _goTab,
                      pal: pal,
                      height: 42,
                      icons: const [Icon(Icons.grid_view_rounded), Icon(Icons.monitor_heart_outlined)],
                    ),
                  ),
                  const SizedBox(height: 7),
                ],
                Expanded(
                  child: wide
                      ? Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(child: fiber), const SizedBox(width: 16), Expanded(child: loss)])
                      : PageView(
                          controller: pc,
                          onPageChanged: (i) => setState(() => tab = i),
                          children: [
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 1), child: fiber),
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 1), child: loss),
                          ],
                        ),
                ),
              ]),
            );
          }),
        ),
      ),
    );
  }
}
