import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../chat/screens/chat_screen.dart';
import '../../profile_creation/models/profile_model.dart';
import '../controllers/match_controller.dart';


class ProfileDetailScreen extends StatefulWidget {
  final ProfileModel profile;
  final String currentUserId;

  const ProfileDetailScreen({
    super.key,
    required this.profile,
    required this.currentUserId,
  });

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  final _matchController = MatchController();
  String? _interestStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final status = await _matchController.getInterestStatus(
      currentUserId: widget.currentUserId,
      otherUserId: widget.profile.id,
    );
    if (mounted) {
      setState(() => _interestStatus = status);
    }
  }

  Future<void> _handleSendInterest() async {
    setState(() => _isLoading = true);
    final success = await _matchController.sendInterest(
      senderId: widget.currentUserId,
      receiverId: widget.profile.id,
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (success) _interestStatus = 'sent';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Interest sent to ${widget.profile.fullName}!'
                : 'Failed to send interest.',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header App Bar with Profile Avatar / Backdrop
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  (p.avatarUrl != null && p.avatarUrl!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: p.avatarUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey.shade300,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.primaryLight,
                            child: const Icon(
                              Icons.person,
                              size: 100,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.primaryLight,
                          child: const Icon(
                            Icons.person,
                            size: 100,
                            color: AppColors.primary,
                          ),
                        ),
                  // Dark gradient overlay at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 120,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withAlpha(200),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              p.fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (p.isVerified) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.verified,
                                color: Colors.blueAccent,
                                size: 20,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${p.age != null ? '${p.age} yrs' : ''}${p.heightCm != null ? ', ${(p.heightCm! / 2.54).round() ~/ 12}\' ${(p.heightCm! / 2.54).round() % 12}"' : ''}${p.city != null && p.city!.isNotEmpty ? ' • ${p.city}' : ''}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content Sections
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 12),

              // About Me
              if (p.aboutMe != null && p.aboutMe!.isNotEmpty)
                _buildSectionCard(
                  title: 'About ${p.fullName}',
                  icon: Icons.info_outline,
                  children: [
                    Text(
                      p.aboutMe!,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),

              // Basic & Location Details
              _buildSectionCard(
                title: 'Basic & Location',
                icon: Icons.person_outline,
                children: [
                  _buildInfoRow('Age', p.age != null ? '${p.age} years' : null),
                  _buildInfoRow('Marital Status', p.maritalStatus),
                  _buildInfoRow(
                    'Height',
                    p.heightCm != null ? '${p.heightCm} cm' : null,
                  ),
                  _buildInfoRow('City', p.city),
                  _buildInfoRow('State', p.state),
                  _buildInfoRow('Country', p.country),
                ],
              ),

              // Religion & Community
              _buildSectionCard(
                title: 'Religious & Social Background',
                icon: Icons.brightness_7_outlined,
                children: [
                  _buildInfoRow('Religion', p.religion),
                  _buildInfoRow('Mother Tongue', p.motherTongue),
                  _buildInfoRow('Caste', p.caste),
                  _buildInfoRow('Gotra', p.gotra),
                ],
              ),

              // Education & Career
              _buildSectionCard(
                title: 'Education & Career',
                icon: Icons.school_outlined,
                children: [
                  _buildInfoRow('Education', p.education),
                  _buildInfoRow('Profession', p.occupation),
                  _buildInfoRow('Annual Income', p.annualIncome),
                ],
              ),

              const SizedBox(height: 100),
            ]),
          ),
        ],
      ),

      // Bottom Action Bar
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : _interestStatus == 'accepted'
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    matchProfile: widget.profile,
                                    currentUserId: widget.currentUserId,
                                  ),
                                ),
                              );
                            }
                          : _interestStatus == 'sent'
                              ? null
                              : _handleSendInterest,
                  icon: Icon(
                    _interestStatus == 'sent'
                        ? Icons.check
                        : _interestStatus == 'accepted'
                            ? Icons.chat_bubble_rounded
                            : Icons.favorite_border,
                  ),
                  label: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _interestStatus == 'sent'
                              ? 'Interest Sent'
                              : _interestStatus == 'accepted'
                                  ? 'Chat Now'
                                  : 'Send Interest',
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _interestStatus == 'accepted'
                        ? const Color(0xFF2E7D32)
                        : _interestStatus == 'sent'
                            ? Colors.grey.shade600
                            : AppColors.primary,
                  ),
                ),

              ),
            ],
          ),
        ),
      ),
    );
  }
}
