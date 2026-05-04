import 'package:escrowflow/commons/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_colors.dart';
import 'drawer_item_widget.dart';

class CustomDrawer extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String userRole;
  final VoidCallback onHomeTap;
  final VoidCallback onTransactionsTap;
  final VoidCallback onProfileTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onLogoutTap;

  const CustomDrawer({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.userRole,
    required this.onHomeTap,
    required this.onTransactionsTap,
    required this.onProfileTap,
    required this.onSettingsTap,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 0.75.sw,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryElement,
                    AppColors.primaryElement.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 32.r,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : "U",
                      style: AppTextStyles.headlineMedium(
                        color: AppColors.primaryBackground,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    userName,
                    style: AppTextStyles.titleLarge(
                      color: AppColors.primaryBackground,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    userEmail,
                    style: AppTextStyles.bodySmall(
                      color: AppColors.primaryBackground.withValues(alpha: 0.8),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_user,
                          size: 12.sp,
                          color: AppColors.primaryBackground,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          userRole.toUpperCase(),
                          style: AppTextStyles.badgeHeading(
                            color: AppColors.primaryBackground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            DrawerItemWidget(
              icon: Icons.home_outlined,
              label: "Home",
              onTap: onHomeTap,
            ),
            DrawerItemWidget(
              icon: Icons.swap_horiz,
              label: "Transactions",
              onTap: onTransactionsTap,
            ),
            DrawerItemWidget(
              icon: Icons.person_outline,
              label: "Profile",
              onTap: onProfileTap,
            ),
            DrawerItemWidget(
              icon: Icons.settings_outlined,
              label: "Settings",
              onTap: onSettingsTap,
            ),
            const Spacer(),
            Divider(color: Colors.grey.shade200, thickness: 1),
            DrawerItemWidget(
              icon: Icons.logout,
              label: "Logout",
              color: AppColors.primaryErrorBg,
              onTap: onLogoutTap,
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}
