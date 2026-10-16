import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../domain/saved_trip.dart';

class SavedTripTile extends StatelessWidget {
  const SavedTripTile({super.key, required this.trip, required this.onEdit, required this.onDelete});

  final SavedTrip trip;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final details = <String>['Tiba ${formatTime(trip.arriveBy)}'];
    if (trip.optionLabel.isNotEmpty) details.add(trip.optionLabel);
    final departAt = trip.departAt;
    if (departAt != null) details.add('Berangkat ${formatTime(departAt)}');
    return Card(
      child: ListTile(
        title: Text(trip.title),
        subtitle: Text('${trip.origin} → ${trip.destination}\n${details.join(' • ')}'),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: Key('editTrip_${trip.id}'),
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Ubah',
              onPressed: onEdit,
            ),
            IconButton(
              key: Key('deleteTrip_${trip.id}'),
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Hapus',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
