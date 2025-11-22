import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/pigeon/counter_api.g.dart',
    swiftOut: 'ios/Runner/Pigeon/CounterApi.g.swift',
    swiftOptions: SwiftOptions(),
  ),
)

@FlutterApi()
abstract class CounterFlutterApi {
  void onCounterIncremented(int count);
  void onReachabilityChanged(bool isReachable);
}

@HostApi()
abstract class CounterHostApi {
  void resetCounter();
  void updateCounter(int count);
  bool isWatchReachable();
}
