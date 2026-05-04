class Profile {
  final int id;
  final ProfileUser user;
  final String bio;
  final String skills;
  final String education;

  Profile({
    required this.id,
    required this.user,
    required this.bio,
    required this.skills,
    required this.education,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] ?? 0,
      user: ProfileUser.fromJson(json['user'] ?? {}),
      bio: json['bio'] ?? '',
      skills: json['skills'] ?? '',
      education: json['education'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'bio': bio,
      'skills': skills,
      'education': education,
    };
  }
}

class ProfileUser {
  final int id;
  final String name;
  final String email;
  final String role;
  final double rating;
  final int totalReviews;
  final String? phoneNumber;

  ProfileUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.rating,
    required this.totalReviews,
    required this.phoneNumber,
  });

  factory ProfileUser.fromJson(Map<String, dynamic> json) {
    return ProfileUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      phoneNumber: json['phoneNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'rating': rating,
      'totalReviews': totalReviews,
      'phoneNumber': phoneNumber,
    };
  }
}