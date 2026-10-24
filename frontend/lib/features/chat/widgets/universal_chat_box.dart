import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../premium/widgets/premium_upgrade_dialog.dart';
import '../screens/chat_screen.dart';

class UniversalChatBox extends StatefulWidget {
  final String currentTier;

  const UniversalChatBox({super.key, this.currentTier = 'free'});

  static void show(BuildContext context, {String currentTier = 'free'}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UniversalChatBox(currentTier: currentTier),
    );
  }

  @override
  State<UniversalChatBox> createState() => _UniversalChatBoxState();
}

class _UniversalChatBoxState extends State<UniversalChatBox> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _directoryData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDirectory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDirectory() async {
    setState(() => _isLoading = true);
    final data = await ApiService.instance.fetchChatDirectory();
    if (mounted) {
      setState(() {
        _directoryData = data;
        _isLoading = false;
      });
    }
  }

  void _openConversation(String userId, String name, String? avatar) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          otherUserId: userId,
          otherUserName: name,
          otherUserAvatar: avatar,
        ),
      ),
    );
  }

  void _handleInitiateChat(String userId, String name, String? avatar) {
    if (widget.currentTier == 'free') {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.lock, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Initiate Chat Locked', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: const Text(
            'Free members cannot initiate chats. Upgrade to Premium Tier 1 or Tier 2 to start direct messages.',
            style: TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                Navigator.pop(context);
                PremiumUpgradeDialog.show(context, currentTier: widget.currentTier);
              },
              child: const Text('Upgrade Now', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      _openConversation(userId, name, avatar);
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversations = (_directoryData?['conversations'] as List<dynamic>?) ?? [];
    final acceptedMembers = (_directoryData?['accepted_members'] as List<dynamic>?) ?? [];
    final shortlistMembers = (_directoryData?['shortlist_members'] as List<dynamic>?) ?? [];
    final onlineMatches = (_directoryData?['online_matches'] as List<dynamic>?) ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.chat_bubble_rounded, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Universal Chat Box', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.black54,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Conversations (${conversations.length})'),
              Tab(text: 'Accepted (${acceptedMembers.length})'),
              Tab(text: 'Shortlists (${shortlistMembers.length})'),
              Tab(text: 'Online Matches (${onlineMatches.length})'),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // 1. Existing Conversations with unread count and delete support
                      conversations.isEmpty
                          ? const Center(child: Text('No active conversations.'))
                          : ListView.separated(
                              itemCount: conversations.length,
                              separatorBuilder: (_, index) => const Divider(height: 1),
                              itemBuilder: (context, idx) {

                                final conv = conversations[idx];
                                final unread = conv['unread_count'] ?? 0;
                                return ListTile(
                                  leading: Stack(
                                    children: [
                                      CircleAvatar(
                                        backgroundImage: (conv['avatar_url'] != null)
                                            ? CachedNetworkImageProvider(conv['avatar_url'])
                                            : null,
                                        child: conv['avatar_url'] == null ? const Icon(Icons.person) : null,
                                      ),
                                      if (conv['chat_status'] == 'online')
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 2),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  title: Text(conv['name'] ?? 'Member', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(conv['last_message'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (unread > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                                          child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                        tooltip: 'Delete conversation',
                                        onPressed: () async {
                                          await ApiService.instance.deleteConversation(conv['user_id']);
                                          _loadDirectory();
                                        },
                                      ),
                                    ],
                                  ),
                                  onTap: () => _openConversation(conv['user_id'], conv['name'] ?? 'Member', conv['avatar_url']),
                                );
                              },
                            ),

                      // 2. Accepted Members Online
                      acceptedMembers.isEmpty
                          ? const Center(child: Text('No accepted members yet.'))
                          : ListView.builder(
                              itemCount: acceptedMembers.length,
                              itemBuilder: (context, idx) {
                                final m = acceptedMembers[idx];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: (m['avatar_url'] != null) ? CachedNetworkImageProvider(m['avatar_url']) : null,
                                    child: m['avatar_url'] == null ? const Icon(Icons.person) : null,
                                  ),
                                  title: Text(m['name'] ?? 'Member', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(m['is_online'] == true ? 'Online' : 'Offline', style: TextStyle(color: m['is_online'] == true ? Colors.green : Colors.grey, fontSize: 12)),
                                  trailing: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                    onPressed: () => _handleInitiateChat(m['user_id'], m['name'], m['avatar_url']),
                                    child: const Text('Chat', style: TextStyle(color: Colors.white, fontSize: 12)),
                                  ),
                                );
                              },
                            ),

                      // 3. Shortlists Online
                      shortlistMembers.isEmpty
                          ? const Center(child: Text('No shortlisted members.'))
                          : ListView.builder(
                              itemCount: shortlistMembers.length,
                              itemBuilder: (context, idx) {
                                final m = shortlistMembers[idx];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: (m['avatar_url'] != null) ? CachedNetworkImageProvider(m['avatar_url']) : null,
                                    child: m['avatar_url'] == null ? const Icon(Icons.person) : null,
                                  ),
                                  title: Text(m['name'] ?? 'Member', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(m['is_online'] == true ? 'Online now' : 'Offline', style: TextStyle(color: m['is_online'] == true ? Colors.green : Colors.grey, fontSize: 12)),
                                  trailing: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                    onPressed: () => _handleInitiateChat(m['user_id'], m['name'], m['avatar_url']),
                                    child: const Text('Chat', style: TextStyle(color: Colors.white, fontSize: 12)),
                                  ),
                                );
                              },
                            ),

                      // 4. Online Matches
                      onlineMatches.isEmpty
                          ? const Center(child: Text('No matches online right now.'))
                          : ListView.builder(
                              itemCount: onlineMatches.length,
                              itemBuilder: (context, idx) {
                                final m = onlineMatches[idx];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: (m['avatar_url'] != null) ? CachedNetworkImageProvider(m['avatar_url']) : null,
                                    child: m['avatar_url'] == null ? const Icon(Icons.person) : null,
                                  ),
                                  title: Text(m['name'] ?? 'Member', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: const Text('Online now', style: TextStyle(color: Colors.green, fontSize: 12)),
                                  trailing: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                    onPressed: () => _handleInitiateChat(m['user_id'], m['name'], m['avatar_url']),
                                    child: const Text('Chat', style: TextStyle(color: Colors.white, fontSize: 12)),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
