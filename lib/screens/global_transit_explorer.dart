import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../services/global_transit_service.dart';

const _bg = Color(0xFF08090B);
const _panel = Color(0xFF111317);
const _line = Color(0xFF272A30);
const _muted = Color(0xFF8B909A);
const _paper = Color(0xFFF2F1EC);
const _lime = Color(0xFFD7FF64);

class GlobalTransitExplorer extends StatefulWidget {
  const GlobalTransitExplorer({super.key, this.initialSearch = ''});
  final String initialSearch;
  @override
  State<GlobalTransitExplorer> createState() => _GlobalTransitExplorerState();
}

class _GlobalTransitExplorerState extends State<GlobalTransitExplorer> {
  final _service = GlobalTransitService();
  final _map = MapController();
  final _search = TextEditingController();
  Position? _position;
  List<TransitStop> _stops = [];
  List<TransitRoute> _routes = [];
  bool _loading = false;
  String? _error;
  String _place = 'Find transit around you';
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    _search.text = widget.initialSearch;
    WidgetsBinding.instance.addPostFrameCallback((_) => _locate());
  }

  @override
  void dispose() {
    _search.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    setState(() { _loading = true; _error = null; });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Turn on device location services, or search for a bus route manually.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('Location permission was not granted. You can still search after enabling location access.');
      }
      final p = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 20)));
      if (!mounted) return;
      setState(() { _position = p; _place = 'Nearby public transport'; });
      _map.move(LatLng(p.latitude, p.longitude), 15);
      await _loadNearby();
      if (_search.text.trim().isNotEmpty) await _searchRoutes();
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _loadNearby() async {
    final p = _position;
    if (p == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final stops = await _service.nearbyStops(p.latitude, p.longitude);
      if (!mounted) return;
      setState(() { _stops = stops; _loading = false; _searched = true; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  Future<void> _searchRoutes() async {
    final p = _position;
    final term = _search.text.trim();
    if (p == null) { setState(() => _error = 'Allow location access to search routes near you.'); return; }
    if (term.isEmpty) { setState(() => _routes = []); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final routes = await _service.searchBusRoutes(p.latitude, p.longitude, term);
      if (mounted) setState(() { _routes = routes; _loading = false; _searched = true; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _position;
    final center = p == null ? const LatLng(20, 0) : LatLng(p.latitude, p.longitude);
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(backgroundColor: _bg, foregroundColor: _paper, title: const Text('Global transit', style: TextStyle(fontWeight: FontWeight.w700)), actions: [IconButton(onPressed: _locate, icon: const Icon(Icons.my_location, color: _lime), tooltip: 'Refresh my location')]),
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_place.toUpperCase(), style: const TextStyle(color: _lime, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: _search, style: const TextStyle(color: _paper), onSubmitted: (_) => _searchRoutes(), decoration: InputDecoration(hintText: 'Search bus number, route or operator', hintStyle: const TextStyle(color: _muted, fontSize: 12), filled: true, fillColor: _panel, prefixIcon: const Icon(Icons.search, color: _muted), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _line)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _line))))),
            const SizedBox(width: 8),
            IconButton.filled(onPressed: _searchRoutes, style: IconButton.styleFrom(backgroundColor: _lime, foregroundColor: _bg), icon: const Icon(Icons.arrow_forward)),
          ]),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: Color(0xFFFFA69B), fontSize: 12))),
        ])),
        Expanded(child: p == null ? _emptyLocation() : FlutterMap(
          mapController: _map,
          options: MapOptions(initialCenter: center, initialZoom: 15),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.sahilsangwan.mywayplus'),
            MarkerLayer(markers: [
              Marker(point: center, width: 42, height: 42, child: Container(decoration: BoxDecoration(color: _lime, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)), child: const Icon(Icons.person_pin_circle, color: _bg))),
              ..._stops.map((s) => Marker(point: LatLng(s.lat, s.lon), width: 34, height: 34, child: Tooltip(message: s.name, child: Container(decoration: BoxDecoration(color: _panel, shape: BoxShape.circle, border: Border.all(color: _lime, width: 1.5)), child: const Icon(Icons.directions_bus, color: _lime, size: 17))))),
            ]),
            RichAttributionWidget(attributions: [TextSourceAttribution('© OpenStreetMap contributors', onTap: () {})]),
          ],
        )),
        Container(color: _panel, padding: const EdgeInsets.fromLTRB(16, 12, 16, 18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [const Expanded(child: Text('Nearby bus stops', style: TextStyle(color: _paper, fontSize: 17, fontWeight: FontWeight.w700))), if (_loading) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _lime)), Text('${_stops.length} found', style: const TextStyle(color: _muted, fontSize: 11))]),
          const SizedBox(height: 8),
          if (_stops.isEmpty && !_loading) Text(_searched ? 'No mapped bus stops found nearby. Try a wider area or another route.' : 'Allow location access to discover public transport.', style: const TextStyle(color: _muted, fontSize: 12)),
          if (_stops.isNotEmpty) SizedBox(height: 116, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: _stops.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (context, i) {
            final s = _stops[i];
            return InkWell(onTap: () => _map.move(LatLng(s.lat, s.lon), 17), child: Container(width: 210, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(13), border: Border.all(color: _line)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.directions_bus, color: _lime, size: 18), const SizedBox(height: 7),
              Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _paper, fontWeight: FontWeight.w600, fontSize: 12)),
              const Spacer(), Text('${s.lat.toStringAsFixed(4)}, ${s.lon.toStringAsFixed(4)}', style: const TextStyle(color: _muted, fontSize: 9)),
            ])));
          })),
          if (_routes.isNotEmpty) ...[
            const SizedBox(height: 12), const Text('ROUTE MATCHES', style: TextStyle(color: _lime, fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.w800)),
            ..._routes.take(5).map((r) => ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: CircleAvatar(backgroundColor: const Color(0xFF252B1D), child: Text(r.ref.isEmpty ? 'BUS' : r.ref, style: const TextStyle(color: _lime, fontSize: 11))), title: Text(r.name, style: const TextStyle(color: _paper, fontSize: 12)), subtitle: Text(r.operator, style: const TextStyle(color: _muted, fontSize: 10)))),
          ],
          const SizedBox(height: 6),
          const Text('Mapped stops/routes from OpenStreetMap. Live vehicle GPS and arrival predictions require feeds published by local transit operators.', style: TextStyle(color: _muted, fontSize: 10)),
        ])),
      ])),
    );
  }

  Widget _emptyLocation() => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.location_searching, color: _lime, size: 42), const SizedBox(height: 14),
    const Text('Discover transit anywhere', style: TextStyle(color: _paper, fontSize: 18, fontWeight: FontWeight.w700)),
    const SizedBox(height: 8), const Text('MyWay+ uses your permissioned device location to find mapped bus stops and routes around you.', textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 12)),
    const SizedBox(height: 18), FilledButton(onPressed: _locate, child: const Text('USE MY LOCATION')),
  ])));
}
