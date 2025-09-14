/// Watch接続ステータスのキーを定義するenum
enum WatchStatusKey {
  /// 接続完了状態
  connected('connected'),

  /// 接続中状態
  connecting('connecting'),

  /// エラー状態
  error('error'),

  /// ペアリングされていない
  notPaired('not_paired'),

  /// Watchアプリがインストールされていない
  notInstalled('not_installed'),

  /// 通信できない状態
  notReachable('not_reachable');

  const WatchStatusKey(this.value);

  final String value;

  /// 文字列からenumを取得
  static WatchStatusKey? fromString(String value) {
    for (final key in WatchStatusKey.values) {
      if (key.value == value) {
        return key;
      }
    }
    return null;
  }
}
