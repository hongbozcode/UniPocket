import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'notifications.dart';

class AndroidNotifications implements LocalNotifications {
  const AndroidNotifications({this.namespace = 'planner'});
  final String namespace;
  static const _channel = MethodChannel('unipocket/notifications');
  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<NotificationAccess> status() async {
    if (!_supported) return NotificationAccess.unsupported;
    return await _channel.invokeMethod<bool>('enabled') == true
        ? NotificationAccess.enabled
        : NotificationAccess.blocked;
  }

  @override
  Future<void> replace(String scope, List<LocalReminder> reminders) async {
    if (!_supported) return;
    await _channel.invokeMethod<void>('replace', {
      'scope': '$namespace/$scope',
      'reminders': [
        for (final reminder in reminders)
          {
            'key': reminder.key,
            'at': reminder.at.millisecondsSinceEpoch,
            'title': reminder.title,
            'body': reminder.body,
          },
      ],
    });
  }

  @override
  Future<void> requestPermission() async {
    if (_supported) await _channel.invokeMethod<void>('requestPermission');
  }

  @override
  Future<void> openSettings() async {
    if (_supported) await _channel.invokeMethod<void>('openSettings');
  }
}
