import 'package:geolocator/geolocator.dart';

/// Гирифтани маҳалли ҷойгиршавии ҳозира барои фиристодани он ба чат.
class LocationService {
  /// `null` — агар иҷозат дода нашуда бошад ё хидмати геолокатсия хомӯш бошад.
  static Future<Position?> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (_) {
      return null;
    }
  }

  /// Суроғаи харита, ки ҳам дар Android ва ҳам дар браузер кушода мешавад.
  static String mapsUrl(double lat, double lng) {
    return 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
  }
}
