import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'api_service.dart';

class PlacesPage extends StatefulWidget {
  const PlacesPage({
    super.key,
    required this.api,
    required this.tripId,
    required this.tripName,
  });

  final ApiService api;
  final String tripId;
  final String tripName;

  @override
  State<PlacesPage> createState() => _PlacesPageState();
}

class _PlacesPageState extends State<PlacesPage> {
  final searchController = TextEditingController();

  GoogleMapController? mapController;

  List<Json> places = [];
  List<Json> results = [];

  Json? selected;

  bool loading = true;
  bool searching = false;
  bool saving = false;
  bool placesLoaded = false;

  String? error;

  String get placesPath => '/trips/${widget.tripId}/places';

  @override
  void initState() {
    super.initState();
    loadPlaces();
  }

  @override
  void dispose() {
    searchController.dispose();
    mapController?.dispose();
    super.dispose();
  }

  LatLng? position(Json place) {
    final lat = place['lat'];
    final lng = place['lng'];

    if (lat is! num || lng is! num) return null;

    return LatLng(lat.toDouble(), lng.toDouble());
  }

  Future<void> focus(Json place) async {
    final point = position(place);

    if (point == null || mapController == null) return;

    await mapController!.animateCamera(CameraUpdate.newLatLngZoom(point, 15));
  }

  Set<Marker> get markers {
    final items = <Marker>{};

    for (final place in places) {
      final point = position(place);

      if (point == null) continue;

      items.add(
        Marker(
          markerId: MarkerId('saved-${place['id']}'),
          position: point,
          infoWindow: InfoWindow(
            title: place['name'] as String,
            snippet: place['location'] as String?,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }

    if (selected != null) {
      final point = position(selected!);

      if (point != null) {
        items.add(
          Marker(
            markerId: const MarkerId('selected'),
            position: point,
            infoWindow: InfoWindow(
              title: selected!['name'] as String,
              snippet: 'Tap Add to trip to save this place.',
            ),
          ),
        );
      }
    }

    return items;
  }

  Future<void> loadPlaces() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await widget.api.list(placesPath);

      if (!mounted) return;

      setState(() {
        places = data;
        placesLoaded = true;
      });

      for (final place in places) {
        if (position(place) != null) {
          await focus(place);
          break;
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = errorMessage(e));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> search() async {
    if (searching || saving) return;

    final query = searchController.text.trim();

    if (query.length < 2) {
      setState(
        () => error = 'Please enter at least 2 characters for the place name.',
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      searching = true;
      results = [];
      selected = null;
      error = null;
    });

    try {
      final data = await widget.api.list(
        '/maps/search?q=${Uri.encodeQueryComponent(query)}',
      );

      if (!mounted) return;

      setState(() {
        results = data;

        if (data.isEmpty) {
          error = 'No places found. Try including the city name.';
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => error = errorMessage(e));
      }
    } finally {
      if (mounted) setState(() => searching = false);
    }
  }

  Future<void> addSelected() async {
    final place = selected;

    if (place == null || saving || loading || !placesLoaded) {
      return;
    }

    final duplicate = places.any(
      (saved) =>
          saved['name'] == place['name'] &&
          saved['lat'] == place['lat'] &&
          saved['lng'] == place['lng'],
    );

    if (duplicate) {
      setState(() => error = 'place already exist in this trip');
      return;
    }

    setState(() {
      saving = true;
      error = null;
    });

    try {
      final response = await widget.api.request(
        'POST',
        placesPath,
        body: {
          // CreatePlaceDto เดิมต้องรับ tripId ใน body ด้วย
          'tripId': widget.tripId,
          'name': place['name'],
          'location': place['location'],
          'lat': place['lat'],
          'lng': place['lng'],
        },
      );

      final saved = Map<String, dynamic>.from(response as Map);

      if (!mounted) return;

      setState(() {
        places.add(saved);
        selected = null;
        results = [];
        searchController.clear();
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('place added to trip')));

      await focus(saved);
    } catch (e) {
      if (mounted) {
        setState(() => error = errorMessage(e));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> removePlace(Json place) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('delete place?'),
        content: Text(place['name'] as String),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      saving = true;
      error = null;
    });

    try {
      await widget.api.request('DELETE', '$placesPath/${place['id']}');

      if (!mounted) return;

      setState(() {
        places.removeWhere((item) => item['id'] == place['id']);
      });
    } catch (e) {
      if (mounted) {
        setState(() => error = errorMessage(e));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tripName),
        actions: [
          IconButton(
            onPressed: loading || saving ? null : loadPlaces,
            tooltip: 'Refresh places',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      enabled: !saving && !searching,
                      maxLength: 100,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => search(),
                      decoration: const InputDecoration(
                        hintText: 'search eg. cafe, huahin',
                        prefixIcon: Icon(Icons.search),
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: searching || saving ? null : search,
                    tooltip: 'Search',
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ],
              ),
            ),
            if (loading || searching || saving) const LinearProgressIndicator(),
            Expanded(
              flex: 3,
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(13.7563, 100.5018),
                  zoom: 11,
                ),
                markers: markers,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: (controller) {
                  mapController = controller;

                  if (selected != null) {
                    focus(selected!);
                    return;
                  }

                  for (final place in places) {
                    if (position(place) != null) {
                      focus(place);
                      break;
                    }
                  }
                },
                onTap: (LatLng point) {
                  if (saving || searching) return;

                  FocusScope.of(context).unfocus();

                  setState(() {
                    selected = {
                      'name': 'Dropped pin',
                      'location':
                          '${point.latitude.toStringAsFixed(6)}, '
                          '${point.longitude.toStringAsFixed(6)}',
                      'lat': point.latitude,
                      'lng': point.longitude,
                    };

                    results = [];
                    error = null;
                  });
                },
              ),
            ),
            Expanded(
              flex: 2,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  if (selected != null)
                    Card(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selected!['name'] as String,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(selected!['location'] as String),
                            const SizedBox(height: 8),
                            FilledButton.icon(
                              onPressed: saving || loading || !placesLoaded
                                  ? null
                                  : addSelected,
                              icon: const Icon(Icons.add_location_alt),
                              label: Text(saving ? 'saving...' : 'add to trip'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (results.isNotEmpty) ...[
                    const Text(
                      'Search results — Select a place to view on the map.',
                    ),
                    for (final place in results)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.place_outlined),
                        title: Text(place['name'] as String),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(place['location'] as String),
                            for (final attribution
                                in (place['attributions'] as List? ?? []))
                              Text(
                                '${attribution['provider'] ?? ''} '
                                '${attribution['providerUri'] ?? ''}',
                                style: const TextStyle(fontSize: 10),
                              ),
                          ],
                        ),
                        selected:
                            selected?['googlePlaceId'] ==
                            place['googlePlaceId'],
                        onTap: saving
                            ? null
                            : () {
                                setState(() {
                                  selected = place;
                                  error = null;
                                });

                                focus(place);
                              },
                      ),
                    const Divider(),
                  ],
                  Text(
                    'Places List (${places.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (!loading && places.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Search for a place above, then tap “Add to trip.”',
                      ),
                    ),
                  for (final place in places)
                    Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      child: ListTile(
                        leading: const Icon(Icons.location_on),
                        title: Text(place['name'] as String),
                        subtitle: Text(place['location'] as String? ?? ''),
                        onTap: () => focus(place),
                        trailing: IconButton(
                          onPressed: saving ? null : () => removePlace(place),
                          tooltip: 'delete place',
                          icon: const Icon(Icons.close),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
