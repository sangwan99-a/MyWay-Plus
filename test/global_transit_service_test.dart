import 'package:flutter_test/flutter_test.dart';
import 'package:myway_plus/services/global_transit_service.dart';

void main() {
  group('TransitPlace', () {
    test('parses Photon GeoJSON coordinates in longitude-latitude order', () {
      final place = TransitPlace.fromPhoton({
        'properties': {
          'name': 'Panipat',
          'state': 'Haryana',
          'country': 'India',
        },
        'geometry': {
          'type': 'Point',
          'coordinates': [76.9635, 29.3909],
        },
      });

      expect(place.name, 'Panipat');
      expect(place.displayName, 'Panipat, Haryana, India');
      expect(place.latitude, 29.3909);
      expect(place.longitude, 76.9635);
    });

    test('rejects a geocoder result without valid coordinates', () {
      expect(
        () => TransitPlace.fromPhoton({
          'properties': {'name': 'Unknown'},
          'geometry': {'coordinates': []},
        }),
        throwsFormatException,
      );
    });
  });

  group('TransitVehicle', () {
    test('parses a GeoJSON vehicle and namespaces its ID by feed', () {
      final vehicle = TransitVehicle.fromGeoJson({
        'geometry': {
          'type': 'Point',
          'coordinates': [77.1025, 28.7041],
        },
        'properties': {
          'vehicle': {'id': 'bus-42', 'label': 'Bus 42', 'bearing': 90},
          'trip': {'route_id': 'R-10'},
          'timestamp': 1795262400,
        },
      }, 'City Transit', 'f-city');

      expect(vehicle.id, 'f-city:bus-42');
      expect(vehicle.route, 'R-10');
      expect(vehicle.label, 'Bus 42');
      expect(vehicle.latitude, 28.7041);
      expect(vehicle.longitude, 77.1025);
      expect(vehicle.bearing, 90);
      expect(vehicle.timestamp, isNotNull);
    });

    test('rejects a vehicle without coordinates', () {
      expect(
        () => TransitVehicle.fromGeoJson({
          'geometry': {'coordinates': []},
        }, 'Agency', 'feed'),
        throwsFormatException,
      );
    });
  });

  group('TransitTripUpdate', () {
    test('parses predicted arrival, delay and skipped-stop relationship', () {
      final update = TransitTripUpdate.fromStopTime(
        {'id': 'entity-1'},
        {'id': 'trip-update-1'},
        {
          'tripId': 'trip-7',
          'routeId': 'route-3',
          'tripHeadsign': 'City Centre',
        },
        {
          'stopId': 'stop-9',
          'stopSequence': 4,
          'scheduleRelationship': 'SKIPPED',
          'arrival': {'time': 1795262400, 'delay': 180},
        },
        'City Transit',
        'f-city',
        DateTime.utc(2026, 11, 21),
      );

      expect(update.id, 'f-city:entity-1:stop-9:4');
      expect(update.tripId, 'trip-7');
      expect(update.routeId, 'route-3');
      expect(update.stopId, 'stop-9');
      expect(update.headsign, 'City Centre');
      expect(update.isSkipped, isTrue);
      expect(update.delaySeconds, 180);
      expect(update.predictedTime, DateTime.fromMillisecondsSinceEpoch(
        1795262400 * 1000,
        isUtc: true,
      ));
    });

    test('recognizes cancelled trips even without stop-time updates', () {
      final update = TransitTripUpdate.fromStopTime(
        {'id': 'cancelled-1'},
        {},
        {'trip_id': 'trip-cancelled', 'schedule_relationship': 'CANCELED'},
        <String, dynamic>{},
        'City Transit',
        'f-city',
        null,
      );

      expect(update.isCancelled, isTrue);
      expect(update.predictedTime, isNull);
    });
  });

  group('TransitServiceAlert', () {
    test('parses translated alert text and affected routes/stops', () {
      final alert = TransitServiceAlert.fromEntity({
        'id': 'alert-1',
        'alert': {
          'headerText': {
            'translation': [{'text': 'Service disruption'}],
          },
          'descriptionText': {
            'translation': [{'text': 'Expect delays on this service.'}],
          },
          'cause': 'CONSTRUCTION',
          'effect': 'SIGNIFICANT_DELAYS',
          'severityLevel': 'SEVERE',
          'informedEntity': [
            {'routeId': 'route-12', 'stopId': 'stop-5'},
            {'routeId': 'route-12'},
          ],
        },
      }, 'City Transit', 'f-city', DateTime.utc(2026, 11, 21));

      expect(alert.id, 'f-city:alert-1');
      expect(alert.title, 'Service disruption');
      expect(alert.description, 'Expect delays on this service.');
      expect(alert.cause, 'Construction');
      expect(alert.effect, 'Significant Delays');
      expect(alert.severity, 'SEVERE');
      expect(alert.routes, ['route-12']);
      expect(alert.stops, ['stop-5']);
    });

    test('filters an alert whose active period has expired', () {
      final now = DateTime.now().toUtc();
      final expired = now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch ~/ 1000;
      final ended = now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;

      expect(
        () => TransitServiceAlert.fromEntity({
          'id': 'expired',
          'alert': {
            'activePeriod': [{'start': expired, 'end': ended}],
            'headerText': {'translation': [{'text': 'Old alert'}]},
          },
        }, 'City Transit', 'f-city', now),
        throwsFormatException,
      );
    });
  });

  group('TransitDeparture', () {
    test('uses an agency-provided estimate and identifies it as realtime', () {
      final departure = TransitDeparture.fromJson({
        'trip': {
          'route': {'route_short_name': 'A1'},
          'trip_headsign': 'Central',
        },
        'departure': {
          'scheduled_local': '2026-11-21T11:30:00',
          'estimated_local': '2026-11-21T11:36:00',
        },
      });

      expect(departure.route, 'A1');
      expect(departure.destination, 'Central');
      expect(departure.isRealtime, isTrue);
      expect(departure.displayTime, '11:36');
    });
  });
}
