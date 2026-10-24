import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../profile_creation/models/profile_model.dart';
import '../screens/profile_detail_screen.dart';

class ProfileCardWidget extends StatelessWidget {
  final ProfileModel profile;
  final String currentUserId;
  final VoidCallback onSendInterest;
  final bool isInterestSent;

  const ProfileCardWidget({
    super.key,
    required this.profile,
    required this.currentUserId,
    required this.onSendInterest,
    this.isInterestSent = false,
  });

  Widget _buildChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image Area with Badges & Name
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileDetailScreen(
                      profile: profile,
                      currentUserId: currentUserId,
                    ),
                  ),
                );
              },
              child: Stack(
                children: [
                  // Image
                  SizedBox(
                    height: 280,
                    width: double.infinity,
                    child: (profile.avatarUrl != null &&
                            profile.avatarUrl!.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: profile.avatarUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.primaryLight,
                              child: const Icon(
                                Icons.person,
                                size: 80,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.primaryLight,
                            child: const Icon(
                              Icons.person,
                              size: 80,
                              color: AppColors.primary,
                            ),
                          ),
                  ),

                  // Gradient
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 100,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withAlpha(180),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),

                  // Overlay Details
                  Positioned(
                    bottom: 12,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              profile.fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (profile.isVerified) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.verified,
                                color: Colors.blueAccent,
                                size: 18,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${profile.age != null ? '${profile.age} yrs' : ''}${profile.heightCm != null ? ', ${(profile.heightCm! / 2.54).round() ~/ 12}\' ${(profile.heightCm! / 2.54).round() % 12}"' : ''}${profile.city != null && profile.city!.isNotEmpty ? ' • ${profile.city}' : ''}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Verified Tag on top right
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(140),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.shield_outlined,
                              color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Chips / Highlights
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (profile.religion != null)
                        _buildChip(Icons.brightness_7_outlined,
                            profile.religion!),
                      if (profile.caste != null && profile.caste!.isNotEmpty)
                        _buildChip(Icons.group_outlined, profile.caste!),
                      if (profile.occupation != null &&
                          profile.occupation!.isNotEmpty)
                        _buildChip(Icons.work_outline, profile.occupation!),
                      if (profile.education != null &&
                          profile.education!.isNotEmpty)
                        _buildChip(Icons.school_outlined, profile.education!),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfileDetailScreen(
                                  profile: profile,
                                  currentUserId: currentUserId,
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('View Profile'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isInterestSent ? null : onSendInterest,
                          icon: Icon(
                            isInterestSent ? Icons.check : Icons.favorite_border,
                            size: 18,
                          ),
                          label: Text(
                            isInterestSent ? 'Sent' : 'Connect',
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            backgroundColor: isInterestSent
                                ? Colors.grey.shade600
                                : AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
