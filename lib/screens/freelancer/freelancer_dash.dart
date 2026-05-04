import 'package:escrowflow/screens/freelancer/profile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import '../../commons/notification_scr.dart';
import '../../commons/widgets/text_widget.dart';
import '../../commons/utils/app_colors.dart';
import '../../commons/widgets/drawer_widget.dart';
import '../../commons/transaction_scr.dart';
import '../../commons/widgets/transactions_widget.dart';
import '../../commons/widgets/quick_link_widget.dart';
import '../../commons/widgets/wallet_widget.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/wallet_provider.dart';
import '../authentication/auth_scr.dart';
import 'assigned_scr.dart';
import 'available_projects.dart';
import 'earning_scr.dart';

class FreelancerDashboard extends ConsumerStatefulWidget {
  const FreelancerDashboard({super.key});

  @override
  ConsumerState<FreelancerDashboard> createState() =>
      _FreelancerDashboardState();
}

class _FreelancerDashboardState extends ConsumerState<FreelancerDashboard> {
  int currentCardIndex = 0;
  int currentNavIndex = 0;
  final PageController pageController = PageController();
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(walletProvider.notifier).fetchBalance();
      ref.read(notificationProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  Future<void> handleLogout() async {
    Navigator.pop(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text("Logout", style: AppTextStyles.bodyLarge()),
        content: const Text("Are you sure you want to logout?"),
        contentTextStyle: AppTextStyles.bodyMedium(),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: AppTextStyles.bodyMedium()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              "Logout",
              style: AppTextStyles.bodyMedium(color: AppColors.primaryErrorBg),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    await ref.read(authProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final walletState = ref.watch(walletProvider);

    ref.listen(authProvider, (prev, next) {
      if (prev?.role != null && next.role == null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (route) => false,
        );
      }
    });

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.grey.shade50,

      endDrawer: CustomDrawer(
        userName: authState.name ?? "User",
        userEmail: authState.email ?? "",
        userRole: authState.role ?? "",
        onHomeTap: () => Navigator.pop(context),
        onTransactionsTap: () {
          Navigator.pop(context);
          // TODO: Navigate to transactions
        },
        onProfileTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileViewScreen()),
          );
        },
        onSettingsTap: () {
          Navigator.pop(context);
          // TODO: Navigate to settings
        },
        onLogoutTap: handleLogout,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),
              customHeader(context, authState),

              SizedBox(height: 20.h),
              walletCarousel(walletState),

              SizedBox(height: 12.h),
              carouselIndicator(),

              SizedBox(height: 24.h),
              quickLinks(),

              SizedBox(height: 32.h),
              recentTransactions(),

