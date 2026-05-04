class Proposal {
  final int id;
  final int freelancerId;
  final String name;
  final String description;
  final double rating;
  final String status;
  final String? phoneNumber;

  Proposal({
    required this.id,
    required this.freelancerId,
    required this.name,
    required this.description,
    required this.rating,
    required this.status,
    this.phoneNumber,
  });

  factory Proposal.fromJson(Map<String, dynamic> json) {
    return Proposal(
      id: json['id'] ?? 0,
      freelancerId: json['freelancerId'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'APPLIED',
    );
  }

  Proposal copyWith({String? phoneNumber, String? status}) {
    return Proposal(
      id: id,
      freelancerId: freelancerId,
      name: name,
      description: description,
      rating: rating,
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}