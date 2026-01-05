import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'search_map_state.dart';

class SearchMapCubit extends Cubit<SearchMapState> {
  SearchMapCubit() : super(const SearchMapInitial());

  /// Load current location
  Future<void> loadCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String locationName = 'Current Location';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          locationName =
          "${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}";
        }
      } catch (_) {}

      emit(SearchMapLoaded(
        currentLocation: LatLng(position.latitude, position.longitude),
        currentLocationName: locationName,
        startLocation: LatLng(position.latitude, position.longitude),
        routePoints: [],
      ));
    } catch (e) {
      emit(SearchMapError(
        message: e.toString(),
        currentLocation: state.currentLocation,
        currentLocationName: state.currentLocationName,
        startLocation: state.startLocation,
        destination: state.destination,
        distance: state.distance,
        mode: state.mode,
        routePoints: state.routePoints,
      ));
    }
  }

  /// Search destination with optional start location
  Future<void> searchDestinationByName(
      String toPlace,
      TransportMode mode, {
        String? fromPlace, // optional
      }) async {
    if (state is! SearchMapLoaded) return;
    final currentState = state as SearchMapLoaded;

    LatLng startLatLng = currentState.startLocation ?? currentState.currentLocation ?? LatLng(0,0);
    String startName = currentState.currentLocationName ?? "Current Location";

    // Use custom "from" location if provided
    if (fromPlace != null && fromPlace.isNotEmpty) {
      final fromLocations = await locationFromAddress(fromPlace);
      if (fromLocations.isNotEmpty) {
        startLatLng = LatLng(fromLocations.first.latitude, fromLocations.first.longitude);
        startName = fromPlace;
      }
    }

    // Find destination
    final toLocations = await locationFromAddress(toPlace);
    if (toLocations.isEmpty) {
      emit(SearchMapError(
        message: "Destination not found",
        currentLocation: currentState.currentLocation,
        currentLocationName: currentState.currentLocationName,
        startLocation: currentState.startLocation,
        destination: currentState.destination,
        distance: currentState.distance,
        mode: currentState.mode,
        routePoints: currentState.routePoints,
      ));
      return;
    }

    final destLatLng = LatLng(toLocations.first.latitude, toLocations.first.longitude);

    // Calculate distance
    final distance = _calculateDistance(startLatLng, destLatLng);

    // Emit updated state
    emit(currentState.copyWith(
      startLocation: startLatLng,
      currentLocation: startLatLng,
      currentLocationName: startName,
      destination: destLatLng,
      distance: distance,
      mode: mode,
      routePoints: [startLatLng, destLatLng],
    ));
  }

  /// Haversine distance in km
  double _calculateDistance(LatLng start, LatLng end) {
    const R = 6371; // Radius of Earth in km
    final dLat = _deg2rad(end.latitude - start.latitude);
    final dLng = _deg2rad(end.longitude - start.longitude);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(start.latitude)) *
            cos(_deg2rad(end.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  /// Estimate travel time based on transport mode
  String estimateTime(double distance, TransportMode mode) {
    double speed; // km/h
    switch (mode) {
      case TransportMode.walk:
        speed = 5;
        break;
      case TransportMode.cycle:
      case TransportMode.bike:
        speed = 15;
        break;
      case TransportMode.car:
        speed = 50;
        break;
      case TransportMode.bus:
        speed = 40;
        break;
      case TransportMode.train:
        speed = 80;
        break;
    }
    final mins = (distance / speed * 60).round();
    return '$mins min';
  }
}
