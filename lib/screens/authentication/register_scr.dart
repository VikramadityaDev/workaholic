import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../commons/widgets/text_widget.dart';
import '../../commons/utils/app_colors.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final Function({String? email}) onSwitch;

  const RegisterScreen({super.key, required this.onSwitch});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();

  String? selectedRole;
  bool isPasswordVisible = false;

  void register() async {
    FocusScope.of(context).unfocus();
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please select a role",
            style: AppTextStyles.bodySmall(),
          ),
        ),
      );
      return;
    }

    final email = emailController.text.trim();
    final role = selectedRole!;

    final result = await ref
        .read(authProvider.notifier)
        .register(
          name: nameController.text.trim(),
          email: email,
          password: passwordController.text.trim(),
          role: role,
          phoneNumber: phoneController.text.trim(),
        );

    if (!mounted) return;

    if (result["success"]) {
      if (role == 'FREELANCER') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    "Registration successful! Please complete your profile.",
                    style: AppTextStyles.bodyMedium(
                      fontSize: 13.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.primaryElementStatus,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            margin: EdgeInsets.all(16.w),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          widget.onSwitch(email: email);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    "Registration successful! Please login with your credentials.",
                    style: AppTextStyles.bodyMedium(
                      fontSize: 13.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.primaryElementStatus,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            margin: EdgeInsets.all(16.w),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          widget.onSwitch(email: email);
        }
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    ref.listen(authProvider, (prev, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.primaryErrorBg,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            margin: EdgeInsets.all(16.w),
          ),
        );
      }
    });
    return Scaffold(
      backgroundColor: AppColors.primaryElement,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: isKeyboardOpen ? 0.12.sh : 0.25.sh,
              child: Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isKeyboardOpen ? 0.0 : 1.0,
                  child: Text(
                    "Workaholic",
                    style: AppTextStyles.displayLarge(),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                width: 1.sw,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryBackground,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(28.r),
                  ),
                ),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Create your account",
                          style: AppTextStyles.titleLarge(),
                        ),
                        SizedBox(height: 20.h),

                        /// Name Field
                        TextFormField(
                          controller: nameController,
                          decoration: InputDecoration(
                            hintText: "Full Name",
                            hintStyle: AppTextStyles.bodyMedium(
                              color: AppColors.primaryTextHeading,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Enter your name";
                            }
                            if (value.length < 2) {
                              return "Name must be at least 2 characters";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),

                        /// Email Field
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: "Email",
                            hintStyle: AppTextStyles.bodyMedium(
                              color: AppColors.primaryTextHeading,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Enter email";
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value)) {
                              return "Enter valid email";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: "Phone Number",
                            hintStyle: AppTextStyles.bodyMedium(
                              color: AppColors.primaryTextHeading,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Enter phone number";
                            }
                            if (value.length < 10) {
                              return "Enter valid phone number";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),
                        /// Password Field
                        TextFormField(
                          controller: passwordController,
                          obscureText: !isPasswordVisible,
                          decoration: InputDecoration(
                            hintText: "Password",
                            hintStyle: AppTextStyles.bodyMedium(
                              color: AppColors.primaryTextHeading,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () => setState(
                                () => isPasswordVisible = !isPasswordVisible,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Enter password";
                            }
                            if (value.length < 6) {
                              return "Password must be at least 6 characters";
                            }
                            if (value.length > 12) {
                              return "Password must be less than 12 characters";
                            }
                            final hasUppercase = value.contains(
                              RegExp(r'[A-Z]'),
                            );
                            final hasLowercase = value.contains(
                              RegExp(r'[a-z]'),
                            );
                            final hasDigit = value.contains(RegExp(r'[0-9]'));
                            final hasSpecialChar = value.contains(
                              RegExp(r'[@$!%*?&]'),
                            );

                            if (!hasUppercase ||
                                !hasLowercase ||
                                !hasDigit ||
                                !hasSpecialChar) {
                              return "Must include A-Z, a-z, 0-9 & special char";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),

                        /// Select Role Dropdown
                        DropdownButtonFormField<String>(
                          initialValue: selectedRole,
                          dropdownColor: AppColors.primaryDisableShade,
                          hint: Text(
                            "Select Role",
                            style: AppTextStyles.bodyMedium(
                              color: AppColors.primaryTextHeading,
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: "CLIENT",
                              child: Text(
                                "Client",
                                style: AppTextStyles.bodyMedium(),
                              ),
                            ),
                            DropdownMenuItem(
                              value: "FREELANCER",
                              child: Text(
                                "Freelancer",
                                style: AppTextStyles.bodyMedium(),
                              ),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => selectedRole = value),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          validator: (value) =>
                              value == null ? "Select a role" : null,
                        ),
                        SizedBox(height: 28.h),

                        /// Register Button
                        SizedBox(
                          width: double.infinity,
                          height: 50.h,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryElement,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            onPressed: authState.isLoading ? null : register,
                            child: authState.isLoading
                                ? SizedBox(
                                    height: 20.h,
                                    width: 20.w,
                                    child: const CircularProgressIndicator(
                                      color: AppColors.primaryBackground,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    "Register",
                                    style: AppTextStyles.bodyLarge(
                                      color: AppColors.primaryBackground,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: 20.h),

                        /// Switch to Login
                        Center(
                          child: TextButton(
                            onPressed: () => widget.onSwitch(),
                            child: Text.rich(
                              TextSpan(
                                text: "Already have an account? ",
                                style: AppTextStyles.bodyMedium(
                                  color: AppColors.primaryTextHeading,
                                ),
                                children: [
                                  TextSpan(
                                    text: "Login",
                                    style: AppTextStyles.bodyMedium(
                                      color: AppColors.primaryElement,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}