import '../../../core/constants/buffer_rules.dart';
import 'departure_advice.dart';
import 'route_option.dart';
import 'trip_request.dart';

class DepartureCalculator {
  const DepartureCalculator({this.rules = const BufferRules()});

  final BufferRules rules;

  List<DepartureAdvice> calculate(TripRequest request, List<RouteOption> options, {DateTime? now}) {
    final feasible = <DepartureAdvice>[];
    for (final option in options) {
      final buffer = rules.bufferFor(option);
      final latest = request.arriveBy.subtract(option.travelTime + buffer);
      final departAt = _pickDeparture(option, request.arriveBy, latest);
      if (departAt == null) continue;
      if (now != null && departAt.isBefore(now)) continue;
      final arrival = departAt.add(option.travelTime);
      feasible.add(DepartureAdvice(
        option: option,
        departAt: departAt,
        buffer: buffer,
        cushion: request.arriveBy.difference(arrival),
      ));
    }
    return _tagAndSort(feasible);
  }

  DateTime? _pickDeparture(RouteOption option, DateTime arriveBy, DateTime latest) {
    if (option.scheduleMinutes.isEmpty) return latest;
    final midnight = DateTime(arriveBy.year, arriveBy.month, arriveBy.day);
    DateTime? best;
    for (final minutes in option.scheduleMinutes) {
      final candidate = midnight.add(Duration(minutes: minutes));
      if (candidate.isAfter(latest)) continue;
      if (best == null || candidate.isAfter(best)) best = candidate;
    }
    return best;
  }

  List<DepartureAdvice> _tagAndSort(List<DepartureAdvice> advice) {
    if (advice.isEmpty) return advice;
    final fastest = _minBy(advice, (a) => a.option.travelMinutes);
    final cheapest = _minBy(advice, (a) => a.option.costRupiah);
    final safest = _minBy(advice, (a) => -a.cushion.inMinutes);
    final tagged = advice.map((a) {
      return a.withTags({
        if (identical(a, fastest)) AdviceTag.fastest,
        if (identical(a, cheapest)) AdviceTag.cheapest,
        if (identical(a, safest)) AdviceTag.safest,
      });
    }).toList();
    tagged.sort((a, b) => b.departAt.compareTo(a.departAt));
    return tagged;
  }

  T _minBy<T>(List<T> items, int Function(T) key) {
    return items.reduce((a, b) => key(b) < key(a) ? b : a);
  }
}
