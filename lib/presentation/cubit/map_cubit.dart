import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'map_state.dart';

class MapCubit extends Cubit<MapState> {
  MapCubit() : super(MapLoading());

  Future<void> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(MapError("Location service disabled"));
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        emit(MapError("Location permission permanently denied"));
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Reverse geocoding to get place name
      String locationName = 'Unknown';
      try {
        final placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          locationName =
          "${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}";
        }
      } catch (_) {
        locationName = 'Unknown';
      }

      // Emit loaded state
      emit(MapLoaded(
        latitude: position.latitude,
        longitude: position.longitude,
        currentLocation: locationName,
      ));
    } catch (e) {
      emit(MapError(e.toString()));
    }
  }
}
