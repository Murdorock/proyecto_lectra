import 'package:geolocator/geolocator.dart';

void main() async {
  try {
    print('Obteniendo ubicación actual...');
    
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('El servicio de ubicación está desactivado');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Permiso de ubicación denegado');
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    print('\n=== TU UBICACIÓN ACTUAL ===');
    print('Latitud:  ${position.latitude}');
    print('Longitud: ${position.longitude}');
    print('Formato:  ${position.latitude} ${position.longitude}');
    print('Precisión: ${position.accuracy} metros');
    print('===========================\n');
  } catch (e) {
    print('Error: $e');
  }
}
