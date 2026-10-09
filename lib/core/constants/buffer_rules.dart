import '../../features/planner/domain/route_option.dart';
import '../../features/planner/domain/transport_mode.dart';

class BufferRules {
  const BufferRules({
    this.krl = const Duration(minutes: 10),
    this.keretaBandara = const Duration(minutes: 15),
    this.transjakartaBase = const Duration(minutes: 10),
    this.transjakartaPerTransit = const Duration(minutes: 7),
    this.taksiOnline = const Duration(minutes: 20),
  });

  final Duration krl;
  final Duration keretaBandara;
  final Duration transjakartaBase;
  final Duration transjakartaPerTransit;
  final Duration taksiOnline;

  Duration bufferFor(RouteOption option) {
    switch (option.mode) {
      case TransportMode.krl:
        return krl;
      case TransportMode.keretaBandara:
        return keretaBandara;
      case TransportMode.transjakarta:
        return transjakartaBase + transjakartaPerTransit * option.transitCount;
      case TransportMode.taksiOnline:
        return taksiOnline;
    }
  }
}
