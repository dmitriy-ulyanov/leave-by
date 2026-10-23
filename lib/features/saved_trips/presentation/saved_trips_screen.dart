import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../application/saved_trips_notifier.dart';
import '../domain/saved_trip.dart';
import 'widgets/saved_trip_tile.dart';

class SavedTripsScreen extends ConsumerWidget {
  const SavedTripsScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, SavedTrip trip) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hapus perjalanan?',
      message: 'Perjalanan "${trip.title}" akan dihapus dari perangkat.',
      confirmLabel: 'Hapus',
    );
    if (confirmed != true) return;
    final success = await ref.read(savedTripsProvider.notifier).remove(trip.id);
    if (!context.mounted) return;
    final message = success ? 'Perjalanan dihapus.' : 'Gagal menghapus perjalanan.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          message: error is ApiException ? error.message : 'Gagal memuat perjalanan tersimpan.',
          onRetry: () => ref.invalidate(savedTripsProvider),
        ),
        data: (trips) {
          if (trips.isEmpty) {
            return const Center(child: EmptyView(message: 'Belum ada perjalanan tersimpan.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];
              return SavedTripTile(
                trip: trip,
                onEdit: () => Navigator.pushNamed(context, AppRoutes.savedForm, arguments: trip),
                onDelete: () => _confirmDelete(context, ref, trip),
              );
            },
          );
        },
      ),
    );
  }
}
