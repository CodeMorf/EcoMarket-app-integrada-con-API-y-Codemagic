import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class ExactAddressResult {
  final String address;
  final String province;
  final String city;
  final String sector;
  final double latitude;
  final double longitude;

  ExactAddressResult({
    required this.address,
    required this.province,
    required this.city,
    required this.sector,
    required this.latitude,
    required this.longitude,
  });
}

class LocationService {
  static Future<ExactAddressResult> getCurrentAddress() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw Exception('La ubicación está apagada. Actívala para rellenar la dirección.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw Exception('Permiso de ubicación denegado.');
    }

    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    final places = await placemarkFromCoordinates(position.latitude, position.longitude);
    final place = places.isNotEmpty ? places.first : null;

    final street = [place?.street, place?.subLocality]
        .where((value) => value != null && value.trim().isNotEmpty)
        .join(', ');
    final province = (place?.administrativeArea ?? '').trim();
    final city = (place?.locality?.trim().isNotEmpty == true)
        ? place!.locality!.trim()
        : (place?.subAdministrativeArea ?? '').trim();
    final sector = (place?.subLocality ?? place?.thoroughfare ?? '').trim();
    final address = [street, city, province, place?.country]
        .where((value) => value != null && value.trim().isNotEmpty)
        .join(', ');

    return ExactAddressResult(
      address: address.isEmpty ? '${position.latitude}, ${position.longitude}' : address,
      province: province,
      city: city,
      sector: sector,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}
