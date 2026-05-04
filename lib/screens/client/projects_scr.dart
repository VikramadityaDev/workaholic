import 'package:escrowflow/screens/client/project_proposal_scr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

import '../../commons/utils/app_colors.dart';
import '../../commons/widgets/text_widget.dart';
import '../../models/project_model.dart';
import '../../models/proposal_model.dart';
import '../../providers/notification_provider.dart';
import '../../providers/proposal_count.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../services/api_service.dart';
import '../authentication/auth_scr.dart';
import 'client_dash.dart';
import 'milestone_approval_scr.dart';

class MyProjectsScreen extends ConsumerStatefulWidget {
  const MyProjectsScreen({super.key});

  @override
  ConsumerState<MyProjectsScreen> createState() => _MyProjectsScreenState();
}

class _MyProjectsScreenState extends ConsumerState<MyProjectsScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  List<Project> allProjects = [];
  List<Project> filteredProjects = [];
  bool isLoading = true;
  String? errorMessage;
  bool isServerError = false;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 4, vsync: this);
    tabController.addListener(() {
      if (!tabController.indexIsChanging) {
        filterProjects();
      }
    });
    fetchProjects();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  Future<void> fetchProjects() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      isServerError = false;
    });

    final result = await ApiService.fetchUserProjects(status: null);
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
        allProjects = [];
        filteredProjects = [];
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
      setState(() {
        allProjects = (result["data"] as List)
            .map((json) => Project.fromJson(json))
            .toList();
        isLoading = false;
      });
      filterProjects();
      fetchProposalCounts();
    } else {
      setState(() {
        errorMessage = result["message"];
        isLoading = false;
      });
    }
  }

  Future<void> fetchProposalCounts() async {
    for (var project in allProjects) {
      try {
        final result = await ApiService.fetchProjectProposals(project.id);
        if (result["success"]) {
          final proposalsList = result["data"] as List;
          ref
              .read(proposalCountProvider.notifier)
              .updateCount(project.id, proposalsList.length);
        }
      } catch (e) {
        debugPrint('Error: $e');
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  void filterProjects() {
    setState(() {
      switch (tabController.index) {
        case 0: // All
          filteredProjects = allProjects;
          break;
        case 1: // Open
          filteredProjects = allProjects
              .where((project) => project.status == "CREATED")
              .toList();
          break;
        case 2: // Active
          filteredProjects = allProjects
              .where((project) => project.status == "IN_PROGRESS")
              .toList();
          break;
        case 3: // Completed
          filteredProjects = allProjects
              .where((project) => project.status == "COMPLETED")
              .toList();
          break;
      }
    });
  }

  String getStatusLabel(String status) {
    switch (status) {
      case "CREATED":
        return "Waiting for Proposals";
      case "IN_PROGRESS":
        return "Active";
      case "COMPLETED":
        return "Completed";
      case "CANCELLED":
        return "Cancelled";
      default:
        return status;
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "CREATED":
        return Colors.orange;
      case "IN_PROGRESS":
        return Colors.blue;
      case "COMPLETED":
        return Colors.green;
      case "CANCELLED":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String getRelativeTime(String deadline) {
    try {
      final date = DateTime.parse(deadline);
      final now = DateTime.now();
      final difference = date.difference(now);

      if (difference.inDays == 0) return "Today";
      if (difference.inDays == 1) return "Tomorrow";
      if (difference.inDays < 7) return "${difference.inDays} days";
      if (difference.inDays < 30) {
        return "${(difference.inDays / 7).floor()} weeks";
      }
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return deadline;
    }
  }

  bool canCompleteProject(Project project) {
    if (project.status != "IN_PROGRESS") return false;
    if (project.milestones.isEmpty) return false;
    return project.milestones.every(
      (m) => m.status == "APPROVED" || m.status == "COMPLETED",
    );
  }

  Future<void> showCompleteProjectDialog(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text("Complete Project", style: AppTextStyles.bodyLarge()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Are you sure you want to mark this project as completed?",
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
                    project.title,
                    style: AppTextStyles.bodyMedium(
                      fontSize: 14.sp,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "${project.milestones.length} milestones completed",
                    style: AppTextStyles.bodySmall(
                      fontSize: 12.sp,
                      color: AppColors.primaryTextHeading,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              "This action will close the project and the freelancer will be notified.",
              style: AppTextStyles.bodySmall(
                fontSize: 12.sp,
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
              backgroundColor: AppColors.primaryElementStatus,
            ),
            child: Text(
              "Complete",
              style: AppTextStyles.bodyMedium(
                color: AppColors.primaryBackground,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await completeProject(project);
    }
  }

  Future<void> completeProject(Project project) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryElement),
      ),
    );

    final result = await ApiService.completeProject(projectId: project.id);
    if (!mounted) return;
    Navigator.pop(context); // Close loading

    if (result["requiresLogin"] == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
      return;
    }

    if (result["success"]) {
      await ref.read(notificationProvider.notifier).refresh();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["message"]),
          backgroundColor: AppColors.primaryElementStatus,
        ),
      );
      fetchProjects();
      showRatingBottomSheet(project);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["message"]),
          backgroundColor: AppColors.primaryErrorBg,
        ),
      );
    }
  }

  void showRatingBottomSheet(Project project) async {
    int? freelancerId;
    final proposalResult = await ApiService.fetchProjectProposals(project.id);
    if (proposalResult["success"] == true) {
      final list = (proposalResult["data"] as List)
          .map((json) => Proposal.fromJson(json))
          .toList();
      final accepted = list.firstWhere(
            (p) => p.status == "ACCEPTED",
        orElse: () => list.first,
      );
      freelancerId = accepted.freelancerId;
    }
    if (freelancerId == null || !mounted) return;
    int selectedRating = 0;
    final screenContext = context;

    showModalBottomSheet(
      context: screenContext,
      isScrollControlled: true,
      backgroundColor: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 40.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Icon(
                    Icons.star_rounded,
                    size: 48.sp,
                    color: AppColors.notificationBg,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    "Rate the Freelancer",
                    style: AppTextStyles.titleLarge(fontSize: 20.sp),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "How was your experience working on\n\"${project.title}\"?",
                    style: AppTextStyles.bodyMedium(
                      color: AppColors.primaryTextHeading,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 28.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      return GestureDetector(
                        onTap: () => setSheetState(() => selectedRating = star),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6.w),
                          child: Icon(
                            selectedRating >= star
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 40.sp,
                            color: selectedRating >= star
                                ? AppColors.notificationBg
                                : Colors.grey.shade400,
                          ),
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    selectedRating == 0
                        ? "Tap to rate"
                        : ["", "Poor", "Fair", "Good", "Very Good", "Excellent"][selectedRating],
                    style: AppTextStyles.bodyMedium(
                      color: selectedRating == 0
                          ? AppColors.primaryTextHeading
                          : AppColors.notificationBg,
                    ),
                  ),
                  SizedBox(height: 28.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selectedRating == 0
                          ? null
                          : () async {
                        Navigator.pop(sheetContext);
                        final result = await ApiService.giveRating(
                          freelancerId: freelancerId!,
                          rating: selectedRating,
                        );
                        if (!mounted) return;
                        if (result["requiresLogin"] == true) {
                          Navigator.pushAndRemoveUntil(
                            screenContext,
                            MaterialPageRoute(
                              builder: (_) => const AuthScreen(),
                            ),
                                (route) => false,
                          );
                          return;
                        }
                        ScaffoldMessenger.of(screenContext).showSnackBar(
                          SnackBar(
                            content: Text(result["message"]),
                            backgroundColor: result["success"]
                                ? AppColors.primaryElementStatus
                                : AppColors.primaryErrorBg,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryElement,
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        "Submit Rating",
                        style: AppTextStyles.bodyMedium(
                          fontSize: 15.sp,
                          color: AppColors.primaryBackground,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: Text(
                      "Skip",
                      style: AppTextStyles.bodyMedium(
                        color: AppColors.primaryTextHeading,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.primaryElement,
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
        bottom: TabBar(
          controller: tabController,
          isScrollable: false,
          labelPadding: EdgeInsets.symmetric(horizontal: 8.w),
          indicatorColor: AppColors.primaryBackground,
          indicatorWeight: 3,
          labelColor: AppColors.primaryBackground,
          unselectedLabelStyle: AppTextStyles.bodyMedium(),
          unselectedLabelColor: Colors.white70,
          labelStyle: AppTextStyles.bodyMedium(),
          tabs: [
            Tab(text: "All (${allProjects.length})"),
            Tab(
              text:
                  "Open (${allProjects.where((p) => p.status == "CREATED").length})",
            ),
            Tab(
              text:
                  "Active (${allProjects.where((p) => p.status == "IN_PROGRESS").length})",
            ),
            Tab(
              text:
                  "Done (${allProjects.where((p) => p.status == "COMPLETED").length})",
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : isServerError
          ? serverErrorState()
          : errorMessage != null
          ? errorState()
          : filteredProjects.isEmpty
          ? emptyState()
          : RefreshIndicator(
              onRefresh: fetchProjects,
              child: ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: filteredProjects.length,
                itemBuilder: (context, index) {
                  return projectCard(filteredProjects[index]);
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
                color: AppColors.warningBg,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              "Backend Server Error",
              style: AppTextStyles.titleLarge(),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              errorMessage ?? "The server is experiencing issues",
              style: AppTextStyles.bodyMedium(),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: fetchProjects,
                  icon: const Icon(Icons.refresh),
                  label: Text("Retry", style: AppTextStyles.bodyMedium()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryElement,
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 12.h,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                OutlinedButton.icon(
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ClientDashboard(),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: Text("Go Back", style: AppTextStyles.bodyMedium()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryElement,
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 12.h,
                    ),
                  ),
                ),
              ],
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
            style: AppTextStyles.bodyMedium(),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          ElevatedButton.icon(
            onPressed: fetchProjects,
            icon: const Icon(Icons.refresh),
            label: Text("Retry", style: AppTextStyles.bodyMedium()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryElement,
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
              color: AppColors.primaryElement.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              Icons.folder_open,
              size: 64.sp,
              color: AppColors.primaryElement,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            "No projects found",
            style: AppTextStyles.titleLarge(fontSize: 18.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            tabController.index == 0
                ? "You haven't created any projects yet"
                : "No ${getTabName()} projects",
            style: AppTextStyles.bodyMedium(
              color: AppColors.primaryTextHeading,
            ),
          ),
        ],
      ),
    );
  }

  String getTabName() {
    switch (tabController.index) {
      case 1:
        return "open";
      case 2:
        return "active";
      case 3:
        return "completed";
      default:
        return "";
    }
  }

  Widget projectCard(Project project) {
    final proposalCount = ref
        .read(proposalCountProvider.notifier)
        .getCount(project.id);
    final hasSubmittedMilestones = project.milestones.any(
      (m) => m.status == "SUBMITTED",
    );
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(12.r),
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
          // Title & Category
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryElement.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.smartphone,
                  color: AppColors.primaryElement,
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

          // Budget & Status
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      "Budget: ",
                      style: AppTextStyles.bodySmall(
                        fontSize: 13.sp,
                        color: AppColors.primaryTextHeading,
                      ),
                    ),
                    Text(
                      "₹${NumberFormat('#,###').format(project.budget)}",
                      style: AppTextStyles.bodyMedium(fontSize: 15.sp),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: getStatusColor(project.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8.w,
                      height: 8.h,
                      decoration: BoxDecoration(
                        color: getStatusColor(project.status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      getStatusLabel(project.status),
                      style: AppTextStyles.bodySmall(
                        fontSize: 11.sp,
                        color: getStatusColor(project.status),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // Posted & Proposals
          Row(
            children: [
              Icon(Icons.access_time, size: 14.sp, color: Colors.grey.shade500),
              SizedBox(width: 4.w),
              Text(
                "Deadline: ${getRelativeTime(project.deadline)}",
                style: AppTextStyles.bodySmall(
                  fontSize: 12.sp,
                  color: AppColors.primaryTextHeading,
                ),
              ),
              SizedBox(width: 16.w),
              Icon(
                Icons.receipt_long,
                size: 14.sp,
                color: proposalCount > 0
                    ? AppColors.primaryElement
                    : Colors.grey.shade500,
              ),
              SizedBox(width: 4.w),
              Container(
                padding: proposalCount > 0
                    ? EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h)
                    : EdgeInsets.zero,
                decoration: proposalCount > 0
                    ? BoxDecoration(
                        color: AppColors.primaryElement.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      )
                    : null,
                child: Text(
                  proposalCount > 0
                      ? "Proposals: $proposalCount"
                      : "No proposals",
                  style: AppTextStyles.bodySmall(
                    fontSize: 12.sp,
                    color: proposalCount > 0
                        ? AppColors.primaryElement
                        : AppColors.primaryTextHeading,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // Milestones
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Milestones:",
                  style: AppTextStyles.bodyMedium(fontSize: 12.sp),
                ),
                SizedBox(height: 8.h),
                ...project.milestones.map((milestone) {
                  String dateStr = "";
                  try {
                    if (milestone.dueDate.isNotEmpty) {
                      final date = DateTime.parse(milestone.dueDate);
                      dateStr = DateFormat('MMM dd').format(date);
                    }
                  } catch (e) {
                    if (milestone.dueDate.length >= 10) {
                      try {
                        final date = DateTime.parse(
                          milestone.dueDate.substring(0, 10),
                        );
                        dateStr = DateFormat('MMM dd').format(date);
                      } catch (e2) {
                        dateStr = "";
                      }
                    }
                  }

                  return Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Row(
                      children: [
                        Container(
                          width: 4.w,
                          height: 4.h,
                          decoration: const BoxDecoration(
                            color: Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            dateStr.isNotEmpty
                                ? "${milestone.name} - ₹${NumberFormat('#,###').format(milestone.amount)} ($dateStr)"
                                : "${milestone.name} - ₹${NumberFormat('#,###').format(milestone.amount)}",
                            style: AppTextStyles.bodySmall(
                              fontSize: 12.sp,
                              color: AppColors.primaryTextHeading,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          SizedBox(height: 12.h),

          Column(
            children: [
              // View Proposals Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProjectProposalsScreen(project: project),
                      ),
                    ).then((_) {
                      fetchProposalCounts();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryElement,
                    side: BorderSide(color: AppColors.primaryElement),
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    "View Proposals",
                    style: AppTextStyles.bodyMedium(
                      fontSize: 13.sp,
                      color: AppColors.primaryElement,
                    ),
                  ),
                ),
              ),
              if (hasSubmittedMilestones) ...[
                SizedBox(height: 8.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              MilestoneApprovalScreen(project: project),
                        ),
                      );
                      if (result == true) {
                        fetchProjects();
                        ref.read(walletProvider.notifier).fetchBalance();
                        ref.read(transactionProvider.notifier).refresh();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.projectBg,
                      foregroundColor: AppColors.primaryBackground,
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      "Review Submissions",
                      style: AppTextStyles.bodyMedium(
                        fontSize: 13.sp,
                        color: AppColors.primaryBackground,
                      ),
                    ),
                  ),
                ),
              ],
              if (canCompleteProject(project)) ...[
                SizedBox(height: 8.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => showCompleteProjectDialog(project),
                    icon: Icon(Icons.check_circle_outline, size: 18.sp),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryElementStatus,
                      foregroundColor: AppColors.primaryBackground,
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    label: Text(
                      "Complete Project",
                      style: AppTextStyles.bodyMedium(
                        fontSize: 13.sp,
                        color: AppColors.primaryBackground,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
