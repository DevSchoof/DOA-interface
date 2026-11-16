import 'package:geolocator/geolocator.dart';

import 'api_exception.dart';

typedef GeoPoint = ({double latitude, double longitude});

/// Recurso nativo: GPS (no Chrome usa a geolocalização do navegador).
class LocationService {
  const LocationService();

  /// Posição atual. Lança [ApiException] com mensagem amigável se não der.
  Future<GeoPoint> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const ApiException('Ative a localização do dispositivo.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const ApiException(
        'Permissão de localização negada. Libere nas configurações para usar este recurso.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return (latitude: position.latitude, longitude: position.longitude);
    } catch (_) {
      // Segunda tentativa: última posição conhecida (comum no emulador logo
      // depois de "Set Location" ou quando o GPS ainda não deu o primeiro fix).
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          return (latitude: last.latitude, longitude: last.longitude);
        }
      } catch (_) {}
      throw const ApiException(
        'Não foi possível obter sua localização agora. No emulador, use '
        '"Set Location" no painel de localização e tente de novo.',
      );
    }
  }
}
