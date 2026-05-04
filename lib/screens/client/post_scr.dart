import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import '../../commons/utils/app_colors.dart';
import '../../commons/widgets/text_widget.dart';
import '../../providers/notification_provider.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../authentication/auth_scr.dart';

class ClientPostScreen extends ConsumerStatefulWidget {
  const ClientPostScreen({super.key});

  @override
  ConsumerState<ClientPostScreen> createState() => _ClientPostScreenState();
}

class _ClientPostScreenState extends ConsumerState<ClientPostScreen> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final budgetController = TextEditingController();

  String? selectedCategory;
  DateTime? selectedDeadline;
  bool isLoading = false;

  List<MilestoneData> milestones = [MilestoneData()];

  final List<String> categories = [
    "Web Development",
    "Mobile App",
    "Design",
    "Writing",
    "Other",
  ];

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    budgetController.dispose();
    for (var milestone in milestones) {
      milestone.dispose();
    }
    super.dispose();
  }

  Future<void> pickDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryElement,
              onPrimary: AppColors.primaryBackground,
              onSurface: AppColors.primaryText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDeadline = picked;
        for (var milestone in milestones) {
          if (milestone.dueDate != null && milestone.dueDate!.isAfter(picked)) {
            milestone.dueDate = null;
          }
        }
      });
    }
  }

  Future<void> pickMilestoneDueDate(int index) async {
    final DateTime lastDate =
        selectedDeadline ?? DateTime.now().add(const Duration(days: 365));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryElement,
              onPrimary: AppColors.primaryBackground,
              onSurface: AppColors.primaryText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => milestones[index].dueDate = picked);
    }
  }

  Future<void> createProject() async {
    FocusScope.of(context).unfocus();
    if (!formKey.currentState!.validate()) return;
    if (selectedCategory == null) {
      showError("Please select a category");
      return;
    }
    if (selectedDeadline == null) {
      showError("Please select a project deadline");
      return;
    }
    if (selectedDeadline!.isBefore(
      DateTime.now().subtract(const Duration(days: 1)),
    )) {
      showError("Deadline cannot be in the past");
      return;
    }
    for (int i = 0; i < milestones.length; i++) {
      final milestone = milestones[i];
      if (milestone.nameController.text.trim().isEmpty) {
        showError("Please fill milestone name for Phase ${i + 1}");
        return;
      }
      if (milestone.amountController.text.trim().isEmpty) {
        showError("Please fill milestone amount for Phase ${i + 1}");
        return;
      }
      if (milestone.dueDate == null) {
        showError("Please select due date for Phase ${i + 1}");
        return;
      }
      if (milestone.dueDate!.isAfter(selectedDeadline!)) {
        showError(
          "Phase ${i + 1} due date cannot exceed project deadline (${DateFormat('MMM dd, yyyy').format(selectedDeadline!)})",
        );
        return;
      }
      if (milestone.dueDate!.isBefore(
        DateTime.now().subtract(const Duration(days: 1)),
      )) {
        showError("Phase ${i + 1} due date cannot be in the past");
        return;
      }
    }

    setState(() => isLoading = true);

    final milestonesData = milestones.map((m) {
      return {
        "name": m.nameController.text.trim(),
        "amount": double.parse(m.amountController.text.trim()),
        "dueDate": DateFormat('yyyy-MM-dd').format(m.dueDate!),
      };
    }).toList();

    final result = await ApiService.createProject(
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      category: selectedCategory!,
      budget: double.parse(budgetController.text.trim()),
      deadline: DateFormat('yyyy-MM-dd').format(selectedDeadline!),
      milestones: milestonesData,
    );

    setState(() => isLoading = false);

    if (!mounted) return;

    if (result["requiresLogin"] == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: const Text("Session Expired"),
          content: const Text("Your session has expired. Please login again."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (route) => false,
                );
              },
              child: const Text("Login"),
            ),
          ],
        ),
      );
      return;
    }
    if (result["success"]) {
      await NotificationService.notifyProjectCreated(
        projectTitle: titleController.text.trim(),
        projectId: result["data"]["id"],
      );
      ref.read(notificationProvider.notifier).refresh();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["message"]),
          backgroundColor: AppColors.primaryElementStatus,
        ),
      );
      Navigator.pop(context);
    } else {
      showError(result["message"]);
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTextStyles.bodySmall()),
        backgroundColor: AppColors.primaryErrorBg,
        duration: const Duration(seconds: 3),
      ),
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
          "Create Project",
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
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sectionHeader("Basic Info"),
              SizedBox(height: 16.h),

              // Project Title
              customLabel("Project Title", required: true),
              SizedBox(height: 8.h),
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: "e.g. Build me a mobile app",
                  hintStyle: AppTextStyles.bodyMedium(
                    color: AppColors.primaryTextHeading.withValues(alpha: 0.7),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: AppColors.primaryTextHeading.withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: AppColors.primaryTextHeading.withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: AppColors.primaryErrorBg.withValues(alpha: 1),
                    ),
                  ),
                  errorStyle: AppTextStyles.bodyMedium(
                    fontSize: 11,
                    color: AppColors.primaryErrorBg.withValues(alpha: 1),
                  ),
                ),
                validator: (value) =>
                    (value?.isEmpty ?? true) ? "Enter project title" : null,
              ),
              SizedBox(height: 16.h),

              // Category
              customLabel("Category", required: true),
              SizedBox(height: 8.h),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                hint: Text(
                  "Select category",
                  style: AppTextStyles.bodyMedium(
                    color: AppColors.primaryTextHeading.withValues(alpha: 0.7),
                  ),
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.primaryBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: AppColors.primaryTextHeading.withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: AppColors.primaryTextHeading.withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ),
                ),
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category, style: AppTextStyles.bodyMedium()),
                  );
                }).toList(),
                onChanged: (value) => setState(() => selectedCategory = value),
              ),
              SizedBox(height: 16.h),

              // Description
              customLabel("Project Description", required: true),
              SizedBox(height: 8.h),
              TextFormField(
                controller: descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: "Describe what you need...",
                  hintStyle: AppTextStyles.bodyMedium(
                    color: AppColors.primaryTextHeading.withValues(alpha: 0.7),
                  ),
                  filled: true,
                  fillColor: AppColors.primaryBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: AppColors.primaryTextHeading.withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: AppColors.primaryTextHeading.withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: AppColors.primaryErrorBg.withValues(alpha: 1),
                    ),
                  ),
                  errorStyle: AppTextStyles.bodyMedium(
                    fontSize: 11,
                    color: AppColors.primaryErrorBg.withValues(alpha: 1),
                  ),
                ),
                validator: (value) =>
                    (value?.isEmpty ?? true) ? "Enter description" : null,
              ),
              SizedBox(height: 16.h),

              // Budget
              customLabel("Budget", required: true),
              SizedBox(height: 8.h),
              TextFormField(
                controller: budgetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Enter amount",
                  hintStyle: AppTextStyles.bodyMedium(
                    color: AppColors.primaryTextHeading.withValues(alpha: 0.7),
                  ),
                  prefixText: "₹ ",
                  filled: true,
                  fillColor: AppColors.primaryBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: AppColors.primaryTextHeading.withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: AppColors.primaryTextHeading.withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: AppColors.primaryErrorBg.withValues(alpha: 1),
                    ),
                  ),
                  errorStyle: AppTextStyles.bodyMedium(
                    fontSize: 11,
                    color: AppColors.primaryErrorBg.withValues(alpha: 1),
                  ),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return "Enter budget";
                  if (double.tryParse(value!) == null) {
                    return "Enter valid amount";
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),

              // deadline
              customLabel("Deadline", required: true),
              SizedBox(height: 8.h),
              InkWell(
                onTap: pickDeadline,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBackground,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.primaryTextHeading.withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: AppColors.primaryElement,
                        size: 20.sp,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        selectedDeadline == null
                            ? "Select Date"
                            : DateFormat(
                                'MMM dd, yyyy',
                              ).format(selectedDeadline!),
                        style: AppTextStyles.bodyMedium(
                          color: selectedDeadline == null
                              ? AppColors.primaryTextHeading.withValues(
                                  alpha: 0.7,
                                )
                              : AppColors.primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32.h),

              // milestones section
              sectionHeader("Milestones"),
              SizedBox(height: 16.h),

              // warning if no deadline selected
              if (selectedDeadline == null)
                Container(
                  padding: EdgeInsets.all(12.w),
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange.shade700,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          "Please select project deadline first",
                          style: AppTextStyles.bodySmall(
                            color: Colors.orange.shade700,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              ...List.generate(milestones.length, (index) {
                return milestoneCard(index);
              }),

              SizedBox(height: 16.h),

              // Add Milestone Button
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    milestones.add(MilestoneData());
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text("Add Another Phase"),
                style: OutlinedButton.styleFrom(
                  textStyle: AppTextStyles.bodyMedium(
                    color: AppColors.primaryElement,
                  ),
                  foregroundColor: AppColors.primaryElement,
                  side: BorderSide(color: AppColors.primaryElement),
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 8.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),

              SizedBox(height: 32.h),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: isLoading ? null : createProject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryElement,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: isLoading
                      ? SizedBox(
                          height: 20.h,
                          width: 20.w,
                          child: const CircularProgressIndicator(
                            color: AppColors.primaryBackground,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          "Create Project",
                          style: AppTextStyles.bodyLarge(
                            color: AppColors.primaryBackground,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget sectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4.w,
          height: 20.h,
          decoration: BoxDecoration(
            color: AppColors.primaryElement,
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        SizedBox(width: 8.w),
        Text(title, style: AppTextStyles.titleLarge(fontSize: 18.sp)),
        SizedBox(width: 8.w),
        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
      ],
    );
  }

  Widget customLabel(String text, {bool required = false}) {
    return Row(
      children: [
        Text(text, style: AppTextStyles.bodyMedium()),
        if (required)
          Text(
            " *",
            style: AppTextStyles.bodyMedium(
              color: AppColors.primaryErrorBg,
              fontSize: 14.sp,
            ),
          ),
      ],
    );
  }

  Widget milestoneCard(int index) {
    final milestone = milestones[index];
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.primaryTextHeading.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Phase ${index + 1}",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryElement,
                ),
              ),
              if (milestones.length > 1)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: AppColors.primaryErrorBg,
                    size: 20.sp,
                  ),
                  onPressed: () {
                    setState(() {
                      milestone.dispose();
                      milestones.removeAt(index);
                    });
                  },
                ),
            ],
          ),
          SizedBox(height: 12.h),
          Text("Name:", style: AppTextStyles.bodyMedium(fontSize: 13.sp)),
          SizedBox(height: 6.h),
          TextFormField(
            controller: milestone.nameController,
            decoration: InputDecoration(
              hintText: "e.g. UI Design",
              hintStyle: TextStyle(
                color: AppColors.primaryTextHeading.withValues(alpha: 0.7),
                fontSize: 14.sp,
              ),
              filled: true,
              fillColor: AppColors.primaryTextHeading.withValues(alpha: 0.04),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 12.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(
                  color: AppColors.primaryTextHeading.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(
                  color: AppColors.primaryTextHeading.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            "Amount:",
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 6.h),
          TextFormField(
            controller: milestone.amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "500",
              hintStyle: TextStyle(
                color: AppColors.primaryTextHeading.withValues(alpha: 0.7),
                fontSize: 14.sp,
              ),
              prefixText: "₹ ",
              filled: true,
              fillColor: AppColors.primaryTextHeading.withValues(alpha: 0.04),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 12.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(
                  color: AppColors.primaryTextHeading.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(
                  color: AppColors.primaryTextHeading.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),

          Text(
            "Due:",
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 6.h),
          InkWell(
            onTap: selectedDeadline == null
                ? () {
                    showError("Please select project deadline first");
                  }
                : () => pickMilestoneDueDate(index),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: AppColors.primaryElement,
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    milestone.dueDate == null
                        ? "Date"
                        : DateFormat('MMM dd, yyyy').format(milestone.dueDate!),
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: milestone.dueDate == null
                          ? Colors.grey.shade500
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class to manage milestone data
class MilestoneData {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  DateTime? dueDate;

  void dispose() {
    nameController.dispose();
    amountController.dispose();
  }
}
