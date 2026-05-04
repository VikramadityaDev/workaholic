import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

class TransactionNotifier extends Notifier<List<Transaction>> {
  @override
  List<Transaction> build() {
    loadTransactions();
    return [];
  }

  void reset() {
    state = [];
  }

  Future<void> loadTransactions() async {
    final transactions = await TransactionService.getTransactions();
    state = transactions;
  }

  Future<void> refresh() async {
    await loadTransactions();
  }

  Future<void> addCredit(double amount) async {
    await TransactionService.addCreditTransaction(amount);
    await refresh();
  }

  Future<void> addDebit({
    required double amount,
    required String projectName,
    String? milestoneName,
  }) async {
    await TransactionService.addDebitTransaction(
      amount: amount,
      projectName: projectName,
      milestoneName: milestoneName,
    );
    await refresh();
  }
}

final transactionProvider =
    NotifierProvider<TransactionNotifier, List<Transaction>>(
      TransactionNotifier.new,
    );
