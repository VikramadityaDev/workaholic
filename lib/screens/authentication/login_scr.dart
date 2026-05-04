import 'package:escrowflow/commons/widgets/text_widget.dart';
import 'package:escrowflow/commons/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../providers/auth_provider.dart';
import '../dash_scr.dart';
import '../freelancer/profile_setup.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final VoidCallback onSwitch;
  final String? prefilledEmail;

  const LoginScreen({super.key, required this.onSwitch, this.prefilledEmail});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledEmail != null && widget.prefilledEmail!.isNotEmpty) {
      emailController.text = widget.prefilledEmail!;
    }
  }

  void login() async {
    FocusScope.of(context).unfocus();
    if (!formKey.currentState!.validate()) return;

    final result = await ref
        .read(authProvider.notifier)
        .login(emailController.text.trim(), passwordController.text.trim());

    if (!mounted) return;

    if (result["success"]) {
      final role = result["role"];
      final profileCompleted = result["profileCompleted"] ?? true;
      if (role == 'FREELANCER' && !profileCompleted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DashRouterScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return Scaffold(
      backgroundColor: AppColors.primaryElement,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: isKeyboardOpen ? 0.15.sh : 0.35.sh,
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
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(28.r),
                  ),
                ),
                child: buildForm(authState),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildForm(authState) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10.h),
            Text("Login into your account", style: AppTextStyles.titleLarge()),
            SizedBox(height: 20.h),

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
                  borderRadius: BorderRadius.circular(5.r),
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
            SizedBox(height: 12.h),

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
                  borderRadius: BorderRadius.circular(5.r),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () =>
                      setState(() => isPasswordVisible = !isPasswordVisible),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Enter password";
                }
                if (value.length < 6) {
                  return "Password must be at least 6 characters";
                }
                return null;
              },
            ),
            SizedBox(height: 8.h),

            /// Error Message Display
            if (authState.error != null)
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryErrorShade,
                  borderRadius: BorderRadius.circular(5.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppColors.primaryErrorBg,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        authState.error!,
                        style: TextStyle(
                          color: AppColors.primaryErrorBg,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 20.h),

            /// Login Button
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: authState.isLoading ? null : login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryElement,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.r),
                  ),
                ),
                child: authState.isLoading
                    ? SizedBox(
                        height: 20.h,
                        width: 20.w,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        "Login",
                        style: AppTextStyles.bodyLarge(
                          color: AppColors.primaryBackground,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 12.h),

            /// Switch to Register
            Center(
              child: TextButton(
                onPressed: widget.onSwitch,
                child: Text.rich(
                  TextSpan(
                    text: "Don't have an account? ",
                    style: AppTextStyles.bodyMedium(
                      color: AppColors.primaryTextHeading,
                    ),
                    children: [
                      TextSpan(
                        text: "Register",
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
    );
  }
}
