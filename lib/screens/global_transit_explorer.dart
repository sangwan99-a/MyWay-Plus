import 'dart:async';
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
  final _placeSearch = TextEditingController();
  Position? _position;
  LatLng? _manualCenter;
  List<TransitPlace> _placeResults = [];
  bool _searchingPlaces = false;
  List<TransitStop> _stops = [];
  List<TransitRoute> _routes = [];
  List<TransitVehicle> _vehicles = [];
  bool _loadingVehicles = false;
  List<TransitServiceAlert> _alerts = [];
  bool _loadingAlerts = false;
  List<TransitTripUpdate> _tripUpdates = [];
  bool _loadingTripUpdates = false;
  String? _tripUpdateNotice;
  int _tripUpdateRequestId = 0;
  Timer? _tripUpdateRefreshTimer;

  String? _alertNotice;
  int _alertRequestId = 0;
  Timer? _alertRefreshTimer;

  int _vehicleRequestId = 0;
  String? _vehicleNotice;
  Timer? _vehicleRefreshTimer;
  TransitStop? _selectedStop;
  List<TransitDeparture> _departures = [];
  bool _loadingDepartures = false;
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
    _vehicleRefreshTimer?.cancel();
    _alertRefreshTimer?.cancel();
    _tripUpdateRefreshTimer?.cancel();
    _search.dispose();
    _placeSearch.dispose();
    _service.dispose();
    super.dispose();
  }

  LatLng? get _activeCenter => _manualCenter ?? (_position == null ? null : LatLng(_position!.latitude, _position!.longitude));

  Future<void> _findPlaces() async {
    final query = _placeSearch.text.trim();
    if (query.length < 2) return;
    setState(() { _searchingPlaces = true; _error = null; _placeResults = []; });
    try {
      final results = await _service.searchPlaces(query);
      if (mounted) setState(() { _placeResults = results; _searchingPlaces = false; });
      if (results.isEmpty && mounted) setState(() => _error = 'No matching places found. Try adding a country name.');
    } catch (e) {
      if (mounted) setState(() { _searchingPlaces = false; _error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  Future<void> _selectPlace(TransitPlace place) async {
    final point = LatLng(place.latitude, place.longitude);
    setState(() {
      _manualCenter = point;
      _place = place.displayName;
      _placeSearch.text = place.displayName;
      _placeResults = [];
      _stops = [];
      _routes = [];
      _vehicles = [];
      _vehicleRequestId++;
      _loadingVehicles = false;
      _alertRequestId++;
      _loadingAlerts = false;
      _alerts = [];
      _tripUpdateRequestId++;
      _loadingTripUpdates = false;
      _tripUpdates = [];
      _selectedStop = null;
      _departures = [];
      _searched = false;
      _error = null;
    });
    _map.move(point, 13);
    await _loadNearby();
    await _refreshVehicles();
    _startVehicleRefresh();
    await _refreshAlerts();
    _startAlertRefresh();
    await _refreshTripUpdates();
    _startTripUpdateRefresh();
    if (_search.text.trim().isNotEmpty) await _searchRoutes();
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
      setState(() { _position = p; _manualCenter = null; _selectedStop = null; _departures = []; _vehicles = []; _vehicleRequestId++; _loadingVehicles = false; _alertRequestId++; _loadingAlerts = false; _alerts = []; _tripUpdateRequestId++; _loadingTripUpdates = false; _tripUpdates = []; _place = 'Nearby public transport'; _placeSearch.text = ''; _placeResults = []; });
      _map.move(LatLng(p.latitude, p.longitude), 15);
      await _loadNearby();
      await _refreshVehicles();
      _startVehicleRefresh();
      await _refreshAlerts();
      _startAlertRefresh();
      await _refreshTripUpdates();
      _startTripUpdateRefresh();
      if (_search.text.trim().isNotEmpty) await _searchRoutes();
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  void _startVehicleRefresh() {
    _vehicleRefreshTimer?.cancel();
    _vehicleRefreshTimer = Timer.periodic(const Duration(seconds: 45), (_) => _refreshVehicles());
  }

  Future<void> _refreshVehicles() async {
    final center = _activeCenter;
    if (center == null || _loadingVehicles) return;
    final requestId = ++_vehicleRequestId;
    setState(() => _loadingVehicles = true);
    try {
      final vehicles = await _service.nearbyVehicles(center.latitude, center.longitude);
      if (!mounted || requestId != _vehicleRequestId) return;
      setState(() {
        _vehicles = vehicles;
        _loadingVehicles = false;
        _vehicleNotice = vehicles.isEmpty
            ? 'No current vehicle positions are published for this area.'
            : null;
      });
    } catch (_) {
      if (!mounted || requestId != _vehicleRequestId) return;
      setState(() {
        _loadingVehicles = false;
        _vehicleNotice = 'Live vehicle feed unavailable right now.';
      });
    }
  }


  void _startAlertRefresh() {
    _alertRefreshTimer?.cancel();
    _alertRefreshTimer = Timer.periodic(const Duration(seconds: 90), (_) => _refreshAlerts());
  }

  Future<void> _refreshAlerts() async {
    final center = _activeCenter;
    if (center == null || _loadingAlerts) return;
    final requestId = ++_alertRequestId;
    setState(() => _loadingAlerts = true);
    try {
      final alerts = await _service.nearbyAlerts(center.latitude, center.longitude);
      if (!mounted || requestId != _alertRequestId) return;
      setState(() {
        _alerts = alerts;
        _loadingAlerts = false;
        _alertNotice = alerts.isEmpty ? 'No active service alerts are published for this area.' : null;
      });
    } catch (_) {
      if (!mounted || requestId != _alertRequestId) return;
      setState(() {
        _loadingAlerts = false;
        _alertNotice = 'Service alert feed unavailable right now.';
      });
    }
  }


  void _startTripUpdateRefresh() {
    _tripUpdateRefreshTimer?.cancel();
    _tripUpdateRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) => _refreshTripUpdates());
  }

  Future<void> _refreshTripUpdates() async {
    final center = _activeCenter;
    if (center == null || _loadingTripUpdates) return;
    final requestId = ++_tripUpdateRequestId;
    setState(() => _loadingTripUpdates = true);
    try {
      final updates = await _service.nearbyTripUpdates(center.latitude, center.longitude);
      if (!mounted || requestId != _tripUpdateRequestId) return;
      setState(() {
        _tripUpdates = updates;
        _loadingTripUpdates = false;
        _tripUpdateNotice = updates.isEmpty
            ? 'No current trip predictions are published for this area.'
            : null;
      });
    } catch (_) {
      if (!mounted || requestId != _tripUpdateRequestId) return;
      setState(() {
        _loadingTripUpdates = false;
        _tripUpdateNotice = 'Real-time trip updates are unavailable right now.';
      });
    }
  }

  Future<void> _showDepartures(TransitStop stop) async {
    _map.move(LatLng(stop.lat, stop.lon), 17);
    setState(() {
      _selectedStop = stop;
      _departures = [];
      _loadingDepartures = stop.scheduleKey != null;
    });
    if (stop.scheduleKey == null) return;
    try {
      final departures = await _service.departuresForStop(stop);
      if (mounted) setState(() { _departures = departures; _loadingDepartures = false; });
    } catch (e) {
      if (mounted) setState(() { _loadingDepartures = false; _error = 'Schedule lookup unavailable: ${e.toString().replaceFirst('Exception: ', '')}'; });
    }
  }

  Future<void> _loadNearby() async {
    final center = _activeCenter;
    if (center == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final stops = await _service.nearbyStops(center.latitude, center.longitude);
      if (!mounted) return;
      setState(() { _stops = stops; _loading = false; _searched = true; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  Future<void> _searchRoutes() async {
    final center = _activeCenter;
    final term = _search.text.trim();
    if (center == null) { setState(() => _error = 'Search for a city or use your current location first.'); return; }
    if (term.isEmpty) { setState(() => _routes = []); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final routes = await _service.searchBusRoutes(center.latitude, center.longitude, term);
      if (mounted) setState(() { _routes = routes; _loading = false; _searched = true; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _activeCenter ?? const LatLng(20, 0);
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(backgroundColor: _bg, foregroundColor: _paper, title: const Text('Global transit', style: TextStyle(fontWeight: FontWeight.w700)), actions: [IconButton(onPressed: _locate, icon: const Icon(Icons.my_location, color: _lime), tooltip: 'Refresh my location')]),
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_place.toUpperCase(), style: const TextStyle(color: _lime, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w800)),
          Row(children: [
            Expanded(child: TextField(
              controller: _placeSearch,
              style: const TextStyle(color: _paper),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _findPlaces(),
              decoration: InputDecoration(
                hintText: 'Search any city or place worldwide',
                hintStyle: const TextStyle(color: _muted, fontSize: 12),
                filled: true, fillColor: _panel,
                prefixIcon: const Icon(Icons.public, color: _lime),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _line)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _line)),
              ),
            )),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _searchingPlaces ? null : _findPlaces,
              style: IconButton.styleFrom(backgroundColor: _lime, foregroundColor: _bg),
              icon: _searchingPlaces
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.travel_explore),
              tooltip: 'Search city',
            ),
          ]),
          if (_placeResults.isNotEmpty) Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: const BoxConstraints(maxHeight: 190),
            decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: _line)),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _placeResults.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: _line),
              itemBuilder: (context, index) {
                final place = _placeResults[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on_outlined, color: _lime, size: 19),
                  title: Text(place.name, style: const TextStyle(color: _paper, fontSize: 12)),
                  subtitle: Text(place.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 10)),
                  onTap: () => _selectPlace(place),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: _search, style: const TextStyle(color: _paper), onSubmitted: (_) => _searchRoutes(), decoration: InputDecoration(hintText: 'Search bus number, route or operator', hintStyle: const TextStyle(color: _muted, fontSize: 12), filled: true, fillColor: _panel, prefixIcon: const Icon(Icons.search, color: _muted), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _line)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _line))))),
            const SizedBox(width: 8),
            IconButton.filled(onPressed: _searchRoutes, style: IconButton.styleFrom(backgroundColor: _lime, foregroundColor: _bg), icon: const Icon(Icons.arrow_forward)),
          ]),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: Color(0xFFFFA69B), fontSize: 12))),
        ])),
        Expanded(child: FlutterMap(
          mapController: _map,
          options: MapOptions(initialCenter: center, initialZoom: _activeCenter == null ? 2 : 15),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.sahilsangwan.mywayplus'),
            MarkerLayer(markers: [
              if (_activeCenter != null) Marker(point: center, width: 42, height: 42, child: Container(decoration: BoxDecoration(color: _lime, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)), child: Icon(_manualCenter == null ? Icons.person_pin_circle : Icons.location_city, color: _bg))),
              ..._stops.map((s) => Marker(point: LatLng(s.lat, s.lon), width: 34, height: 34, child: Tooltip(message: s.name, child: Container(decoration: BoxDecoration(color: _panel, shape: BoxShape.circle, border: Border.all(color: _lime, width: 1.5)), child: const Icon(Icons.directions_bus, color: _lime, size: 17))))),
              ..._vehicles.map((v) => Marker(
                point: LatLng(v.latitude, v.longitude),
                width: 38,
                height: 38,
                child: Tooltip(
                  message: [
                    v.route.isEmpty ? 'Live vehicle' : 'Route ${v.route}',
                    if (v.label.isNotEmpty) v.label,
                    v.timestamp == null ? 'Timestamp unavailable' : 'Updated ${v.timestamp!.toLocal()}',
                    v.feedName,
                  ].join(' · '),
                  child: Transform.rotate(
                    angle: (v.bearing ?? 0) * 3.141592653589793 / 180,
                    child: Container(
                      decoration: BoxDecoration(color: const Color(0xFFB7E7FF), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 5)]),
                      child: const Icon(Icons.directions_bus, color: Color(0xFF101820), size: 20),
                    ),
                  ),
                ),
              )),
            ]),
            RichAttributionWidget(attributions: [TextSourceAttribution('© OpenStreetMap contributors', onTap: () {})]),
          ],
        )),
        Container(color: _panel, constraints: const BoxConstraints(maxHeight: 360), padding: const EdgeInsets.fromLTRB(16, 12, 16, 18), child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [const Expanded(child: Text('Nearby bus stops', style: TextStyle(color: _paper, fontSize: 17, fontWeight: FontWeight.w700))), if (_loading) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _lime)), Text('${_stops.length} found', style: const TextStyle(color: _muted, fontSize: 11))]),
          const SizedBox(height: 8),
          if (_stops.isEmpty && !_loading) Text(_searched ? 'No mapped bus stops found nearby. Try a wider area or another route.' : 'Search for any city above, or use the location button to find buses near you.', style: const TextStyle(color: _muted, fontSize: 12)),
          if (_stops.isNotEmpty) SizedBox(height: 116, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: _stops.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (context, i) {
            final s = _stops[i];
            return InkWell(onTap: () => _showDepartures(s), child: Container(width: 210, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(13), border: Border.all(color: _line)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.directions_bus, color: _lime, size: 18), const SizedBox(height: 7),
              Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _paper, fontWeight: FontWeight.w600, fontSize: 12)),
              const Spacer(), Text('${s.lat.toStringAsFixed(4)}, ${s.lon.toStringAsFixed(4)}', style: const TextStyle(color: _muted, fontSize: 9)),
            ])));
          })),
          const SizedBox(height: 12),
          Row(children: [
            const Expanded(child: Text('LIVE VEHICLES', style: TextStyle(color: _lime, fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.w800))),
            if (_loadingVehicles) const SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 2, color: _lime)),
            Text('${_vehicles.length} on map', style: const TextStyle(color: _muted, fontSize: 10)),
            IconButton(onPressed: _refreshVehicles, icon: const Icon(Icons.refresh, color: _muted, size: 17), tooltip: 'Refresh live vehicles', visualDensity: VisualDensity.compact),
          ]),
          if (_vehicles.isEmpty && !_loadingVehicles)
            Text(_vehicleNotice ?? 'No current vehicle positions are available.', style: const TextStyle(color: _muted, fontSize: 11)),

          const SizedBox(height: 12),
          Row(children: [
            const Expanded(child: Text('SERVICE ALERTS', style: TextStyle(color: _lime, fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.w800))),
            if (_loadingAlerts) const SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 2, color: _lime)),
            Text('${_alerts.length} active', style: const TextStyle(color: _muted, fontSize: 10)),
            IconButton(onPressed: _refreshAlerts, icon: const Icon(Icons.refresh, color: _muted, size: 17), tooltip: 'Refresh service alerts', visualDensity: VisualDensity.compact),
          ]),
          if (_alerts.isEmpty && !_loadingAlerts)
            Text(_alertNotice ?? 'No active service alerts.', style: const TextStyle(color: _muted, fontSize: 11)),
          ..._alerts.take(8).map((alert) {
            final severe = alert.severity.toUpperCase() == 'SEVERE';
            final warning = alert.severity.toUpperCase() == 'WARNING';
            final accent = severe ? const Color(0xFFFF7777) : warning ? const Color(0xFFFFC36B) : _lime;
            final scope = [
              if (alert.routes.isNotEmpty) 'Routes ${alert.routes.take(4).join(', ')}',
              if (alert.stops.isNotEmpty) 'Stops ${alert.stops.take(4).join(', ')}',
            ].join(' · ');
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 7),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(11), border: Border.all(color: _line)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.warning_amber_rounded, color: accent, size: 16),
                  const SizedBox(width: 6),
                  Expanded(child: Text(alert.title, style: const TextStyle(color: _paper, fontSize: 12, fontWeight: FontWeight.w700))),
                  Text(alert.severity.replaceAll('_', ' '), style: TextStyle(color: accent, fontSize: 8, fontWeight: FontWeight.w800)),
                ]),
                if (alert.description.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 5), child: Text(alert.description, style: const TextStyle(color: _paper, fontSize: 11))),
                if (scope.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 5), child: Text(scope, style: const TextStyle(color: _muted, fontSize: 10))),
                Padding(padding: const EdgeInsets.only(top: 4), child: Text('${alert.cause} · ${alert.effect} · ${alert.feedName}', style: const TextStyle(color: _muted, fontSize: 9))),
                if (alert.endsAt != null) Padding(padding: const EdgeInsets.only(top: 3), child: Text('Until ${alert.endsAt!.toLocal()}', style: const TextStyle(color: _muted, fontSize: 9))),
                if (alert.url != null) Padding(padding: const EdgeInsets.only(top: 3), child: Text(alert.url!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 9))),
              ]),
            );
          }),

          const SizedBox(height: 12),
          Row(children: [
            const Expanded(child: Text('REAL-TIME TRIP UPDATES', style: TextStyle(color: _lime, fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.w800))),
            if (_loadingTripUpdates) const SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 2, color: _lime)),
            Text('${_tripUpdates.length} updates', style: const TextStyle(color: _muted, fontSize: 10)),
            IconButton(onPressed: _refreshTripUpdates, icon: const Icon(Icons.refresh, color: _muted, size: 17), tooltip: 'Refresh trip predictions', visualDensity: VisualDensity.compact),
          ]),
          if (_tripUpdates.isEmpty && !_loadingTripUpdates)
            Text(_tripUpdateNotice ?? 'No live trip predictions published.', style: const TextStyle(color: _muted, fontSize: 11)),
          ..._tripUpdates.take(8).map((update) {
            final canceled = update.isCancelled;
            final skipped = update.isSkipped;
            final delay = update.delaySeconds;
            final eventTime = update.predictedTime?.toLocal();
            final timeLabel = eventTime == null
                ? (delay == null ? 'Prediction time unavailable' : '${delay >= 0 ? '+' : ''}${(delay / 60).round()} min delay')
                : '${eventTime.hour.toString().padLeft(2, '0')}:${eventTime.minute.toString().padLeft(2, '0')}';
            final status = canceled ? 'CANCELLED' : skipped ? 'STOP SKIPPED' : delay == null ? 'LIVE UPDATE' : delay == 0 ? 'ON TIME' : '${delay > 0 ? '+' : ''}${(delay / 60).round()} MIN';
            final accent = canceled || skipped ? const Color(0xFFFF7777) : delay != null && delay > 120 ? const Color(0xFFFFC36B) : _lime;
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _line)),
              child: Row(children: [
                SizedBox(width: 58, child: Text(timeLabel, style: const TextStyle(color: _paper, fontSize: 12, fontWeight: FontWeight.w700))),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(update.routeId.isEmpty ? 'Trip ${update.tripId.isEmpty ? 'update' : update.tripId}' : 'Route ${update.routeId}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _paper, fontSize: 11, fontWeight: FontWeight.w700)),
                  Text([
                    if (update.stopId.isNotEmpty) 'Stop ${update.stopId}',
                    if (update.headsign.isNotEmpty) update.headsign,
                    update.feedName,
                  ].join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 9)),
                ])),
                const SizedBox(width: 6),
                Text(status, style: TextStyle(color: accent, fontSize: 8, fontWeight: FontWeight.w800)),
              ]),
            );
          }),
          if (_selectedStop != null) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Text('DEPARTURES · ${_selectedStop!.name.toUpperCase()}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _lime, fontSize: 9, letterSpacing: 1.4, fontWeight: FontWeight.w800))),
              if (_loadingDepartures) const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: _lime)),
            ]),
            const SizedBox(height: 5),
            if (_selectedStop!.scheduleKey == null)
              const Text('This mapped stop has no linked GTFS schedule in Transitland yet.', style: TextStyle(color: _muted, fontSize: 11))
            else if (!_loadingDepartures && _departures.isEmpty)
              const Text('No published departures found for this stop in the current service window.', style: TextStyle(color: _muted, fontSize: 11))
            else
              ..._departures.take(4).map((d) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  SizedBox(width: 54, child: Text(d.displayTime, style: const TextStyle(color: _paper, fontSize: 13, fontWeight: FontWeight.w700))),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: const Color(0xFF252B1D), borderRadius: BorderRadius.circular(6)), child: Text(d.route, style: const TextStyle(color: _lime, fontSize: 10, fontWeight: FontWeight.w700))),
                  const SizedBox(width: 8),
                  Expanded(child: Text(d.destination, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _paper, fontSize: 11))),
                  Text(d.isRealtime ? 'REAL-TIME' : 'SCHEDULED', style: TextStyle(color: d.isRealtime ? _lime : _muted, fontSize: 8, fontWeight: FontWeight.w800)),
                ]),
              )),
          ],
          if (_routes.isNotEmpty) ...[
            const SizedBox(height: 12), const Text('ROUTE MATCHES', style: TextStyle(color: _lime, fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.w800)),
            ..._routes.take(5).map((r) => ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: CircleAvatar(backgroundColor: const Color(0xFF252B1D), child: Text(r.ref.isEmpty ? 'BUS' : r.ref, style: const TextStyle(color: _lime, fontSize: 11))), title: Text(r.name, style: const TextStyle(color: _paper, fontSize: 12)), subtitle: Text(r.operator, style: const TextStyle(color: _muted, fontSize: 10)))),
          ],
          const SizedBox(height: 6),
          const Text('Transitland GTFS schedules, mapped stops and operator-published GTFS Realtime vehicle positions. Vehicle markers refresh every 45 seconds and service alerts every 90 seconds and trip updates every 60 seconds when feeds are available; coverage varies by operator.', style: TextStyle(color: _muted, fontSize: 10)),
        ]))),
      ])),
    );
  }


}
