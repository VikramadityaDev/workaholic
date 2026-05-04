import 'package:escrowflow/commons/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class QuickLinkCardWidget extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const QuickLinkCardWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: SvgPicture.asset(
              icon,
              width: 24.w,
              height: 24.h,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
          ),
          SizedBox(height: 12.h),
          Text(label, style: AppTextStyles.bodyMedium(fontSize: 12)),
        ],
      ),
    );
  }
}
