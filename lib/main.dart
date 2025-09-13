import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Method Channel Sample'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            // Method Channelを作成
            const methodChannel = MethodChannel('foo');

            try {
              // print('Flutter: ボタンが押されました');
              const message = "Hello from Flutter!";
              // print('Flutter: メッセージを送信します - $message');

              // Method Channelを使ってメッセージを送信
              await methodChannel.invokeMethod('showMessage', message);

              // print('Flutter: メッセージ送信完了');
            } on PlatformException catch (e) {
              print("Failed to send message: '${e.message}'.");
            }
          },
          child: const Text('Send Message'),
        ),
      ),
    );
  }
}
