import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../profile_creation/models/profile_model.dart';
import '../controllers/match_controller.dart';
import '../widgets/profile_card_widget.dart';
import '../widgets/search_filter_bottom_sheet.dart';

class MatchesFeedScreen extends StatefulWidget {
  const MatchesFeedScreen({super.key});

  @override
  State<MatchesFeedScreen> createState() => _MatchesFeedScreenState();
}

class _MatchesFeedScreenState extends State<MatchesFeedScreen> {
  final _authController = AuthController();
  final _matchController = MatchController();

  ProfileModel? _currentProfile;
  List<ProfileModel> _matches = [];
  final Set<String> _sentInterestIds = {};
  bool _isLoading = true;
  MatchFilter _filter = MatchFilter();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final profile = await _authController.getCurrentProfile();
    _currentProfile = profile;

    if (profile != null) {
      final matches = await _matchController.fetchMatches(
        currentUserId: profile.id,
        currentGender: profile.gender,
        filter: _filter,
      );
      if (mounted) {
        setState(() {
          _matches = matches;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSendInterest(ProfileModel target) async {
    if (_currentProfile == null) return;
    setState(() {
      _sentInterestIds.add(target.id);
    });

    final success = await _matchController.sendInterest(
      senderId: _currentProfile!.id,
      receiverId: target.id,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Interest sent to ${target.fullName}!'
                : 'Failed to send interest.',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SearchFilterBottomSheet(
        filter: _filter,
        onApply: (newFilter) {
          setState(() => _filter = newFilter);
          _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'Daily Recommendations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (_matches.isNotEmpty)
              Text(
                '${_matches.length} matching profiles found',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                onPressed: _openFilterSheet,
              ),
              if (_filter.hasActiveFilters)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: _matches.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_search_outlined,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No Profiles Found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _filter.hasActiveFilters
                                  ? 'Try broadening your search filters to discover more brides & grooms.'
                                  : 'More profiles will appear here as members register.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (_filter.hasActiveFilters)
                              ElevatedButton(
                                onPressed: () {
                                  setState(() => _filter.reset());
                                  _loadData();
                                },
                                child: const Text('Reset Filters'),
                              ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24, top: 6),
                      itemCount: _matches.length,
                      itemBuilder: (context, index) {
                        final match = _matches[index];
                        return ProfileCardWidget(
                          profile: match,
                          currentUserId: _currentProfile?.id ?? '',
                          isInterestSent: _sentInterestIds.contains(match.id),
                          onSendInterest: () => _handleSendInterest(match),
                        );
                      },
                    ),
            ),
    );
  }
}
