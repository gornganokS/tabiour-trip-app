import 'package:flutter/material.dart';

import 'api_service.dart';
import 'places_page.dart';

class TripDetailPage extends StatefulWidget {
  const TripDetailPage({super.key, required this.api, required this.tripId});

  final ApiService api;
  final String tripId;

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  final form = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final amountController = TextEditingController();

  Json? trip;

  List<Json> people = [];
  List<Json> bills = [];

  String? payerId;
  Set<String> selectedPeople = {};

  bool loading = true;
  bool saving = false;
  String? error;

  String get path => '/trips/${widget.tripId}';

  bool get isOwner =>
      trip?['ownerId'] == trip?['currentUserId'] && trip != null;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    super.dispose();
  }

  List<Json> readRows(dynamic value) {
    return (value as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  String money(num value) {
    return '฿${value.toStringAsFixed(2)}';
  }

  void showMessage(Object value) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(errorMessage(value))));
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await widget.api.request('GET', path);

      if (!mounted) return;

      setState(() {
        trip = Map<String, dynamic>.from(result as Map);

        people = readRows(trip!['people']);
        bills = readRows(trip!['bills']);

        payerId = trip!['currentUserId'] as String;

        selectedPeople = people.map((person) => person['id'] as String).toSet();
      });
    } catch (e) {
      if (mounted) {
        setState(() => error = errorMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> addMember() async {
    String enteredEmail = '';

    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add member'),
        content: TextField(
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          onChanged: (value) => enteredEmail = value,
          decoration: const InputDecoration(
            labelText: 'Email',
            helperText: 'Your friend needs to sign up first.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext, enteredEmail.trim());
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (email == null || email.isEmpty || !mounted) return;

    setState(() => saving = true);

    try {
      await widget.api.request('POST', '$path/members', body: {'email': email});

      if (!mounted) return;

      showMessage('member added');
      await load();
    } catch (e) {
      if (mounted) showMessage(e);
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Future<void> saveExpense() async {
    if (!form.currentState!.validate()) return;

    if (selectedPeople.isEmpty) {
      showMessage('choose split participants atleast 1 person');
      return;
    }

    if (payerId == null) {
      showMessage('choose payer');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => saving = true);

    try {
      await widget.api.request(
        'POST',
        '$path/bills',
        body: {
          'title': titleController.text.trim(),
          'amount': double.parse(amountController.text),
          'payerId': payerId,
          'splitUserIds': people
              .where((person) => selectedPeople.contains(person['id']))
              .map((person) => person['id'])
              .toList(),
        },
      );

      if (!mounted) return;

      titleController.clear();
      amountController.clear();

      showMessage('expense saved');

      await load();
    } catch (e) {
      if (mounted) showMessage(e);
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Future<void> deleteExpense(Json bill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('delete bill ${bill['title']}?'),
        content: const Text(
          'The expense splits for this bill will also be deleted.',
        ),
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

    setState(() => saving = true);

    try {
      await widget.api.request('DELETE', '$path/bills/${bill['id']}');

      if (!mounted) return;

      showMessage('Expense deleted successfully.');
      await load();
    } catch (e) {
      if (mounted) showMessage(e);
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Widget memberAvatar(Json person) {
  final colors = Theme.of(context).colorScheme;
  final avatarPath = person['avatarUrl'] as String?;

  final imageUrl = avatarPath == null || avatarPath.trim().isEmpty
      ? null
      : Uri.parse(ApiService.baseUrl)
          .resolve(avatarPath)
          .toString();

  Widget placeholder() {
    return ColoredBox(
      color: colors.surface,
      child: Center(
        child: Icon(
          Icons.person_outline,
          color: colors.onSurface,
          size: 28,
        ),
      ),
    );
  }

  return ClipOval(
    child: SizedBox(
      width: 48,
      height: 48,
      child: imageUrl == null
          ? placeholder()
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return placeholder();
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }

                return placeholder();
              },
            ),
    ),
  );
}

  Widget membersSection() {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Members (${people.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (isOwner)
              IconButton(
                onPressed: saving ? null : addMember,
                tooltip: 'add member',
                icon: const Icon(Icons.person_add_outlined),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              for (final person in people)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    memberAvatar(person),
                    const SizedBox(height: 4),
                    Text(person['name'] as String),
                    if (person['id'] == trip!['ownerId'])
                      const Text('Owner', style: TextStyle(fontSize: 10)),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget expenseForm() {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add new expense',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: titleController,
              enabled: !saving,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Dinner',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter an expense title.';
                }

                return null;
              },
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: amountController,
              enabled: !saving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Total (฿)'),
              validator: (value) {
                final text = value ?? '';

                if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(text)) {
                  return 'Enter an amount with up to 2 decimal places.';
                }

                final number = double.tryParse(text);

                if (number == null || number <= 0 || number > 100000000) {
                  return 'The amount must be greater than 0 and no more than 100,000,000.';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: payerId,
              decoration: const InputDecoration(labelText: 'Who pays?'),
              items: [
                for (final person in people)
                  DropdownMenuItem<String>(
                    value: person['id'] as String,
                    child: Text(person['name'] as String),
                  ),
              ],
              onChanged: saving
                  ? null
                  : (value) {
                      setState(() => payerId = value);
                    },
            ),

            const SizedBox(height: 16),

            Text(
              'Split by (${selectedPeople.length} people)',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            for (final person in people)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(person['name'] as String),
                value: selectedPeople.contains(person['id']),
                onChanged: saving
                    ? null
                    : (checked) {
                        setState(() {
                          final id = person['id'] as String;

                          if (checked == true) {
                            selectedPeople.add(id);
                          } else {
                            selectedPeople.remove(id);
                          }
                        });
                      },
              ),

            const SizedBox(height: 12),

            FilledButton.icon(
              onPressed: saving ? null : saveExpense,
              icon: const Icon(Icons.add),
              label: Text(saving ? 'saving...' : 'Add expense'),
            ),
          ],
        ),
      ),
    );
  }

  Widget billsSection() {
    final total = bills.fold<double>(
      0,
      (sum, bill) => sum + (bill['amount'] as num).toDouble(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total expenses'),
            Text(money(total), style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 12),

        if (bills.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('No expenses yet', textAlign: TextAlign.center),
          ),

        for (final bill in bills)
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: ExpansionTile(
              title: Text(bill['title'] as String),
              subtitle: Text(
                '${money(bill['amount'] as num)}'
                ' · ${bill['payer']['name']} paid',
              ),
              children: [
                if ((bill['splits'] as List).isEmpty)
                  const ListTile(
                    title: Text('This bill has no split details yet.'),
                  ),

                for (final split in readRows(bill['splits']))
                  ListTile(
                    dense: true,
                    title: Text(split['user']['name'] as String),
                    trailing: Text(money(split['amount'] as num)),
                  ),

                if (isOwner)
                  TextButton.icon(
                    onPressed: saving ? null : () => deleteExpense(bill),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete bill'),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: Text(trip?['name'] ?? 'Trip')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null || trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error ?? 'cannot load trip', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(onPressed: load, child: const Text('try again')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(trip!['name'] as String),
        actions: [
          IconButton(
            onPressed: saving ? null : load,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          membersSection(),

          const SizedBox(height: 20),

          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: ListTile(
              leading: const Icon(Icons.map_outlined),
              title: const Text('Places'),
              trailing: const Icon(Icons.chevron_right),
              onTap: saving
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlacesPage(
                            api: widget.api,
                            tripId: widget.tripId,
                            tripName: trip!['name'] as String,
                          ),
                        ),
                      );
                    },
            ),
          ),

          const SizedBox(height: 24),

          Text('Expenses', style: Theme.of(context).textTheme.titleLarge),

          const SizedBox(height: 12),

          expenseForm(),

          const SizedBox(height: 24),

          billsSection(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
