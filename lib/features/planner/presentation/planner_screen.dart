import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/api_config.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../auth/application/auth_notifier.dart';
import '../../saved_trips/domain/saved_trip.dart';
import '../application/planner_notifier.dart';
import '../application/planner_state.dart';
import '../domain/departure_advice.dart';
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

  Future<void> _confirmLogout() async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: 'Keluar dari akun?',
      message: 'Kamu perlu masuk lagi untuk melihat perjalanan tersimpan.',
      confirmLabel: 'Keluar',
    );
    if (confirmed != true) return;
    await ref.read(authProvider.notifier).signOut();
    messenger.showSnackBar(const SnackBar(content: Text('Kamu sudah keluar.')));
  }

  void _openSaveForm(DepartureAdvice advice, TripRequest request) {
    final trip = SavedTrip(
      id: '',
      title: '${request.origin} → ${request.destination}',
      origin: request.origin,
      destination: request.destination,
      arriveBy: request.arriveBy,
      optionLabel: advice.option.label,
      departAt: advice.departAt,
      createdAt: ref.read(clockProvider)(),
    );
    Navigator.pushNamed(context, AppRoutes.savedForm, arguments: trip);
  }

  @override
  Widget build(BuildContext context) {
    final planner = ref.watch(plannerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave By'),
        actions: [
          IconButton(
            key: const Key('openSavedButton'),
            icon: const Icon(Icons.bookmarks_outlined),
            tooltip: 'Perjalanan Tersimpan',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.saved),
          ),
          if (storageMode != 'local')
            IconButton(
              key: const Key('logoutButton'),
              icon: const Icon(Icons.logout),
              tooltip: 'Keluar',
              onPressed: _confirmLogout,
            ),
        ],
      ),
      body: planner.when(
        loading: () => const Center(child: CircularProgressIndicator(semanticsLabel: 'Memuat')),
        error: (_, _) => ErrorView(
          message: 'Gagal memuat data lokasi.',
          onRetry: () => ref.invalidate(plannerProvider),
        ),
        data: _buildContent,
      ),
    );
  }

  Widget _buildContent(PlannerData data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final form = _buildForm(data);
        final results = _buildResults(data);
        final Widget body;
        if (isWideWidth(constraints.maxWidth)) {
          body = ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: contentMaxWidth),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: plannerFormWidth, child: form),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: results),
                ),
              ],
            ),
          );
        } else {
          body = ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: formMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [form, const SizedBox(height: 16), ...results],
            ),
          );
        }
        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(16),
          child: Center(child: body),
        );
      },
    );
  }

  Widget _buildForm(PlannerData data) {
    final now = ref.read(clockProvider)();
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            key: const Key('originField'),
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Asal'),
            items: [
              for (final place in data.places)
                DropdownMenuItem(value: place, child: Text(place, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (value) => _origin = value,
            validator: (value) => Validators.requiredChoice(value, 'Asal wajib dipilih'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: const Key('destinationField'),
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Tujuan'),
            items: [
              for (final place in data.places)
                DropdownMenuItem(value: place, child: Text(place, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (value) => _destination = value,
            validator: (value) => Validators.destination(value, _origin),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('arriveByField'),
            controller: _timeController,
            scrollPadding: formScrollPadding,
            keyboardType: TextInputType.datetime,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) {
              if (!data.isSubmitting) _submit();
            },
            decoration: const InputDecoration(labelText: 'Jam tiba yang dibutuhkan (HH:mm)'),
            validator: (value) => Validators.arriveBy(value, now),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('searchButton'),
            onPressed: data.isSubmitting ? null : _submit,
            child: data.isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, semanticsLabel: 'Memproses'),
                  )
                : const Text('Cari Rute'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildResults(PlannerData data) {
    if (data.isSubmitting) {
      return [
        Semantics(
          liveRegion: true,
          child: const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Mencari rute…')),
        ),
      ];
    }
    if (data.searchError != null) {
      return [
        Semantics(
          liveRegion: true,
          child: Text(data.searchError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
      ];
    }
    final results = data.results;
    if (results == null) return const [];
    if (results.isEmpty) {
      return const [EmptyView(message: 'Tidak ada opsi yang sempat dikejar. Coba jam tiba yang lebih longgar.')];
    }
    final request = data.request;
    return [
      Semantics(
        liveRegion: true,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('Ditemukan ${results.length} opsi rute', style: Theme.of(context).textTheme.titleSmall),
        ),
      ),
      for (final advice in results)
        RouteOptionCard(
          advice: advice,
          onSave: request == null ? null : () => _openSaveForm(advice, request),
        ),
    ];
  }
}
