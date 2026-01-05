import 'package:latlong2/latlong.dart';

/// 🚶‍♂️ Transport types
enum TransportMode { walk, cycle, bike, car, train, bus }

/// 🗺 Base state for SearchMap
abstract class SearchMapState {
  final LatLng? currentLocation;
  final String? currentLocationName;
  final LatLng? startLocation;   // "From" location
  final LatLng? destination;     // "To" location
  final double? distance;
  final TransportMode? mode;
  final List<LatLng> routePoints;

  const SearchMapState({
    this.currentLocation,
    this.currentLocationName,
    this.startLocation,
    this.destination,
    this.distance,
    this.mode,
    this.routePoints = const [],
  });
}

/// 🟢 Initial state (before location is loaded)
final class SearchMapInitial extends SearchMapState {
  const SearchMapInitial() : super();
}

/// 🔵 Loaded state (location fetched or route calculated)
final class SearchMapLoaded extends SearchMapState {
  const SearchMapLoaded({
    super.currentLocation,
    super.currentLocationName,
    super.startLocation,
    super.destination,
    super.distance,
    super.mode,
    super.routePoints,
  });

  /// 🔁 CopyWith for easy updates
  SearchMapLoaded copyWith({
    LatLng? currentLocation,
    String? currentLocationName,
    LatLng? startLocation,
    LatLng? destination,
    double? distance,
    TransportMode? mode,
    List<LatLng>? routePoints,
  }) {
    return SearchMapLoaded(
      currentLocation: currentLocation ?? this.currentLocation,
      currentLocationName: currentLocationName ?? this.currentLocationName,
      startLocation: startLocation ?? this.startLocation,
      destination: destination ?? this.destination,
      distance: distance ?? this.distance,
      mode: mode ?? this.mode,
      routePoints: routePoints ?? this.routePoints,
    );
  }
}

/// 🔴 Error state
final class SearchMapError extends SearchMapState {
  final String message;

  const SearchMapError({
    required this.message,
    super.currentLocation,
    super.currentLocationName,
    super.startLocation,
    super.destination,
    super.distance,
    super.mode,
    super.routePoints,
  });
}
