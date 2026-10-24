import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../matches/screens/matches_tab_screen.dart';
import '../../search/screens/search_tab_screen.dart';
import '../../inbox/screens/inbox_tab_screen.dart';
import '../../account/screens/my_account_tab_screen.dart';
import '../../chat/widgets/universal_chat_box.dart';
import '../../premium/widgets/premium_upgrade_dialog.dart';

class HomeNavScreen extends StatefulWidget {
  const HomeNavScreen({super.key});

  @override
  State<HomeNavScreen> createState() => _HomeNavScreenState();
}

class _HomeNavScreenState extends State<HomeNavScreen> {
  int _selectedIndex = 0;
  final _authController = AuthController();
  Timer? _badgePollingTimer;

  int _unreadMessages = 0;
  int _pendingInterests = 0;
  String _userTier = 'free';

  @override
  void initState() {
    super.initState();
    _fetchBadges();
    _badgePollingTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (mounted) _fetchBadges();
    });
  }

  @override
  void dispose() {
    _badgePollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchBadges() async {
    final profile = await _authController.getCurrentProfile();
    if (profile != null && mounted) {
      setState(() => _userTier = profile.membershipTier);
    }
    final dir = await ApiService.instance.fetchChatDirectory();
    if (dir != null && mounted) {
      final badge = dir['badge'] as Map<String, dynamic>?;
      if (badge != null) {
        setState(() {
          _unreadMessages = badge['unread_message_count'] ?? 0;
          _pendingInterests = badge['pending_interest_count'] ?? 0;
        });
      }
    }
  }

  Widget _buildChatIcon() {
    return Stack(
      children: [
        IconButton(
          tooltip: 'Universal Chat Box',
          icon: const Icon(Icons.chat_bubble_rounded, color: AppColors.primary),
          onPressed: () => UniversalChatBox.show(context, currentTier: _userTier),
        ),
        if (_unreadMessages > 0 || _pendingInterests > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '${_unreadMessages + _pendingInterests}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDrawerSidebar() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dil Ka Rishta',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Indian Matrimony & Matchmaking',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.favorite_rounded, color: AppColors.primary),
              title: const Text('Matches', style: TextStyle(fontWeight: FontWeight.w600)),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() => _selectedIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.search_rounded, color: AppColors.primary),
              title: const Text('Search', style: TextStyle(fontWeight: FontWeight.w600)),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() => _selectedIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Stack(
                children: [
                  const Icon(Icons.mail_rounded, color: AppColors.primary),
                  if (_pendingInterests > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
              title: const Text('Inbox', style: TextStyle(fontWeight: FontWeight.w600)),
              trailing: _pendingInterests > 0
                  ? Chip(label: Text('$_pendingInterests', style: const TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: Colors.red)
                  : null,
              selected: _selectedIndex == 2,
              onTap: () {
                setState(() => _selectedIndex = 2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_rounded, color: AppColors.primary),
              title: const Text('My Account', style: TextStyle(fontWeight: FontWeight.w600)),
              selected: _selectedIndex == 3,
              onTap: () {
                setState(() => _selectedIndex = 3);
                Navigator.pop(context);
              },
            ),
            const Spacer(),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.workspace_premium),
                label: const Text('Premium Plans', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(context);
                  PremiumUpgradeDialog.show(context, currentTier: _userTier);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1024;

    final List<Widget> screens = [
      const MatchesTabScreen(),
      const SearchTabScreen(),
      InboxTabScreen(onNavigateToPreferences: () => setState(() => _selectedIndex = 3)),
      const MyAccountTabScreen(),
    ];

    // Desktop Layout (Page 1: horizontal tabs top center)
    if (isDesktop) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Dil Ka Rishta', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          centerTitle: false,
          actions: [
            // Top Center Horizontal Tabs
            Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.favorite),
                  label: const Text('Matches'),
                  onPressed: () => setState(() => _selectedIndex = 0),
                  style: TextButton.styleFrom(
                    foregroundColor: _selectedIndex == 0 ? AppColors.primary : Colors.black87,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.search),
                  label: const Text('Search'),
                  onPressed: () => setState(() => _selectedIndex = 1),
                  style: TextButton.styleFrom(
                    foregroundColor: _selectedIndex == 1 ? AppColors.primary : Colors.black87,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.mail),
                  label: Text('Inbox ($_pendingInterests)'),
                  onPressed: () => setState(() => _selectedIndex = 2),
                  style: TextButton.styleFrom(
                    foregroundColor: _selectedIndex == 2 ? AppColors.primary : Colors.black87,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.person),
                  label: const Text('My Account'),
                  onPressed: () => setState(() => _selectedIndex = 3),
                  style: TextButton.styleFrom(
                    foregroundColor: _selectedIndex == 3 ? AppColors.primary : Colors.black87,
                  ),
                ),
              ],
            ),

            const SizedBox(width: 24),
            IconButton(
              icon: const Icon(Icons.workspace_premium, color: Colors.amber),
              onPressed: () => PremiumUpgradeDialog.show(context, currentTier: _userTier),
            ),
            _buildChatIcon(),
            const SizedBox(width: 16),
          ],
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: screens,
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white),
          label: Text(
            _unreadMessages > 0 ? 'Chat ($_unreadMessages unread)' : 'Open Chat',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          onPressed: () => UniversalChatBox.show(context, currentTier: _userTier),
        ),
      );
    }

    // Phone & Tablet Layout (Page 1: vertical collapsible sidebar drawer + top bar chat icon)
    return Scaffold(
      drawer: _buildDrawerSidebar(),
      appBar: AppBar(
        title: const Text('Dil Ka Rishta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            tooltip: 'Premium Upgrade',
            icon: const Icon(Icons.workspace_premium, color: Colors.amber),
            onPressed: () => PremiumUpgradeDialog.show(context, currentTier: _userTier),
          ),
          _buildChatIcon(),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        indicatorColor: AppColors.primaryLight,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(Icons.favorite_rounded, color: AppColors.primary),
            label: 'Matches',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search_rounded),
            selectedIcon: Icon(Icons.saved_search_rounded, color: AppColors.primary),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _pendingInterests > 0,
              label: Text('$_pendingInterests'),
              child: const Icon(Icons.mark_email_unread_outlined),
            ),
            selectedIcon: const Icon(Icons.mail_rounded, color: AppColors.primary),
            label: 'Inbox',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
            label: 'My Account',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: AppColors.primary,
        tooltip: 'Chat Box',
        onPressed: () => UniversalChatBox.show(context, currentTier: _userTier),
        child: const Icon(Icons.chat_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}
