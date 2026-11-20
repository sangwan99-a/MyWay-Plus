import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() => runApp(const MyWayApp());

const ink = Color(0xFF08090B);
const panel = Color(0xFF111317);
const line = Color(0xFF272A30);
const muted = Color(0xFF8B909A);
const paper = Color(0xFFF2F1EC);
const lime = Color(0xFFD7FF64);

class MyWayApp extends StatelessWidget {
  const MyWayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyWay+',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: ink,
        colorScheme: const ColorScheme.dark(primary: lime, surface: panel),
        fontFamily: 'Arial',
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _ambient = AnimationController(
    vsync: this, duration: const Duration(seconds: 18),
  )..repeat();
  int _tab = 0;
  final _from = TextEditingController(text: 'Current location');
  final _to = TextEditingController();

  @override
  void dispose() {
    _ambient.dispose();
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth > 850;
          return Row(children: [
            if (wide) _sideRail(),
            Expanded(child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _header(wide)),
                SliverToBoxAdapter(child: _hero(wide)),
                SliverToBoxAdapter(child: _planner(wide)),
                SliverToBoxAdapter(child: _sectionHeading('LIVE AROUND YOU', 'Nearby departures')),
                SliverToBoxAdapter(child: _departures(wide)),
                SliverToBoxAdapter(child: _footer()),
                const SliverToBoxAdapter(child: SizedBox(height: 30)),
              ],
            )),
          ]);
        }),
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width > 850 ? null : _bottomBar(),
    );
  }

  Widget _sideRail() => Container(
    width: 92, decoration: const BoxDecoration(border: Border(right: BorderSide(color: line))),
    child: Column(children: [
      const SizedBox(height: 28), _mark(42), const SizedBox(height: 50),
      _railIcon(Icons.explore_outlined, 0), _railIcon(Icons.map_outlined, 1),
      _railIcon(Icons.bookmark_border, 2), const Spacer(),
      _railIcon(Icons.settings_outlined, 3), const SizedBox(height: 24),
    ]),
  );

  Widget _railIcon(IconData icon, int index) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: IconButton(
      onPressed: () => setState(() => _tab = index),
      style: IconButton.styleFrom(
        backgroundColor: _tab == index ? const Color(0xFF242A1C) : Colors.transparent,
        foregroundColor: _tab == index ? lime : muted,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Icon(icon, size: 21),
    ),
  );

  Widget _header(bool wide) => Padding(
    padding: EdgeInsets.fromLTRB(wide ? 42 : 22, 22, wide ? 42 : 22, 24),
    child: Row(children: [
      if (!wide) _mark(38),
      if (!wide) const SizedBox(width: 12),
      const Text('MYWAY', style: TextStyle(fontSize: 13, letterSpacing: 3.4, fontWeight: FontWeight.w800)),
      const Text('+', style: TextStyle(color: lime, fontSize: 17, fontWeight: FontWeight.w900)),
      const Spacer(),
      _liveBadge(),
      const SizedBox(width: 14),
      Container(width: 38, height: 38, decoration: BoxDecoration(
        border: Border.all(color: line), borderRadius: BorderRadius.circular(13)),
        child: const Icon(Icons.person_outline, color: paper, size: 19)),
    ]),
  );

  Widget _mark(double size) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: lime, borderRadius: BorderRadius.circular(size * .28)),
    child: Icon(Icons.route_rounded, color: ink, size: size * .56),
  );

  Widget _liveBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(color: const Color(0xFF172016), borderRadius: BorderRadius.circular(30),
      border: Border.all(color: const Color(0xFF34452A))),
    child: const Row(children: [
      Icon(Icons.circle, color: lime, size: 6), SizedBox(width: 7),
      Text('NETWORK LIVE', style: TextStyle(color: lime, fontSize: 9, letterSpacing: 1.3, fontWeight: FontWeight.w700)),
    ]),
  );

  Widget _hero(bool wide) => Padding(
    padding: EdgeInsets.fromLTRB(wide ? 42 : 22, 4, wide ? 42 : 22, 22),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        height: wide ? 340 : 310,
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF20252A), Color(0xFF101317), Color(0xFF0B0D10)]),
        ),
        child: Stack(children: [
          Positioned.fill(child: AnimatedBuilder(
            animation: _ambient,
            builder: (_, __) => CustomPaint(painter: CityPainter(_ambient.value)),
          )),
          Positioned(left: 26, top: 27, child: _eyebrow('MOVE WITH THE CITY')),
          Positioned(left: 26, top: 65, right: 24, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('The city,\nin your rhythm.', style: TextStyle(
                fontSize: wide ? 54 : 43, height: .98, letterSpacing: -2.6,
                fontWeight: FontWeight.w700, color: paper)),
              const SizedBox(height: 15),
              const Text('Every connection. One clear journey.', style: TextStyle(color: Color(0xFFB4B9C0), fontSize: 13)),
            ],
          )),
          Positioned(left: 26, bottom: 24, child: Row(children: [
            const Icon(Icons.wb_sunny_outlined, color: lime, size: 15),
            const SizedBox(width: 8),
            const Text('CANBERRA  ·  18°', style: TextStyle(fontSize: 10, color: paper, letterSpacing: 1.5)),
          ])),
          Positioned(right: 24, bottom: 24, child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .07), borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: .1))),
            child: const Icon(Icons.north_east, color: lime, size: 18),
          )),
        ]),
      ),
    ),
  );

  Widget _eyebrow(String text) => Text(text, style: const TextStyle(
    color: lime, fontSize: 9, letterSpacing: 2.4, fontWeight: FontWeight.w800));

  Widget _planner(bool wide) => Padding(
    padding: EdgeInsets.fromLTRB(wide ? 42 : 22, 8, wide ? 42 : 22, 34),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: panel, border: Border.all(color: line), borderRadius: BorderRadius.circular(22)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [_eyebrow('PLAN A JOURNEY'), const Spacer(),
          const Text('SIMPLE. SEAMLESS.', style: TextStyle(color: muted, fontSize: 9, letterSpacing: 1.2))]),
        const SizedBox(height: 18),
        LayoutBuilder(builder: (context, c) {
          final horizontal = c.maxWidth > 620;
          final fields = [
            _locationField('FROM', _from, Icons.my_location),
            _locationField('TO', _to, Icons.place_outlined),
          ];
          return horizontal ? Row(children: [
            Expanded(child: fields[0]), const SizedBox(width: 12),
            Expanded(child: fields[1]), const SizedBox(width: 12), _searchButton(),
          ]) : Column(children: [
            fields[0], const SizedBox(height: 10), fields[1], const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: _searchButton()),
          ]);
        }),
        const SizedBox(height: 14),
        Row(children: [
          _chip(Icons.directions_bus_outlined, 'BUS'),
          const SizedBox(width: 8), _chip(Icons.directions_walk, 'WALK'),
          const SizedBox(width: 8), _chip(Icons.access_time, 'LEAVE NOW'),
        ]),
      ]),
    ),
  );

  Widget _locationField(String label, TextEditingController controller, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
    decoration: BoxDecoration(color: const Color(0xFF0B0D10), borderRadius: BorderRadius.circular(13),
      border: Border.all(color: line)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: muted, fontSize: 8, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
      Row(children: [
        Icon(icon, size: 16, color: lime), const SizedBox(width: 9),
        Expanded(child: TextField(controller: controller, style: const TextStyle(color: paper, fontSize: 13),
          decoration: const InputDecoration(border: InputBorder.none, isDense: true, hintText: 'Choose destination',
            hintStyle: TextStyle(color: Color(0xFF686D76)))),
        ),
      ]),
    ]),
  );

  Widget _searchButton() => FilledButton.icon(
    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Journey planning will connect to live transit data in the next integration step.'))),
    style: FilledButton.styleFrom(backgroundColor: lime, foregroundColor: ink,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 19),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
    icon: const Icon(Icons.arrow_forward, size: 16),
    label: const Text('FIND ROUTE', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w900)),
  );

  Widget _chip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(border: Border.all(color: line), borderRadius: BorderRadius.circular(30)),
    child: Row(children: [Icon(icon, size: 12, color: muted), const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 8, color: muted, letterSpacing: .8, fontWeight: FontWeight.w700))]),
  );

  Widget _sectionHeading(String eyebrow, String title) => Padding(
    padding: EdgeInsets.fromLTRB(MediaQuery.sizeOf(context).width > 850 ? 42 : 22, 0,
      MediaQuery.sizeOf(context).width > 850 ? 42 : 22, 16),
    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _eyebrow(eyebrow), const SizedBox(height: 7),
        Text(title, style: const TextStyle(fontSize: 23, letterSpacing: -.7, fontWeight: FontWeight.w600, color: paper)),
      ]),
      const Spacer(),
      const Text('VIEW MAP  ↗', style: TextStyle(color: muted, fontSize: 9, letterSpacing: 1.2)),
    ]),
  );

  Widget _departures(bool wide) {
    final items = [
      ('R2', 'City · Belconnen', '2 min', 'ON TIME', 'Platform 1'),
      ('6', 'Woden · City', '6 min', 'ON TIME', 'Platform 3'),
      (' Rapid 10', 'Civic · Gungahlin', '11 min', 'TRACKING', 'Platform 2'),
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(wide ? 42 : 22, 0, wide ? 42 : 22, 20),
      child: Column(children: items.map((e) => Container(
        margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: panel, border: Border.all(color: line), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Container(width: 43, height: 43, alignment: Alignment.center,
            decoration: BoxDecoration(color: const Color(0xFF22291C), borderRadius: BorderRadius.circular(12)),
            child: Text(e.$1.trim(), style: const TextStyle(color: lime, fontWeight: FontWeight.w900, fontSize: 13))),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.$2, style: const TextStyle(color: paper, fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 5),
            Text(e.$5, style: const TextStyle(color: muted, fontSize: 10)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(e.$3, style: const TextStyle(color: paper, fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(e.$4, style: const TextStyle(color: lime, fontSize: 8, letterSpacing: 1, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(width: 8), const Icon(Icons.chevron_right, color: muted, size: 18),
        ]),
      )).toList()),
    );
  }

  Widget _footer() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
    child: Text('MYWAY+  /  YOUR CITY, CONNECTED', textAlign: TextAlign.center,
      style: TextStyle(color: Color(0xFF515660), fontSize: 8, letterSpacing: 2)),
  );

  Widget _bottomBar() => Container(
    decoration: const BoxDecoration(color: ink, border: Border(top: BorderSide(color: line))),
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _navItem(Icons.explore_outlined, 'EXPLORE', 0),
      _navItem(Icons.map_outlined, 'MAP', 1),
      _navItem(Icons.bookmark_border, 'SAVED', 2),
      _navItem(Icons.person_outline, 'PROFILE', 3),
    ]),
  );

  Widget _navItem(IconData icon, String label, int index) => InkWell(
    onTap: () => setState(() => _tab = index),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: _tab == index ? lime : muted, size: 20),
      const SizedBox(height: 5),
      Text(label, style: TextStyle(color: _tab == index ? lime : muted, fontSize: 8, letterSpacing: .8)),
    ]),
  );
}

