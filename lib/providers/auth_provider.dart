import 'package:escrowflow/providers/transaction_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/transaction_service.dart';

class AuthState {
  final bool isLoading;
  final bool isInitialized;
  final String? error;
  final String? role;
  final String? name;
  final String? email;
  final String? id;

  const AuthState({
    this.isLoading = false,
    this.isInitialized = false,
    this.error,
    this.role,
    this.name,
    this.email,
    this.id,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isInitialized,
    String? error,
    String? role,
    String? name,
    String? email,
    String? id,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error,
      role: role,
      name: name,
      email: email,
      id: id,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  @override
  AuthState build() {
    loadSession();
    return const AuthState(isInitialized: false);
  }

  /// Load saved session when app starts
  Future<void> loadSession() async {
    final savedRole = await storage.read(key: 'role');
    final savedToken = await storage.read(key: 'token');
    final savedName = await storage.read(key: 'name');
    final savedEmail = await storage.read(key: 'email');
    final savedId = await storage.read(key: 'id');

    if (savedRole != null && savedToken != null) {
      state = state.copyWith(
        role: savedRole,
        name: savedName,
        email: savedEmail,
        id: savedId,
        isInitialized: true,
      );
    } else {
      state = state.copyWith(isInitialized: true);
    }
  }

  /// Check if freelancer has completed profile
  Future<bool> hasCompletedProfile() async {
    final role = state.role;
    if (role != 'FREELANCER') {
      return true;
    }
    final profileCompleted = await storage.read(key: 'profileCompleted');
    if (profileCompleted == 'true') {
      return true;
    }
    final result = await ApiService.getProfile();
    if (result['hasProfile'] == true) {
      await storage.write(key: 'profileCompleted', value: 'true');
      return true;
    }
    return false;
  }

  /// Mark profile as completed
  Future<void> markProfileCompleted() async {
    await storage.write(key: 'profileCompleted', value: 'true');
  }

  /// REGISTER
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String phoneNumber,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await ApiService.registerUser(
      name: name,
      email: email,
      password: password,
      role: role,
      phoneNumber: phoneNumber
    );

    if (result["success"]) {
      state = state.copyWith(isLoading: false, error: null);
      return {"success": true, "role": role, "message": result["message"]};
    } else {
      state = state.copyWith(isLoading: false, error: result["message"]);
      return {"success": false, "message": result["message"]};
    }
  }

  /// LOGIN
  Future<Map<String, dynamic>> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await ApiService.loginUser(email: email, password: password);

    if (result["success"]) {
      final userData = result["data"];

      await storage.write(key: 'token', value: userData["token"]);
      await storage.write(key: 'role', value: userData["role"]);
      await storage.write(key: 'name', value: userData["name"]);
      await storage.write(key: 'email', value: userData["email"]);
      await storage.write(key: 'id', value: userData["id"].toString());

      ref.read(transactionProvider.notifier).reset();
      await ref.read(transactionProvider.notifier).loadTransactions();

      state = state.copyWith(
        isLoading: false,
        role: userData["role"],
        name: userData["name"],
        email: userData["email"],
        id: userData["id"].toString(),
      );

      bool profileCompleted = true;
      if (userData["role"] == 'FREELANCER') {
        profileCompleted = await hasCompletedProfile();
      }

      return {
        "success": true,
        "role": userData["role"],
        "profileCompleted": profileCompleted,
        "message": result["message"],
      };
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result["message"] ?? "Login failed",
      );
      return {"success": false, "message": result["message"] ?? "Login failed"};
    }
  }

  /// LOGOUT
  Future<void> logout() async {
    state = state.copyWith(isLoading: true, error: null);
    ref.read(transactionProvider.notifier).reset();
    await storage.delete(key: 'role');
    await storage.delete(key: 'token');
    await storage.delete(key: 'name');
    await storage.delete(key: 'email');
    await storage.delete(key: 'id');
    await storage.delete(key: 'profileCompleted');

    await TransactionService.clearTransactions();
    await NotificationService.clearAll();

    state = const AuthState(isInitialized: true, isLoading: false);
  }

  Future<void> clearRegistrationData() async {
    state = state.copyWith(
      role: null,
      name: null,
      email: null,
      id: null,
      error: null,
    );
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
