import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

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
      home: const MyHomePage(title: 'Platform Channel Sample'),
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
            final messenger = CustomMessenger();
            // print('Flutter: ボタンが押されました');
            const message = "Hello from Flutter!";
            final WriteBuffer buffer = WriteBuffer();
            final data = message.codeUnits;
            buffer.putUint8List(Uint8List.fromList(data));
            final ByteData byteData = buffer.done();
            // print('Flutter: メッセージを送信します - $message');
            await messenger.send('foo', byteData);
            // print('Flutter: メッセージ送信完了');
          },
          child: const Text('Send Message'),
        ),
      ),
    );
  }
}

class CustomMessenger implements BinaryMessenger {
  @override
  Future<void> handlePlatformMessage(
    String channel,
    ByteData? data,
    PlatformMessageResponseCallback? callback,
  ) {
    throw UnsupportedError("This platform message handling is not supported.");
  }

  @override
  Future<ByteData?>? send(String channel, ByteData? message) {
    ui.PlatformDispatcher.instance.sendPlatformMessage(
      channel,
      message,
      (data) {},
    );
    return null;
  }

  @override
  void setMessageHandler(String channel, MessageHandler? handler) {
    throw UnsupportedError("Setting message handler is not supported.");
  }
}
