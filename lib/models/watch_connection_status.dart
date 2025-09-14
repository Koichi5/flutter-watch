enum WatchConnectionStatus {
  connecting('接続確認中...'),
  connected('接続完了'),
  error('エラー'),
  notPaired('Apple Watchとペアリングされていません'),
  notInstalled('Watchアプリがインストールされていません'),
  notReachable('Apple Watchと通信できません');

  const WatchConnectionStatus(this.message);

  final String message;

  bool get isError =>
      this == WatchConnectionStatus.error ||
      this == WatchConnectionStatus.notPaired ||
      this == WatchConnectionStatus.notInstalled ||
      this == WatchConnectionStatus.notReachable;
}
