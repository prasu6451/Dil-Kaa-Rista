import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../profile_creation/models/profile_model.dart';
import '../../premium/widgets/premium_upgrade_dialog.dart';
import '../../chat/screens/chat_screen.dart';

class MatchCardFullWidget extends StatefulWidget {
  final ProfileModel profile;
  final ProfileModel? currentUserProfile;
  final VoidCallback onInterestSent;
  final bool isInterestSent;

  const MatchCardFullWidget({
    super.key,
    required this.profile,
    required this.currentUserProfile,
    required this.onInterestSent,
    this.isInterestSent = false,
  });

  @override
  State<MatchCardFullWidget> createState() => _MatchCardFullWidgetState();
}

class _MatchCardFullWidgetState extends State<MatchCardFullWidget> {
  bool _isAboutExpanded = false;
  late bool _isShortlisted;
  bool _isContactRequested = false;

  @override
  void initState() {
    super.initState();
    _isShortlisted = widget.profile.isShortlisted;
  }

  void _showEnlargedPhoto(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image, color: Colors.white, size: 48)),
              ),

            ),
            IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleToggleShortlist() async {
    final nextState = await ApiService.instance.toggleShortlist(widget.profile.id, _isShortlisted);
    setState(() => _isShortlisted = nextState);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isShortlisted ? 'Profile added to Shortlist!' : 'Removed from Shortlist.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleRequestContact() async {
    final success = await ApiService.instance.sendPhotoOrContactRequest(
      receiverId: widget.profile.id,
      requestType: 'contact',
    );
    if (mounted) {
      setState(() => _isContactRequested = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Contact request sent to ${widget.profile.effectiveName}! You will be notified upon approval.'
                : 'Failed to send contact request.',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  void _handleInitiateChat() {
    final myTier = widget.currentUserProfile?.membershipTier ?? 'free';
    if (myTier == 'free') {
      // Page 7: Chat: Disabled or hidden. Displayed as a locked state with an "Upgrade to unlock" prompt. Free members cannot initiate chat.
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.lock, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Chat Locked', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Initiating chats is a Premium feature. Upgrade to Tier 1 or Tier 2 to start direct conversations with your matches.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Maybe Later'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                Navigator.pop(context);
                PremiumUpgradeDialog.show(context, currentTier: myTier);
              },
              child: const Text('Upgrade Now', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            otherUserId: widget.profile.id,
            otherUserName: widget.profile.effectiveName,
            otherUserAvatar: widget.profile.avatarUrl,
          ),
        ),
      );
    }
  }

  Widget _buildSnippetItem(String label, String? value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            (value != null && value.isNotEmpty) ? value : 'Not Specified',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final photos = p.photos;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Why am I seeing this match?" Explanation Pill (Page 5 & 7)
          if (p.matchReason != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(15),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Why am I seeing this? ${p.matchReason}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // 1. Header (Photo & Identity) (Page 7)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    if (p.avatarUrl != null && p.avatarUrl!.isNotEmpty) {
                      _showEnlargedPhoto(p.avatarUrl!);
                    }
                  },
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.primaryLight,
                        backgroundImage: (p.avatarUrl != null && p.avatarUrl!.isNotEmpty)
                            ? CachedNetworkImageProvider(p.avatarUrl!)
                            : null,
                        child: (p.avatarUrl == null || p.avatarUrl!.isEmpty)
                            ? const Icon(Icons.person, size: 40, color: AppColors.primary)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.zoom_in, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              p.effectiveName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Owner's Premium Badge (Page 7: "that badge belongs to them, not to you")
                          if (p.isPremium) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.amber.shade400),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.workspace_premium, color: Colors.amber.shade900, size: 12),
                                  const SizedBox(width: 2),
                                  Text(
                                    p.membershipTier == 'tier_2' ? 'VIP' : 'PREMIUM',
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${p.profileId ?? "DKR${p.id.substring(0, 6).toUpperCase()}"}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                      ),

                      const SizedBox(height: 4),
                      Text(
                        '${p.age != null ? "${p.age} yrs" : ""}${p.heightCm != null ? " • ${p.heightCm} cm" : ""} • ${p.city ?? "India"}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                      if (p.occupation != null && p.occupation!.isNotEmpty)
                        Text(
                          p.occupation!,
                          style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Core Information Snippet (Page 7)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Core Information Snippet',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 2.2,
                  children: [
                    _buildSnippetItem('Religion', p.religion),
                    _buildSnippetItem('Community/Caste', p.caste),
                    _buildSnippetItem('Mother Tongue', p.motherTongue),
                    _buildSnippetItem('Education', p.education),
                    _buildSnippetItem('Profession', p.occupation),
                    _buildSnippetItem('Annual Income', p.annualIncome),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 3. About Me & Hobbies (Page 7)
          if ((p.aboutMe != null && p.aboutMe!.isNotEmpty) || p.hobbies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('About Me & Hobbies', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 6),
                  if (p.aboutMe != null && p.aboutMe!.isNotEmpty)
                    GestureDetector(
                      onTap: () => setState(() => _isAboutExpanded = !_isAboutExpanded),
                      child: Text(
                        p.aboutMe!,
                        maxLines: _isAboutExpanded ? 10 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                      ),
                    ),
                  if (p.hobbies.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: p.hobbies.take(6).map((hobby) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.purple.shade100),
                          ),
                          child: Text(hobby, style: TextStyle(fontSize: 11, color: Colors.purple.shade700, fontWeight: FontWeight.w500)),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

          const SizedBox(height: 14),

          // 4. Photos Carousel / Thumbnails (Page 7)
          if (photos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Photos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      Text('${photos.length} photos', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 70,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: photos.length,
                      separatorBuilder: (_, index) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        return GestureDetector(
                          onTap: () => _showEnlargedPhoto(photos[idx]),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: photos[idx],
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: Colors.grey.shade200),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                ],
              ),
            ),

          const SizedBox(height: 14),

          // 5. Horoscope / Kundli (Page 7: Read-only, visible if set to public)
          if (p.horoscopePrivacy == 'all_members')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wb_sunny_rounded, color: Colors.orange, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Horoscope / Kundli Available', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('Public chart available. Compatibility report requires Tier 2 Premium.', style: TextStyle(fontSize: 10, color: Colors.black54)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        PremiumUpgradeDialog.show(context, currentTier: widget.currentUserProfile?.membershipTier ?? 'free');
                      },
                      child: const Text('Check Match', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 14),

          // 6. Contact Area (Locked/Premium) (Page 7)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_locked_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Phone & Direct Contact', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        Text('Verified contact details require member approval.', style: TextStyle(fontSize: 10, color: Colors.black54)),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isContactRequested ? Colors.grey : AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onPressed: _isContactRequested ? null : _handleRequestContact,
                    icon: Icon(_isContactRequested ? Icons.check : Icons.lock_open, size: 14),
                    label: Text(_isContactRequested ? 'Requested' : 'Request Contact', style: const TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),

          // 7. Action Buttons (Bottom of Card) (Page 7)
          // Express Interest (Free) | Chat (Locked/Upgrade) | Shortlist
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              children: [
                // Express Interest (Free)
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isInterestSent ? AppColors.success : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: widget.isInterestSent ? null : widget.onInterestSent,
                    icon: Icon(widget.isInterestSent ? Icons.check : Icons.favorite_rounded, size: 18),
                    label: Text(
                      widget.isInterestSent ? 'Interest Sent' : 'Express Interest',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Chat (Locked state with upgrade prompt for free members)
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: (widget.currentUserProfile?.isPremium ?? false) ? AppColors.primary : Colors.grey.shade700,
                      side: BorderSide(
                        color: (widget.currentUserProfile?.isPremium ?? false) ? AppColors.primary : Colors.grey.shade400,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _handleInitiateChat,
                    icon: Icon(
                      (widget.currentUserProfile?.isPremium ?? false) ? Icons.chat_bubble_rounded : Icons.lock_outline,
                      size: 16,
                    ),
                    label: Text(
                      (widget.currentUserProfile?.isPremium ?? false) ? 'Chat' : 'Chat (Lock)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Shortlist
                IconButton(
                  tooltip: _isShortlisted ? 'Remove from shortlist' : 'Shortlist profile',
                  icon: Icon(
                    _isShortlisted ? Icons.star_rounded : Icons.star_border_rounded,
                    color: _isShortlisted ? Colors.amber : Colors.grey.shade600,
                    size: 26,
                  ),
                  onPressed: _handleToggleShortlist,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
