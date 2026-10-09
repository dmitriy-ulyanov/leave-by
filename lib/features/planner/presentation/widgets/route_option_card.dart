import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../domain/departure_advice.dart';

class RouteOptionCard extends StatelessWidget {
  const RouteOptionCard({super.key, required this.advice});

  final DepartureAdvice advice;

  static String _tagLabel(AdviceTag tag) {
    switch (tag) {
      case AdviceTag.fastest:
        return 'Tercepat';
      case AdviceTag.cheapest:
        return 'Termurah';
      case AdviceTag.safest:
        return 'Paling aman';
    }
  }

  @override
  Widget build(BuildContext context) {
    final option = advice.option;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(option.label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Berangkat paling lambat ${formatTime(advice.departAt)}'),
            Text(
              'Durasi ${option.travelMinutes} menit • ${option.transitCount} transit • ${formatRupiah(option.costRupiah)}',
            ),
            Text('Cadangan waktu ${advice.cushion.inMinutes} menit'),
            if (advice.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  children: [for (final tag in advice.tags) Chip(label: Text(_tagLabel(tag)))],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
