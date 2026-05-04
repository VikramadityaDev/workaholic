import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/transaction_model.dart';

class TransactionService {
  static const FlutterSecureStorage storage = FlutterSecureStorage();

  static Future<String> getTransactionsKey() async {
    final userId = await storage.read(key: 'id');
    return 'local_transactions_${userId ?? 'guest'}';
  }

  static Future<String> getProcessedMilestonesKey() async {
    final userId = await storage.read(key: 'id');
    return 'processed_milestones_${userId ?? 'guest'}';
  }

  static Future<void> saveTransactions(List<Transaction> transactions) async {
    final key = await getTransactionsKey();
    final jsonList = transactions.map((t) => t.toJson()).toList();
    await storage.write(key: key, value: jsonEncode(jsonList));
  }

  static Future<List<Transaction>> getTransactions() async {
    try {
      final key = await getTransactionsKey();
      final data = await storage.read(key: key);
      if (data == null) return [];
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((json) => Transaction.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> addTransaction(Transaction transaction) async {
    final transactions = await getTransactions();
    transactions.insert(0, transaction);
    if (transactions.length > 100) {
      transactions.removeRange(100, transactions.length);
    }
    await saveTransactions(transactions);
  }

  static Future<void> addCreditTransaction(double amount, {String? projectName}) async {
    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: "CREDIT",
      amount: amount,
      description: projectName != null ? "Payment received" : "Wallet credited",
      projectName: projectName,
      timestamp: DateTime.now(),
    );
    await addTransaction(transaction);
  }

  static Future<void> addDebitTransaction({
    required double amount,
    required String projectName,
    String? milestoneName,
  }) async {
    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: "DEBIT",
      amount: amount,
      description: milestoneName != null
          ? "Payment for $milestoneName"
          : "Payment sent",
      projectName: projectName,
      timestamp: DateTime.now(),
    );
    await addTransaction(transaction);
  }

  static Future<Set<int>> getProcessedMilestones() async {
    try {
      final key = await getProcessedMilestonesKey();
      final data = await storage.read(key: key);
      if (data == null) return {};
      final List<dynamic> list = jsonDecode(data);
      return list.map((e) => e as int).toSet();
    } catch (e) {
      return {};
    }
  }

  static Future<void> markMilestoneAsProcessed(int milestoneId) async {
    final processed = await getProcessedMilestones();
    processed.add(milestoneId);
    final key = await getProcessedMilestonesKey();
    await storage.write(
      key: key,
      value: jsonEncode(processed.toList()),
    );
  }

  static Future<void> clearTransactions() async {
    final transKey = await getTransactionsKey();
    final milestonesKey = await getProcessedMilestonesKey();
    await storage.delete(key: transKey);
    await storage.delete(key: milestonesKey);
  }
}