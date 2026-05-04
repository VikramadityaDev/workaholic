import 'package:escrowflow/screens/authentication/register_scr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'login_scr.dart';

class AuthScreen extends ConsumerStatefulWidget {
  final String? prefilledEmail;

  const AuthScreen({super.key, this.prefilledEmail});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool isLogin = true;
  String? registeredEmail;

  void switchScreen({String? email}) {
    setState(() {
      isLogin = !isLogin;
      if (email != null) {
        registeredEmail = email;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return isLogin
        ? LoginScreen(
            onSwitch: () => switchScreen(),
            prefilledEmail: registeredEmail ?? widget.prefilledEmail,
          )
        : RegisterScreen(onSwitch: switchScreen);
  }
}
