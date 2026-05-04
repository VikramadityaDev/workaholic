import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

import '../../commons/utils/app_colors.dart';
import '../../commons/widgets/text_widget.dart';
import '../../models/proposal_model.dart';
import '../../models/project_model.dart';
import '../../providers/proposal_count.dart';
import '../../services/api_service.dart';
import '../authentication/auth_scr.dart';

class ProjectProposalsScreen extends ConsumerStatefulWidget {
  final Project project;

  const ProjectProposalsScreen({super.key, required this.project});

  @override
  ConsumerState<ProjectProposalsScreen> createState() =>
      _ProjectProposalsScreenState();
}

class _ProjectProposalsScreenState
    extends ConsumerState<ProjectProposalsScreen> {
  List<Proposal> proposals = [];
  bool isLoading = true;
  String? errorMessage;
  bool isServerError = false;
  Set<int> acceptedProposalIds = {};

  @override
  void initState() {
    super.initState();
    fetchProposals();
  }

  Future<void> fetchProposals() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      isServerError = false;
    });

    final result = await ApiService.fetchProjectProposals(widget.project.id);

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
        proposals = [];
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Backend error: ${result["message"]}",
            style: AppTextStyles.bodyMedium(
              fontSize: 13.sp,
              color: AppColors.primaryElement,
            ),
          ),
          backgroundColor: AppColors.warningBg,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: "Retry",
            textColor: AppColors.primaryBackground,
            onPressed: fetchProposals,
          ),
        ),
      );
      return;
    }

    if (result["success"]) {
      List<Proposal> loaded = (result["data"] as List)
          .map((json) => Proposal.fromJson(json))
          .toList();

      for (int i = 0; i < loaded.length; i++) {
        if (loaded[i].status == "ACCEPTED") {
          final detailResult = await ApiService.getFreelancerDetails(
            freelancerId: loaded[i].freelancerId,
          );
          if (detailResult["success"] == true) {
            final phone = detailResult["data"]["phoneNumber"];
            loaded[i] = loaded[i].copyWith(phoneNumber: phone);
          }
        }
      }
      if (!mounted) return;
      setState(() {
        proposals = loaded;
        isLoading = false;
      });
      ref
          .read(proposalCountProvider.notifier)
          .updateCount(widget.project.id, proposals.length);
    } else {
      setState(() {
        errorMessage = result["message"];
        isLoading = false;
      });
    }
  }

  Future<void> acceptProposal(Proposal proposal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text("Accept Proposal", style: AppTextStyles.bodyMedium()),
        content: Text(
          "Are you sure you want to accept ${proposal.name}'s proposal?",
          style: AppTextStyles.bodySmall(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: AppTextStyles.bodySmall()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              "Accept",
              style: AppTextStyles.bodySmall(
                color: AppColors.primaryElementStatus,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await ApiService.acceptProposal(proposal.id);

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
      // Fetch phone using freelancerId
      String? phone;
      final detailResult = await ApiService.getFreelancerDetails(
        freelancerId: proposal.freelancerId,
      );
      if (detailResult["success"] == true) {
        phone = detailResult["data"]["phoneNumber"];
      }

      // Update locally — no fetchProposals() to avoid wiping phone
      setState(() {
        final idx = proposals.indexWhere((p) => p.id == proposal.id);
        if (idx != -1) {
          proposals[idx] = proposals[idx].copyWith(
            status: "ACCEPTED",
            phoneNumber: phone,
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result["message"],
            style: AppTextStyles.bodyMedium(
              fontSize: 13.sp,
              color: AppColors.primaryElement,
            ),
          ),
          backgroundColor: AppColors.primaryElementStatus,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result["message"],
            style: AppTextStyles.bodyMedium(
              fontSize: 13.sp,
              color: AppColors.primaryElement,
            ),
          ),
          backgroundColor: AppColors.primaryErrorBg,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.primaryElement,
        elevation: 0,
        title: Text(
          "Proposals",
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
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            color: AppColors.primaryBackground,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.project.title,
                  style: AppTextStyles.bodyLarge(fontSize: 16.sp),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    SvgPicture.asset(
                      AppIcons.rupee,
                      width: 12.w,
                      height: 12.h,
                      colorFilter: ColorFilter.mode(
                        AppColors.primaryElement,
                        BlendMode.srcIn,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      NumberFormat('#,###').format(widget.project.budget),
                      style: AppTextStyles.bodyMedium(
                        color: AppColors.primaryElement,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Icon(
                      Icons.people_outline,
                      size: 16.sp,
                      color: AppColors.primaryTextHeading,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      "${proposals.length} Proposals",
                      style: AppTextStyles.bodySmall(
                        color: AppColors.primaryTextHeading,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Proposals List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : isServerError
                ? serverErrorState()
                : errorMessage != null
                ? errorState()
                : proposals.isEmpty
                ? emptyState()
                : RefreshIndicator(
                    onRefresh: fetchProposals,
                    child: ListView.builder(
                      padding: EdgeInsets.all(16.w),
                      itemCount: proposals.length,
                      itemBuilder: (context, index) {
                        return proposalCard(proposals[index]);
                      },
                    ),
                  ),
          ),
        ],
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
            Icon(Icons.cloud_off, size: 64.sp, color: AppColors.warningBg),
            SizedBox(height: 20.h),
            Text("Server Error", style: AppTextStyles.titleLarge()),
            SizedBox(height: 12.h),
            Text(
              errorMessage ?? "Unable to load proposals",
              style: AppTextStyles.bodyMedium(),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: fetchProposals,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryElement,
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
          Text(errorMessage!, style: AppTextStyles.bodyMedium()),
          SizedBox(height: 16.h),
          ElevatedButton.icon(
            onPressed: fetchProposals,
            icon: const Icon(Icons.refresh),
            label: const Text("Retry"),
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
              Icons.inbox_outlined,
              size: 64.sp,
              color: AppColors.primaryElement,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            "No Proposals Yet",
            style: AppTextStyles.titleLarge(fontSize: 18.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            "Freelancers haven't submitted proposals yet",
            style: AppTextStyles.bodyMedium(
              color: AppColors.primaryTextHeading,
            ),
          ),
        ],
      ),
    );
  }

  Widget proposalCard(Proposal proposal) {
    final isAccepted = proposal.status == "ACCEPTED";
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: isAccepted
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
          // Freelancer Info
          Row(
            children: [
              CircleAvatar(
                radius: 28.r,
                backgroundColor: AppColors.primaryElement.withValues(
                  alpha: 0.2,
                ),
                child: Text(
                  proposal.name.isNotEmpty
                      ? proposal.name[0].toUpperCase()
                      : "F",
                  style: AppTextStyles.titleLarge(
                    fontSize: 24.sp,
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
                      proposal.name,
                      style: AppTextStyles.bodyLarge(fontSize: 16.sp),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 16.sp,
                          color: AppColors.notificationBg,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          proposal.rating.toStringAsFixed(1),
                          style: AppTextStyles.bodyMedium(
                            fontSize: 13.sp,
                            color: AppColors.primaryTextHeading,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor(
                              proposal.status,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            proposal.status,
                            style: AppTextStyles.bodySmall(
                              fontSize: 10.sp,
                              color: statusColor(proposal.status),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isAccepted)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryElementStatus.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14.sp,
                        color: AppColors.primaryElementStatus,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        "Accepted",
                        style: AppTextStyles.bodySmall(
                          color: AppColors.primaryElementStatus,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          SizedBox(height: 16.h),
          if (isAccepted && proposal.phoneNumber != null) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.phone,
                    color: Colors.green.shade700,
                    size: 20.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Contact Freelancer",
                          style: AppTextStyles.bodySmall(
                            fontSize: 11.sp,
                            color: AppColors.primaryTextHeading,
                          ),
                        ),
                        Text(
                          proposal.phoneNumber!,
                          style: AppTextStyles.bodyMedium(
                            fontSize: 14.sp,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy, size: 18.sp),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: proposal.phoneNumber!),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Phone number copied"),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
          // Proposal Description/Cover Letter
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.article_outlined,
                      size: 16.sp,
                      color: AppColors.primaryElement,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      "Cover Letter",
                      style: AppTextStyles.bodyMedium(
                        fontSize: 12.sp,
                        color: AppColors.primaryElement,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  proposal.description,
                  style: AppTextStyles.bodyMedium(
                    fontSize: 13.sp,
                    color: AppColors.primaryText,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // Accept Button
          if (!isAccepted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => acceptProposal(proposal),
                icon: Icon(
                  Icons.check,
                  size: 18.sp,
                  color: AppColors.primaryBackground,
                ),
                label: Text(
                  "Accept Proposal",
                  style: AppTextStyles.bodyMedium(
                    fontSize: 14.sp,
                    color: AppColors.primaryBackground,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryElement,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
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

  Color statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPLIED':
        return AppColors.warningBg;
      case 'ACCEPTED':
        return AppColors.primaryElementStatus;
      case 'REJECTED':
        return AppColors.primaryErrorBg;
      default:
        return AppColors.primaryTextHeading;
    }
  }
}
