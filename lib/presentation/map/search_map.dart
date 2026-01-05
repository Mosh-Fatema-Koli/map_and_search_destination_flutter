import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shimmer/shimmer.dart';
import '../cubit/search_map_cubit.dart';
import '../cubit/search_map_state.dart';

class SearchMapPage extends StatelessWidget {
  SearchMapPage({super.key});

  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SearchMapCubit()..loadCurrentLocation(),
      child: Scaffold(
        appBar: AppBar(title: const Text("Search Location")),
        body: BlocBuilder<SearchMapCubit, SearchMapState>(
          builder: (context, state) {
            final currentLocation = state.currentLocation ?? LatLng(0, 0);
            final currentName = state.currentLocationName ?? "Loading...";
            final destination = state.destination;
            final distance = state.distance;
            final mode = state.mode;
            final routePoints = state.routePoints;

            // Error state
            if (state is SearchMapError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<SearchMapCubit>().loadCurrentLocation(),
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              );
            }

            // Loading
            // Loading state
            if (state is SearchMapInitial || currentLocation.latitude == 0) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 20, width: 150, color: Colors.white),
                      const SizedBox(height: 12),
                      Container(height: 50, width: double.infinity, color: Colors.white),
                      const SizedBox(height: 12),
                      Container(height: 50, width: double.infinity, color: Colors.white),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: List.generate(5, (index) => Container(height: 30, width: 80, color: Colors.white)),
                      ),
                      const SizedBox(height: 16),
                      Container(height: 80, width: double.infinity, color: Colors.white),
                      const SizedBox(height: 16),
                      Expanded(child: Container(color: Colors.white)),
                    ],
                  ),
                ),
              );
            }
            fromController.text=currentName;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  /// CURRENT LOCATION
                  Row(
                    children: [
                      const Icon(Icons.my_location, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          currentName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () => context.read<SearchMapCubit>().loadCurrentLocation(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  /// FROM FIELD
                  TextFormField(
                    controller: fromController,
                    decoration: InputDecoration(
                      labelText: "From (leave empty for current location)",
                      hintText: "Enter your starting location",
                      suffixIcon: const Icon(Icons.my_location),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  /// TO FIELD
                  TextFormField(
                    controller: toController,
                    decoration: InputDecoration(
                      labelText: "To (destination)",
                      hintText: "Enter destination",
                      suffixIcon: const Icon(Icons.location_on),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// TRANSPORT MODES
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      children: TransportMode.values.map((tMode) {
                        final icon = {
                          TransportMode.walk: Icons.directions_walk,
                          TransportMode.cycle: Icons.directions_bike,
                          TransportMode.bike: Icons.directions_bike_sharp,
                          TransportMode.car: Icons.directions_car,
                          TransportMode.bus: Icons.directions_bus,
                          TransportMode.train: Icons.train,
                        }[tMode]!;

                        return ChoiceChip(
                          avatar: Icon(icon, size: 18, color: mode == tMode ? Colors.white : Colors.blue),
                          label: Text(tMode.name.toUpperCase()),
                          selected: mode == tMode,
                          selectedColor: Colors.blue,
                          onSelected: (_) {
                          final from = fromController.text.trim();
                          final to = toController.text.trim();
                          if (to.isNotEmpty) {
                          context.read<SearchMapCubit>().searchDestinationByName(
                          to,
                          tMode,
                          fromPlace: from.isEmpty ? null : from,
                          );
                          }
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// DISTANCE + TIME
                  if (distance != null && mode != null)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                const Text("Distance", style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text("${distance.toStringAsFixed(2)} km"),
                              ],
                            ),
                            Column(
                              children: [
                                const Text("Estimated Time", style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(context.read<SearchMapCubit>().estimateTime(distance, mode)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  /// MAP
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: SearchMapView(
                        current: currentLocation,
                        destination: destination,
                        routePoints: routePoints,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class SearchMapView extends StatelessWidget {
  final LatLng current;
  final LatLng? destination;
  final List<LatLng> routePoints;

  const SearchMapView({
    super.key,
    required this.current,
    this.destination,
    required this.routePoints,
  });

  @override
  Widget build(BuildContext context) {
    final bounds = routePoints.isNotEmpty
        ? LatLngBounds.fromPoints(routePoints)
        : LatLngBounds(current, current);

    return FlutterMap(
      options: MapOptions(
        bounds: bounds,
        boundsOptions: const FitBoundsOptions(padding: EdgeInsets.all(50)),
      ),
      children: [
        // Map Tiles
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: 'com.example.app',
        ),

        // Polyline
        if (routePoints.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                color: Colors.blueAccent,
                strokeWidth: 4,
              ),
            ],
          ),

        // Markers
        MarkerLayer(
          markers: [
            Marker(
              point: current,
              width: 40,
              height: 40,
              child: const Icon(Icons.my_location, color: Colors.blue, size: 32),
            ),
            if (destination != null)
              Marker(
                point: destination!,
                width: 40,
                height: 40,
                child: const Icon(Icons.location_pin, color: Colors.red, size: 36),
              ),
          ],
        ),
      ],
    );
  }
}
