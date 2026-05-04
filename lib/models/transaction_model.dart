class Transaction {
  final String id;
  final String type;
  final double amount;
  final String description;
  final String? projectName;
  final DateTime timestamp;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    this.projectName,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'description': description,
      'projectName': projectName,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      type: json['type'],
      amount: json['amount'],
      description: json['description'],
      projectName: json['projectName'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}