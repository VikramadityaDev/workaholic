class Project {
  final int id;
  final String title;
  final String description;
  final String category;
  final double budget;
  final String deadline;
  final Client client;
  final Freelancer? freelancer;
  final String status;
  final List<Milestone> milestones;

  Project({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.budget,
    required this.deadline,
    required this.client,
    this.freelancer,
    required this.status,
    required this.milestones,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      budget: (json['budget'] ?? 0).toDouble(),
      deadline: json['deadline'] ?? '',
      client: Client.fromJson(json['client'] ?? {}),
      freelancer: json['freelancer'] != null
          ? Freelancer.fromJson(json['freelancer'])
          : null,
      status: json['status'] ?? 'CREATED',
      milestones: (json['milestones'] as List? ?? [])
          .map((m) => Milestone.fromJson(m))
          .toList(),
    );
  }
}

class Client {
  final int id;
  final String name;
  final String email;
  final String role;
  final double rating;
  final int totalReviews;
  final String? phoneNumber;

  Client({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.phoneNumber,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'CLIENT',
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      phoneNumber: json['phoneNumber'],
    );
  }
}

class Freelancer {
  final int id;
  final String name;
  final String email;
  final double rating;
  final int totalReviews;
  final String role;
  final String? phoneNumber;

  Freelancer({
    required this.id,
    required this.name,
    required this.email,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.role = 'FREELANCER',
    this.phoneNumber,
  });

  factory Freelancer.fromJson(Map<String, dynamic> json) {
    return Freelancer(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      role: json['role'] ?? 'FREELANCER',
      phoneNumber: json['phoneNumber'],
    );
  }
}

class Milestone {
  final int id;
  final String name;
  final double amount;
  final String dueDate;
  final String status;
  final String? message;

  Milestone({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.message,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      dueDate: json['dueDate'] ?? '',
      status: json['status'] ?? 'PENDING',
      message: json['message'],
    );
  }
}