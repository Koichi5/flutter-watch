import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_watch/models/app_settings.dart';
import 'package:flutter_watch/providers/settings_provider.dart';
import 'package:intl/intl.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isReachable = ref.watch(watchReachableProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: DefaultTextStyle(
        style: TextStyle(
          fontSize: settings.fontSize.points,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
        child: ListView(
          children: [
            ConnectionStatusWidget(
              isReachable: isReachable,
              fontSize: settings.fontSize,
            ),
            const Divider(),
            ColorSectionWidget(settings: settings, fontSize: settings.fontSize),
            const Divider(),
            FontSizeSectionWidget(settings: settings),
            const Divider(),
            NotificationSectionWidget(
              settings: settings,
              fontSize: settings.fontSize,
            ),
            const Divider(),
            LastUpdatedSectionWidget(
              settings: settings,
              fontSize: settings.fontSize,
            ),
          ],
        ),
      ),
    );
  }
}

class ConnectionStatusWidget extends StatelessWidget {
  final bool isReachable;
  final FontSize fontSize;

  const ConnectionStatusWidget({
    super.key,
    required this.isReachable,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        isReachable ? Icons.watch : Icons.watch_off,
        color: isReachable ? Colors.green : Colors.grey,
      ),
      title: Text('Apple Watch', style: TextStyle(fontSize: fontSize.points)),
      subtitle: Text(
        isReachable ? '接続中' : '未接続',
        style: TextStyle(
          color: isReachable ? Colors.green : Colors.grey,
          fontSize: fontSize.points * 0.9,
        ),
      ),
    );
  }
}

class ColorSectionWidget extends ConsumerWidget {
  final AppSettings settings;
  final FontSize fontSize;

  const ColorSectionWidget({
    super.key,
    required this.settings,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'テーマカラー',
            style: TextStyle(
              fontSize: fontSize.points * 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ThemeColor.values.map((color) {
              final isSelected = settings.themeColor == color;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: isSelected
                      ? FilledButton(
                          onPressed: () {
                            ref
                                .read(settingsProvider.notifier)
                                .updateColor(color);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: color.color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            color.displayName,
                            style: TextStyle(fontSize: fontSize.points),
                          ),
                        )
                      : OutlinedButton(
                          onPressed: () {
                            ref
                                .read(settingsProvider.notifier)
                                .updateColor(color);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            foregroundColor: color.color,
                          ),
                          child: Text(
                            color.displayName,
                            style: TextStyle(fontSize: fontSize.points),
                          ),
                        ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class FontSizeSectionWidget extends ConsumerWidget {
  final AppSettings settings;

  const FontSizeSectionWidget({super.key, required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'フォントサイズ',
            style: TextStyle(
              fontSize: settings.fontSize.points * 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: FontSize.values.map((size) {
              final isSelected = settings.fontSize == size;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: isSelected
                      ? FilledButton(
                          onPressed: () {
                            ref
                                .read(settingsProvider.notifier)
                                .updateFontSize(size);
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            size.displayName,
                            style: TextStyle(
                              fontSize: size.points,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : OutlinedButton(
                          onPressed: () {
                            ref
                                .read(settingsProvider.notifier)
                                .updateFontSize(size);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(
                              color: Colors.grey,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            size.displayName,
                            style: TextStyle(
                              fontSize: size.points,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class NotificationSectionWidget extends ConsumerWidget {
  final AppSettings settings;
  final FontSize fontSize;

  const NotificationSectionWidget({
    super.key,
    required this.settings,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwitchListTile(
      title: Text('通知', style: TextStyle(fontSize: fontSize.points)),
      subtitle: Text(
        settings.notificationEnabled ? '有効' : '無効',
        style: TextStyle(fontSize: fontSize.points * 0.9),
      ),
      value: settings.notificationEnabled,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateNotification(value);
      },
    );
  }
}

class LastUpdatedSectionWidget extends ConsumerWidget {
  final AppSettings settings;
  final FontSize fontSize;

  const LastUpdatedSectionWidget({
    super.key,
    required this.settings,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastUpdated = settings.lastUpdated;
    final formattedTime = lastUpdated != null
        ? DateFormat('yyyy/MM/dd HH:mm:ss').format(lastUpdated)
        : '未設定';

    return ListTile(
      leading: const Icon(Icons.access_time),
      title: Text('最終更新', style: TextStyle(fontSize: fontSize.points)),
      subtitle: Text(
        formattedTime,
        style: TextStyle(fontSize: fontSize.points * 0.9),
      ),
    );
  }
}
