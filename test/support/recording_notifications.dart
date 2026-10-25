import 'package:unipocket/reminders/notifications.dart';

/// Controls only the operating-system boundary, keeping the real planner/store.
class RecordingNotifications implements LocalNotifications {
  NotificationAccess access = NotificationAccess.enabled;
  bool fail = false;
  bool settingsOpened = false;
  List<LocalReminder> pending = [];

  @override
  Future<NotificationAccess> status() async => access;

  @override
  Future<void> replace(String scope, List<LocalReminder> reminders) async {
    if (fail) throw StateError('OS scheduling unavailable');
    pending = List.of(reminders);
  }

  @override
  Future<void> openSettings() async => settingsOpened = true;

  @override
  Future<void> requestPermission() async {}
}
