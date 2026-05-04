import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationState {
  final List<AppNotification> notifications;
  final int unreadCount;
  final bool isLoading;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
    bool? isLoading,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class NotificationNotifier extends Notifier<NotificationState> {
  @override
  NotificationState build() {
    // ✅ DON'T call refresh here - just return initial state
    // Load will happen when dashboard calls refresh
    return const NotificationState();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);

    final notifications = await NotificationService.getNotifications();
    final unreadCount = await NotificationService.getUnreadCount();

    state = NotificationState(
      notifications: notifications,
      unreadCount: unreadCount,
      isLoading: false,
    );
  }

  Future<void> markAsRead(String notificationId) async {
    await NotificationService.markAsRead(notificationId);
    await refresh();
  }

  Future<void> markAllAsRead() async {
    await NotificationService.markAllAsRead();
    await refresh();
  }

  Future<void> deleteNotification(String notificationId) async {
    await NotificationService.deleteNotification(notificationId);
    await refresh();
  }

  Future<void> clearAll() async {
    await NotificationService.clearAll();
    await refresh();
  }
}

final notificationProvider =
NotifierProvider<NotificationNotifier, NotificationState>(
  NotificationNotifier.new,
);