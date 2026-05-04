import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_colors.dart';
import 'text_widget.dart';

class DrawerItemWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const DrawerItemWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? AppColors.primaryText;

    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: (color ?? AppColors.primaryElement).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(icon, color: itemColor, size: 20.sp),
      ),
      title: Text(label, style: AppTextStyles.bodyMedium(color: itemColor)),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14.sp,
        color: AppColors.primaryTextHeading.withValues(alpha: 0.6),
      ),
      onTap: onTap,
    );
  }
}
