import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

import 'utils/app_colors.dart';
import 'widgets/text_widget.dart';
import 'widgets/transactions_widget.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  final bool isFreelancer;

  const TransactionsScreen({super.key, this.isFreelancer = false});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  String selectedFilter = "All";

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    tabController.addListener(() {
      if (!tabController.indexIsChanging) {
        setState(() {
          selectedFilter = ["All", "Credit", "Debit"][tabController.index];
        });
      }
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  List<Transaction> getFilteredTransactions(List<Transaction> transactions) {
    switch (selectedFilter) {
      case "Credit":
        return transactions.where((t) => t.type == "CREDIT").toList();
      case "Debit":
        return transactions.where((t) => t.type == "DEBIT").toList();
      default:
        return transactions;
    }
  }

  Map<String, List<Transaction>> groupTransactionsByDate(
    List<Transaction> transactions,
  ) {
    final Map<String, List<Transaction>> grouped = {};

    for (var transaction in transactions) {
      final date = DateFormat('MMM dd, yyyy').format(transaction.timestamp);
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(transaction);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final allTransactions = ref.watch(transactionProvider);
    final filteredTransactions = getFilteredTransactions(allTransactions);
    final groupedTransactions = groupTransactionsByDate(filteredTransactions);

    // Calculate totals
    final totalCredit = allTransactions
        .where((t) => t.type == "CREDIT")
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalDebit = allTransactions
        .where((t) => t.type == "DEBIT")
        .fold(0.0, (sum, t) => sum + t.amount);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: widget.isFreelancer
            ? AppColors.primaryFreelancerBG
            : AppColors.primaryElement,
        elevation: 0,
        title: Text(
          "Transactions",
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
        bottom: TabBar(
          controller: tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: AppTextStyles.bodyMedium(),
          unselectedLabelStyle: AppTextStyles.bodyMedium(),
          tabs: const [
            Tab(text: "All"),
            Tab(text: "Credit"),
            Tab(text: "Debit"),
          ],
        ),
      ),
      body: Column(
        children: [
          // Summary Cards
          Container(
            padding: EdgeInsets.all(16.w),
            color: AppColors.primaryBackground,
            child: Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    title: "Total Received",
                    amount: totalCredit,
                    color: Colors.green,
                    icon: Icons.arrow_downward,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _summaryCard(
                    title: "Total Sent",
                    amount: totalDebit,
                    color: Colors.red,
                    icon: Icons.arrow_upward,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 8.h),

          // Transactions List
          Expanded(
            child: filteredTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64.sp,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          "No ${selectedFilter != 'All' ? selectedFilter : ''} Transactions",
                          style: AppTextStyles.bodyLarge(),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      ref.read(transactionProvider.notifier).refresh();
                    },
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: groupedTransactions.keys.length,
                      itemBuilder: (context, index) {
                        final date = groupedTransactions.keys.elementAt(index);
                        final transactions = groupedTransactions[date]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 16.h),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 4.w,
                                vertical: 8.h,
                              ),
                              child: Text(
                                date,
                                style: AppTextStyles.bodyMedium(
                                  fontSize: 14.sp,
                                  color: AppColors.primaryTextHeading,
                                ),
                              ),
                            ),
                            ...transactions.map((transaction) {
                              return TransactionItemWidget(
                                transaction: transaction,
                              );
                            }).toList(),
                          ],
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: color, size: 16.sp),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodySmall(
                    fontSize: 12.sp,
                    color: AppColors.primaryTextHeading,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            "₹${NumberFormat('#,###.##').format(amount)}",
            style: AppTextStyles.bodyLarge(fontSize: 20.sp, color: color),
          ),
        ],
      ),
    );
  }
}
