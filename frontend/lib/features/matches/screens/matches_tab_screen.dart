import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../profile_creation/models/profile_model.dart';
import '../widgets/match_card_full_widget.dart';
import '../../premium/widgets/premium_upgrade_dialog.dart';

class MatchesTabScreen extends StatefulWidget {
  const MatchesTabScreen({super.key});

  @override
  State<MatchesTabScreen> createState() => _MatchesTabScreenState();
}

class _MatchesTabScreenState extends State<MatchesTabScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _authController = AuthController();

  ProfileModel? _currentUserProfile;
  List<ProfileModel> _matches = [];
  final Set<String> _sentInterestIds = {};
  bool _isLoading = true;

  // Refine search filter state (Page 4)
  bool _refinePhotoOnly = false;
  String _refineMotherTongue = '';
  String _refineCity = '';
  String _refineEducation = '';
  String _refineProfession = '';
  bool _isRefinePanelOpen = false;

  final List<String> _categories = ['preferred', 'broader', 'reverse', 'near_me'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadMatches();
      }
    });
    _loadUserAndMatches();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndMatches() async {
    setState(() => _isLoading = true);
    _currentUserProfile = await _authController.getCurrentProfile();
    await _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() => _isLoading = true);
    final category = _categories[_tabController.index];

    final filters = <String, String>{};
    if (_refinePhotoOnly) filters['has_photo'] = 'true';
    if (_refineMotherTongue.isNotEmpty) filters['mother_tongue'] = _refineMotherTongue;
    if (_refineCity.isNotEmpty) filters['city'] = _refineCity;
    if (_refineEducation.isNotEmpty) filters['education'] = _refineEducation;
    if (_refineProfession.isNotEmpty) filters['profession'] = _refineProfession;

    final list = await ApiService.instance.fetchCategorizedMatches(
      category: category,
      refineFilters: filters,
    );

    if (mounted) {
      setState(() {
        _matches = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSendInterest(ProfileModel target) async {
    setState(() => _sentInterestIds.add(target.id));
    final success = await _authController.sendInterest(receiverId: target.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Interest sent to ${target.effectiveName}!' : 'Failed to send interest.',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  void _showReverseMatchTooltip() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.swap_horiz, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Reverse Matches', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          'Reverse Matches shows profiles of members whose partner preferences match your profile criteria.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showNearMeCityDialog() {
    final controller = TextEditingController(text: _currentUserProfile?.city ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Near Me - Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your city manually or allow location access to find matches near you.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'e.g. Mumbai, New Delhi, Bengaluru',
                prefixIcon: const Icon(Icons.location_city, color: AppColors.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(context);
              setState(() => _refineCity = controller.text.trim());
              _loadMatches();
            },
            child: const Text('Search Near Me', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildRefineSearchBox() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.tune, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text('Refine Search Box', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              IconButton(
                icon: Icon(_isRefinePanelOpen ? Icons.expand_less : Icons.expand_more),
                onPressed: () => setState(() => _isRefinePanelOpen = !_isRefinePanelOpen),
              ),
            ],
          ),
          if (_isRefinePanelOpen) ...[
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Photo Available Only', style: TextStyle(fontSize: 13)),
              value: _refinePhotoOnly,
              onChanged: (val) => setState(() => _refinePhotoOnly = val),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Mother Tongue',
                      hintText: 'Hindi, Tamil, etc.',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onChanged: (val) => _refineMotherTongue = val.trim(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'City / State',
                      hintText: 'Delhi, Gujarat, etc.',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onChanged: (val) => _refineCity = val.trim(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Education',
                      hintText: 'B.Tech, MBA, etc.',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onChanged: (val) => _refineEducation = val.trim(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Profession',
                      hintText: 'Engineer, Doctor, etc.',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onChanged: (val) => _refineProfession = val.trim(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _refinePhotoOnly = false;
                      _refineMotherTongue = '';
                      _refineCity = '';
                      _refineEducation = '';
                      _refineProfession = '';
                    });
                    _loadMatches();
                  },
                  child: const Text('Reset'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () {
                    _loadMatches();
                  },
                  child: const Text('Apply Refinements', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Premium Upgrade',
            icon: const Icon(Icons.workspace_premium, color: Colors.amber),
            onPressed: () => PremiumUpgradeDialog.show(context, currentTier: _currentUserProfile?.membershipTier ?? 'free'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.black54,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: [
            const Tab(text: 'Preferred Matches'),
            const Tab(text: 'Broader Matches'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Reverse Matches'),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _showReverseMatchTooltip,
                    child: const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Near Me'),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _showNearMeCityDialog,
                    child: const Icon(Icons.edit_location_alt_outlined, size: 16, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadMatches,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // Refine Search Box (Page 4)
            _buildRefineSearchBox(),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_matches.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text(
                        'No matches found in this category',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Try adjusting your Refine Search filters or broadening your partner preferences.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _matches.length,
                itemBuilder: (context, index) {
                  final profile = _matches[index];
                  final isSent = _sentInterestIds.contains(profile.id);
                  return MatchCardFullWidget(
                    profile: profile,
                    currentUserProfile: _currentUserProfile,
                    isInterestSent: isSent,
                    onInterestSent: () => _handleSendInterest(profile),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
