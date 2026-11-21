import 'dart:convert';
import 'package:http/http.dart' as http;


class TransitPlace {
  const TransitPlace({required this.name, required this.displayName, required this.latitude, required this.longitude});
  final String name;
  final String displayName;
  final double latitude;
  final double longitude;

  factory TransitPlace.fromPhoton(Map<String, dynamic> feature) {
    final properties = Map<String, dynamic>.from(feature['properties'] as Map? ?? {});
    final geometry = Map<String, dynamic>.from(feature['geometry'] as Map? ?? {});
    final coordinates = geometry['coordinates'] as List? ?? const [];
    if (coordinates.length < 2 || coordinates[0] is! num || coordinates[1] is! num) {
      throw const FormatException('Place has no coordinates');
    }
    final parts = [properties['name'], properties['city'], properties['state'], properties['country']]
        .where((value) => value != null && value.toString().trim().isNotEmpty)
        .map((value) => value.toString()).toList();
    return TransitPlace(
      name: (properties['name'] ?? properties['city'] ?? 'Selected place').toString(),
      displayName: parts.toSet().join(', '),
      longitude: (coordinates[0] as num).toDouble(),
      latitude: (coordinates[1] as num).toDouble(),
    );
  }
}

class TransitStop {
  const TransitStop({required this.id, required this.name, required this.lat, required this.lon, required this.tags, this.scheduleKey});
  final String id;
  final String? scheduleKey;
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

  factory TransitStop.fromTransitland(Map<String, dynamic> e) {
    final geometry = e['geometry'] as Map<String, dynamic>?;
    final coordinates = geometry?['coordinates'] as List?;
    final lat = e['stop_lat'] ?? e['lat'] ?? (coordinates != null && coordinates.length > 1 ? coordinates[1] : null);
    final lon = e['stop_lon'] ?? e['lon'] ?? (coordinates != null && coordinates.isNotEmpty ? coordinates[0] : null);
    if (lat is! num || lon is! num) throw const FormatException('Stop has no coordinates');
    return TransitStop(
      id: 'transitland/${e['id'] ?? e['onestop_id'] ?? '${lat}_${lon}'}',
      scheduleKey: e['id']?.toString() ?? (e['onestop_id']?.toString().isNotEmpty == true ? e['onestop_id'].toString() : null),
      name: (e['stop_name'] ?? e['name'] ?? e['stop_code'] ?? 'Unnamed transit stop').toString(),
      lat: lat.toDouble(),
      lon: lon.toDouble(),
      tags: e,
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
    return TransitRoute(
      id: '${e['type']}/${e['id']}',
      ref: (t['ref'] ?? '').toString(),
      name: (t['name'] ?? 'Bus route').toString(),
      operator: (t['operator'] ?? 'Operator not listed').toString(),
    );
  }

  factory TransitRoute.fromTransitland(Map<String, dynamic> e) {
    final agency = e['agency'] as Map<String, dynamic>?;
    return TransitRoute(
      id: 'transitland/${e['id'] ?? e['onestop_id'] ?? e['route_id'] ?? ''}',
      ref: (e['route_short_name'] ?? e['route_id'] ?? '').toString(),
      name: (e['route_long_name'] ?? e['route_short_name'] ?? e['route_id'] ?? 'Bus route').toString(),
      operator: (e['agency_name'] ?? agency?['agency_name'] ?? agency?['name'] ?? 'Operator not listed').toString(),
    );
  }
}

class TransitDeparture {
  const TransitDeparture({
    required this.route,
    required this.destination,
    required this.scheduledTime,
    required this.estimatedTime,
    required this.operator,
    required this.isRealtime,
    required this.status,
  });

  final String route;
  final String destination;
  final String scheduledTime;
  final String? estimatedTime;
  final String operator;
  final bool isRealtime;
  final String status;

  String get displayTime => _clockTime(estimatedTime ?? scheduledTime);

  static String _clockTime(String value) {
    if (value.isEmpty) return 'Time unavailable';
    final time = value.length >= 19 && value.contains('T') ? value.substring(11, 19) : value;
    return time.length >= 5 ? time.substring(0, 5) : time;
  }

