import 'package:escrowflow/screens/freelancer/profile_setup.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import '../../commons/utils/app_colors.dart';
import '../../commons/widgets/text_widget.dart';
import '../../models/profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../authentication/auth_scr.dart';

class ProfileViewScreen extends ConsumerStatefulWidget {
  final int? freelancerId;
  const ProfileViewScreen({super.key, this.freelancerId});

  @override
  _ProfileViewScreenState createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends ConsumerState<ProfileViewScreen> {
  Profile? profile;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final userId = widget.freelancerId ??
        int.tryParse(await ApiService.tokenStore.read(key: 'id') ?? '0');

    if (userId == null || userId == 0) {
      setState(() {
        errorMessage = "User ID not found";
        isLoading = false;
      });
      return;
    }

    final result = widget.freelancerId != null
        ? await ApiService.getFreelancerDetails(freelancerId: widget.freelancerId!)
        : await ApiService.getProfile();


    if (!mounted) return;
    if (result["requiresLogin"] == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
      return;
    }

    if (result["success"] && result["hasProfile"] == true) {
      setState(() {
        profile = Profile.fromJson(result["data"]);
        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = result["message"];
        isLoading = false;
      });
    }
  }

  Future<void> showRatingDialog() async {
    int selectedRating = 0;

    final result = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            "Rate Freelancer",
            style: AppTextStyles.bodyLarge(),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "How was your experience with ${profile?.user.name}?",
                style: AppTextStyles.bodyMedium(),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedRating = index + 1;
                      });
                    },
                    child: Icon(
                      index < selectedRating ? Icons.star : Icons.star_border,
                      size: 40.sp,
                      color: Colors.amber,
                    ),
                  );
                }),
              ),
              SizedBox(height: 8.h),
              if (selectedRating > 0)
                Text(
                  "$selectedRating ${selectedRating == 1 ? 'Star' : 'Stars'}",
                  style: AppTextStyles.bodyMedium(
                    fontSize: 14.sp,
                    color: AppColors.primaryTextHeading,
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: AppTextStyles.bodyMedium()),
            ),
            ElevatedButton(
              onPressed: selectedRating > 0
                  ? () => Navigator.pop(context, selectedRating)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryElement,
              ),
              child: Text(
                "Submit",
                style: AppTextStyles.bodyMedium(
                  color: AppColors.primaryBackground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (result != null && result > 0) {
      await submitRating(result);
    }
  }

  Future<void> submitRating(int rating) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryElement),
      ),
    );
    final result = await ApiService.giveRating(
      freelancerId: widget.freelancerId!,
      rating: rating,
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
        ),
      );
      fetchProfile();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["message"]),
          backgroundColor: AppColors.primaryErrorBg,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isOwnProfile = widget.freelancerId == null;
    final isClient = authState.role == 'CLIENT';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.primaryFreelancerBG,
        elevation: 0,
        title: Text(
          isOwnProfile ? "My Profile" : "Freelancer Profile",
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
        actions: [
          if (!isOwnProfile && isClient)
            IconButton(
              icon: Icon(
                Icons.star_rate,
                color: AppColors.primaryBackground,
                size: 24.sp,
              ),
              onPressed: showRatingDialog,
            ),
          if (isOwnProfile)
            IconButton(
              icon: Icon(
                Icons.edit,
                color: AppColors.primaryBackground,
                size: 24.sp,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfileSetupScreen(),
                  ),
                ).then((_) => fetchProfile());
              },
            ),
        ],
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryFreelancerBG,
        ),
      )
          : errorMessage != null
          ? Center(
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
            ElevatedButton(
              onPressed: fetchProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryFreelancerBG,
              ),
              child: Text("Retry"),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: fetchProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              // Profile Header
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
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50.r,
                      backgroundColor: AppColors.primaryBackground,
                      child: Text(
                        profile!.user.name.isNotEmpty
                            ? profile!.user.name[0].toUpperCase()
                            : "U",
                        style: TextStyle(
                          color: AppColors.primaryFreelancerBG,
                          fontSize: 36.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      profile!.user.name,
                      style: AppTextStyles.titleLarge(
                        fontSize: 24.sp,
                        color: AppColors.primaryBackground,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 20.sp,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          "${profile!.user.rating.toStringAsFixed(1)} (${profile!.user.totalReviews} reviews)",
                          style: AppTextStyles.bodyMedium(
                            color: AppColors.primaryBackground,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Contact Info
              infoCard(
                icon: Icons.email,
                title: "Email",
                content: profile!.user.email,
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(text: profile!.user.email),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Email copied to clipboard"),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              if (profile!.user.phoneNumber != null &&
                  profile!.user.phoneNumber!.isNotEmpty)
                infoCard(
                  icon: Icons.phone,
                  title: "Phone",
                  content: profile!.user.phoneNumber!,
                  onTap: () {
                    Clipboard.setData(
                      ClipboardData(text: profile!.user.phoneNumber!),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Phone copied to clipboard"),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),

              infoCard(
                icon: Icons.work,
                title: "Role",
                content: profile!.user.role,
              ),

              // Bio
              if (profile!.bio.isNotEmpty) ...[
                SizedBox(height: 24.h),
                sectionCard(
                  title: "About",
                  icon: Icons.person_outline,
                  content: profile!.bio,
                ),
              ],

              // Skills
              if (profile!.skills.isNotEmpty) ...[
                SizedBox(height: 16.h),
                sectionCard(
                  title: "Skills",
                  icon: Icons.lightbulb_outline,
                  content: profile!.skills,
                ),
              ],

              // Education
              if (profile!.education.isNotEmpty) ...[
                SizedBox(height: 16.h),
                sectionCard(
                  title: "Education",
                  icon: Icons.school_outlined,
                  content: profile!.education,
                ),
              ],

              SizedBox(height: 80.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget infoCard({
    required IconData icon,
    required String title,
    required String content,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.primaryBackground,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppColors.primaryFreelancerBG.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                icon,
                color: AppColors.primaryFreelancerBG,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodySmall(
                      fontSize: 12.sp,
                      color: AppColors.primaryTextHeading,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    content,
                    style: AppTextStyles.bodyMedium(fontSize: 14.sp),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.copy,
                size: 18.sp,
                color: AppColors.primaryTextHeading,
              ),
          ],
        ),
      ),
    );
  }

  Widget sectionCard({
    required String title,
    required IconData icon,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppColors.primaryFreelancerBG,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                title,
                style: AppTextStyles.bodyLarge(fontSize: 16.sp),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            content,
            style: AppTextStyles.bodyMedium(fontSize: 14.sp),
          ),
        ],
      ),
    );
  }

  Widget buildSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
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
              Icon(icon, color: AppColors.primaryFreelancerBG, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                title,
                style: AppTextStyles.bodyLarge(
                  fontSize: 16.sp,
                  color: AppColors.primaryFreelancerBG,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            content,
            style: AppTextStyles.bodyMedium(
              fontSize: 14.sp,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
