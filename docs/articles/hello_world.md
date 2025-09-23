## 初めに
この章のゴールは、Flutterのプロジェクトを作成して、Apple Watchのアプリを実行できる状態にすることです。
すでにプロジェクトを作成したことがある方は飛ばしていただいても問題ありません。

## 環境
筆者の手元は以下のような環境になっています。
- Flutter 3.35.1
- Dart 3.9.0
- Cursor 1.4.5
- Xcode 26.0 beta
- MacBook Pro Apple M3

## Flutterプロジェクト作成
まずはFlutterプロジェクトを作成していきます。
CursorやVScodeでは `command + p` を押して上部バーを開きます。
開いたバーに `> Flutter: New Project` を入力します。
![](https://storage.googleapis.com/zenn-user-upload/8a46e16460f9-20250824.png)

次に`Application`を押します。
![](https://storage.googleapis.com/zenn-user-upload/43bffcc36358-20250824.png)

次にFlutterプロジェクトの名前を入力します。今回は `flutter_watch` という名前にしておきます。
これで新しいFlutterプロジェクトの作成が完了します。
![](https://storage.googleapis.com/zenn-user-upload/33a2c9b2c15d-20250824.png)

## watchターゲットの追加
次に、作成したFlutterプロジェクトの `ios/Runner.xcworkspace` ディレクトリで `Reveal in Finder`をタップします。
![](https://storage.googleapis.com/zenn-user-upload/222fb4d2d0d4-20250824.png)

Finderで `Runner.xcworkspace` をタップしてXcodeのワークスペースを開きます。
![](https://storage.googleapis.com/zenn-user-upload/ec21cb3537fb-20250824.png)

Xcodeを開いたら `New > Target...` をタップします。
![](https://storage.googleapis.com/zenn-user-upload/8af691ebf392-20250824.png)

ここで `watchOS` の `App` をタップして `Next` を選択します。
![](https://storage.googleapis.com/zenn-user-upload/a93b37949e12-20250824.png)

次にWatchアプリの名前を設定します。今回は `FlutterWatch` という名前にしておきます。
また、今回はiOSアプリと連携したwatchアプリを作成するため、`Watch App for Existing iOS App`を選択しておきます。
![](https://storage.googleapis.com/zenn-user-upload/d3b20145daf9-20250824.png)

watchターゲットを追加すると、watchアプリのscheme作成されるので、 `Activate` しておきます。
![](https://storage.googleapis.com/zenn-user-upload/30a55df26101-20250824.png)

以下のようにApple Watchのディレクトリが作成されます。
これでwatchターゲットの追加は完了です。
![](https://storage.googleapis.com/zenn-user-upload/62c6c82da354-20250824.png)

## Simulatorの追加
次にSilumatorを追加していきます。
Xcodeの上部バーから `Window > Devices and Simulators` を選択すると以下のようなウィンドウが開きます。
![](https://storage.googleapis.com/zenn-user-upload/7140c3d61750-20250824.png)

ここで新たにwatchOSのSimulatorを追加していきます。
Simulator一覧の下の＋ボタンを押すと、以下のようにデバイスの種類とOSを指定することができます。
今回は `watchOS 26.0` の `Apple Watch Series 10(46mm)` にしておきます。
watchOSを選択して `Next` を選択します。
![](https://storage.googleapis.com/zenn-user-upload/0047bb38439f-20250824.png)

次にwatchOSのSimulatorとペアするiOS Simulatorの設定も行います。
今回は `iOS 26.0` の `iPhone 16 Pro` にしておきます。
![](https://storage.googleapis.com/zenn-user-upload/6f2eae6b581e-20250824.png)

iPhoneと連携したwatchOSのSimulatorを追加すると、以下の画像のように`Apple Watch via iPhone` のSimulatorを使用することができるようになります。
![](https://storage.googleapis.com/zenn-user-upload/9f83a3889d8b-20250824.png)

## 実行
最後にApple Watchのプロジェクトを実行対象に、先ほど追加したSimulatorを実行デバイスに設定してXcodeの実行ボタンを押すと、以下のようにiPhoneと一緒にApple WatchのSimulatorが起動して実行結果を確認することができます。
![](https://storage.googleapis.com/zenn-user-upload/4c583f07e72e-20250824.png)