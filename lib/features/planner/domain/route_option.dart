import 'transport_mode.dart';

class RouteOption {
  const RouteOption({
    required this.id,
    required this.mode,
    required this.label,
    required this.travelMinutes,
    required this.transitCount,
    required this.costRupiah,
    this.scheduleMinutes = const [],
  });

  factory RouteOption.fromJson(Map<String, dynamic> json) {
    return RouteOption(
      id: json['id'] as String,
      mode: TransportMode.values.byName(json['mode'] as String),
      label: json['label'] as String,
      travelMinutes: json['travelMinutes'] as int,
      transitCount: json['transitCount'] as int,
      costRupiah: json['costRupiah'] as int,
      scheduleMinutes: ((json['scheduleMinutes'] as List?) ?? const []).cast<int>(),
    );
  }

  final String id;
  final TransportMode mode;
  final String label;
  final int travelMinutes;
  final int transitCount;
  final int costRupiah;
  final List<int> scheduleMinutes;

  Duration get travelTime => Duration(minutes: travelMinutes);
}
