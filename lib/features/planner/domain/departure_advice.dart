import 'route_option.dart';

enum AdviceTag { fastest, cheapest, safest }

class DepartureAdvice {
  const DepartureAdvice({
    required this.option,
    required this.departAt,
    required this.buffer,
    required this.cushion,
    this.tags = const {},
  });

  final RouteOption option;
  final DateTime departAt;
  final Duration buffer;
  final Duration cushion;
  final Set<AdviceTag> tags;

  DepartureAdvice withTags(Set<AdviceTag> newTags) {
    return DepartureAdvice(option: option, departAt: departAt, buffer: buffer, cushion: cushion, tags: newTags);
  }
}
