import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/profile_creation/models/profile_model.dart';
import '../../features/chat/models/message_model.dart';

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  static const String _tokenKey = 'django_auth_token';
  static const String _userKey = 'django_auth_user';

  String get baseUrl {
    final envUrl = dotenv.env['DJANGO_API_URL'];
    String url = (envUrl != null && envUrl.isNotEmpty) ? envUrl : 'http://127.0.0.1:8000/api';

    // In Android Emulator, localhost/127.0.0.1 must be routed to 10.0.2.2 (host machine)
    if (!kIsWeb && Platform.isAndroid && url.contains('127.0.0.1')) {
      url = url.replaceAll('127.0.0.1', '10.0.2.2');
    }
    return url;
  }

  String? _authToken;
  Map<String, dynamic>? _currentUser;

  String? get token => _authToken;
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isAuthenticated => _authToken != null;

  /// Initialize and load saved session token
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString(_tokenKey);
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        try {
          _currentUser = jsonDecode(userJson) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('Error decoding cached user: $e');
        }
      }
    } catch (e) {
      debugPrint('SharedPreferences init fallback: $e');
    }
  }

  Map<String, String> _headers({bool requiresAuth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (requiresAuth && _authToken != null) {
      headers['Authorization'] = 'Token $_authToken';
    }
    return headers;
  }

  /// Sign Up with Email and Password
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String gender,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register/');
    final response = await http.post(
      url,
      headers: _headers(requiresAuth: false),
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'password': password,
        'full_name': fullName.trim(),
        'gender': gender.trim().toLowerCase(),
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (data['token'] != null) {
        await _saveAuthData(data['token'], data['user']);
      }
      return data;
    } else {
      final msg = data['error'] ?? data['detail'] ?? 'Registration failed';
      throw Exception(msg);
    }
  }

  /// Sign In with Email and Password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/login/');
    final response = await http.post(
      url,
      headers: _headers(requiresAuth: false),
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (data['token'] != null) {
        await _saveAuthData(data['token'], data['user']);
      }
      return data;
    } else {
      final msg = data['error'] ?? data['detail'] ?? 'Invalid credentials';
      throw Exception(msg);
    }
  }

  /// Sign Out
  Future<void> logout() async {
    try {
      if (_authToken != null) {
        final url = Uri.parse('$baseUrl/auth/logout/');
        await http.post(url, headers: _headers());
      }
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
    } catch (_) {}
    _authToken = null;
    _currentUser = null;
  }

  Future<void> _saveAuthData(String token, Map<String, dynamic>? user) async {
    _authToken = token;
    _currentUser = user;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      if (user != null) {
        await prefs.setString(_userKey, jsonEncode(user));
      }
    } catch (e) {
      debugPrint('SharedPreferences save fallback: $e');
    }
  }

  /// Get Current User Profile
  Future<ProfileModel?> getMyProfile() async {
    try {
      final url = Uri.parse('$baseUrl/profiles/me/');
      final response = await http.get(url, headers: _headers());
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ProfileModel.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting my profile: $e');
      return null;
    }
  }

  /// Update Current User Profile
  Future<ProfileModel?> updateProfile(ProfileModel profile) async {
    try {
      final url = Uri.parse('$baseUrl/profiles/me/');
      final response = await http.put(
        url,
        headers: _headers(),
        body: jsonEncode(profile.toJson()),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ProfileModel.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error saving profile: $e');
      return null;
    }
  }

  /// Fetch Matches with query filters
  Future<List<ProfileModel>> fetchMatches({
    String? gender,
    int? minAge,
    int? maxAge,
    String? religion,
    String? motherTongue,
    String? maritalStatus,
    String? state,
    String? city,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (gender != null && gender.isNotEmpty) queryParams['gender'] = gender;
      if (minAge != null) queryParams['min_age'] = minAge.toString();
      if (maxAge != null) queryParams['max_age'] = maxAge.toString();
      if (religion != null && religion.isNotEmpty) queryParams['religion'] = religion;
      if (motherTongue != null && motherTongue.isNotEmpty) queryParams['mother_tongue'] = motherTongue;
      if (maritalStatus != null && maritalStatus.isNotEmpty) queryParams['marital_status'] = maritalStatus;
      if (state != null && state.isNotEmpty) queryParams['state'] = state;
      if (city != null && city.isNotEmpty) queryParams['city'] = city;

      final uri = Uri.parse('$baseUrl/matches/').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers());

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        List<dynamic> items = [];
        if (decoded is List) {
          items = decoded;
        } else if (decoded is Map && decoded['results'] != null) {
          items = decoded['results'] as List;
        }
        return items.map((e) => ProfileModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching matches: $e');
      return [];
    }
  }

  /// Send Interest to candidate
  Future<bool> sendInterest({required String receiverId, bool isPremium = false}) async {
    try {
      final url = Uri.parse('$baseUrl/matches/send-interest/');
      final response = await http.post(
        url,
        headers: _headers(),
        body: jsonEncode({
          'receiver_id': receiverId,
          if (isPremium) 'is_premium': true,
        }),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Error sending interest: $e');
      return false;
    }
  }

  /// Check Interest Status
  Future<String?> getInterestStatus(String otherUserId) async {
    try {
      final url = Uri.parse('$baseUrl/matches/interest-status/?other_user_id=$otherUserId');
      final response = await http.get(url, headers: _headers());
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting interest status: $e');
      return null;
    }
  }

  /// Fetch Requests (Received or Sent)
  Future<List<Map<String, dynamic>>> fetchRequests({required bool isReceived}) async {
    try {
      final type = isReceived ? 'received' : 'sent';
      final url = Uri.parse('$baseUrl/matches/requests/?type=$type');
      final response = await http.get(url, headers: _headers());

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        List<dynamic> items = decoded is List ? decoded : (decoded['results'] ?? []);
        return items.map<Map<String, dynamic>>((req) {
          final profileData = req['profile'];
          return {
            'request_id': req['id'].toString(),
            'status': req['status'],
            'created_at': req['created_at'],
            'profile': profileData != null ? ProfileModel.fromJson(profileData) : null,
          };
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching requests: $e');
      return [];
    }
  }

  /// Respond to Request (accept / reject)
  Future<bool> respondToRequest({required String requestId, required String newStatus}) async {
    try {
      final url = Uri.parse('$baseUrl/matches/requests/$requestId/respond/');
      final response = await http.post(
        url,
        headers: _headers(),
        body: jsonEncode({'status': newStatus}),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Error responding to request: $e');
      return false;
    }
  }

  /// Fetch Messages with other user
  Future<List<MessageModel>> fetchMessages(String otherUserId) async {
    try {
      final url = Uri.parse('$baseUrl/chat/messages/?other_user_id=$otherUserId');
      final response = await http.get(url, headers: _headers());
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        List<dynamic> items = decoded is List ? decoded : (decoded['results'] ?? []);
        return items.map((m) => MessageModel.fromJson(m as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      return [];
    }
  }

  /// Send Message
  Future<bool> sendMessage({required String receiverId, required String content}) async {
    try {
      final url = Uri.parse('$baseUrl/chat/send/');
      final response = await http.post(
        url,
        headers: _headers(),
        body: jsonEncode({
          'receiver_id': receiverId,
          'content': content.trim(),
        }),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    }
  }

  /// Upload Photo
  Future<String?> uploadProfilePhoto(File file) async {
    try {
      final url = Uri.parse('$baseUrl/profiles/upload-photo/');
      final request = http.MultipartRequest('POST', url);
      if (_authToken != null) {
        request.headers['Authorization'] = 'Token $_authToken';
      }
      request.files.add(await http.MultipartFile.fromPath('photo', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return data['url'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error uploading photo: $e');
      return null;
    }
  }

  /// Reorder Photos
  Future<bool> reorderPhotos({required List<String> photos, int primaryIndex = 0}) async {
    try {
      final url = Uri.parse('$baseUrl/profiles/reorder-photos/');
      final response = await http.post(
        url,
        headers: _headers(),
        body: jsonEncode({
          'photos': photos,
          'primary_photo_index': primaryIndex,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error reordering photos: $e');
      return false;
    }
  }

  /// Resubmit Profile for Customer Relations screening
  Future<Map<String, dynamic>?> resubmitProfile() async {
    try {
      final url = Uri.parse('$baseUrl/profiles/resubmit/');
      final response = await http.post(url, headers: _headers());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Error resubmitting profile: $e');
      return null;
    }
  }

  /// Partner Preferences
  Future<Map<String, dynamic>?> fetchPartnerPreferences() async {
    try {
      final url = Uri.parse('$baseUrl/profiles/partner-preferences/');
      final response = await http.get(url, headers: _headers());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching partner preferences: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> savePartnerPreferences(Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('$baseUrl/profiles/partner-preferences/');
      final response = await http.put(url, headers: _headers(), body: jsonEncode(data));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Error saving partner preferences: $e');
      return null;
    }
  }

  /// Privacy Settings
  Future<Map<String, dynamic>?> fetchPrivacySettings() async {
    try {
      final url = Uri.parse('$baseUrl/profiles/privacy-settings/');
      final response = await http.get(url, headers: _headers());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching privacy settings: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> savePrivacySettings(Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('$baseUrl/profiles/privacy-settings/');
      final response = await http.put(url, headers: _headers(), body: jsonEncode(data));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Error saving privacy settings: $e');
      return null;
    }
  }

  /// General Settings
  Future<Map<String, dynamic>?> fetchGeneralSettings() async {
    try {
      final url = Uri.parse('$baseUrl/auth/settings/');
      final response = await http.get(url, headers: _headers());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching general settings: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> saveGeneralSettings(Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('$baseUrl/auth/settings/');
      final response = await http.put(url, headers: _headers(), body: jsonEncode(data));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Error saving general settings: $e');
      return null;
    }
  }

  /// Active Sessions
  Future<List<dynamic>> fetchActiveSessions() async {
    try {
      final url = Uri.parse('$baseUrl/auth/sessions/');
      final response = await http.get(url, headers: _headers());
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching sessions: $e');
      return [];
    }
  }

  Future<bool> logoutSession(int sessionId) async {
    try {
      final url = Uri.parse('$baseUrl/auth/sessions/');
      final response = await http.post(url, headers: _headers(), body: jsonEncode({'session_id': sessionId}));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error logging out session: $e');
      return false;
    }
  }

  /// Change Password
  Future<Map<String, dynamic>> changePassword(String oldPassword, String newPassword) async {
    final url = Uri.parse('$baseUrl/auth/change-password/');
    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({'old_password': oldPassword, 'new_password': newPassword}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['error'] ?? 'Password update failed');
  }

  /// Data Download
  Future<Map<String, dynamic>?> downloadPersonalData() async {
    try {
      final url = Uri.parse('$baseUrl/auth/download-data/');
      final response = await http.get(url, headers: _headers());
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      debugPrint('Error downloading data: $e');
      return null;
    }
  }

  /// Account Deletion
  Future<bool> deleteAccount(String password) async {
    final url = Uri.parse('$baseUrl/auth/delete-account/');
    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({'confirmation': 'DELETE', 'password': password}),
    );
    return response.statusCode == 200;
  }

  /// Block and Report
  Future<bool> blockMember(String userId) async {
    try {
      final url = Uri.parse('$baseUrl/profiles/block/');
      final response = await http.post(url, headers: _headers(), body: jsonEncode({'user_id': userId}));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error blocking member: $e');
      return false;
    }
  }

  Future<bool> unblockMember(String userId) async {
    try {
      final url = Uri.parse('$baseUrl/profiles/block/');
      final response = await http.delete(url, headers: _headers(), body: jsonEncode({'user_id': userId}));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error unblocking member: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> reportMisuse(String userId, String reason, String details) async {
    final url = Uri.parse('$baseUrl/profiles/report/');
    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({'user_id': userId, 'reason': reason, 'details': details}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 201) return data;
    throw Exception(data['error'] ?? 'Report failed');
  }

  /// Fetch Matches with 4 subcategories (Page 4 & 5)
  Future<List<ProfileModel>> fetchCategorizedMatches({
    String category = 'preferred',
    Map<String, String>? refineFilters,
  }) async {
    try {
      final queryParams = <String, String>{'category': category};
      if (refineFilters != null) {
        queryParams.addAll(refineFilters);
      }
      final uri = Uri.parse('$baseUrl/matches/').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers());
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => ProfileModel.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching categorized matches: $e');
      return [];
    }
  }

  /// Search Profiles (Page 5)
  Future<List<ProfileModel>> searchProfiles(Map<String, String> searchParams) async {
    try {
      final uri = Uri.parse('$baseUrl/matches/search/').replace(queryParameters: searchParams);
      final response = await http.get(uri, headers: _headers());
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => ProfileModel.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error searching profiles: $e');
      return [];
    }
  }

  /// Saved Searches & History
  Future<List<dynamic>> fetchSavedSearches() async {
    try {
      final url = Uri.parse('$baseUrl/matches/saved-searches/');
      final response = await http.get(url, headers: _headers());
      if (response.statusCode == 200) return jsonDecode(response.body) as List<dynamic>;
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> saveSearch(String title, Map<String, dynamic> filters) async {
    try {
      final url = Uri.parse('$baseUrl/matches/saved-searches/');
      final response = await http.post(url, headers: _headers(), body: jsonEncode({'title': title, 'filters': filters}));
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteSavedSearch(int id) async {
    try {
      final url = Uri.parse('$baseUrl/matches/saved-searches/$id/');
      final response = await http.delete(url, headers: _headers());
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> fetchSearchHistory() async {
    try {
      final url = Uri.parse('$baseUrl/matches/search-history/');
      final response = await http.get(url, headers: _headers());
      if (response.statusCode == 200) return jsonDecode(response.body) as List<dynamic>;
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Shortlists (Page 7)
  Future<bool> toggleShortlist(String profileId, bool currentlyShortlisted) async {
    try {
      if (currentlyShortlisted) {
        final url = Uri.parse('$baseUrl/matches/shortlists/$profileId/');
        final response = await http.delete(url, headers: _headers());
        return response.statusCode == 200 ? false : true;
      } else {
        final url = Uri.parse('$baseUrl/matches/shortlists/');
        final response = await http.post(url, headers: _headers(), body: jsonEncode({'profile_id': profileId}));
        return response.statusCode == 200 ? true : false;
      }
    } catch (e) {
      return currentlyShortlisted;
    }
  }

  Future<List<dynamic>> fetchShortlists() async {
    try {
      final url = Uri.parse('$baseUrl/matches/shortlists/');
      final response = await http.get(url, headers: _headers());
      if (response.statusCode == 200) return jsonDecode(response.body) as List<dynamic>;
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Inbox (Page 5)
  Future<List<dynamic>> fetchInbox({String folder = 'received'}) async {
    try {
      final uri = Uri.parse('$baseUrl/matches/inbox/').replace(queryParameters: {'folder': folder});
      final response = await http.get(uri, headers: _headers());
      if (response.statusCode == 200) return jsonDecode(response.body) as List<dynamic>;
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> bulkInboxAction(String action, List<String> requestIds) async {
    try {
      final url = Uri.parse('$baseUrl/matches/inbox/');
      final response = await http.post(
        url,
        headers: _headers(),
        body: jsonEncode({'action': action, 'request_ids': requestIds}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Photo & Contact Requests (Page 5 & 7)
  Future<List<dynamic>> fetchPhotoOrContactRequests({String? type, String folder = 'received'}) async {
    try {
      final queryParams = <String, String>{'folder': folder};
      if (type != null) queryParams['type'] = type;
      final uri = Uri.parse('$baseUrl/matches/photo-contact-requests/').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers());
      if (response.statusCode == 200) return jsonDecode(response.body) as List<dynamic>;
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> sendPhotoOrContactRequest({required String receiverId, required String requestType}) async {
    try {
      final url = Uri.parse('$baseUrl/matches/photo-contact-requests/');
      final response = await http.post(
        url,
        headers: _headers(),
        body: jsonEncode({'receiver_id': receiverId, 'request_type': requestType}),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> respondPhotoOrContactRequest(String requestId, String newStatus) async {
    try {
      final url = Uri.parse('$baseUrl/matches/photo-contact-requests/$requestId/');
      final response = await http.patch(
        url,
        headers: _headers(),
        body: jsonEncode({'status': newStatus}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Chat Directory & Presence (Page 1 & 5)
  Future<Map<String, dynamic>?> fetchChatDirectory() async {
    try {
      final url = Uri.parse('$baseUrl/chat/directory/');
      final response = await http.get(url, headers: _headers());
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      debugPrint('Error fetching chat directory: $e');
      return null;
    }
  }

  Future<bool> deleteConversation(String otherUserId) async {
    try {
      final url = Uri.parse('$baseUrl/chat/conversation/$otherUserId/delete/');
      final response = await http.delete(url, headers: _headers());
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

