# Flutter 実装詳細

Flutter 側の実装について詳しく解説します。本プロジェクトでは、Riverpod + riverpod_generator を使用した状態管理と、Method Channel を使ったプラットフォーム通信を組み合わせています。

## 📁 ファイル構成

```
lib/
├── main.dart                                    # アプリエントリーポイント
├── pages/
│   └── counter_page.dart                       # メインUI画面
├── providers/
│   ├── counter_provider.dart                   # カウンター状態管理
│   ├── counter_provider.g.dart                 # 生成されたプロバイダー
│   ├── connection_status_provider.dart         # 接続状態管理
│   ├── connection_status_provider.g.dart       # 生成されたプロバイダー
│   ├── watch_communication_service_provider.dart # Watch通信サービス
│   └── watch_communication_service_provider.g.dart # 生成されたプロバイダー
└── models/
    ├── watch_connection_status.dart            # 接続状態enum
    ├── method_channel_method.dart              # メソッド名enum
    └── watch_status_key.dart                   # ステータスキーenum
```

## 🎯 主要コンポーネント

### 1. アプリエントリーポイント (`main.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'pages/counter_page.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iPhone-Watch Counter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const CounterPage(),
    );
  }
}
```

**ポイント:**

- `ProviderScope`で Riverpod を初期化
- シンプルな Material Design テーマ
- 単一ページ構成

### 2. メイン UI (`pages/counter_page.dart`)

```dart
class CounterPage extends HookConsumerWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counter = ref.watch(counterProvider);
    final connectionStatus = ref.watch(connectionStatusProvider);
    final watchService = ref.read(watchCommunicationServiceProvider);

    // 初期化処理をuseEffectで実行
    useEffect(() {
      watchService.initializeConnection();
      return null;
    }, []);

    // UI実装...
  }
}
```

**使用技術:**

- `HookConsumerWidget`: flutter_hooks と Riverpod の組み合わせ
- `useEffect`: ライフサイクル管理
- `ref.watch`: 状態の監視
- `ref.read`: 一回限りの読み取り

## 🏗️ 状態管理アーキテクチャ

### 1. カウンター状態 (`providers/counter_provider.dart`)

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'counter_provider.g.dart';

@riverpod
class Counter extends _$Counter {
  @override
  int build() => 0;

  void increment() => state = state + 1;
  void decrement() => state = state - 1;
  void set(int value) => state = value;
}
```

**特徴:**

- `@riverpod`アノテーションによるコード生成
- 型安全な状態管理
- シンプルな API 設計

### 2. 接続状態管理 (`providers/connection_status_provider.dart`)

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/watch_connection_status.dart';

part 'connection_status_provider.g.dart';

@riverpod
class ConnectionStatus extends _$ConnectionStatus {
  @override
  WatchConnectionStatus build() => WatchConnectionStatus.connecting;

  void update(WatchConnectionStatus status) => state = status;
}
```

**ポイント:**

- enum 型による型安全な状態管理
- 明確な状態遷移

### 3. Watch 通信サービス

```dart
@riverpod
WatchCommunicationService watchCommunicationService(
  WatchCommunicationServiceRef ref,
) {
  return WatchCommunicationService(ref);
}

class WatchCommunicationService {
  final Ref _ref;

  WatchCommunicationService(this._ref) {
    _setupMessageListener();
  }

  // 初期化処理
  Future<void> initializeConnection() async {
    try {
      final result = await platformChannel.invokeMethod('initializeSession');
      final statusKey = result['status_key'] ?? 'error';
      final status = _parseConnectionStatus(statusKey);
      _ref.read(connectionStatusProvider.notifier).update(status);
    } on PlatformException {
      _ref
          .read(connectionStatusProvider.notifier)
          .update(WatchConnectionStatus.error);
    }
  }

  // メッセージリスナーの設定
  void _setupMessageListener() {
    platformChannel.setMethodCallHandler((call) async {
      if (call.method == 'counterUpdated') {
        final int newValue = call.arguments['counter'];
        debugPrint('📱 Watch → iPhone: $newValue');
        _ref.read(counterProvider.notifier).set(newValue);
      } else if (call.method == 'sessionStateChanged') {
        final String statusKey = call.arguments['status_key'] ?? 'error';
        final status = _parseConnectionStatus(statusKey);
        _ref.read(connectionStatusProvider.notifier).update(status);
      }
    });
  }

  // カウンター値の送信
  Future<bool> updateCounter(int newValue) async {
    try {
      debugPrint('📱 iPhone → Watch: $newValue');
      final success = await platformChannel.invokeMethod('sendCounter', {
        'counter': newValue,
      });
      return success == true;
    } on PlatformException catch (e) {
      debugPrint('📱 Send error: ${e.message}');
      rethrow;
    }
  }
}
```

## 🔄 Method Channel 通信

### Platform Channel 設定

```dart
const MethodChannel platformChannel = MethodChannel('flutter_watch/counter');
```

### 通信メソッド

#### 1. セッション初期化

```dart
// Flutter → iOS
await platformChannel.invokeMethod('initializeSession');

