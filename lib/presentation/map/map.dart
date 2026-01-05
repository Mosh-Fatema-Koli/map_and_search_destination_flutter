

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:map/presentation/map/search_map.dart';
import 'package:shimmer/shimmer.dart';
import '../cubit/map_cubit.dart';
import '../cubit/map_state.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final mapController = MapController();

    return BlocProvider(
      create: (_) => MapCubit()..getCurrentLocation(),
      child: Scaffold(
        backgroundColor: Colors.blue,
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: BlocBuilder<MapCubit, MapState>(
            builder: (context, state) {
              if (state is MapLoaded) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10,),
                    const Text("Hello User," , style: const TextStyle(fontSize: 20,color: Colors.white,fontWeight: FontWeight.bold),),
                    SizedBox(height: 5,),
                    Text(
                      "Current Location: ${state.currentLocation}",
                      style: const TextStyle(fontSize: 12,color: Colors.white),
                    ),

                  ],
                );
              }
              return Column(
                children: [
                  const Text("Hello User"),
                  const Text("Loading location...",
                    style: const TextStyle(fontSize: 12),),
                ],
              );
            },
          ),
        ),
        body: BlocBuilder<MapCubit, MapState>(
          builder: (context, state) {
            if (state is MapLoading) {
            return const MapShimmerLoading();
            }

            if (state is MapLoaded) {
              final point = LatLng(state.latitude, state.longitude);

              return Padding(
                padding: const EdgeInsets.only(top: 20),
                child: SafeArea(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.7),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      borderRadius: BorderRadiusGeometry.only(topRight: Radius.circular(50),topLeft: Radius.circular(50)),
                    ),

                    child: Stack(
                      children: [
                        Column(
                          children: [
                            SizedBox(height: 15,),
                            // Search bar
                            Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SearchMapPage(),
                                    ),
                                  );
                                },
                                child: Container(
                                  height: 50,
                                  alignment: Alignment.centerLeft,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.blue),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      "Search location",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Map
                            Expanded(
                              child: FlutterMap(
                                mapController: mapController,
                                options: MapOptions(center: point, zoom: 15),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.example.map',
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: point,
                                        width: 100,
                                        height: 100,

                                        child: TweenAnimationBuilder<double>(
                                          tween: Tween(begin: 0.5, end: 1.2),
                                          duration: const Duration(seconds: 2),
                                          curve: Curves.easeOut,
                                          builder: (context, scale, child) {
                                            return Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Container(
                                                  width: 60 * scale,
                                                  height: 60 * scale,
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.withOpacity(0.3),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const Icon(
                                                  Icons.location_pin,
                                                  color: Colors.red,
                                                  size: 40,
                                                ),
                                              ],
                                            );
                                          },
                                          onEnd: () {
                                            // repeat animation by rebuilding child
                                            // optional: you can use an AnimationController for smoother looping
                                          },
                                        ),
                                      ),

                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Floating buttons
                        Positioned(
                          bottom: 20,
                          right: 20,
                          child: Column(
                            children: [
                              FloatingActionButton(
                                heroTag: 'refresh',
                                mini: true,
                                onPressed: () {
                                  final cubit = context.read<MapCubit>();
                                  cubit.getCurrentLocation(); // fetch current location

                                  // move the map to current location with zoom 15
                                  if (cubit.state is MapLoaded) {
                                    final state = cubit.state as MapLoaded;
                                    mapController.move(LatLng(state.latitude, state.longitude), 15);
                                  }
                                },
                                child: const Icon(Icons.refresh),
                              ),
                              const SizedBox(height: 10),
                              FloatingActionButton(
                                heroTag: 'zoom_in',
                                mini: true,
                                onPressed: () {
                                  mapController.move(point, mapController.zoom + 1);
                                },
                                child: const Icon(Icons.zoom_in),
                              ),
                              const SizedBox(height: 10),
                              FloatingActionButton(
                                heroTag: 'zoom_out',
                                mini: true,
                                onPressed: () {
                                  mapController.move(point, mapController.zoom - 1);
                                },
                                child: const Icon(Icons.zoom_out),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            if (state is MapError) {
              return Center(child: Text(state.message));
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }
}



class MapShimmerLoading extends StatelessWidget {
  const MapShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(50),
            topRight: Radius.circular(50),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),

            /// Search Bar Shimmer
            Padding(
              padding: const EdgeInsets.all(15),
              child: Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            /// Map Area Shimmer
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
