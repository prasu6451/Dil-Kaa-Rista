import 'dart:io';
import '../../../core/services/api_service.dart';
import '../../profile_creation/models/profile_model.dart';

class AuthUser {
  final String id;
  final String email;
  final String fullName;
  final String gender;

  AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.gender,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      gender: json['gender']?.toString() ?? 'male',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'gender': gender,
  };

  Map<String, dynamic>? get userMetadata => {
    'full_name': fullName,
    'gender': gender,
  };
}

class AuthResponse {
  final AuthUser? user;
  final ProfileModel? profile;
  final String? error;

  AuthResponse({this.user, this.profile, this.error});
}

class AuthController {
  final _api = ApiService.instance;

  /// Get current auth user
  AuthUser? get currentUser {
    final u = _api.currentUser;
    if (u == null) return null;
    return AuthUser.fromJson(u);
  }

  /// Check auth state
  bool get isLoggedIn => _api.isAuthenticated;

  /// Sign Up with Email and Password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String gender,
  }) async {
    try {
      final res = await _api.register(
        email: email,
        password: password,
        fullName: fullName,
        gender: gender,
      );
      final user = res['user'] != null ? AuthUser.fromJson(res['user'] as Map<String, dynamic>) : null;
      final profile = res['profile'] != null ? ProfileModel.fromJson(res['profile'] as Map<String, dynamic>) : null;
      return AuthResponse(user: user, profile: profile);
    } catch (e) {
      return AuthResponse(error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Sign In with Email and Password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _api.login(email: email, password: password);
      final user = res['user'] != null ? AuthUser.fromJson(res['user'] as Map<String, dynamic>) : null;
      final profile = res['profile'] != null ? ProfileModel.fromJson(res['profile'] as Map<String, dynamic>) : null;
      return AuthResponse(user: user, profile: profile);
    } catch (e) {
      return AuthResponse(error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Sign In with OTP
  Future<void> signInWithOtp({required String email}) async {
    // Kept for UI compatibility
  }

  /// Verify OTP
  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
  }) async {
    return AuthResponse(error: 'OTP login not enabled');
  }

  /// Sign Out
  Future<void> signOut() async {
    await _api.logout();
  }

  /// Logout alias
  Future<void> logout() async {
    await signOut();
  }

  /// Send Interest
  Future<bool> sendInterest({required String receiverId, bool isPremium = false}) async {
    return await _api.sendInterest(receiverId: receiverId, isPremium: isPremium);
  }

  /// Fetch Current User Profile
  Future<ProfileModel?> getCurrentProfile() async {
    return await _api.getMyProfile();
  }


  /// Update Profile Details
  Future<void> saveProfile(ProfileModel profile) async {
    await _api.updateProfile(profile);
  }

  /// Upload Profile Photo to Django Backend Media Storage
  Future<String?> uploadProfilePhoto(File file, String userId) async {
    return await _api.uploadProfilePhoto(file);
  }
}