  factory TransitDeparture.fromJson(Map<String, dynamic> json) {
    final trip = Map<String, dynamic>.from(json['trip'] as Map? ?? {});
    final routeData = Map<String, dynamic>.from(trip['route'] as Map? ?? {});
    final departure = Map<String, dynamic>.from(json['departure'] as Map? ?? {});
    final scheduled = (departure['scheduled_local'] ?? departure['scheduled'] ?? json['departure_time'] ?? json['arrival_time'] ?? '').toString();
    final estimated = (departure['estimated_local'] ?? departure['estimated'] ?? '').toString();
    final relationship = (json['schedule_relationship'] ?? trip['schedule_relationship'] ?? '').toString();
    return TransitDeparture(
      route: (routeData['route_short_name'] ?? routeData['route_long_name'] ?? routeData['route_id'] ?? 'Transit').toString(),
      destination: (json['stop_headsign'] ?? trip['trip_headsign'] ?? 'Destination not listed').toString(),
      scheduledTime: scheduled,
      estimatedTime: estimated.isEmpty ? null : estimated,
      operator: (routeData['agency'] is Map ? (routeData['agency']['agency_name'] ?? '') : '').toString(),
      isRealtime: estimated.isNotEmpty,
      status: relationship,
    );
  }
}

class TransitVehicle {
  const TransitVehicle({
    required this.id,
    required this.route,
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.feedName,
    this.bearing,
    this.speed,
    this.timestamp,
  });

  final String id;
  final String route;
  final String label;
  final double latitude;
  final double longitude;
  final String feedName;
  final double? bearing;
  final double? speed;
  final DateTime? timestamp;

  factory TransitVehicle.fromGeoJson(Map<String, dynamic> feature, String feedName, String feedId) {
    final geometry = Map<String, dynamic>.from(feature['geometry'] as Map? ?? {});
    final coordinates = geometry['coordinates'] as List? ?? const [];
    if (coordinates.length < 2 || coordinates[0] is! num || coordinates[1] is! num) {
      throw const FormatException('Vehicle has no valid coordinates');
    }
    final properties = Map<String, dynamic>.from(feature['properties'] as Map? ?? {});
    final nested = Map<String, dynamic>.from(properties['vehicle'] as Map? ?? {});
    final trip = Map<String, dynamic>.from(properties['trip'] as Map? ?? nested['trip'] as Map? ?? {});
    final id = (nested['id'] ?? properties['vehicle_id'] ?? properties['id'] ?? properties['vehicleId'] ?? '').toString();
    final route = (properties['route_id'] ?? trip['route_id'] ?? properties['route'] ?? nested['route_id'] ?? '').toString();
    final label = (nested['label'] ?? properties['label'] ?? properties['vehicle_label'] ?? '').toString();
    final bearingValue = properties['bearing'] ?? nested['bearing'];
    final speedValue = properties['speed'] ?? nested['speed'];
    final timestampValue = properties['timestamp'] ?? nested['timestamp'];
    DateTime? timestamp;
    if (timestampValue is num) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(timestampValue.toInt() * 1000, isUtc: true);
    } else if (timestampValue is String) {
      timestamp = DateTime.tryParse(timestampValue);
    }
    return TransitVehicle(
      id: '$feedId:${id.isEmpty ? '${coordinates[0]}_${coordinates[1]}' : id}',
      route: route,
      label: label,
      latitude: (coordinates[1] as num).toDouble(),
      longitude: (coordinates[0] as num).toDouble(),
      feedName: feedName,
      bearing: bearingValue is num ? bearingValue.toDouble() : null,
      speed: speedValue is num ? speedValue.toDouble() : null,
      timestamp: timestamp,
    );
  }
}


