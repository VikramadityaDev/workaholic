import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

import '../../commons/utils/app_colors.dart';
import '../../commons/widgets/text_widget.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  final bool isFreelancer;

  const NotificationsScreen({super.key, this.isFreelancer = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationProvider);
    final notifications = notificationState.notifications;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: isFreelancer
            ? AppColors.primaryFreelancerBG
            : AppColors.primaryElement,
        elevation: 0,
        title: Text(
          "Notifications",
          style: AppTextStyles.titleLarge(color: AppColors.primaryBackground),
        ),
        leading: IconButton(
          icon: SvgPicture.asset(
            AppIcons.leftArrow,
            width: 28.w,
            height: 28.h,
            colorFilter: ColorFilter.mode(
              AppColors.primaryBackground,
              BlendMode.srcIn,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: AppColors.primaryBackground),
              onSelected: (value) async {
                if (value == 'mark_all') {
                  await ref.read(notificationProvider.notifier).markAllAsRead();
                } else if (value == 'clear_all') {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      title: Text(
                        "Clear All",
                        style: AppTextStyles.bodyLarge(),
                      ),
                      content: Text(
                        "Are you sure you want to delete all notifications?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            "Clear",
                            style: TextStyle(color: AppColors.primaryErrorBg),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await ref.read(notificationProvider.notifier).clearAll();
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'mark_all',
                  child: Row(
                    children: [
                      Icon(Icons.done_all, size: 20.sp),
                      SizedBox(width: 12.w),
                      Text("Mark all as read"),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 20.sp,
                        color: AppColors.primaryErrorBg,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        "Clear all",
                        style: TextStyle(color: AppColors.primaryErrorBg),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64.sp,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 16.h),
                  Text("No Notifications", style: AppTextStyles.bodyLarge()),
                  SizedBox(height: 8.h),
                  Text(
                    "You're all caught up!",
                    style: AppTextStyles.bodyMedium(
                      color: AppColors.primaryTextHeading,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(notificationProvider.notifier).refresh();
              },
              child: ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  return NotificationItemWidget(
                    notification: notifications[index],
                    isFreelancer: isFreelancer,
                  );
                },
              ),
            ),
    );
  }
}

class NotificationItemWidget extends ConsumerWidget {
  final AppNotification notification;
  final bool isFreelancer;

  const NotificationItemWidget({
    super.key,
    required this.notification,
    this.isFreelancer = false,
  });

  IconData _getIcon() {
    switch (notification.type) {
      case 'proposal':
        return Icons.description;
      case 'milestone':
        return Icons.flag;
      case 'project':
        return Icons.work;
      case 'payment':
        return Icons.account_balance_wallet;
      default:
        return Icons.notifications;
    }
  }

  Color _getColor() {
    switch (notification.type) {
      case 'proposal':
        return Colors.blue;
      case 'milestone':
        return isFreelancer
            ? AppColors.primaryFreelancerBG
            : AppColors.primaryElement;
      case 'project':
        return Colors.purple;
      case 'payment':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr = DateFormat(
      'MMM dd, yyyy • hh:mm a',
    ).format(notification.timestamp);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        ref
            .read(notificationProvider.notifier)
            .deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Notification deleted"),
            duration: Duration(seconds: 2),
          ),
        );
      },
      background: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: AppColors.primaryErrorBg,
          borderRadius: BorderRadius.circular(12.r),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        child: Icon(Icons.delete, color: Colors.white, size: 24.sp),
      ),
      child: GestureDetector(
        onTap: () {
          if (!notification.isRead) {
            ref.read(notificationProvider.notifier).markAsRead(notification.id);
          }
        },
        child: Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: notification.isRead
                ? AppColors.primaryBackground
                : _getColor().withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: notification.isRead
                  ? Colors.grey.shade200
                  : _getColor().withValues(alpha: 0.3),
              width: notification.isRead ? 1 : 2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: _getColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(_getIcon(), color: _getColor(), size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTextStyles.bodyMedium(
                              fontSize: 14.sp,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8.w,
                            height: 8.h,
                            decoration: BoxDecoration(
                              color: _getColor(),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      notification.message,
                      style: AppTextStyles.bodySmall(
                        fontSize: 13.sp,
                        color: AppColors.primaryTextHeading,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      dateStr,
                      style: AppTextStyles.bodySmall(
                        fontSize: 11.sp,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
