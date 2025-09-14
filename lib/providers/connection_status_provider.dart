import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_watch/models/watch_connection_status.dart';

part 'connection_status_provider.g.dart';

@riverpod
class ConnectionStatus extends _$ConnectionStatus {
  @override
  WatchConnectionStatus build() => WatchConnectionStatus.connected;

  void update(WatchConnectionStatus status) => state = status;
}
