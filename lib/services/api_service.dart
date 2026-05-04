import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl =
      "https://your-api-url.com";

  static const tokenStore = FlutterSecureStorage();

  /// REGISTER USER
  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
    required String role,
    required String phoneNumber,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/auth/register");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": password,
          "role": role,
          "phoneNumber": phoneNumber,
        }),
      );
      if (response.body.isEmpty) {
        return {"success": false, "message": "Empty response from server"};
      }
      final data = jsonDecode(response.body);
      if (data["success"] == true) {
        return {
          "success": true,
          "data": data["data"],
          "message": data["message"] ?? "Registration successful",
        };
      } else {
        return {
          "success": false,
          "message": data["message"] ?? "Registration failed",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Error: ${e.toString()}"};
    }
  }

  /// LOGIN USER
  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/auth/login");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );
      if (response.body.isEmpty) {
        return {"success": false, "message": "Empty response from server"};
      }
      final data = jsonDecode(response.body);
      if (data["success"] == true) {
        return {
          "success": true,
          "data": data["data"],
          "message": data["message"] ?? "Login successful",
        };
      } else {
        String errorMessage = "Login failed";
        if (data["message"] != null) {
          errorMessage = data["message"];
        } else if (data["data"] != null && data["data"] is String) {
          errorMessage = data["data"];
        } else if (data["error"] != null) {
          errorMessage = data["error"];
        }
        return {"success": false, "message": errorMessage};
      }
    } catch (e) {
      return {"success": false, "message": "Error: ${e.toString()}"};
    }
  }

  /// CREATE PROJECT
  static Future<Map<String, dynamic>> createProject({
    required String title,
    required String description,
    required String category,
    required double budget,
    required String deadline,
    required List<Map<String, dynamic>> milestones,
  }) async {
    try {
      final token = await tokenStore.read(key: 'token');
      if (token == null) {
        return {"success": false, "message": "No token found. Please login."};
      }
      final url = Uri.parse("$baseUrl/projects/create");
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "title": title,
          "description": description,
          "category": category,
          "budget": budget,
          "deadline": deadline,
          "milestones": milestones,
        }),
      );
      if (response.statusCode == 401) {
        return {
          "success": false,
          "message": "Session expired. Please login again.",
          "requiresLogin": true,
        };
      }
      if (response.body.isEmpty) {
        return {"success": false, "message": "Empty response from server"};
      }
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data["success"] == true) {
          return {
            "success": true,
            "data": data["data"],
            "message": data["message"] ?? "Project created successfully",
          };
        }
      }
      String errorMessage = "Failed to create project";
      if (data["message"] != null) {
        errorMessage = data["message"];
      } else if (data["data"] != null && data["data"] is String) {
        errorMessage = data["data"];
      } else if (data["error"] != null) {
        errorMessage = data["error"];
      }
      return {"success": false, "message": errorMessage};
    } catch (e) {
      return {"success": false, "message": "Error: ${e.toString()}"};
    }
  }

  /// FETCH USER PROJECTS
  static Future<Map<String, dynamic>> fetchUserProjects({String? status}) async {
    try {
      final token = await tokenStore.read(key: 'token');
      if (token == null) {
        return {"success": false, "message": "No token found. Please login."};
      }
      String url = "$baseUrl/projects/my";
      if (status != null && status.isNotEmpty) {
        url += "?status=$status";
      }
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 401) {
        return {
          "success": false,
          "message": "Session expired. Please login again.",
          "requiresLogin": true,
        };
      }
      if (response.body.isEmpty) {
        return {"success": false, "message": "Empty response from server"};
      }
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (data["success"] == true) {
          return {
            "success": true,
            "data": data["data"] ?? [],
            "message": data["message"] ?? "Projects fetched successfully",
          };
        }
      }
      if (response.statusCode == 500) {
        String errorMessage = "Server error";
        if (data["data"] is String) {
          errorMessage = data["data"];
        } else if (data["message"] != null) {
          errorMessage = data["message"];
        }
        return {
          "success": true,
          "data": [],
          "message": errorMessage,
          "isServerError": true,
        };
      }
      String errorMessage = "Failed to fetch projects";
      if (data["message"] != null) {
        errorMessage = data["message"];
      } else if (data["data"] is String) {
        errorMessage = data["data"];
      }
      return {"success": false, "message": errorMessage};
    } catch (e) {
      return {
        "success": false,
        "message": "Network error: ${e.toString()}",
      };
    }
  }

  /// FETCH AVAILABLE PROJECTS (For Freelancers)
  static Future<Map<String, dynamic>> fetchAvailableProjects({String? status}) async {
    try {
      final token = await tokenStore.read(key: 'token');
      if (token == null) {
        return {"success": false, "message": "No token found. Please login."};
      }
      String url = "$baseUrl/projects/available";
      if (status != null && status.isNotEmpty) {
        url += "?status=$status";
      }
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 401) {
        return {
          "success": false,
          "message": "Session expired. Please login again.",
          "requiresLogin": true,
        };
      }
      if (response.body.isEmpty) {
        return {"success": false, "message": "Empty response from server"};
      }
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (data["success"] == true) {
          return {
            "success": true,
            "data": data["data"] ?? [],
            "message": data["message"] ?? "Projects fetched successfully",
          };
        }
      }
      if (response.statusCode == 500) {
        String errorMessage = "Server error";
        if (data["data"] is String) {
          errorMessage = data["data"];
        } else if (data["message"] != null) {
          errorMessage = data["message"];
        }
        return {
          "success": true,
          "data": [],
          "message": errorMessage,
          "isServerError": true,
        };
      }
      String errorMessage = "Failed to fetch projects";
      if (data["message"] != null) {
        errorMessage = data["message"];
      } else if (data["data"] is String) {
        errorMessage = data["data"];
      }
      return {"success": false, "message": errorMessage};
    } catch (e) {
      return {
        "success": false,
        "message": "Network error: ${e.toString()}",
      };
    }
  }

  /// APPLY TO PROJECT
  static Future<Map<String, dynamic>> applyToProject({
    required int projectId,
    required String description,
  }) async {
    try {
      final token = await tokenStore.read(key: 'token');
      if (token == null) {
        return {"success": false, "message": "No token found. Please login."};
      }
      final url = Uri.parse("$baseUrl/applications/apply/$projectId");
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "description": description,
        }),
      );
      if (response.statusCode == 401) {
        return {
          "success": false,
          "message": "Session expired. Please login again.",
          "requiresLogin": true,
        };
      }
      if (response.body.isEmpty) {
        return {"success": false, "message": "Empty response from server"};
      }
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data["success"] == true) {
          return {
            "success": true,
            "data": data["data"],
            "message": data["message"] ?? "Application submitted successfully",
          };
        }
      }
      String errorMessage = "Failed to submit application";
      if (data["message"] != null) {
        errorMessage = data["message"];
      } else if (data["data"] is String) {
        errorMessage = data["data"];
      }
      return {"success": false, "message": errorMessage};
    } catch (e) {
      return {
        "success": false,
        "message": "Error: ${e.toString()}",
      };
    }
  }

  /// FETCH PROPOSALS FOR A PROJECT
  static Future<Map<String, dynamic>> fetchProjectProposals(int projectId) async {
    try {
      final token = await tokenStore.read(key: 'token');
      if (token == null) {
        return {"success": false, "message": "No token found. Please login."};
      }
      final url = Uri.parse("$baseUrl/applications/proposal/$projectId");
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 401) {
        return {
          "success": false,
          "message": "Session expired. Please login again.",
          "requiresLogin": true,
        };
      }
      if (response.body.isEmpty) {
        return {"success": false, "message": "Empty response from server"};
      }
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (data["success"] == true) {
          return {
            "success": true,
            "data": data["data"] ?? [],
            "message": data["message"] ?? "Proposals fetched successfully",
          };
        }
      }
      if (response.statusCode == 500) {
        return {
          "success": true,
          "data": [],
          "message": data["data"] ?? "Server error",
          "isServerError": true,
        };
      }
      String errorMessage = "Failed to fetch proposals";
      if (data["message"] != null) {
        errorMessage = data["message"];
      } else if (data["data"] is String) {
        errorMessage = data["data"];
      }
      return {"success": false, "message": errorMessage};
    } catch (e) {
      return {"success": false, "message": "Error: ${e.toString()}"};
    }
  }

  /// ACCEPT PROPOSAL
  static Future<Map<String, dynamic>> acceptProposal(int proposalId) async {
    try {
      final token = await tokenStore.read(key: 'token');
      if (token == null) {
        return {"success": false, "message": "No token found. Please login."};
      }
      final url = Uri.parse("$baseUrl/applications/proposal/$proposalId/accept");
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 401) {
        return {
          "success": false,
          "message": "Session expired. Please login again.",
          "requiresLogin": true,
        };
      }
      if (response.body.isEmpty) {
        return {"success": false, "message": "Empty response from server"};
      }
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data["success"] == true) {
          return {
            "success": true,
            "data": data["data"],
            "message": data["message"] ?? "Proposal accepted successfully",
          };
        }
      }
      String errorMessage = "Failed to accept proposal";
      if (data["message"] != null) {
        errorMessage = data["message"];
      } else if (data["data"] is String) {
        errorMessage = data["data"];
      }
      return {"success": false, "message": errorMessage};
    } catch (e) {
      return {"success": false, "message": "Error: ${e.toString()}"};
    }
  }

  /// FETCH ASSIGNED PROJECTS
  static Future<Map<String, dynamic>> fetchAssignedProjects() async {
    try {
      final token = await tokenStore.read(key: 'token');
      if (token == null) {
        return {"success": false, "message": "No token found. Please login."};
      }
      final url = Uri.parse("$baseUrl/projects/assigned");
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 401) {
        return {
          "success": false,
          "message": "Session expired. Please login again.",
          "requiresLogin": true,
        };
      }
      if (response.body.isEmpty) {
        return {"success": false, "message": "Empty response from server"};
      }
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (data["success"] == true) {
          return {
            "success": true,
            "data": data["data"] ?? [],
            "message": data["message"] ?? "Assigned projects fetched successfully",
          };
        }
      }
      if (response.statusCode == 500) {
        return {
          "success": true,
          "data": [],
          "message": data["data"] ?? "Server error",
          "isServerError": true,
        };
      }
      String errorMessage = "Failed to fetch assigned projects";
      if (data["message"] != null) {
        errorMessage = data["message"];
      } else if (data["data"] is String) {
        errorMessage = data["data"];
      }
      return {"success": false, "message": errorMessage};
    } catch (e) {
      return {"success": false, "message": "Error: ${e.toString()}"};
    }
  }

  /// UPDATE PROFILE
  static Future<Map<String, dynamic>> updateProfile({
    required String bio,
    required String skills,
    required String education,
  }) async {
    try {
      final token = await tokenStore.read(key: 'token');
      if (token == null) {
        return {"success": false, "message": "No token found. Please login."};
      }
      final url = Uri.parse("$baseUrl/profile");
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "bio": bio,
          "skills": skills,
          "education": education,
        }),
      );
      if (response.statusCode == 401) {
        return {
          "success": false,
          "message": "Session expired. Please login again.",
          "requiresLogin": true,
        };
      }
      if (response.body.isEmpty) {
        return {"success": false, "message": "Empty response from server"};
      }
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data["success"] == true) {
          return {
            "success": true,
            "data": data["data"],
            "message": data["message"] ?? "Profile updated successfully",
          };
        }
      }
      String errorMessage = "Failed to update profile";
      if (data["message"] != null) {
        errorMessage = data["message"];
      } else if (data["data"] is String) {
        errorMessage = data["data"];
      } else if (data["error"] != null) {
        errorMessage = data["error"];
      }
      return {"success": false, "message": errorMessage};
    } catch (e) {
      return {"success": false, "message": "Error: ${e.toString()}"};
    }
  }

  /// GET PROFILE
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await tokenStore.read(key: 'token');
      if (token == null) {
        return {"success": false, "message": "No token found. Please login."};
      }
      final userId = await tokenStore.read(key: 'id');
      if (userId == null) {
        return {"success": false, "message": "User ID not found. Please login."};
      }
      final url = Uri.parse("$baseUrl/profile/$userId");
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 401) {
        return {
          "success": false,
          "message": "Session expired. Please login again.",
          "requiresLogin": true,
        };
      }
      if (response.body.isEmpty) {
        return {"success": false, "message": "Empty response from server"};
      }
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (data["success"] == true) {
          return {
            "success": true,
            "data": data["data"],
            "message": data["message"] ?? "Profile fetched successfully",
            "hasProfile": true,
          };
        }
      }
      if (response.statusCode == 404) {
        return {
          "success": false,
          "message": "Profile not found",
          "hasProfile": false,
        };
      }
      String errorMessage = "Failed to fetch profile";
      if (data["message"] != null) {
        errorMessage = data["message"];
      }
      return {
        "success": false,
        "message": errorMessage,
        "hasProfile": false,
      };
    } catch (e) {
      return {
        "success": false,
        "message": "Error: ${e.toString()}",
        "hasProfile": false,
      };
    }
  }

  /// SUBMIT MILESTONE/PHASE
  static Future<Map<String, dynamic>> submitMilestone({
    required int milestoneId,
    required String message,
  }) async {
    try {
      final token = await tokenStore.read(key: 'token');
      if (token == null) {
        return {"success": false, "message": "No token found. Please login."};
      }
      final url = Uri.parse("$baseUrl/phases/submit/$milestoneId");
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "message": message,
        }),
      );
      if (response.statusCode == 401) {
        return {
          "success": false,
          "message": "Session expired. Please login again.",
          "requiresLogin": true,
        };
      }
      if (response.body.isEmpty) {
        return {"success": false, "message": "Empty response from server"};
      }
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data["success"] == true) {
          return {
            "success": true,
            "data": data["data"],
            "message": data["message"] ?? "Milestone submitted successfully",
          };
        }
      }
      String errorMessage = "Failed to submit milestone";
      if (data["message"] != null) {
        errorMessage = data["message"];
      } else if (data["data"] is String) {
        errorMessage = data["data"];
      } else if (data["error"] != null) {
        errorMessage = data["error"];
      }
      return {"success": false, "message": errorMessage};
    } catch (e) {
      return {"success": false, "message": "Error: ${e.toString()}"};
    }
  }

  /// APPROVE MILESTONE
  static Future<Map<String, dynamic>> approveMilestone({
    required int milestoneId,
  }) async {
    try {
      final token = await tokenStore.read(key: 'token');
      if (token == null) {
        return {"success": false, "message": "No token found. Please login."};
      }
      final url = Uri.parse("$baseUrl/phases/approve/$milestoneId");
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 401) {
        return {
          "success": false,
          "message": "Session expired. Please login again.",
          "requiresLogin": true,
        };
      }
      if (response.body.isEmpty) {
        return {"success": false, "message": "Empty response from server"};
      }
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data["success"] == true) {
          return {
            "success": true,
            "data": data["data"],
            "message": data["message"] ?? "Milestone approved successfully",
          };
        }
      }
      String errorMessage = "Failed to approve milestone";
      if (data["message"] != null) {
        errorMessage = data["message"];
      } else if (data["data"] is String) {
        errorMessage = data["data"];
      } else if (data["error"] != null) {
        errorMessage = data["error"];
      }
      return {"success": false, "message": errorMessage};
    } catch (e) {
      return {"success": false, "message": "Error: ${e.toString()}"};
    }
  }

  /// REJECT MILESTONE
  static Future<Map<String, dynamic>> rejectMilestone({
    required int milestoneId,
  }) async {
    try {
      final token = await tokenStore.read(key: 'token');
      if (token == null) {
        return {"success": false, "message": "No token found. Please login."};
      }
      final url = Uri.parse("$baseUrl/phases/reject/$milestoneId");
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 401) {
        return {
          "success": false,
          "message": "Session expired. Please login again.",
          "requiresLogin": true,
        };
      }
      if (response.body.isEmpty) {
        return {"success": false, "message": "Empty response from server"};
      }
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data["success"] == true) {
          return {
            "success": true,
            "data": data["data"],
            "message": data["message"] ?? "Milestone rejected successfully",
          };
        }
      }
      String errorMessage = "Failed to reject milestone";
      if (data["message"] != null) {
        errorMessage = data["message"];
      } else if (data["data"] is String) {
        errorMessage = data["data"];
      }
      return {"success": false, "message": errorMessage};
    } catch (e) {
      return {"success": false, "message": "Error: ${e.toString()}"};
    }
  }

  /// GET WALLET BALANCE
  static Future<Map<String, dynamic>> getWalletBalance() async {
    try {
      final token = await tokenStore.read(key: 'token');
      if (token == null) {
        return {"success": false, "message": "No token found. Please login."};
      }
      final url = Uri.parse("$baseUrl/wallet");
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 401) {
        return {
          "success": false,
          "message": "Session expired. Please login again.",
          "requiresLogin": true,
        };
      }
      if (response.body.isEmpty) {
        return {"success": false, "message": "Empty response from server"};
      }
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (data["success"] == true) {
          return {
            "success": true,
            "data": data["data"],
            "message": data["message"] ?? "Balance fetched successfully",
          };
        }
      }
      String errorMessage = "Failed to fetch balance";
      if (data["message"] != null) {
        errorMessage = data["message"];
      }
      return {"success": false, "message": errorMessage};
    } catch (e) {
      return {"success": false, "message": "Error: ${e.toString()}"};
    }
  }

  /// ADD FUNDS TO WALLET
  static Future<Map<String, dynamic>> addFundsToWallet({
    required double amount,
  }) async {
    try {
      final token = await tokenStore.read(key: 'token');
      if (token == null) {
        return {"success": false, "message": "No token found. Please login."};
      }
      final url = Uri.parse("$baseUrl/wallet/add");
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "amount": amount,
        }),
      );
      if (response.statusCode == 401) {
        return {
          "success": false,
          "message": "Session expired. Please login again.",
          "requiresLogin": true,
        };
      }
      if (response.body.isEmpty) {
        return {"success": false, "message": "Empty response from server"};
      }
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data["success"] == true) {
          return {
            "success": true,
            "data": data["data"],
            "message": data["message"] ?? "Funds added successfully",
          };
        }
      }
      String errorMessage = "Failed to add funds";
      if (data["message"] != null) {
        errorMessage = data["message"];
      } else if (data["data"] is String) {
        errorMessage = data["data"];
      }
      return {"success": false, "message": errorMessage};
    } catch (e) {
      return {"success": false, "message": "Error: ${e.toString()}"};
    }
  }

  /// COMPLETE PROJECT
  static Future<Map<String, dynamic>> completeProject({
    required int projectId,
  }) async {
    try {
      final token = await tokenStore.read(key: 'token');
      if (token == null) {
        return {"success": false, "message": "No token found. Please login."};
      }
      final url = Uri.parse("$baseUrl/phases/project/complete/$projectId");
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 401) {
        return {
          "success": false,
          "message": "Session expired. Please login again.",
          "requiresLogin": true,
        };
      }
      if (response.body.isEmpty) {
        return {"success": false, "message": "Empty response from server"};
      }
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data["success"] == true) {
          return {
            "success": true,
            "data": data["data"],
            "message": data["message"] ?? "Project completed successfully",
          };
        }
      }
      String errorMessage = "Failed to complete project";
      if (data["message"] != null) {
        errorMessage = data["message"];
      } else if (data["data"] is String) {
        errorMessage = data["data"];
      }
      return {"success": false, "message": errorMessage};
    } catch (e) {
      return {"success": false, "message": "Error: ${e.toString()}"};
    }
  }

  /// GIVE RATING TO FREELANCER
  static Future<Map<String, dynamic>> giveRating({
    required int freelancerId,
    required int rating,
  }) async {
    try {
      final token = await tokenStore.read(key: 'token');
      if (token == null) {
        return {"success": false, "message": "No token found. Please login."};
      }
      final url = Uri.parse("$baseUrl/rating/give/$freelancerId");
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "rating": rating,
        }),
      );
      if (response.statusCode == 401) {
        return {
          "success": false,
          "message": "Session expired. Please login again.",
          "requiresLogin": true,
        };
      }
      if (response.body.isEmpty) {
        return {"success": false, "message": "Empty response from server"};
      }
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data["success"] == true) {
          return {
            "success": true,
            "data": data["data"],
            "message": data["message"] ?? "Rating submitted successfully",
          };
        }
      }
      String errorMessage = "Failed to submit rating";
      if (data["message"] != null) {
        errorMessage = data["message"];
      }
      return {"success": false, "message": errorMessage};
    } catch (e) {
      return {"success": false, "message": "Error: ${e.toString()}"};
    }
  }

  /// GET FREELANCER DETAILS
  static Future<Map<String, dynamic>> getFreelancerDetails({
    required int freelancerId,
  }) async {
    try {
      final token = await tokenStore.read(key: 'token');
      if (token == null) {
        return {"success": false, "message": "No token found. Please login."};
      }
      final url = Uri.parse("$baseUrl/freelancer/$freelancerId");
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 401) {
        return {
          "success": false,
          "message": "Session expired. Please login again.",
          "requiresLogin": true,
        };
      }
      if (response.body.isEmpty) {
        return {"success": false, "message": "Empty response from server"};
      }
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (data["success"] == true) {
          return {
            "success": true,
            "data": data["data"],
          };
        }
      }
      String errorMessage = "Failed to fetch freelancer details";
      if (data["message"] != null) {
        errorMessage = data["message"];
      }
      return {"success": false, "message": errorMessage};
    } catch (e) {
      return {"success": false, "message": "Error: ${e.toString()}"};
    }
  }
}