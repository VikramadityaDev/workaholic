import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/notification_model.dart';

class NotificationService {
  static const FlutterSecureStorage storage = FlutterSecureStorage();

  static Future<String> getNotificationsKey() async {
    final userId = await storage.read(key: 'id');
    return 'local_notifications_${userId ?? 'guest'}';
  }

  static Future<void> saveNotifications(List<AppNotification> notifications) async {
    final key = await getNotificationsKey();
    final jsonList = notifications.map((n) => n.toJson()).toList();
    await storage.write(key: key, value: jsonEncode(jsonList));
  }

  static Future<List<AppNotification>> getNotifications() async {
    try {
      final key = await getNotificationsKey();
      final data = await storage.read(key: key);
      if (data == null) return [];
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((json) => AppNotification.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> addNotification(AppNotification notification) async {
    final notifications = await getNotifications();
    notifications.insert(0, notification);
    if (notifications.length > 100) {
      notifications.removeRange(100, notifications.length);
    }
    await saveNotifications(notifications);
  }

  static Future<void> markAsRead(String notificationId) async {
    final notifications = await getNotifications();
    final index = notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      notifications[index] = notifications[index].copyWith(isRead: true);
      await saveNotifications(notifications);
    }
  }

  static Future<void> markAllAsRead() async {
    final notifications = await getNotifications();
    final updatedNotifications = notifications.map((n) => n.copyWith(isRead: true)).toList();
    await saveNotifications(updatedNotifications);
  }

  static Future<void> deleteNotification(String notificationId) async {
    final notifications = await getNotifications();
    notifications.removeWhere((n) => n.id == notificationId);
    await saveNotifications(notifications);
  }

  static Future<int> getUnreadCount() async {
    final notifications = await getNotifications();
    return notifications.where((n) => !n.isRead).length;
  }

  static Future<void> clearAll() async {
    final key = await getNotificationsKey();
    await storage.delete(key: key);
  }

  static Future<void> notifyProposalReceived({
    required String projectTitle,
    required String freelancerName,
    required int projectId,
    required int proposalId,
  }) async {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: "New Proposal Received",
      message: "$freelancerName submitted a proposal for '$projectTitle'",
      type: "proposal",
      timestamp: DateTime.now(),
      data: {
        "projectId": projectId,
        "proposalId": proposalId,
      },
    );
    await addNotification(notification);
  }

  static Future<void> notifyProposalAccepted({
    required String projectTitle,
    required int projectId,
  }) async {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: "Proposal Accepted 🎉",
      message: "Your proposal for '$projectTitle' has been accepted!",
      type: "proposal",
      timestamp: DateTime.now(),
      data: {
        "projectId": projectId,
      },
    );
    await addNotification(notification);
  }

  static Future<void> notifyMilestoneSubmitted({
    required String projectTitle,
    required String milestoneName,
    required String freelancerName,
    required int projectId,
    required int milestoneId,
  }) async {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: "Work Submitted",
      message: "$freelancerName submitted '$milestoneName' for '$projectTitle'",
      type: "milestone",
      timestamp: DateTime.now(),
      data: {
        "projectId": projectId,
        "milestoneId": milestoneId,
      },
    );
    await addNotification(notification);
  }

  static Future<void> notifyMilestoneApproved({
    required String projectTitle,
    required String milestoneName,
    required double amount,
    required int projectId,
  }) async {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: "Milestone Approved",
      message: "'$milestoneName' approved for '$projectTitle'. ₹${amount.toStringAsFixed(0)} credited!",
      type: "milestone",
      timestamp: DateTime.now(),
      data: {
        "projectId": projectId,
      },
    );
    await addNotification(notification);
  }

  static Future<void> notifyMilestoneRejected({
    required String projectTitle,
    required String milestoneName,
    required int projectId,
  }) async {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: "Revision Required",
      message: "'$milestoneName' for '$projectTitle' needs revision",
      type: "milestone",
      timestamp: DateTime.now(),
      data: {
        "projectId": projectId,
      },
    );
    await addNotification(notification);
  }

  static Future<void> notifyMilestoneResubmitted({
    required String projectTitle,
    required String milestoneName,
    required String freelancerName,
    required int projectId,
    required int milestoneId,
  }) async {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: "Work Resubmitted",
      message: "$freelancerName resubmitted '$milestoneName' for '$projectTitle'",
      type: "milestone",
      timestamp: DateTime.now(),
      data: {
        "projectId": projectId,
        "milestoneId": milestoneId,
      },
    );
    await addNotification(notification);
  }

  static Future<void> notifyProjectCompleted({
    required String projectTitle,
    required int projectId,
  }) async {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: "Project Completed 🎊",
      message: "'$projectTitle' has been marked as completed by the client",
      type: "project",
      timestamp: DateTime.now(),
      data: {
        "projectId": projectId,
      },
    );
    await addNotification(notification);
  }

  static Future<void> notifyProjectCreated({
    required String projectTitle,
    required int projectId,
  }) async {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: "Project Created",
      message: "'$projectTitle' has been posted successfully",
      type: "project",
      timestamp: DateTime.now(),
      data: {
        "projectId": projectId,
      },
    );
    await addNotification(notification);
  }

  static Future<void> notifyFundsAdded({
    required double amount,
  }) async {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: "Funds Added",
      message: "₹${amount.toStringAsFixed(0)} has been added to your wallet",
      type: "payment",
      timestamp: DateTime.now(),
    );
    await addNotification(notification);
  }
}