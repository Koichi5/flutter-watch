/// Method Channelで使用されるメソッド名を定義するenum
enum MethodChannelMethod {
  /// カウンター値が更新された際のメソッド
  counterUpdated('counterUpdated'),

  /// セッション状態が変更された際のメソッド
  sessionStateChanged('sessionStateChanged');

  const MethodChannelMethod(this.value);

  final String value;

  /// 文字列からenumを取得
  static MethodChannelMethod? fromString(String value) {
    for (final method in MethodChannelMethod.values) {
      if (method.value == value) {
        return method;
      }
    }
    return null;
  }
}
