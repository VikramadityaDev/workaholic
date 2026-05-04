import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class ProposalCountNotifier extends Notifier<Map<int, int>> {
  final storage = const FlutterSecureStorage();

  @override
  Map<int, int> build() {
    loadCounts();
    return {};
  }

  Future<void> loadCounts() async {
    try {
      final countsString = await storage.read(key: 'proposalCounts');
      if (countsString != null) {
        final Map<String, dynamic> decoded = jsonDecode(countsString);
        state = decoded.map(
          (key, value) => MapEntry(int.parse(key), value as int),
        );
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> saveCounts() async {
    try {
      final countsMap = state.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      await storage.write(key: 'proposalCounts', value: jsonEncode(countsMap));
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void updateCount(int projectId, int count) {
    state = {...state, projectId: count};
    saveCounts();
  }

  int getCount(int projectId) {
    return state[projectId] ?? 0;
  }

  void clearCounts() {
    state = {};
    storage.delete(key: 'proposalCounts');
  }
}

final proposalCountProvider =
    NotifierProvider<ProposalCountNotifier, Map<int, int>>(() {
      return ProposalCountNotifier();
    });