              SizedBox(height: 80.h),
            ],
          ),
        ),
      ),
      bottomNavigationBar: customBottomNavigation(),
    );
  }

  Widget customHeader(BuildContext context, AuthState authState) {
    final userName = authState.name ?? "User";
    final userRole = authState.role ?? "";

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Hi, $userName", style: AppTextStyles.titleLarge()),
              SizedBox(height: 4.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryElement.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.primaryElement.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_user,
                      size: 14.sp,
                      color: AppColors.primaryElement,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      userRole.toUpperCase(),
                      style: AppTextStyles.badgeHeading(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => scaffoldKey.currentState?.openEndDrawer(),
            child: CircleAvatar(
              radius: 24.r,
              backgroundColor: AppColors.primaryElement.withValues(alpha: 0.1),
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : "U",
                style: TextStyle(
                  color: AppColors.primaryElement,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget walletCarousel(WalletState walletState) {
    return SizedBox(
      height: 200.h,
      child: PageView(
        controller: pageController,
        onPageChanged: (index) => setState(() => currentCardIndex = index),
        children: [
          WalletCardWidget(
            gradient: const [Color(0xFF10B981), Color(0xFF059669)],
            balance: walletState.isLoading
                ? "Loading..."
                : "₹ ${walletState.balance.toStringAsFixed(2)}",
            bankName: "Workaholic Bank",
            accountNumber: "XXXXXXXX5671",
          ),
          // const WalletCardWidget(
          //   gradient: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          //   balance: "₹ 0.00",
          //   bankName: "Workaholic Bank",
          //   accountNumber: "XXXXXXXXXXXX",
          // ),
        ],
      ),
    );
  }

  Widget carouselIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (index) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          width: currentCardIndex == index ? 24.w : 8.w,
          height: 8.h,
          decoration: BoxDecoration(
            color: currentCardIndex == index
                ? const Color(0xFF6366F1)
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4.r),
          ),
        );
      }),
    );
  }

  Widget quickLinks() {
    final unreadCount = ref.watch(notificationProvider).unreadCount;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Quick Link", style: AppTextStyles.bodyLarge()),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: QuickLinkCardWidget(
                  icon: AppIcons.findWork,
                  label: "Find Work",
                  color: AppColors.primaryElement,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AvailableProjectsScreen(),
                      ),
                    );
                  },
                ),
              ),
              //SizedBox(width: 16.w),
              Expanded(
                child: QuickLinkCardWidget(
                  icon: AppIcons.earning,
                  label: "Withdraw",
                  color: AppColors.fundBg,
                  onTap: () {},
                ),
              ),
              Expanded(
                child: QuickLinkCardWidget(
                  icon: AppIcons.projects,
                  label: "Projects",
                  color: AppColors.projectBg,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AssignedProjectsScreen(),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    QuickLinkCardWidget(
                      icon: AppIcons.notification,
                      label: "Notification",
                      color: AppColors.notificationBg,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const NotificationsScreen(isFreelancer: true),
                          ),
                        );
                      },
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8.w,
                        top: 8.h,
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: AppColors.primaryErrorBg,
                            shape: BoxShape.circle,
                          ),
                          constraints: BoxConstraints(
                            minWidth: 18.w,
                            minHeight: 18.h,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : unreadCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget recentTransactions() {
    final transactions = ref.watch(transactionProvider);
    final hasTransactions = transactions.isNotEmpty;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Recent Transactions", style: AppTextStyles.bodyLarge()),
              if (hasTransactions)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const TransactionsScreen(isFreelancer: true),
                      ),
                    );
                  },
                  child: Text(
                    "View All",
                    style: AppTextStyles.bodySmall(
                      fontSize: 12.sp,
                      color: AppColors.primaryFreelancerBG,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 20.h),
          if (!hasTransactions)
            const EmptyTransactionsWidget()
          else
            TransactionListWidget(transactions: transactions, maxDisplay: 5),
        ],
      ),
    );
  }

  Widget customBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.primaryBackground,
        selectedItemColor: AppColors.primaryElement,
        unselectedItemColor: AppColors.primaryTextHeading,
        selectedFontSize: 12.sp,
        unselectedFontSize: 12.sp,
        selectedLabelStyle: AppTextStyles.bodySmall(),
        unselectedLabelStyle: AppTextStyles.bodySmall(),
        currentIndex: currentNavIndex,
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: svgIcon(AppIcons.home, isActive: false),
            activeIcon: svgIcon(AppIcons.home, isActive: true),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: svgIcon(AppIcons.earning, isActive: false),
            activeIcon: svgIcon(AppIcons.earning, isActive: true),
            label: "Earnings",
          ),
          BottomNavigationBarItem(
            icon: svgIcon(AppIcons.user, isActive: false),
            activeIcon: svgIcon(AppIcons.user, isActive: true),
            label: "Profile",
          ),
        ],
        onTap: (index) {
          setState(() => currentNavIndex = index);
          switch (index) {
            case 0:
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EarningsScreen()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileViewScreen()),
              );
              break;
          }
        },
      ),
    );
  }

  Widget svgIcon(String path, {required bool isActive}) {
    return SvgPicture.asset(
      path,
      width: 20.w,
      height: 20.h,
      colorFilter: ColorFilter.mode(
        isActive ? AppColors.primaryElement : AppColors.primaryTextHeading,
        BlendMode.srcIn,
      ),
    );
  }
}
