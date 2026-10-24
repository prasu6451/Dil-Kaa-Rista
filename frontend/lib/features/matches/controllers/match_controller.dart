import '../../../core/services/api_service.dart';
import '../../profile_creation/models/profile_model.dart';

class MatchFilter {
  int minAge;
  int maxAge;
  String? religion;
  String? motherTongue;
  String? maritalStatus;
  String? city;
  String? state;
  String? education;

  MatchFilter({
    this.minAge = 18,
    this.maxAge = 60,
    this.religion,
    this.motherTongue,
    this.maritalStatus,
    this.city,
    this.state,
    this.education,
  });

  bool get hasActiveFilters =>
      minAge > 18 ||
      maxAge < 60 ||
      religion != null ||
      motherTongue != null ||
      maritalStatus != null ||
      (city != null && city!.isNotEmpty) ||
      (state != null && state!.isNotEmpty) ||
      (education != null && education!.isNotEmpty);

  void reset() {
    minAge = 18;
    maxAge = 60;
    religion = null;
    motherTongue = null;
    maritalStatus = null;
    city = null;
    state = null;
    education = null;
  }
}

class MatchController {
  final _api = ApiService.instance;

  /// Fetch Matches for the current user
  Future<List<ProfileModel>> fetchMatches({
    required String currentUserId,
    String? currentGender,
    MatchFilter? filter,
  }) async {
    try {
      String? targetGender;
      final safeGender = (currentGender ?? '').trim().toLowerCase();
      if (safeGender == 'male') {
        targetGender = 'female';
      } else if (safeGender == 'female') {
        targetGender = 'male';
      }

      return await _api.fetchMatches(
        gender: targetGender,
        minAge: filter?.minAge,
        maxAge: filter?.maxAge,
        religion: filter?.religion,
        motherTongue: filter?.motherTongue,
        maritalStatus: filter?.maritalStatus,
        state: filter?.state,
        city: filter?.city,
      );
    } catch (e) {
      return [];
    }
  }

  /// Send Interest to a candidate
  Future<bool> sendInterest({
    required String senderId,
    required String receiverId,
  }) async {
    return await _api.sendInterest(receiverId: receiverId);
  }

  /// Check status of match request between two users
  Future<String?> getInterestStatus({
    required String currentUserId,
    required String otherUserId,
  }) async {
    return await _api.getInterestStatus(otherUserId);
  }

  /// Fetch Requests (Received and Sent)
  Future<List<Map<String, dynamic>>> fetchRequests({
    required String currentUserId,
    required bool isReceived,
  }) async {
    return await _api.fetchRequests(isReceived: isReceived);
  }

  /// Respond to Request (Accept / Decline)
  Future<bool> respondToRequest({
    required String requestId,
    required String newStatus,
  }) async {
    return await _api.respondToRequest(requestId: requestId, newStatus: newStatus);
  }
}
