import 'package:flutter_riverpod/flutter_riverpod.dart';

final idGeneratorProvider = Provider<String Function()>((ref) {
  var counter = 0;
  return () => '${DateTime.now().microsecondsSinceEpoch}-${counter++}';
});
