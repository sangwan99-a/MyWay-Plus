import 'dart:convert';
import 'package:http/http.dart' as http;

class TransitStop {
  const TransitStop({required this.id, required this.name, required this.lat, required this.lon, required this.tags});
  final String id;
  final String name;
  final double lat;
  final double lon;
  final Map<String, dynamic> tags;

  factory TransitStop.fromElement(Map<String, dynamic> e) {
    final tags = Map<String, dynamic>.from(e['tags'] as Map? ?? {});
    final center = e['center'] as Map<String, dynamic>?;
    return TransitStop(
      id: '${e['type']}/${e['id']}',
      name: (tags['name'] ?? tags['local_name'] ?? tags['ref'] ?? 'Unnamed bus stop').toString(),
      lat: ((e['lat'] ?? center?['lat']) as num).toDouble(),
      lon: ((e['lon'] ?? center?['lon']) as num).toDouble(),
      tags: tags,
    );
  }
}

class TransitRoute {
  const TransitRoute({required this.id, required this.ref, required this.name, required this.operator});
  final String id;
  final String ref;
  final String name;
  final String operator;
  factory TransitRoute.fromElement(Map<String, dynamic> e) {
    final t = Map<String, dynamic>.from(e['tags'] as Map? ?? {});
    return TransitRoute(id: '${e['type']}/${e['id']}', ref: (t['ref'] ?? '').toString(),
      name: (t['name'] ?? 'Bus route').toString(), operator: (t['operator'] ?? 'Operator not listed').toString());
  }
}

class GlobalTransitService {
  GlobalTransitService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static const _overpass = 'https://overpass-api.de/api/interpreter';

  Future<List<TransitStop>> nearbyStops(double lat, double lon, {int radius = 1200}) async {
    final query = '[out:json][timeout:25];(node["highway"="bus_stop"](around:$radius,$lat,$lon);node["public_transport"="platform"]["bus"="yes"](around:$radius,$lat,$lon);way["highway"="bus_stop"](around:$radius,$lat,$lon););out center tags;';
    final json = await _overpassQuery(query);
    final items = (json['elements'] as List? ?? []).whereType<Map<String, dynamic>>();
    final stops = <TransitStop>[];
    for (final e in items) {
      try { stops.add(TransitStop.fromElement(e)); } catch (_) { /* Ignore incomplete map features. */ }
    }
    return stops;
  }

  Future<List<TransitRoute>> searchBusRoutes(double lat, double lon, String term, {int radius = 10000}) async {
    final escaped = term.replaceAll(RegExp(r'[^a-zA-Z0-9 -]'), '').trim();
    if (escaped.isEmpty) return const [];
    final query = '[out:json][timeout:25];(relation["route"="bus"]["ref"~"$escaped",i](around:$radius,$lat,$lon);relation["route"="bus"]["name"~"$escaped",i](around:$radius,$lat,$lon);relation["route_master"="bus"]["ref"~"$escaped",i](around:$radius,$lat,$lon););out tags;';
    final json = await _overpassQuery(query);
    final items = (json['elements'] as List? ?? []).whereType<Map<String, dynamic>>();
    return items.map(TransitRoute.fromElement).toList();
  }

  Future<Map<String, dynamic>> _overpassQuery(String query) async {
    final response = await _client.post(Uri.parse(_overpass),
      headers: {'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8', 'User-Agent': 'MyWayPlus/2.2 (global transit discovery)'},
      body: {'data': query}).timeout(const Duration(seconds: 35));
    if (response.statusCode != 200) {
      throw Exception('OpenStreetMap transit data is temporarily unavailable (HTTP ${response.statusCode}).');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  void dispose() => _client.close();
}