// レスポンス形式
{
  'status_key': 'connected' | 'error' | 'connecting' | ...
}
```

#### 2. カウンター値送信

```dart
// Flutter → iOS
await platformChannel.invokeMethod('sendCounter', {
  'counter': newValue,
});

// レスポンス: bool (成功/失敗)
```

#### 3. イベント受信

```dart
// iOS → Flutter
platformChannel.setMethodCallHandler((call) async {
  switch (call.method) {
    case 'counterUpdated':
      final int newValue = call.arguments['counter'];
      // 状態更新処理
      break;
    case 'sessionStateChanged':
      final String statusKey = call.arguments['status_key'];
      // 接続状態更新処理
      break;
  }
});
```

## 📱 UI 実装詳細

### レスポンシブな状態管理

```dart
// カウンターを増加
Future<void> incrementCounter() async {
  try {
    // まずローカル状態を更新（即座のUI反映）
    ref.read(counterProvider.notifier).increment();
    final newValue = ref.read(counterProvider);

    // Apple Watchに送信
    await watchService.updateCounter(newValue);
  } on PlatformException catch (e) {
    // エラー時は元の値に戻す（ロールバック）
    ref.read(counterProvider.notifier).decrement();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('送信エラー: ${e.message}')),
      );
    }
  }
}
```

**ポイント:**

1. **楽観的 UI 更新**: ローカル状態を先に更新して即座に UI に反映
2. **エラーハンドリング**: 通信失敗時のロールバック処理
3. **ユーザーフィードバック**: エラー時の SnackBar 表示

### 接続状態の表示

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Icon(
      connectionStatus.isError ? Icons.error : Icons.watch,
      color: connectionStatus.isError ? Colors.red : Colors.green,
    ),
    const SizedBox(width: 8),
    Text(
      connectionStatus.isError ? 'エラー' : '接続完了',
      style: TextStyle(
        color: connectionStatus.isError ? Colors.red : Colors.green,
        fontSize: 16,
      ),
    ),
  ],
),
```

## 🎨 型安全な設計

### 1. 接続状態の enum

```dart
enum WatchConnectionStatus {
  connecting('接続確認中...'),
  connected('接続完了'),
  error('エラー'),
  notPaired('Apple Watchとペアリングされていません'),
  notInstalled('Watchアプリがインストールされていません'),
  notReachable('Apple Watchと通信できません');

  const WatchConnectionStatus(this.message);

  final String message;

  bool get isError => this == WatchConnectionStatus.error ||
                     this == WatchConnectionStatus.notPaired ||
                     this == WatchConnectionStatus.notInstalled ||
                     this == WatchConnectionStatus.notReachable;
}
```

### 2. メソッド名の enum

```dart
enum MethodChannelMethod {
  counterUpdated('counterUpdated'),
  sessionStateChanged('sessionStateChanged');

  const MethodChannelMethod(this.value);

  final String value;

  static MethodChannelMethod? fromString(String value) {
    for (final method in MethodChannelMethod.values) {
      if (method.value == value) {
        return method;
      }
    }
    return null;
  }
}
```

### 3. ステータスキーの enum

```dart
enum WatchStatusKey {
  connected('connected'),
  connecting('connecting'),
  error('error'),
  notPaired('not_paired'),
  notInstalled('not_installed'),
  notReachable('not_reachable');

  const WatchStatusKey(this.value);

  final String value;

  static WatchStatusKey? fromString(String value) {
    for (final key in WatchStatusKey.values) {
      if (key.value == value) {
        return key;
      }
    }
    return null;
  }
}
```

## 🔧 開発時のポイント

### 1. コード生成

```bash
# プロバイダーのコード生成
dart run build_runner build --delete-conflicting-outputs
```

### 2. デバッグ出力

```dart
debugPrint('📱 Watch → iPhone: $newValue');
debugPrint('📱 iPhone → Watch: $newValue');
debugPrint('📱 Send error: ${e.message}');
```

### 3. エラーハンドリング

- `PlatformException`の適切なキャッチ
- ユーザーフレンドリーなエラーメッセージ
- 楽観的 UI 更新でのロールバック処理

## 🧪 テスト観点

### 1. Provider テスト

- カウンターの増減処理
- 接続状態の遷移
- エラー状態の処理

### 2. Method Channel テスト

- メッセージの送受信
- エラーケースの処理
- タイムアウト処理

### 3. UI テスト

- ボタンタップの動作
- 状態変化時の UI 更新
- エラー時のフィードバック表示
