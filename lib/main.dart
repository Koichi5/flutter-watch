import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pages/message_page.dart';

void main() {
  runApp(const ProviderScope(child: MessageApp()));
}

class MessageApp extends StatelessWidget {
  const MessageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WCSession - transferUserInfo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MessagePage(),
    );
  }
}
