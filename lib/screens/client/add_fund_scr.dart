import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../commons/utils/app_colors.dart';
import '../../commons/widgets/text_widget.dart';
import '../../providers/notification_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../services/notification_service.dart';

class AddFundsScreen extends ConsumerStatefulWidget {
  const AddFundsScreen({super.key});

  @override
  ConsumerState<AddFundsScreen> createState() => _AddFundsScreenState();
}

class _AddFundsScreenState extends ConsumerState<AddFundsScreen> {
  final formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  late Razorpay razorpay;
  bool isProcessing = false;

  static const String razorpayKeyId = "your_razorpay_key";
  final List<double> quickAmounts = [500, 1000, 2000, 5000, 10000];

  @override
  void initState() {
    super.initState();
    razorpay = Razorpay();
    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccess);
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentError);
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, handleExternalWallet);
  }

  @override
  void dispose() {
    razorpay.clear();
    amountController.dispose();
    super.dispose();
  }

  void handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() {
      isProcessing = true;
    });
    final amount = double.tryParse(amountController.text) ?? 0;
    final success = await ref.read(walletProvider.notifier).addFunds(amount);

    if (!mounted) return;

    setState(() {
      isProcessing = false;
    });

    if (success) {
      await NotificationService.notifyFundsAdded(amount: amount);
      await ref.read(transactionProvider.notifier).addCredit(amount);
      await ref.read(notificationProvider.notifier).refresh();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("₹${amount.toStringAsFixed(2)} added successfully!"),
          backgroundColor: AppColors.primaryElementStatus,
          duration: const Duration(seconds: 3),
        ),
      );

      // Navigate back
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Payment successful but failed to update wallet. Please contact support.",
          ),
          backgroundColor: AppColors.warningBg,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  void handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Payment failed: ${response.message}"),
        backgroundColor: AppColors.primaryErrorBg,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("External wallet selected: ${response.walletName}"),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openRazorpayCheckout() {
    if (!formKey.currentState!.validate()) return;

    final amount = double.tryParse(amountController.text) ?? 0;

    if (amount < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Minimum amount is ₹10"),
          backgroundColor: AppColors.warningBg,
        ),
      );
      return;
    }

    final amountInPaise = (amount * 100).toInt();

    var options = {
      'key': razorpayKeyId,
      'amount': amountInPaise,
      'name': 'Workaholic',
      'description': 'Add Funds to Wallet',
      'prefill': {'contact': '', 'email': ''},
      'theme': {'color': '#6366F1'},
    };

    try {
      razorpay.open(options);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error opening payment: $e"),
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
          "Add Funds",
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
      body: isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primaryElement),
                  SizedBox(height: 16),
                  Text("Processing payment..."),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Card
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: 24.sp,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              "Add money to your wallet to hire freelancers and manage projects",
                              style: AppTextStyles.bodySmall(
                                fontSize: 13.sp,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 32.h),

                    // Amount Field
                    Text(
                      "Enter Amount",
                      style: AppTextStyles.bodyLarge(fontSize: 16.sp),
                    ),
                    SizedBox(height: 12.h),
                    TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "0.00",
                        hintStyle: AppTextStyles.bodyMedium(
                          color: AppColors.primaryTextHeading,
                        ),
                        prefixIcon: Padding(
                          padding: EdgeInsets.all(16.w),
                          child: Text(
                            "₹",
                            style: AppTextStyles.bodyMedium(fontSize: 16.sp),
                          ),
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
                            color: AppColors.primaryElement,
                            width: 2,
                          ),
                        ),
                      ),
                      style: AppTextStyles.bodyMedium(fontSize: 14.sp),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter amount";
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return "Please enter valid amount";
                        }
                        if (amount < 10) {
                          return "Minimum amount is ₹10";
                        }
                        if (amount > 100000) {
                          return "Maximum amount is ₹1,00,000";
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 24.h),

                    // Quick Amount Buttons
                    Text(
                      "Quick Select",
                      style: AppTextStyles.bodyMedium(fontSize: 14.sp),
                    ),
                    SizedBox(height: 12.h),
                    Wrap(
                      spacing: 12.w,
                      runSpacing: 12.h,
                      children: quickAmounts.map((amount) {
                        return GestureDetector(
                          onTap: () {
                            amountController.text = amount.toStringAsFixed(0);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 12.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBackground,
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: AppColors.primaryElement.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Text(
                              "₹${amount.toStringAsFixed(0)}",
                              style: AppTextStyles.bodyMedium(
                                fontSize: 14.sp,
                                color: AppColors.primaryElement,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    SizedBox(height: 40.h),

                    // Payment Button
                    SizedBox(
                      width: double.infinity,
                      height: 52.h,
                      child: ElevatedButton(
                        onPressed: _openRazorpayCheckout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryElement,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.payment,
                              color: AppColors.primaryBackground,
                              size: 24.sp,
                            ),
                            SizedBox(width: 12.w),
                            Text(
                              "Proceed to Pay",
                              style: AppTextStyles.bodyLarge(
                                fontSize: 16.sp,
                                color: AppColors.primaryBackground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // Payment Methods Info
                    Center(
                      child: Column(
                        children: [
                          Text(
                            "Secure payment powered by",
                            style: AppTextStyles.bodySmall(
                              fontSize: 12.sp,
                              color: AppColors.primaryTextHeading,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            "Razorpay",
                            style: AppTextStyles.bodyLarge(
                              fontSize: 16.sp,
                              color: AppColors.primaryElement,
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
