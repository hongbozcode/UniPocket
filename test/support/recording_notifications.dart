import 'package:unipocket/reminders/notifications.dart';

/// Controls only the operating-system boundary, keeping the real planner/store.
class RecordingNotifications implements LocalNotifications {
  NotificationAccess access = NotificationAccess.enabled;
  bool fail = false;
  String? failScope;
  bool settingsOpened = false;
  final Map<String, List<LocalReminder>> scopes = {};
  List<LocalReminder> get pending =>
      scopes.values.expand((items) => items).toList();

  @override
  Future<NotificationAccess> status() async => access;

  @override
  Future<void> replace(String scope, List<LocalReminder> reminders) async {
    if (fail || scope == failScope) {
      throw StateError('OS scheduling unavailable');
    }
    scopes[scope] = List.of(reminders);
  }

  @override
  Future<void> openSettings() async => settingsOpened = true;

  @override
  Future<void> requestPermission() async {}
}
