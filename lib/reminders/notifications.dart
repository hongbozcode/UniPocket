enum NotificationAccess { enabled, blocked, unsupported, unavailable }

class LocalReminder {
  const LocalReminder({
    required this.key,
    required this.at,
    required this.title,
    required this.body,
  });
  final String key;
  final DateTime at;
  final String title;
  final String body;
}

/// Operating-system boundary shared by course, task, and event reminders.
/// Replacing one scope must leave other scopes untouched.
abstract interface class LocalNotifications {
  Future<NotificationAccess> status();
  Future<void> replace(String scope, List<LocalReminder> reminders);
  Future<void> requestPermission();
  Future<void> openSettings();
}

class UnsupportedNotifications implements LocalNotifications {
  const UnsupportedNotifications();
  @override
  Future<NotificationAccess> status() async => NotificationAccess.unsupported;
  @override
  Future<void> replace(String scope, List<LocalReminder> reminders) async {}
  @override
  Future<void> requestPermission() async {}
  @override
  Future<void> openSettings() async {}
}
