abstract class MapState {}

class MapLoading extends MapState {}

class MapLoaded extends MapState {
  final double latitude;
  final double longitude;
  final String currentLocation; // place name

  MapLoaded({
    required this.latitude,
    required this.longitude,
    required this.currentLocation,
  });
}

class MapError extends MapState {
  final String message;
  MapError(this.message);
}
