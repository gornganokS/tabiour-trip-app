import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'app_shell.dart';
import 'api_service.dart';
import 'places_page.dart';

void main() {
  runApp(const TripApp());
}

class TripApp extends StatelessWidget {
  const TripApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.mode,
      builder: (context, mode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Your Trip',
          theme: AppTheme.build(false),
          darkTheme: AppTheme.build(true),
          themeMode: mode,
          home: const LoginPage(),
        );
      },
    );
  }
}

// ---------------- Login / Register ----------------

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final api = ApiService();
  final form = GlobalKey<FormState>();

  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  bool registering = false;
  bool busy = false;
  String? error;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;

    setState(() {
      busy = true;
      error = null;
    });

    try {
      if (registering) {
        await api.register(name.text, email.text, password.text);
      } else {
        await api.login(email.text, password.text);
      }

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AppShell(
            api: api,
            createTripBuilder: (_) => CreateTripPage(api: api),
            loginBuilder: (_) => const LoginPage(),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => error = errorMessage(e));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.travel_explore, size: 72),
                    const SizedBox(height: 20),
                    Text(
                      'Your Trip',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 32),
                    if (registering) ...[
                      TextFormField(
                        controller: name,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Please enter your name.'
                            : null,
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) {
                        final text = value?.trim() ?? '';

                        return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                .hasMatch(text)
                            ? null
                            : 'Please enter a valid email address.';
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: password,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password.';
                        }

                        if (registering && value.length < 6) {
                          return 'Password must be at least 6 characters long.';
                        }

                        return null;
                      },
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: busy ? null : submit,
                      child: Text(
                        busy
                            ? 'Please wait...'
                            : registering
                            ? 'Sign up'
                            : 'Log in',
                      ),
                    ),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () {
                              setState(() {
                                registering = !registering;
                                error = null;
                              });
                            },
                      child: Text(
                        registering
                            ? 'Already have an account? Log in'
                            : 'Need an account? Sign up',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- Trip list ----------------

class TripsPage extends StatefulWidget {
  const TripsPage({super.key, required this.api});

  final ApiService api;

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  List<Json> trips = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
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
      MaterialPageRoute(builder: (_) => CreateTripPage(api: widget.api)),
    );

    if (created == true && mounted) await load();
  }

  void logout() {
    widget.api.token = null;

    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  Widget content() {
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
              TextButton(onPressed: load, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }

    if (trips.isEmpty) {
      return const Center(
        child: Text('No trips yet. Tap + to start planning.'),
      );
    }

    return RefreshIndicator(
      onRefresh: load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];

          return Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: ListTile(
              leading: const Icon(Icons.luggage_outlined),
              title: Text(trip['name'] as String),
              subtitle: const Text('View map and places'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
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
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Trip'),
        actions: [
          IconButton(
            onPressed: loading ? null : load,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: logout,
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 64,
              child: FilledButton.icon(
                onPressed: createTrip,
                icon: const Icon(Icons.add),
                label: const Text('Create trip'),
              ),
            ),
          ),
          Expanded(child: content()),
        ],
      ),
    );
  }
}

// ---------------- Create trip ----------------

class CreateTripPage extends StatefulWidget {
  const CreateTripPage({super.key, required this.api});

  final ApiService api;

  @override
  State<CreateTripPage> createState() => _CreateTripPageState();
}

class _CreateTripPageState extends State<CreateTripPage> {
  final name = TextEditingController();

  DateTimeRange? dates;
  bool busy = false;
  String? error;

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  String dateLabel(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> chooseDates() async {
    final year = DateTime.now().year;

    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(year - 1),
      lastDate: DateTime(year + 5),
      initialDateRange: dates,
    );

    if (result != null && mounted) {
      setState(() => dates = result);
    }
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty || dates == null) {
      setState(
        () => error = 'Please enter a trip name and select your travel dates.',
      );
      return;
    }

    setState(() {
      busy = true;
      error = null;
    });

    try {
      await widget.api.request(
        'POST',
        '/trips',
        body: {
          'name': name.text.trim(),
          'startDate': dates!.start.toIso8601String(),
          'endDate': dates!.end.toIso8601String(),
        },
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => error = errorMessage(e));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create trip')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: name,
            maxLength: 100,
            decoration: const InputDecoration(
              labelText: 'Trip name',
              hintText: 'e.g. Hua Hin getaway',
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: busy ? null : chooseDates,
            icon: const Icon(Icons.calendar_month),
            label: Text(
              dates == null
                  ? 'Select travel dates'
                  : '${dateLabel(dates!.start)} – '
                        '${dateLabel(dates!.end)}',
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(error!, style: const TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: busy ? null : save,
            child: Text(busy ? 'Creating...' : 'Create trip'),
          ),
        ],
      ),
    );
  }
}
