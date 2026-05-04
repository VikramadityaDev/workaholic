import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../freelancer/profile_setup.dart';
import 'auth_scr.dart';
import '../dash_scr.dart';

class AuthGateScreen extends ConsumerStatefulWidget {
  const AuthGateScreen({super.key});

  @override
  ConsumerState<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends ConsumerState<AuthGateScreen> {
  bool hasCheckedProfile = false;
  bool isCheckingProfile = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    if (!authState.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (authState.role == null) {
      return const AuthScreen();
    }
    if (authState.role == 'FREELANCER' &&
        !hasCheckedProfile &&
        !isCheckingProfile) {
      isCheckingProfile = true;
      return FutureBuilder<bool>(
        future: ref.read(authProvider.notifier).hasCompletedProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          hasCheckedProfile = true;
          final hasProfile = snapshot.data ?? false;
          if (!hasProfile) {
            return const ProfileSetupScreen();
          }
          return const DashRouterScreen();
        },
      );
    }
    return const DashRouterScreen();
  }
}
