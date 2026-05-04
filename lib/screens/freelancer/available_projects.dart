import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../commons/utils/app_colors.dart';
import '../../commons/widgets/text_widget.dart';
import '../../models/project_model.dart';
import '../../providers/proposal_count.dart';
import '../../services/api_service.dart';
import '../authentication/auth_scr.dart';

class AvailableProjectsScreen extends ConsumerStatefulWidget {
  const AvailableProjectsScreen({super.key});

  @override
  ConsumerState<AvailableProjectsScreen> createState() =>
      _AvailableProjectsScreenState();
}

class _AvailableProjectsScreenState
    extends ConsumerState<AvailableProjectsScreen>
    with SingleTickerProviderStateMixin {
  TabController? tabController;
  List<Project> allProjects = [];
  List<Project> displayedProjects = [];
  bool isLoading = true;
  String? errorMessage;
  bool isServerError = false;
  Set<int> appliedProjectIds = {};
  Map<int, bool> expandedDescriptions = {};

  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    tabController!.addListener(() {
      if (!tabController!.indexIsChanging) {
        filterProjects();
      }
    });
    loadAppliedProjects();
    fetchProjects();
  }

  @override
  void dispose() {
    tabController?.dispose();
    super.dispose();
  }

  Future<void> loadAppliedProjects() async {
    try {
      final appliedIdsString = await storage.read(key: 'appliedProjectIds');
      if (appliedIdsString != null && appliedIdsString.isNotEmpty) {
        setState(() {
          appliedProjectIds = appliedIdsString
              .split(',')
              .map((id) => int.tryParse(id))
              .where((id) => id != null)
              .cast<int>()
              .toSet();
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> saveAppliedProjects() async {
    try {
      final appliedIdsString = appliedProjectIds.join(',');
      await storage.write(key: 'appliedProjectIds', value: appliedIdsString);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> fetchProjects() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      isServerError = false;
    });

    final result = await ApiService.fetchAvailableProjects(status: null);

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
        displayedProjects = [];
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Backend error: ${result["message"]}"),
          backgroundColor: Colors.orange,
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
    } else {
      setState(() {
        errorMessage = result["message"];
        isLoading = false;
      });
    }
  }

  void filterProjects() {
    setState(() {
      switch (tabController?.index ?? 0) {
        case 0: // All Projects
          displayedProjects = allProjects;
          break;
        case 1: // Applied Projects
          displayedProjects = allProjects
              .where((project) => appliedProjectIds.contains(project.id))
              .toList();
          break;
      }
    });
  }

  Future<void> showApplyDialog(Project project) async {
    final descriptionController = TextEditingController();
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
            color: Colors.white,
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
                    Text("Apply to Project", style: AppTextStyles.titleLarge()),
                    IconButton(
                      onPressed: () => Navigator.pop(context, false),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFreelancerBG.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.work_outline,
                        color: AppColors.primaryFreelancerBG,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          project.title,
                          style: AppTextStyles.bodyMedium(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  "Cover Letter / Proposal *",
                  style: AppTextStyles.bodyMedium(),
                ),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText:
                        "Explain why you're the best fit for this project...",
                    hintStyle: AppTextStyles.bodySmall(
                      color: AppColors.primaryTextHeading,
                    ),
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
                      return "Please write your proposal";
                    }
                    if (value.trim().length < 50) {
                      return "Proposal should be at least 50 characters";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20.h),
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
                      "Submit Application",
                      style: AppTextStyles.bodyLarge(
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
      await applyToProject(project.id, descriptionController.text.trim());
    }

    descriptionController.dispose();
  }

  Future<void> applyToProject(int projectId, String description) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryFreelancerBG),
      ),
    );

    final result = await ApiService.applyToProject(
      projectId: projectId,
      description: description,
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
      setState(() {
        appliedProjectIds.add(projectId);
      });
      await saveAppliedProjects();
      filterProjects();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result["message"],
            style: AppTextStyles.bodyMedium(
              fontSize: 13.sp,
              color: AppColors.primaryBackground,
            ),
          ),
          backgroundColor: AppColors.primaryElementStatus,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result["message"],
            style: AppTextStyles.bodyMedium(
              fontSize: 13.sp,
              color: AppColors.primaryBackground,
            ),
          ),
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
    if (tabController == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.primaryFreelancerBG,
        elevation: 0,
        title: Text(
          "Find Work",
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
          controller: tabController!,
          indicatorColor: AppColors.primaryBackground,
          indicatorWeight: 3,
          labelColor: AppColors.primaryBackground,
          unselectedLabelColor: Colors.white70,
          labelStyle: AppTextStyles.bodyMedium(),
          tabs: [
            Tab(text: "All Projects (${allProjects.length})"),
            Tab(text: "Applied (${appliedProjectIds.length})"),
          ],
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
          : displayedProjects.isEmpty
          ? emptyState()
          : RefreshIndicator(
              onRefresh: fetchProjects,
              color: AppColors.primaryFreelancerBG,
              child: ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: displayedProjects.length,
                itemBuilder: (context, index) {
                  return projectCard(displayedProjects[index]);
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
              label: Text("Retry", style: AppTextStyles.bodyMedium()),
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
            label: Text(
              "Retry",
              style: AppTextStyles.bodyMedium(
                color: AppColors.primaryBackground,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryFreelancerBG,
            ),
          ),
        ],
      ),
    );
  }

  Widget emptyState() {
    final isAppliedTab = tabController?.index == 1;

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
              isAppliedTab ? Icons.inbox_outlined : Icons.work_outline,
              size: 64.sp,
              color: AppColors.primaryFreelancerBG,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            isAppliedTab ? "No Applications Yet" : "No Projects Available",
            style: AppTextStyles.titleLarge(fontSize: 18.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            isAppliedTab
                ? "You haven't applied to any projects yet"
                : "Check back later for new opportunities",
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
    final hasApplied = appliedProjectIds.contains(project.id);
    final proposalCount = ref
        .read(proposalCountProvider.notifier)
        .getCount(project.id);
    final isExpanded = expandedDescriptions[project.id] ?? false;

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

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.description,
                style: AppTextStyles.bodySmall(
                  fontSize: 13.sp,
                  color: AppColors.primaryTextHeading,
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
                      style: AppTextStyles.bodyMedium(
                        fontSize: 13.sp,
                        color: AppColors.primaryFreelancerBG,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: 12.h),
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
                    "Client",
                    style: AppTextStyles.bodySmall(
                      fontSize: 11.sp,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10.r,
                        backgroundColor: AppColors.primaryElement.withValues(
                          alpha: 0.2,
                        ),
                        child: Text(
                          project.client.name.isNotEmpty
                              ? project.client.name[0].toUpperCase()
                              : "C",
                          style: AppTextStyles.bodyMedium(
                            fontSize: 10.sp,
                            color: AppColors.primaryElement,
                          ),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        project.client.name,
                        style: AppTextStyles.bodyMedium(fontSize: 13.sp),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14.sp,
                  color: AppColors.primaryTextHeading,
                ),
                SizedBox(width: 4.w),
                Text(
                  getRelativeTime(project.deadline),
                  style: AppTextStyles.bodySmall(
                    color: AppColors.primaryTextHeading,
                  ),
                ),
                SizedBox(width: 16.w),
                Icon(
                  Icons.people_outline,
                  size: 14.sp,
                  color: proposalCount > 5
                      ? Colors.orange
                      : AppColors.primaryTextHeading,
                ),
                SizedBox(width: 4.w),
                Text(
                  proposalCount > 0
                      ? "$proposalCount Proposals"
                      : "No proposals",
                  style: AppTextStyles.bodySmall(
                    color: proposalCount > 5
                        ? Colors.orange
                        : proposalCount > 0
                        ? AppColors.primaryFreelancerBG
                        : AppColors.primaryTextHeading,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          if (project.milestones.isNotEmpty)
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppColors.primaryFreelancerBG.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: AppColors.primaryFreelancerBG.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 14.sp,
                    color: AppColors.primaryFreelancerBG,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    "${project.milestones.length} Milestones",
                    style: AppTextStyles.bodyMedium(
                      fontSize: 12.sp,
                      color: AppColors.primaryFreelancerBG,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: hasApplied
                ? OutlinedButton.icon(
                    onPressed: null,
                    icon: Icon(Icons.check_circle, size: 18.sp),
                    label: Text(
                      "Applied",
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      side: BorderSide(color: Colors.grey.shade400),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: () => showApplyDialog(project),
                    icon: Icon(Icons.send, size: 18.sp),
                    label: Text(
                      "Apply Now",
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryFreelancerBG,
                      foregroundColor: AppColors.primaryBackground,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
