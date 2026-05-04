import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'client/client_dash.dart';
import 'freelancer/freelancer_dash.dart';

class DashRouterScreen extends ConsumerWidget {
  const DashRouterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.role == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authState.role == "CLIENT") {
      return const ClientDashboard();
    } else {
      return const FreelancerDashboard();
    }
  }
}
