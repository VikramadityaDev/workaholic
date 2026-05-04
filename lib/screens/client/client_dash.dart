import 'package:escrowflow/screens/client/post_scr.dart';
import 'package:escrowflow/screens/client/projects_scr.dart';
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
import 'add_fund_scr.dart';

class ClientDashboard extends ConsumerStatefulWidget {
  const ClientDashboard({super.key});

  @override
  ConsumerState<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends ConsumerState<ClientDashboard> {
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TransactionsScreen(isFreelancer: false),
            ),
          );
        },
        onProfileTap: () {
          Navigator.pop(context);
          // TODO: Navigate to profile
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
            gradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            balance: walletState.isLoading
                ? "Loading..."
                : "₹ ${walletState.balance.toStringAsFixed(2)}",
            bankName: "Workaholic Bank",
            accountNumber: "XXXXXXXX6249",
          ),
          // WalletCardWidget(
          //   gradient: [Color(0xFF10B981), Color(0xFF059669)],
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
                ? AppColors.primaryElement
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
                  icon: AppIcons.create,
                  label: "Create",
                  color: AppColors.primaryElement,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ClientPostScreen(),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: QuickLinkCardWidget(
                  icon: AppIcons.wallet,
                  label: "Add Fund",
                  color: AppColors.fundBg,
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddFundsScreen()),
                    );
                    if (result == true) {
                      ref.read(walletProvider.notifier).fetchBalance();
                    }
                  },
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
                        builder: (_) => const MyProjectsScreen(),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
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
                                const NotificationsScreen(isFreelancer: false),
                          ),
                        );
                      },
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8.w,
                        top: 8.h,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 5.w,
                            vertical: 2.h,
                          ),
                          constraints: BoxConstraints(
                            minWidth: 18.w,
                            minHeight: 18.h,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryErrorBg,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            unreadCount > 9 ? '9+' : unreadCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              height: 1,
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
                            const TransactionsScreen(isFreelancer: false),
                      ),
                    );
                  },
                  child: Text(
                    "View All",
                    style: AppTextStyles.bodySmall(
                      fontSize: 12.sp,
                      color: AppColors.primaryElement,
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
            icon: svgIcon(AppIcons.receipt, isActive: false),
            activeIcon: svgIcon(AppIcons.receipt, isActive: true),
            label: "Transaction",
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
                MaterialPageRoute(
                  builder: (_) => const TransactionsScreen(isFreelancer: false),
                ),
              );
              break;
            case 2:
              scaffoldKey.currentState?.openEndDrawer();
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
