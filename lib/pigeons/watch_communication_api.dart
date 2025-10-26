import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/pigeons/watch_communication_api.g.dart',
    swiftOut: 'ios/Runner/WatchCommunicationApi.g.swift',
  ),
)

// カウンター送信のリクエスト
class CounterRequest {
  final int counter;

  CounterRequest({required this.counter});
}

// カウンター送信の結果
class CounterResult {
  final bool success;

  CounterResult({required this.success});
}

// カウンター更新のイベント
class CounterUpdateEvent {
  final int counter;

  CounterUpdateEvent({required this.counter});
}

// セッション初期化の結果
class SessionInitializeResult {
  final bool success;
  final String statusKey;

  SessionInitializeResult({required this.success, required this.statusKey});
}

// セッション状態変更のイベント
class SessionStateEvent {
  final String statusKey;

  SessionStateEvent({required this.statusKey});
}

// Flutter → iOS の呼び出し (HostApi)
@HostApi()
abstract class WatchCommunicationHostApi {
  @async
  SessionInitializeResult initializeSession();

  @async
  CounterResult sendCounter(CounterRequest request);
}

// iOS → Flutter の呼び出し (FlutterApi)
@FlutterApi()
abstract class WatchCommunicationFlutterApi {
  void onSessionStateChanged(SessionStateEvent event);
  void onCounterUpdated(CounterUpdateEvent event);
}
