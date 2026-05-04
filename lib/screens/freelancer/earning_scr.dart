import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

import '../../commons/utils/app_colors.dart';
import '../../commons/widgets/text_widget.dart';
import '../../commons/transaction_scr.dart';
import '../../commons/widgets/transactions_widget.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/wallet_provider.dart';

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletState = ref.watch(walletProvider);
    final transactions = ref.watch(transactionProvider);

    final totalEarnings = transactions
        .where((t) => t.type == "CREDIT")
        .fold(0.0, (sum, t) => sum + t.amount);

    final thisMonthEarnings = transactions
        .where(
          (t) =>
              t.type == "CREDIT" &&
              t.timestamp.month == DateTime.now().month &&
              t.timestamp.year == DateTime.now().year,
        )
        .fold(0.0, (sum, t) => sum + t.amount);

    final recentEarnings = transactions
        .where((t) => t.type == "CREDIT")
        .take(10)
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.primaryFreelancerBG,
        elevation: 0,
        title: Text(
          "Earnings",
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
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(walletProvider.notifier).fetchBalance();
          await ref.read(transactionProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Balance Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Available Balance",
                      style: AppTextStyles.bodyMedium(
                        fontSize: 14.sp,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      walletState.isLoading
                          ? "Loading..."
                          : "₹${NumberFormat('#,###.##').format(walletState.balance)}",
                      style: AppTextStyles.titleLarge(
                        fontSize: 32.sp,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Navigate to withdraw screen
                      },
                      icon: Icon(Icons.account_balance_wallet, size: 18.sp),
                      label: Text("Withdraw Funds"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF10B981),
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 12.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _statsCard(
                      title: "Total Earned",
                      amount: totalEarnings,
                      icon: Icons.trending_up,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _statsCard(
                      title: "This Month",
                      amount: thisMonthEarnings,
                      icon: Icons.calendar_today,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 32.h),

              // Recent Earnings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Recent Earnings",
                    style: AppTextStyles.bodyLarge(fontSize: 18.sp),
                  ),
                  if (recentEarnings.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const TransactionsScreen(isFreelancer: true),
                          ),
                        );
                      },
                      child: Text(
                        "View All",
                        style: AppTextStyles.bodySmall(
                          fontSize: 12.sp,
                          color: AppColors.primaryFreelancerBG,
                        ),
                      ),
                    ),
                ],
              ),

              SizedBox(height: 16.h),

              if (recentEarnings.isEmpty)
                const EmptyTransactionsWidget()
              else
                TransactionListWidget(
                  transactions: recentEarnings,
                  maxDisplay: 10,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statsCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            title,
            style: AppTextStyles.bodySmall(
              fontSize: 12.sp,
              color: AppColors.primaryTextHeading,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            "₹${NumberFormat('#,###.##').format(amount)}",
            style: AppTextStyles.bodyLarge(
              fontSize: 18.sp,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
