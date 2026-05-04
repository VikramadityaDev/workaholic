import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

import '../../commons/utils/app_colors.dart';
import '../../commons/widgets/text_widget.dart';
import '../../models/project_model.dart';
import '../../providers/notification_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../services/api_service.dart';
import '../authentication/auth_scr.dart';

class MilestoneApprovalScreen extends ConsumerStatefulWidget {
  final Project project;

  const MilestoneApprovalScreen({super.key, required this.project});

  @override
  ConsumerState<MilestoneApprovalScreen> createState() =>
      _MilestoneApprovalScreenState();
}

class _MilestoneApprovalScreenState
    extends ConsumerState<MilestoneApprovalScreen> {
  bool isLoading = false;

  Future<void> handleApprove(Milestone milestone) async {
    final confirmed = await showApprovalConfirmDialog(milestone);
    if (!confirmed) return;

    await processApproval(milestone: milestone, isApprove: true);
  }

  Future<void> handleReject(Milestone milestone) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text("Reject Milestone", style: AppTextStyles.bodyLarge()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Are you sure you want to reject this milestone?",
              style: AppTextStyles.bodyMedium(),
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    milestone.name,
                    style: AppTextStyles.bodyMedium(
                      fontSize: 14.sp,
                      color: AppColors.primaryText,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "₹${NumberFormat('#,###').format(milestone.amount)}",
                    style: AppTextStyles.bodyLarge(
                      fontSize: 16.sp,
                      color: AppColors.primaryErrorBg,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              "The freelancer will be able to resubmit this work.",
              style: AppTextStyles.bodySmall(
                color: AppColors.primaryTextHeading,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: AppTextStyles.bodyMedium()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryErrorBg,
            ),
            child: Text(
              "Reject",
              style: AppTextStyles.bodyMedium(
                color: AppColors.primaryBackground,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await processApproval(milestone: milestone, isApprove: false);
    }
  }

  Future<void> processApproval({
    required Milestone milestone,
    required bool isApprove,
  }) async {
    setState(() {
      isLoading = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryElement),
      ),
    );

    final result = isApprove
        ? await ApiService.approveMilestone(milestoneId: milestone.id)
        : await ApiService.rejectMilestone(milestoneId: milestone.id);

    if (!mounted) return;

    Navigator.pop(context);

    setState(() {
      isLoading = false;
    });

    if (result["requiresLogin"] == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
      return;
    }

    if (result["success"]) {
      if (isApprove) {
        await ref
            .read(transactionProvider.notifier)
            .addDebit(
              amount: milestone.amount,
              projectName: widget.project.title,
              milestoneName: milestone.name,
            );
        await ref.read(walletProvider.notifier).fetchBalance();
      }

      await ref.read(notificationProvider.notifier).refresh();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["message"]),
          backgroundColor: isApprove
              ? AppColors.primaryElementStatus
              : AppColors.primaryErrorBg,
        ),
      );

      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["message"]),
          backgroundColor: AppColors.primaryErrorBg,
        ),
      );
    }
  }

  Future<bool> showApprovalConfirmDialog(Milestone milestone) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text("Approve Milestone", style: AppTextStyles.bodyLarge()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Are you sure you want to approve this milestone?",
              style: AppTextStyles.bodyMedium(),
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    milestone.name,
                    style: AppTextStyles.bodyMedium(
                      fontSize: 14.sp,
                      color: AppColors.primaryText,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "₹${NumberFormat('#,###').format(milestone.amount)}",
                    style: AppTextStyles.bodyLarge(
                      fontSize: 16.sp,
                      color: AppColors.primaryElementStatus,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: AppTextStyles.bodyMedium()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryElementStatus,
            ),
            child: Text(
              "Approve",
              style: AppTextStyles.bodyMedium(
                color: AppColors.primaryBackground,
              ),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<String?> showRejectionDialog() async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text("Reject Milestone", style: AppTextStyles.bodyLarge()),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Please provide a reason for rejection:",
                style: AppTextStyles.bodyMedium(),
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: reasonController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Explain what needs to be improved...",
                  hintStyle: AppTextStyles.bodyMedium(
                    color: AppColors.primaryTextHeading,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please provide a reason";
                  }
                  if (value.trim().length < 10) {
                    return "Reason should be at least 10 characters";
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: AppTextStyles.bodyMedium()),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, reasonController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryErrorBg,
            ),
            child: Text(
              "Reject",
              style: AppTextStyles.bodyMedium(
                color: AppColors.primaryBackground,
              ),
            ),
          ),
        ],
      ),
    );

    reasonController.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final submittedMilestones = widget.project.milestones
        .where((m) => m.status == "SUBMITTED")
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.primaryElement,
        elevation: 0,
        title: Text(
          "Review Milestones",
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
      body: submittedMilestones.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64.sp,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    "No Pending Submissions",
                    style: AppTextStyles.titleLarge(fontSize: 18.sp),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "All milestones are up to date",
                    style: AppTextStyles.bodyMedium(
                      color: AppColors.primaryTextHeading,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: submittedMilestones.length,
              itemBuilder: (context, index) {
                final milestone = submittedMilestones[index];
                return milestoneCard(milestone);
              },
            ),
    );
  }

  Widget milestoneCard(Milestone milestone) {
    final date = DateTime.tryParse(milestone.dueDate);
    final dateStr = date != null
        ? DateFormat('MMM dd, yyyy').format(date)
        : milestone.dueDate;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.blue.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.assignment_outlined,
                  color: Colors.blue,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      milestone.name,
                      style: AppTextStyles.bodyLarge(fontSize: 16.sp),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "Due: $dateStr",
                      style: AppTextStyles.bodySmall(
                        color: AppColors.primaryTextHeading,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Amount
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(Icons.currency_rupee, color: Colors.green, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  NumberFormat('#,###').format(milestone.amount),
                  style: AppTextStyles.bodyLarge(
                    fontSize: 20.sp,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          if (milestone.message != null && milestone.message!.isNotEmpty) ...[
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.message_outlined,
                        size: 16.sp,
                        color: AppColors.primaryTextHeading,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        "Submission Message:",
                        style: AppTextStyles.bodyMedium(
                          fontSize: 13.sp,
                          color: AppColors.primaryTextHeading,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    milestone.message!,
                    style: AppTextStyles.bodyMedium(fontSize: 14.sp),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 16.h),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : () => handleReject(milestone),
                  icon: Icon(Icons.close, size: 18.sp),
                  label: Text("Reject", style: TextStyle(fontSize: 14.sp)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryErrorBg,
                    side: BorderSide(color: AppColors.primaryErrorBg),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : () => handleApprove(milestone),
                  icon: Icon(Icons.check, size: 18.sp),
                  label: Text("Approve", style: TextStyle(fontSize: 14.sp)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
