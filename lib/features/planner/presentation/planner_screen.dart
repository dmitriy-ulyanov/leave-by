import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/clock_provider.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../application/planner_notifier.dart';
import '../application/planner_state.dart';
import '../domain/trip_request.dart';
import 'widgets/route_option_card.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _timeController = TextEditingController();
  String? _origin;
  String? _destination;

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final now = ref.read(clockProvider)();
    final arriveBy = Validators.parseTime(_timeController.text, now)!;
    ref.read(plannerProvider.notifier).search(
          TripRequest(origin: _origin!, destination: _destination!, arriveBy: arriveBy),
        );
  }

  @override
  Widget build(BuildContext context) {
    final planner = ref.watch(plannerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Leave By')),
      body: planner.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => ErrorView(
          message: 'Gagal memuat data lokasi.',
          onRetry: () => ref.invalidate(plannerProvider),
        ),
        data: _buildContent,
      ),
    );
  }

  Widget _buildContent(PlannerData data) {
    final now = ref.read(clockProvider)();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              key: const Key('originField'),
              decoration: const InputDecoration(labelText: 'Asal'),
              items: [for (final place in data.places) DropdownMenuItem(value: place, child: Text(place))],
              onChanged: (value) => _origin = value,
              validator: (value) => Validators.requiredChoice(value, 'Asal wajib dipilih'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const Key('destinationField'),
              decoration: const InputDecoration(labelText: 'Tujuan'),
              items: [for (final place in data.places) DropdownMenuItem(value: place, child: Text(place))],
              onChanged: (value) => _destination = value,
              validator: (value) => Validators.destination(value, _origin),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('arriveByField'),
              controller: _timeController,
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(labelText: 'Jam tiba yang dibutuhkan (HH:mm)'),
              validator: (value) => Validators.arriveBy(value, now),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('searchButton'),
              onPressed: data.isSubmitting ? null : _submit,
              child: data.isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Cari Rute'),
            ),
            const SizedBox(height: 16),
            ..._buildResults(data),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildResults(PlannerData data) {
    if (data.searchError != null) {
      return [Text(data.searchError!, style: TextStyle(color: Theme.of(context).colorScheme.error))];
    }
    final results = data.results;
    if (results == null) return const [];
    if (results.isEmpty) {
      return const [EmptyView(message: 'Tidak ada opsi yang sempat dikejar. Coba jam tiba yang lebih longgar.')];
    }
    return [for (final advice in results) RouteOptionCard(advice: advice)];
  }
}
