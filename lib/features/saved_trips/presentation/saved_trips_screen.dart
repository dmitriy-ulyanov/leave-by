import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/breakpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../application/saved_trips_notifier.dart';
import '../data/saved_trip_providers.dart';
import '../domain/saved_trip.dart';
import 'widgets/saved_trip_tile.dart';

class SavedTripsScreen extends ConsumerWidget {
  const SavedTripsScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, SavedTrip trip) async {
    final messenger = ScaffoldMessenger.of(context);
    final container = ProviderScope.containerOf(context);
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hapus perjalanan?',
      message: 'Perjalanan "${trip.title}" akan dihapus dari perangkat.',
      confirmLabel: 'Hapus',
    );
    if (confirmed != true) return;
    final success = await ref.read(savedTripsProvider.notifier).remove(trip.id);
    if (!success) {
      messenger.showSnackBar(const SnackBar(content: Text('Gagal menghapus perjalanan.')));
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Perjalanan dihapus.'),
        action: SnackBarAction(label: 'Urungkan', onPressed: () => _restore(container, messenger, trip)),
      ),
    );
  }

  Future<void> _restore(ProviderContainer container, ScaffoldMessengerState messenger, SavedTrip trip) async {
    try {
      await container.read(savedTripRepositoryProvider).save(trip);
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Gagal mengurungkan penghapusan.')));
      return;
    }
    container.invalidate(savedTripsProvider);
    messenger.showSnackBar(const SnackBar(content: Text('Perjalanan dikembalikan.')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedTripsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Perjalanan Tersimpan')),
      floatingActionButton: FloatingActionButton(
        key: const Key('addTripButton'),
        tooltip: 'Tambah perjalanan',
        onPressed: () => Navigator.pushNamed(context, AppRoutes.savedForm),
        child: const Icon(Icons.add),
      ),
      body: saved.when(
        loading: () => const Center(child: CircularProgressIndicator(semanticsLabel: 'Memuat')),
        error: (error, _) => ErrorView(
          message: error is ApiException ? error.message : 'Gagal memuat perjalanan tersimpan.',
          onRetry: () => ref.invalidate(savedTripsProvider),
        ),
        data: (trips) {
          if (trips.isEmpty) {
            return const Center(child: EmptyView(message: 'Belum ada perjalanan tersimpan.'));
          }
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: listMaxWidth),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                itemCount: trips.length,
                itemBuilder: (context, index) {
                  final trip = trips[index];
                  return SavedTripTile(
                    trip: trip,
                    onEdit: () => Navigator.pushNamed(context, AppRoutes.savedForm, arguments: trip),
                    onDelete: () => _confirmDelete(context, ref, trip),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
