import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../commons/utils/app_colors.dart';
import '../../commons/widgets/text_widget.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../dash_scr.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final formKey = GlobalKey<FormState>();
  final bioController = TextEditingController();
  final skillsController = TextEditingController();
  final educationController = TextEditingController();
  final storage = const FlutterSecureStorage();

  bool isLoading = false;

  @override
  void dispose() {
    bioController.dispose();
    skillsController.dispose();
    educationController.dispose();
    super.dispose();
  }

  Future<void> submitProfile() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    final result = await ApiService.updateProfile(
      bio: bioController.text.trim(),
      skills: skillsController.text.trim(),
      education: educationController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (result["success"]) {
      await ref.read(authProvider.notifier).markProfileCompleted();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["message"]),
          backgroundColor: AppColors.primaryElementStatus,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashRouterScreen()),
        (route) => false,
      );
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
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.primaryFreelancerBG,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          "Complete Your Profile",
          style: AppTextStyles.titleLarge(color: AppColors.primaryBackground),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryFreelancerBG.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 64.sp,
                      color: AppColors.primaryFreelancerBG,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      "Welcome! Let's set up your profile",
                      style: AppTextStyles.titleLarge(fontSize: 18.sp),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      "Complete your profile to start finding work opportunities",
                      style: AppTextStyles.bodyMedium(
                        fontSize: 14.sp,
                        color: AppColors.primaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),
              Text(
                "Bio *",
                style: AppTextStyles.bodyMedium(
                  fontSize: 14.sp,
                  color: AppColors.primaryText,
                ),
              ),
              SizedBox(height: 8.h),
              TextFormField(
                controller: bioController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                      "Tell us about yourself, your experience, and what makes you unique...",
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13.sp,
                  ),
                  filled: true,
                  fillColor: AppColors.primaryBackground,
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
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(
                      color: AppColors.primaryErrorBg,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(
                      color: AppColors.primaryErrorBg,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter your bio";
                  }
                  if (value.trim().length < 50) {
                    return "Bio should be at least 50 characters";
                  }
                  return null;
                },
              ),
              SizedBox(height: 24.h),
              Text(
                "Skills *",
                style: AppTextStyles.bodyMedium(
                  fontSize: 14.sp,
                  color: AppColors.primaryText,
                ),
              ),
              SizedBox(height: 8.h),
              TextFormField(
                controller: skillsController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      "e.g., Flutter, React, Node.js, UI/UX Design, Project Management",
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13.sp,
                  ),
                  filled: true,
                  fillColor: AppColors.primaryBackground,
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
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(
                      color: AppColors.primaryErrorBg,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(
                      color: AppColors.primaryErrorBg,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter your skills";
                  }
                  if (value.trim().length < 10) {
                    return "Please provide more details about your skills";
                  }
                  return null;
                },
              ),
              SizedBox(height: 24.h),
              Text(
                "Education *",
                style: AppTextStyles.bodyMedium(
                  fontSize: 14.sp,
                  color: AppColors.primaryText,
                ),
              ),
              SizedBox(height: 8.h),
              TextFormField(
                controller: educationController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      "e.g., B.Tech in Computer Science, Stanford University, 2020",
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13.sp,
                  ),
                  filled: true,
                  fillColor: AppColors.primaryBackground,
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
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(
                      color: AppColors.primaryErrorBg,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(
                      color: AppColors.primaryErrorBg,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter your education";
                  }
                  if (value.trim().length < 10) {
                    return "Please provide more details about your education";
                  }
                  return null;
                },
              ),
              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: isLoading ? null : submitProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryFreelancerBG,
                    disabledBackgroundColor: Colors.grey.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: isLoading
                      ? SizedBox(
                          height: 24.h,
                          width: 24.w,
                          child: const CircularProgressIndicator(
                            color: AppColors.primaryBackground,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          "Complete Profile",
                          style: AppTextStyles.bodyLarge(
                            fontSize: 16.sp,
                            color: AppColors.primaryBackground,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        "You can update your profile anytime from the settings",
                        style: AppTextStyles.bodySmall(
                          fontSize: 12.sp,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
