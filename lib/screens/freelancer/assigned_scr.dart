import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

import '../../commons/utils/app_colors.dart';
import '../../commons/widgets/text_widget.dart';
import '../../models/project_model.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../services/api_service.dart';
import '../../services/transaction_service.dart';
import '../authentication/auth_scr.dart';

class AssignedProjectsScreen extends ConsumerStatefulWidget {
  const AssignedProjectsScreen({super.key});

  @override
  ConsumerState<AssignedProjectsScreen> createState() =>
      _AssignedProjectsScreenState();
}

class _AssignedProjectsScreenState
    extends ConsumerState<AssignedProjectsScreen> {
  List<Project> projects = [];
  bool isLoading = true;
  String? errorMessage;
  bool isServerError = false;

  Map<int, bool> expandedDescriptions = {};

  @override
  void initState() {
    super.initState();
    fetchProjects();
  }

  Future<void> fetchProjects() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      isServerError = false;
    });

    final result = await ApiService.fetchAssignedProjects();

    if (!mounted) return;

    if (result["requiresLogin"] == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
      return;
    }

    if (result["isServerError"] == true) {
      setState(() {
        isServerError = true;
        errorMessage = result["message"];
        projects = [];
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Backend error: ${result["message"]}"),
          backgroundColor: AppColors.warningBg,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: "Retry",
            textColor: AppColors.primaryBackground,
            onPressed: fetchProjects,
          ),
        ),
      );
      return;
    }

    if (result["success"]) {
      final List<Project> fetchedProjects = (result["data"] as List)
          .map((json) => Project.fromJson(json))
          .toList();

      await _checkForNewEarnings(fetchedProjects);

      setState(() {
        projects = fetchedProjects;
        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = result["message"];
        isLoading = false;
      });
    }
  }

  Future<void> _checkForNewEarnings(List<Project> projects) async {
    final processedMilestones =
        await TransactionService.getProcessedMilestones();

    for (var project in projects) {
      for (var milestone in project.milestones) {
        // Check if milestone is approved/completed and not yet processed
        if ((milestone.status == "APPROVED" ||
                milestone.status == "COMPLETED") &&
            !processedMilestones.contains(milestone.id)) {
          // Add credit transaction for this milestone
          await TransactionService.addCreditTransaction(
            milestone.amount,
            projectName: project.title,
          );
          await TransactionService.markMilestoneAsProcessed(milestone.id);
        }
      }
    }
    if (mounted) {
      ref.read(transactionProvider.notifier).refresh();
      ref.read(walletProvider.notifier).fetchBalance();
    }
  }

  Future<void> showSubmitDialog(Milestone milestone, int projectId) async {
    final messageController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primaryBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Submit Milestone",
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context, false),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),

                // Milestone Info
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFreelancerBG.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.flag_outlined,
                            color: AppColors.primaryFreelancerBG,
                            size: 18.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              milestone.name,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Text(
                            "Amount: ",
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            "₹${NumberFormat('#,###').format(milestone.amount)}",
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryFreelancerBG,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),

                // Message Field
                Text(
                  "Submission Message *",
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: messageController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText:
                        "Describe your completed work, deliverables, and any important notes for the client...",
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(
                        color: AppColors.primaryFreelancerBG,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please write your submission message";
                    }
                    if (value.trim().length < 20) {
                      return "Message should be at least 20 characters";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20.h),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(context, true);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryFreelancerBG,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      "Submit Work",
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBackground,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true) {
      await submitMilestone(
        milestone.id,
        messageController.text.trim(),
        projectId,
      );
    }

    messageController.dispose();
  }

  Future<void> submitMilestone(
    int milestoneId,
    String message,
    int projectId,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryFreelancerBG),
      ),
    );

    final result = await ApiService.submitMilestone(
      milestoneId: milestoneId,
      message: message,
    );

    if (!mounted) return;

    Navigator.pop(context);

    if (result["requiresLogin"] == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
      return;
    }
    if (result["success"]) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["message"]),
          backgroundColor: AppColors.primaryElementStatus,
          duration: const Duration(seconds: 3),
        ),
      );
      fetchProjects();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["message"]),
          backgroundColor: AppColors.primaryErrorBg,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String getRelativeTime(String deadline) {
    try {
      final date = DateTime.parse(deadline);
      final now = DateTime.now();
      final difference = date.difference(now);

      if (difference.inDays == 0) return "Today";
      if (difference.inDays == 1) return "Tomorrow";
      if (difference.inDays < 7) return "${difference.inDays} days left";
      if (difference.inDays < 30) return "${(difference.inDays / 7).floor()} weeks left";
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return deadline;
    }
  }

  IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'web development':
        return Icons.language;
      case 'mobile app':
        return Icons.smartphone;
      case 'design':
        return Icons.palette;
      case 'writing':
        return Icons.edit;
      default:
        return Icons.work_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.primaryFreelancerBG,
        elevation: 0,
        title: Text(
          "My Projects",
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
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryFreelancerBG,
              ),
            )
          : isServerError
          ? serverErrorState()
          : errorMessage != null
          ? errorState()
          : projects.isEmpty
          ? emptyState()
          : RefreshIndicator(
              onRefresh: fetchProjects,
              color: AppColors.primaryFreelancerBG,
              child: ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  return projectCard(projects[index]);
                },
              ),
            ),
    );
  }

  Widget serverErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(
                Icons.cloud_off,
                size: 64.sp,
                color: Colors.orange.shade700,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              "Server Error",
              style: AppTextStyles.titleLarge(fontSize: 20.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              errorMessage ?? "Unable to load projects",
              style: AppTextStyles.bodyMedium(
                fontSize: 14.sp,
                color: AppColors.primaryTextHeading,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: fetchProjects,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryFreelancerBG,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget errorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.sp,
            color: AppColors.primaryErrorBg,
          ),
          SizedBox(height: 16.h),
          Text(
            errorMessage!,
            style: AppTextStyles.bodyMedium(
              color: AppColors.primaryTextHeading,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          ElevatedButton.icon(
            onPressed: fetchProjects,
            icon: const Icon(Icons.refresh),
            label: const Text("Retry"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryFreelancerBG,
            ),
          ),
        ],
      ),
    );
  }

  Widget emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: AppColors.primaryFreelancerBG.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              Icons.work_outline,
              size: 64.sp,
              color: AppColors.primaryFreelancerBG,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            "No Projects Assigned",
            style: AppTextStyles.titleLarge(fontSize: 18.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            "You don't have any active projects yet",
            style: AppTextStyles.bodyMedium(
              fontSize: 14.sp,
              color: AppColors.primaryTextHeading,
            ),
          ),
        ],
      ),
    );
  }

  Widget projectCard(Project project) {
    final isExpanded = expandedDescriptions[project.id] ?? false;
    final isCompleted = project.status == "COMPLETED";

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: isCompleted
            ? Border.all(color: AppColors.primaryElementStatus, width: 2)
            : null,
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
          if (isCompleted) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.primaryElementStatus.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: AppColors.primaryElementStatus.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.primaryElementStatus,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    "Project Completed by Client",
                    style: AppTextStyles.bodyMedium(
                      fontSize: 14.sp,
                      color: AppColors.primaryElementStatus,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
          ],

          // Title & Category
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryFreelancerBG.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  getCategoryIcon(project.category),
                  color: AppColors.primaryFreelancerBG,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      style: AppTextStyles.bodyLarge(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      project.category,
                      style: AppTextStyles.bodySmall(
                        color: AppColors.primaryTextHeading,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // Description with See More/Less
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.description,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
                maxLines: isExpanded ? null : 3,
                overflow: isExpanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
              ),
              if (project.description.length > 100)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      expandedDescriptions[project.id] = !isExpanded;
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Text(
                      isExpanded ? "See Less" : "See More",
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.primaryFreelancerBG,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: 12.h),

          // Budget & Deadline
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Budget",
                      style: AppTextStyles.bodyMedium(
                        fontSize: 11.sp,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      "₹${NumberFormat('#,###').format(project.budget)}",
                      style: AppTextStyles.bodyLarge(
                        fontSize: 18.sp,
                        color: AppColors.primaryFreelancerBG,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Deadline",
                    style: AppTextStyles.bodySmall(
                      fontSize: 11.sp,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    getRelativeTime(project.deadline),
                    style: AppTextStyles.bodyMedium(
                      fontSize: 13.sp,
                      color: AppColors.warningBg,
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // Client Info
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20.r,
                  backgroundColor: AppColors.primaryElement.withValues(
                    alpha: 0.2,
                  ),
                  child: Text(
                    project.client.name.isNotEmpty
                        ? project.client.name[0].toUpperCase()
                        : "C",
                    style: AppTextStyles.bodyLarge(
                      fontSize: 18.sp,
                      color: AppColors.primaryElement,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.client.name,
                        style: AppTextStyles.bodyMedium(fontSize: 14.sp),
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 14.sp,
                            color: AppColors.notificationBg,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            "${project.client.rating.toStringAsFixed(1)} (${project.client.totalReviews} reviews)",
                            style: AppTextStyles.bodySmall(
                              fontSize: 12.sp,
                              color: AppColors.primaryTextHeading,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 12.h),

          if (project.status == "IN_PROGRESS" &&
              project.client.phoneNumber != null &&
              project.client.phoneNumber!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppColors.primaryElement.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: AppColors.primaryElement.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.phone,
                    color: AppColors.primaryElement,
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      project.client.phoneNumber!,
                      style: AppTextStyles.bodySmall(
                        fontSize: 13.sp,
                        color: AppColors.primaryElement,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy, size: 16.sp),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: project.client.phoneNumber!),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Phone number copied"),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],

          // Milestones
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.primaryFreelancerBG.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: AppColors.primaryFreelancerBG.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 16.sp,
                      color: AppColors.primaryFreelancerBG,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      "Milestones (${project.milestones.length})",
                      style: AppTextStyles.bodyMedium(
                        fontSize: 13.sp,
                        color: AppColors.primaryFreelancerBG,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                ...project.milestones.map((milestone) {
                  String dateStr = "";
                  try {
                    if (milestone.dueDate.isNotEmpty) {
                      final date = DateTime.parse(milestone.dueDate);
                      dateStr = DateFormat('MMM dd, yyyy').format(date);
                    }
                  } catch (e) {
                    if (milestone.dueDate.length >= 10) {
                      try {
                        final date = DateTime.parse(
                          milestone.dueDate.substring(0, 10),
                        );
                        dateStr = DateFormat('MMM dd, yyyy').format(date);
                      } catch (e2) {
                        dateStr = "";
                      }
                    }
                  }

                  final isRejected = milestone.status == "REJECTED";
                  final isSubmitted = milestone.status == "SUBMITTED";
                  final isApproved =
                      milestone.status == "APPROVED" ||
                      milestone.status == "COMPLETED";
                  final isPending = milestone.status == "PENDING";
                  final canSubmit = isPending;
                  final canResubmit = isRejected;

                  return Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6.w,
                              height: 6.h,
                              decoration: BoxDecoration(
                                color: isApproved
                                    ? AppColors.primaryElementStatus
                                    : isRejected
                                    ? AppColors.primaryErrorBg
                                    : isSubmitted
                                    ? AppColors.projectBg
                                    : AppColors.warningBg,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    milestone.name,
                                    style: AppTextStyles.bodyMedium(
                                      fontSize: 13.sp,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Row(
                                    children: [
                                      Text(
                                        "₹${NumberFormat('#,###').format(milestone.amount)}",
                                        style: AppTextStyles.bodySmall(
                                          fontSize: 12.sp,
                                          color: AppColors.primaryFreelancerBG,
                                        ),
                                      ),
                                      if (dateStr.isNotEmpty) ...[
                                        SizedBox(width: 8.w),
                                        Text(
                                          "• $dateStr",
                                          style: AppTextStyles.bodySmall(
                                            fontSize: 11.sp,
                                            color: AppColors.primaryTextHeading,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: isApproved
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : isRejected
                                    ? Colors.red.withValues(alpha: 0.1)
                                    : isSubmitted
                                    ? Colors.blue.withValues(alpha: 0.1)
                                    : Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                isApproved ? "COMPLETED" : milestone.status,
                                style: AppTextStyles.bodySmall(
                                  fontSize: 10.sp,
                                  color: isApproved
                                      ? AppColors.primaryElementStatus
                                      : isRejected
                                      ? AppColors.primaryErrorBg
                                      : isSubmitted
                                      ? AppColors.projectBg
                                      : AppColors.warningBg,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (canSubmit) ...[
                          SizedBox(height: 8.h),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  showSubmitDialog(milestone, project.id),
                              icon: Icon(Icons.upload_file, size: 16.sp),
                              label: Text(
                                "Submit Work",
                                style: AppTextStyles.bodyMedium(
                                  fontSize: 12.sp,
                                  color: AppColors.primaryBackground,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryFreelancerBG,
                                foregroundColor: AppColors.primaryBackground,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 8.h,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (canResubmit) ...[
                          SizedBox(height: 8.h),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  showSubmitDialog(milestone, project.id),
                              icon: Icon(Icons.refresh, size: 16.sp),
                              label: Text(
                                "Resubmit Work",
                                style: AppTextStyles.bodyMedium(
                                  fontSize: 12.sp,
                                  color: AppColors.primaryBackground,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.warningBg,
                                foregroundColor: AppColors.primaryBackground,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 8.h,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                              ),
                            ),
                          ),
                        ],

                        if (isSubmitted) ...[
                          SizedBox(height: 8.h),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6.r),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 16.sp,
                                  color: AppColors.projectBg,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  "Under Review",
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: AppColors.projectBg,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Navigate to project details
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryFreelancerBG,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                "View Details",
                style: AppTextStyles.bodyMedium(
                  fontSize: 14.sp,
                  color: AppColors.primaryBackground,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