class TransitServiceAlert {
  const TransitServiceAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.cause,
    required this.effect,
    required this.severity,
    required this.routes,
    required this.stops,
    required this.feedName,
    required this.feedId,
    required this.updatedAt,
    this.startsAt,
    this.endsAt,
    this.url,
  });

  final String id;
  final String title;
  final String description;
  final String cause;
  final String effect;
  final String severity;
  final List<String> routes;
  final List<String> stops;
  final String feedName;
  final String feedId;
  final DateTime? updatedAt;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String? url;

  static String _translation(dynamic value) {
    if (value is! Map) return '';
    final translations = value['translation'];
    if (translations is! List) return '';
    for (final item in translations) {
      if (item is Map && (item['text'] ?? '').toString().trim().isNotEmpty) {
        return item['text'].toString().trim();
      }
    }
    return '';
  }

  static DateTime? _epoch(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    final seconds = int.tryParse(value.toString());
    return seconds == null ? null : DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
  }

  factory TransitServiceAlert.fromEntity(
    Map<String, dynamic> entity,
    String feedName,
    String feedId,
    DateTime? updatedAt,
  ) {
    final alert = Map<String, dynamic>.from(entity['alert'] as Map? ?? {});
    final periods = (alert['activePeriod'] as List? ?? []).whereType<Map>().toList();
    DateTime? startsAt;
    DateTime? endsAt;
    for (final period in periods) {
      final start = _epoch(period['start']);
      final end = _epoch(period['end']);
      if (start != null && (startsAt == null || start.isBefore(startsAt))) startsAt = start;
      if (end != null && (endsAt == null || end.isAfter(endsAt))) endsAt = end;
    }
    final now = DateTime.now().toUtc();
    final active = periods.isEmpty ||
        periods.any((period) {
          final start = _epoch(period['start']);
          final end = _epoch(period['end']);
          return (start == null || !now.isBefore(start)) && (end == null || !now.isAfter(end));
        });
    if (!active) throw const FormatException('Alert is outside its active period');

    final informed = (alert['informedEntity'] as List? ?? []).whereType<Map>().toList();
    final routes = <String>{};
    final stops = <String>{};
    for (final item in informed) {
      final route = (item['routeId'] ?? item['route_id'] ?? '').toString();
      final stop = (item['stopId'] ?? item['stop_id'] ?? '').toString();
      if (route.isNotEmpty) routes.add(route);
      if (stop.isNotEmpty) stops.add(stop);
    }
    final cause = (alert['cause'] ?? 'UNKNOWN_CAUSE').toString();
    final effect = (alert['effect'] ?? 'UNKNOWN_EFFECT').toString();
    final severity = (alert['severityLevel'] ?? alert['severity_level'] ?? 'UNKNOWN_SEVERITY').toString();
    final title = _translation(alert['headerText']);
    final description = _translation(alert['descriptionText']);
    final link = _translation(alert['url']);
    final id = (entity['id'] ?? '').toString();
    return TransitServiceAlert(
      id: '$feedId:${id.isEmpty ? '${title}_${description}'.hashCode : id}',
      title: title.isEmpty ? _humanize(effect) : title,
      description: description,
      cause: _humanize(cause),
      effect: _humanize(effect),
      severity: severity,
      routes: routes.toList(),
      stops: stops.toList(),
      feedName: feedName,
      feedId: feedId,
      updatedAt: updatedAt,
      startsAt: startsAt,
      endsAt: endsAt,
      url: link.isEmpty ? null : link,
    );
  }

  static String _humanize(String value) {
    return value.toLowerCase().replaceAll('_', ' ').split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class GlobalTransitService {
  GlobalTransitService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  static const _overpass = 'https://overpass-api.de/api/interpreter';
  static const _transitland = 'https://transit.land/api/v2/rest';
  // Public client-side key requested by the project owner. Anyone inspecting
  // the compiled app can extract it; rotate it if it is abused.
  static const _transitlandApiKey = 'iwa_live_tlv2api_54c2b783d0ac275320ed2e6c96e879024b74ece027cfc1e20CmjjZ';


  Future<List<TransitPlace>> searchPlaces(String query) async {
    final term = query.trim();
    if (term.length < 2) return const [];
    final uri = Uri.https('photon.komoot.io', '/api/', {'q': term, 'limit': '7', 'lang': 'en'});
    final response = await _client.get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Place search is temporarily unavailable (HTTP ${response.statusCode}).');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final features = (data['features'] as List? ?? []).whereType<Map<String, dynamic>>();
    final places = <TransitPlace>[];
    for (final feature in features) {
      try { places.add(TransitPlace.fromPhoton(feature)); } catch (_) { /* Ignore malformed geocoder results. */ }
    }
    return places;
  }

  Future<List<TransitVehicle>> nearbyVehicles(double lat, double lon, {int radius = 10000}) async {
    final data = await _transitlandGet('/feeds', {
      'spec': 'gtfs-rt',
      'lat': '$lat',
      'lon': '$lon',
      'radius': '${radius.clamp(1, 10000)}',
      'limit': '50',
    });
    final feeds = (data['feeds'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .where((feed) {
          final urls = Map<String, dynamic>.from(feed['urls'] as Map? ?? {});
          return (urls['realtime_vehicle_positions'] ?? '').toString().isNotEmpty;
        })
        .take(10)
        .toList();
    final vehicles = <TransitVehicle>[];
    for (final feed in feeds) {
      final feedKey = (feed['onestop_id'] ?? feed['id'] ?? '').toString();
      if (feedKey.isEmpty) continue;
      try {
        final feedData = await _transitlandGet(
          '/feeds/${Uri.encodeComponent(feedKey)}/download_latest_rt/vehicle_positions.geojson',
          const {},
        );
        final features = (feedData['features'] as List? ?? []).whereType<Map<String, dynamic>>();
        for (final feature in features) {
          try {
            final vehicle = TransitVehicle.fromGeoJson(feature, (feed['name'] ?? feedKey).toString(), feedKey);
            final age = vehicle.timestamp == null ? null : DateTime.now().toUtc().difference(vehicle.timestamp!.toUtc());
            if (age != null && (age.isNegative || age > const Duration(minutes: 10))) continue;
            vehicles.add(vehicle);
          } catch (_) {
            // Ignore malformed vehicle records while keeping valid positions.
          }
        }
      } catch (_) {
        // One unavailable or restricted operator feed must not block other feeds.
      }
    }
    final unique = <String, TransitVehicle>{};
    for (final vehicle in vehicles) {
      unique.putIfAbsent(vehicle.id, () => vehicle);
    }
    return unique.values.toList();
  }


  Future<List<TransitServiceAlert>> nearbyAlerts(double lat, double lon, {int radius = 10000}) async {
    final data = await _transitlandGet('/feeds', {
      'spec': 'gtfs-rt',
      'lat': '$lat',
      'lon': '$lon',
      'radius': '${radius.clamp(1, 10000)}',
      'limit': '50',
    });
    final feeds = (data['feeds'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .where((feed) {
          final urls = Map<String, dynamic>.from(feed['urls'] as Map? ?? {});
          return (urls['realtime_alerts'] ?? '').toString().isNotEmpty;
        })
        .take(10)
        .toList();
    final alerts = <TransitServiceAlert>[];
    for (final feed in feeds) {
      final feedKey = (feed['onestop_id'] ?? feed['id'] ?? '').toString();
      if (feedKey.isEmpty) continue;
      try {
        final feedData = await _transitlandGet(
          '/feeds/${Uri.encodeComponent(feedKey)}/download_latest_rt/alerts.json',
          const {},
        );
        final header = Map<String, dynamic>.from(feedData['header'] as Map? ?? {});
        final updatedAt = TransitServiceAlert._epoch(header['timestamp']);
        final entities = (feedData['entity'] as List? ?? []).whereType<Map<String, dynamic>>();
        for (final entity in entities) {
          if (entity['alert'] is! Map) continue;
          try {
            alerts.add(TransitServiceAlert.fromEntity(
              entity,
              (feed['name'] ?? feedKey).toString(),
              feedKey,
              updatedAt,
            ));
          } catch (_) {
            // Ignore expired or malformed alerts, retaining valid feed entries.
          }
        }
      } catch (_) {
        // Restricted or unavailable feeds must not block alerts from other agencies.
      }
    }
    final unique = <String, TransitServiceAlert>{};
    for (final alert in alerts) {
      unique.putIfAbsent(alert.id, () => alert);
    }
    final result = unique.values.toList();
    result.sort((a, b) {
      int rank(String severity) {
        final value = severity.toUpperCase();
        if (value == 'SEVERE') return 0;
        if (value == 'WARNING') return 1;
        if (value == 'INFO') return 2;
        return 3;
      }
      return rank(a.severity).compareTo(rank(b.severity));
    });
    return result;
  }

  Future<List<TransitDeparture>> departuresForStop(TransitStop stop) async {
    final key = stop.scheduleKey;
    if (key == null || key.isEmpty) return const [];
    final encodedKey = Uri.encodeComponent(key);
    final data = await _transitlandGet('/stops/$encodedKey/departures', {
      'relative_date': 'TODAY',
      'next': '43200',
      'limit': '25',
      'include_alerts': 'true',
    });
    final stops = (data['stops'] as List? ?? []).whereType<Map<String, dynamic>>();
    if (stops.isEmpty) return const [];
    final raw = (stops.first['departures'] as List? ?? []).whereType<Map<String, dynamic>>();
    return raw.map(TransitDeparture.fromJson).where((item) => item.scheduledTime.isNotEmpty || item.estimatedTime != null).toList();
  }

  Future<List<TransitStop>> nearbyStops(double lat, double lon, {int radius = 1200}) async {
    final transitlandStops = await _tryTransitlandStops(lat, lon, radius);
    final osmStops = await _tryOsmStops(lat, lon, radius);
    final merged = <String, TransitStop>{};
    for (final stop in [...transitlandStops, ...osmStops]) {
      merged.putIfAbsent(stop.id, () => stop);
    }
    return merged.values.toList();
  }

  Future<List<TransitStop>> _tryTransitlandStops(double lat, double lon, int radius) async {
    try {
      final data = await _transitlandGet('/stops', {
        'lat': '$lat', 'lon': '$lon', 'radius': '${radius.clamp(1, 10000)}',
        'limit': '100', 'include_routes': 'true',
      });
      final items = (data['stops'] as List? ?? []).whereType<Map<String, dynamic>>();
      final stops = <TransitStop>[];
      for (final item in items) {
        try { stops.add(TransitStop.fromTransitland(item)); } catch (_) { /* Skip incomplete feed records. */ }
      }
      return stops;
    } catch (_) {
      return const [];
    }
  }

  Future<List<TransitStop>> _tryOsmStops(double lat, double lon, int radius) async {
    try {
      final query = '[out:json][timeout:25];(node["highway"="bus_stop"](around:$radius,$lat,$lon);node["public_transport"="platform"]["bus"="yes"](around:$radius,$lat,$lon);way["highway"="bus_stop"](around:$radius,$lat,$lon););out center tags;';
      final json = await _overpassQuery(query);
      final items = (json['elements'] as List? ?? []).whereType<Map<String, dynamic>>();
      final stops = <TransitStop>[];
      for (final e in items) {
        try { stops.add(TransitStop.fromElement(e)); } catch (_) { /* Ignore incomplete map features. */ }
      }
      return stops;
    } catch (_) {
      return const [];
    }
  }

  Future<List<TransitRoute>> searchBusRoutes(double lat, double lon, String term, {int radius = 10000}) async {
    final searchTerm = term.trim();
    if (searchTerm.isEmpty) return const [];
    final transitlandRoutes = await _tryTransitlandRoutes(lat, lon, searchTerm, radius);
    final osmRoutes = await _tryOsmRoutes(lat, lon, searchTerm, radius);
    final merged = <String, TransitRoute>{};
    for (final route in [...transitlandRoutes, ...osmRoutes]) {
      merged.putIfAbsent(route.id, () => route);
    }
    return merged.values.toList();
  }

  Future<List<TransitRoute>> _tryTransitlandRoutes(double lat, double lon, String term, int radius) async {
    try {
      final data = await _transitlandGet('/routes', {
        'lat': '$lat', 'lon': '$lon', 'radius': '${radius.clamp(1, 10000)}',
        'route_types': '3', 'search': term, 'limit': '100',
      });
      final items = (data['routes'] as List? ?? []).whereType<Map<String, dynamic>>();
      return items.map(TransitRoute.fromTransitland).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<TransitRoute>> _tryOsmRoutes(double lat, double lon, String term, int radius) async {
    try {
      final escaped = term.replaceAll(RegExp(r'[^a-zA-Z0-9 -]'), '').trim();
      if (escaped.isEmpty) return const [];
      final query = '[out:json][timeout:25];(relation["route"="bus"]["ref"~"$escaped",i](around:$radius,$lat,$lon);relation["route"="bus"]["name"~"$escaped",i](around:$radius,$lat,$lon);relation["route_master"="bus"]["ref"~"$escaped",i](around:$radius,$lat,$lon););out tags;';
      final json = await _overpassQuery(query);
      final items = (json['elements'] as List? ?? []).whereType<Map<String, dynamic>>();
      return items.map(TransitRoute.fromElement).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<Map<String, dynamic>> _transitlandGet(String path, Map<String, String> params) async {
    final uri = Uri.parse('$_transitland$path').replace(queryParameters: params);
    final response = await _client.get(uri, headers: {'apikey': _transitlandApiKey, 'Accept': 'application/json'})
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('Transitland request failed (HTTP ${response.statusCode}).');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _overpassQuery(String query) async {
    final response = await _client.post(Uri.parse(_overpass),
      headers: {'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'},
      body: {'data': query}).timeout(const Duration(seconds: 35));
    if (response.statusCode != 200) {
      throw Exception('OpenStreetMap transit data is temporarily unavailable (HTTP ${response.statusCode}).');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  void dispose() => _client.close();
}
