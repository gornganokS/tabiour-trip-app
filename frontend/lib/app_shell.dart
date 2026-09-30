import 'package:flutter/material.dart';

import 'trip_detail_page.dart';
import 'profile_page.dart';
import 'api_service.dart';
import 'app_theme.dart';
import 'places_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.api,
    required this.createTripBuilder,
    required this.loginBuilder,
  });

  final ApiService api;
  final WidgetBuilder createTripBuilder;
  final WidgetBuilder loginBuilder;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int tab = 0;

  List<Json> trips = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadTrips();
  }

  Future<void> loadTrips() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await widget.api.list('/trips');

      if (mounted) {
        setState(() => trips = result);
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = errorMessage(e));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> createTrip() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: widget.createTripBuilder),
    );

    if (created == true && mounted) {
      await loadTrips();
    }
  }

  void openPlaces(Json trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlacesPage(
          api: widget.api,
          tripId: trip['id'] as String,
          tripName: trip['name'] as String,
        ),
      ),
    );
  }

  Widget tripList({required bool mapMode}) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error!, textAlign: TextAlign.center),
              TextButton(onPressed: loadTrips, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadTrips,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            mapMode ? 'Maps' : 'Your Trip',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),

          if (!mapMode) ...[
            SizedBox(
              height: 72,
              child: FilledButton(
                onPressed: createTrip,
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                ),
                child: const Icon(Icons.add, size: 32),
              ),
            ),
            const SizedBox(height: 20),
          ],

          if (mapMode)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text('Select a trip to open its map.'),
            ),

          if (trips.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No trips yet. Create one from Home.',
                textAlign: TextAlign.center,
              ),
            ),

          for (final trip in trips)
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: ListTile(
                leading: Icon(
                  mapMode ? Icons.map_outlined : Icons.luggage_outlined,
                ),
                title: Text(
                  trip['name'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  mapMode
                      ? 'View map and places'
                      : 'Members, places, and expenses',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  if (mapMode) {
                    openPlaces(trip);
                  } else {
                    openTripDetails(trip);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> chooseTheme() async {
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Theme', textAlign: TextAlign.center)),
            ListTile(
              leading: const Icon(Icons.light_mode_outlined),
              title: const Text('Light'),
              trailing: AppTheme.mode.value == ThemeMode.light
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                Navigator.pop(sheetContext, ThemeMode.light);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark'),
              trailing: AppTheme.mode.value == ThemeMode.dark
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                Navigator.pop(sheetContext, ThemeMode.dark);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (selected != null && mounted) {
      AppTheme.mode.value = selected;
      setState(() {});
    }
  }

  Future<void> logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    widget.api.token = null;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: widget.loginBuilder),
      (_) => false,
    );
  }

  Future<void> openTripDetails(Json trip) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TripDetailPage(api: widget.api, tripId: trip['id'] as String),
      ),
    );

    if (mounted) {
      await loadTrips();
    }
  }

  Widget settingsPage() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Setting', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 24),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: ListTile(
            title: const Text('Theme'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppTheme.mode.value == ThemeMode.dark ? 'Dark' : 'Light'),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: chooseTheme,
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: logout,
          child: const Text('Logout', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: switch (tab) {
          0 => tripList(mapMode: false),
          1 => tripList(mapMode: true),
          2 => ProfilePage(api: widget.api),
          _ => settingsPage(),
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) {
          setState(() => tab = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Maps',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Setting',
          ),
        ],
      ),
    );
  }
}
