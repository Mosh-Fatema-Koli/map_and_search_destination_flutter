import 'dart:convert';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
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
      emit(SearchMapError(message: e.toString()));
    }
  }

  /// Search destination and fetch route
  Future<void> searchDestinationByName(
      String toPlace,
      TransportMode mode, {
        String? fromPlace,
      }) async {
    if (state is! SearchMapLoaded) return;
    final currentState = state as SearchMapLoaded;

    try {
      // 1️⃣ Get coordinates for "to" place
      final toLocations = await locationFromAddress(toPlace);
      final toLatLng =
      LatLng(toLocations.first.latitude, toLocations.first.longitude);

      // 2️⃣ Get "from" coordinates
      LatLng fromLatLng = currentState.currentLocation!;
      if (fromPlace != null && fromPlace.isNotEmpty) {
        final fromLocations = await locationFromAddress(fromPlace);
        if (fromLocations.isNotEmpty) {
          fromLatLng =
              LatLng(fromLocations.first.latitude, fromLocations.first.longitude);
        }
      }

      // 3️⃣ Call OpenRouteService API
      final apiKey = "eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImJmYjRkMzI0NDg3ZTQ3MWQ4ZmExZWRhYWFkOGRjOTNlIiwiaCI6Im11cm11cjY0In0="; // Replace with your key
      final profile = {
        TransportMode.walk: "foot-walking",
        TransportMode.cycle: "cycling-regular",
        TransportMode.bike: "cycling-road",
        TransportMode.car: "driving-car",
        TransportMode.bus: "driving-car",
        TransportMode.train: "driving-car",
      }[mode]!;

      final url =
          "https://api.openrouteservice.org/v2/directions/$profile?start=${fromLatLng.longitude},${fromLatLng.latitude}&end=${toLatLng.longitude},${toLatLng.latitude}";

      final response = await http.get(Uri.parse(url), headers: {"Authorization": apiKey});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final geometry = data['features'][0]['geometry']['coordinates'] as List;
        final routePoints = geometry
            .map((p) => LatLng(p[1] as double, p[0] as double))
            .toList();

        // Distance in km
        final distance = (data['features'][0]['properties']['segments'][0]['distance'] as num) / 1000;

        emit(currentState.copyWith(
          startLocation: fromLatLng,
          destination: toLatLng,
          distance: distance,
          mode: mode,
          routePoints: routePoints,
        ));
      } else {
        emit(SearchMapError(message: "Failed to get route from API"));
      }
    } catch (e) {
      emit(SearchMapError(message: e.toString()));
    }
  }

  /// Haversine distance in km
  double _calculateDistance(LatLng start, LatLng end) {
    const R = 6371;
    final dLat = _deg2rad(end.latitude - start.latitude);
    final dLng = _deg2rad(end.longitude - start.longitude);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(start.latitude)) *
            cos(_deg2rad(end.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  /// Estimate travel time
  String estimateTime(double distance, TransportMode mode) {
    double speed;
    switch (mode) {
      case TransportMode.walk:
        speed = 5;
        break;
      case TransportMode.cycle:
        speed = 15;
        break;
      case TransportMode.bike:
        speed = 40;
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
