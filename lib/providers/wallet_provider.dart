import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class WalletState {
  final double balance;
  final bool isLoading;
  final String? error;

  const WalletState({
    this.balance = 0.0,
    this.isLoading = false,
    this.error,
  });

  WalletState copyWith({
    double? balance,
    bool? isLoading,
    String? error,
  }) {
    return WalletState(
      balance: balance ?? this.balance,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class WalletNotifier extends Notifier<WalletState> {
  @override
  WalletState build() {
    return const WalletState();
  }

  Future<void> fetchBalance() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await ApiService.getWalletBalance();

      if (result["success"]) {
        final data = result["data"];
        final balance = (data["balance"] ?? 0).toDouble();

        state = state.copyWith(
          balance: balance,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          error: result["message"],
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<bool> addFunds(double amount) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await ApiService.addFundsToWallet(amount: amount);

    if (result["success"]) {
      await fetchBalance();
      return true;
    } else {
      state = state.copyWith(
        error: result["message"],
        isLoading: false,
      );
      return false;
    }
  }
}

final walletProvider = NotifierProvider<WalletNotifier, WalletState>(
  WalletNotifier.new,
);