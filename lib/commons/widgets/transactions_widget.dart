import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import 'text_widget.dart';
import '../../models/transaction_model.dart';

class EmptyTransactionsWidget extends StatelessWidget {
  const EmptyTransactionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48.sp,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 12.h),
          Text(
            "No Transactions Yet",
            style: AppTextStyles.bodyMedium(
              fontSize: 14.sp,
              color: AppColors.primaryTextHeading,
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionListWidget extends StatelessWidget {
  final List<Transaction> transactions;
  final int maxDisplay;

  const TransactionListWidget({
    super.key,
    required this.transactions,
    this.maxDisplay = 5,
  });

  @override
  Widget build(BuildContext context) {
    final displayTransactions = transactions.take(maxDisplay).toList();

    return Column(
      children: displayTransactions.map((transaction) {
        return TransactionItemWidget(transaction: transaction);
      }).toList(),
    );
  }
}

class TransactionItemWidget extends StatelessWidget {
  final Transaction transaction;

  const TransactionItemWidget({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.type == "CREDIT";
    final dateStr = DateFormat(
      'MMM dd, yyyy • hh:mm a',
    ).format(transaction.timestamp);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: isCredit
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: isCredit
                  ? AppColors.primaryElementStatus
                  : AppColors.primaryErrorBg,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: AppTextStyles.bodyMedium(fontSize: 14.sp),
                ),
                SizedBox(height: 4.h),
                if (transaction.projectName != null) ...[
                  Text(
                    transaction.projectName!,
                    style: AppTextStyles.bodySmall(
                      fontSize: 12.sp,
                      color: AppColors.primaryTextHeading,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                ],
                Text(
                  dateStr,
                  style: AppTextStyles.bodySmall(
                    fontSize: 11.sp,
                    color: AppColors.primaryTextHeading,
                  ),
                ),
              ],
            ),
          ),
          // Amount
          Text(
            "${isCredit ? '+' : '-'}₹${NumberFormat('#,###.##').format(transaction.amount)}",
            style: AppTextStyles.bodyLarge(
              fontSize: 16.sp,
              color: isCredit
                  ? AppColors.primaryElementStatus
                  : AppColors.primaryErrorBg,
            ),
          ),
        ],
      ),
    );
  }
}