class CityPainter extends CustomPainter {
  CityPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.stroke..strokeWidth = 1;
    final horizon = size.height * .68;
    p.color = const Color(0xFF69747D).withValues(alpha: .12);
    for (var i = 0; i < 9; i++) {
      final x = size.width * i / 8;
      canvas.drawLine(Offset(x, horizon), Offset(size.width / 2 + (x - size.width / 2) * 1.7, size.height), p);
    }
    for (var i = 0; i < 7; i++) {
      final y = horizon + i * i * 2.8;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
    final buildings = <Rect>[
      Rect.fromLTWH(size.width*.58, size.height*.34, 34, size.height*.34),
      Rect.fromLTWH(size.width*.67, size.height*.22, 48, size.height*.46),
      Rect.fromLTWH(size.width*.79, size.height*.39, 35, size.height*.29),
      Rect.fromLTWH(size.width*.88, size.height*.29, 52, size.height*.39),
      Rect.fromLTWH(size.width*.48, size.height*.48, 25, size.height*.20),
    ];
    final fill = Paint()..color = const Color(0xFF87949B).withValues(alpha: .10);
    final stroke = Paint()..color = const Color(0xFF87949B).withValues(alpha: .22)..style = PaintingStyle.stroke;
    for (final r in buildings) {
      canvas.drawRect(r, fill); canvas.drawRect(r, stroke);
      for (var y = r.top + 10; y < r.bottom - 5; y += 13) {
        for (var x = r.left + 7; x < r.right - 4; x += 11) {
          final window = Paint()..color = lime.withValues(alpha: .18);
          canvas.drawRect(Rect.fromLTWH(x, y, 3, 4), window);
        }
      }
    }
    final route = Path()
      ..moveTo(size.width*.44, size.height*.80)
      ..cubicTo(size.width*.56, size.height*.68, size.width*.62, size.height*.78, size.width*.70, size.height*.61)
      ..cubicTo(size.width*.78, size.height*.48, size.width*.84, size.height*.62, size.width*.94, size.height*.44);
    final glow = Paint()..color = lime.withValues(alpha: .13)..style = PaintingStyle.stroke..strokeWidth = 8..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(route, glow);
    final routePaint = Paint()..color = lime.withValues(alpha: .78)..style = PaintingStyle.stroke..strokeWidth = 1.6;
    canvas.drawPath(route, routePaint);
    final t = progress;
    final point = Offset(size.width*(.44 + .50*t), size.height*(.80 - .36*t + .06*math.sin(t*math.pi*2)));
    final bus = Paint()..color = lime;
    canvas.drawCircle(point, 4.5, bus);
    canvas.drawCircle(point, 10, Paint()..color = lime.withValues(alpha: .18));
    final dots = Paint()..color = Colors.white.withValues(alpha: .25);
    for (var i=0; i<34; i++) {
      final x = (i*71.0 + progress*size.width*.12) % size.width;
      final y = (i*37.0) % (size.height*.7);
      canvas.drawCircle(Offset(x,y), i%4==0 ? 1.4 : .7, dots);
    }
  }

  @override
  bool shouldRepaint(covariant CityPainter oldDelegate) => oldDelegate.progress != progress;
}
