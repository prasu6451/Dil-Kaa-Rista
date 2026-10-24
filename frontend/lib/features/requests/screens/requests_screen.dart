import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../chat/screens/chat_screen.dart';
import '../../matches/controllers/match_controller.dart';
import '../../matches/screens/profile_detail_screen.dart';
import '../../profile_creation/models/profile_model.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _authController = AuthController();
  final _matchController = MatchController();
  Timer? _pollingTimer;

  List<Map<String, dynamic>> _receivedRequests = [];
  List<Map<String, dynamic>> _sentRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadRequests();
      }
    });
    _loadRequests();
    _subscribeRealtime();
  }

  void _subscribeRealtime() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _loadRequests(silent: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    final user = _authController.currentUser;
    if (user != null) {
      final received = await _matchController.fetchRequests(
        currentUserId: user.id,
        isReceived: true,
      );
      final sent = await _matchController.fetchRequests(
        currentUserId: user.id,
        isReceived: false,
      );

      if (mounted) {
        setState(() {
          _receivedRequests = received;
          _sentRequests = sent;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResponse(String requestId, String status) async {
    final success = await _matchController.respondToRequest(
      requestId: requestId,
      newStatus: status,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'accepted' ? 'Interest accepted!' : 'Interest declined.',
            ),
            backgroundColor:
                status == 'accepted' ? AppColors.success : Colors.grey.shade700,
          ),
        );
        _loadRequests();
      }
    }
  }

  Widget _buildRequestList({
    required List<Map<String, dynamic>> requests,
    required bool isReceived,
  }) {
    final currentUserId = _authController.currentUser?.id ?? '';

    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isReceived
                  ? Icons.mark_email_unread_outlined
                  : Icons.send_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              isReceived ? 'No Received Interests' : 'No Sent Interests',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              isReceived
                  ? 'When members send you an interest, it will appear here in real time.'
                  : 'Start sending interests from the Recommendations feed!',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: requests.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = requests[index];
        final ProfileModel p = item['profile'];
        final String status = item['status'];
        final String reqId = item['request_id'];

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(6),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileDetailScreen(
                            profile: p,
                            currentUserId: currentUserId,
                          ),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primaryLight,
                      backgroundImage: (p.avatarUrl != null &&
                              p.avatarUrl!.isNotEmpty)
                          ? CachedNetworkImageProvider(p.avatarUrl!)
                          : null,
                      child: (p.avatarUrl == null || p.avatarUrl!.isEmpty)
                          ? const Icon(Icons.person,
                              color: AppColors.primary, size: 30)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${p.age != null ? '${p.age} yrs' : ''}${p.religion != null ? ' • ${p.religion}' : ''}${p.city != null ? ' • ${p.city}' : ''}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: status == 'accepted'
                                ? Colors.green.shade50
                                : status == 'declined'
                                    ? Colors.red.shade50
                                    : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status == 'accepted'
                                ? 'MATCHED'
                                : status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: status == 'accepted'
                                  ? Colors.green.shade700
                                  : status == 'declined'
                                      ? Colors.red.shade700
                                      : Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Action for Pending Received Request
              if (isReceived && status == 'pending') ...[
                const Divider(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _handleResponse(reqId, 'declined'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          side: BorderSide(color: Colors.grey.shade400),
                          minimumSize: const Size.fromHeight(38),
                        ),
                        child: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _handleResponse(reqId, 'accepted'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(38),
                        ),
                        child: const Text('Accept Interest'),
                      ),
                    ),
                  ],
                ),
              ],

              // Chat Button for Accepted Match (Both Sender & Receiver)
              if (status == 'accepted') ...[
                const Divider(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          matchProfile: p,
                          currentUserId: currentUserId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                  label: Text('Chat with ${p.fullName}'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    backgroundColor: const Color(0xFF2E7D32), // Emerald Green
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Interests & Activity'),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.fiber_manual_record, color: Colors.green, size: 8),
                  SizedBox(width: 3),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: 'Received (${_receivedRequests.length})'),
            Tab(text: 'Sent (${_sentRequests.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _loadRequests,
              color: AppColors.primary,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRequestList(
                    requests: _receivedRequests,
                    isReceived: true,
                  ),
                  _buildRequestList(
                    requests: _sentRequests,
                    isReceived: false,
                  ),
                ],
              ),
            ),
    );
  }
}
