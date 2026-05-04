import 'package:escrowflow/commons/utils/app_colors.dart';
import 'package:escrowflow/commons/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WalletCardWidget extends StatelessWidget {
  final List<Color> gradient;
  final String balance;
  final String bankName;
  final String accountNumber;

  const WalletCardWidget({
    super.key,
    required this.gradient,
    required this.balance,
    required this.bankName,
    required this.accountNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryBackground.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.credit_card,
                      color: AppColors.primaryBackground,
                      size: 16.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      "Workaholic",
                      style: AppTextStyles.bodyMedium(
                        color: AppColors.primaryBackground,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: AppColors.primaryBackground.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          Text(
            balance,
            style: AppTextStyles.headlineMedium(
              color: AppColors.primaryBackground,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bankName,
                style: AppTextStyles.bodySmall(
                  color: AppColors.primaryBackground.withValues(alpha: 0.9),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                accountNumber,
                style: AppTextStyles.bodyMedium(
                  color: AppColors.primaryBackground.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
