import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../chat/screens/chat_screen.dart';

class InboxTabScreen extends StatefulWidget {
  final VoidCallback? onNavigateToPreferences;

  const InboxTabScreen({super.key, this.onNavigateToPreferences});

  @override
  State<InboxTabScreen> createState() => _InboxTabScreenState();
}

class _InboxTabScreenState extends State<InboxTabScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  // Active items for current tab
  List<dynamic> _items = [];
  final Set<String> _selectedIds = {};

  final List<String> _folders = ['received', 'filtered_out', 'requests', 'accepted', 'deleted'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _selectedIds.clear();
        _loadFolderData();
      }
    });
    _loadFolderData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFolderData() async {
    setState(() => _isLoading = true);
    final idx = _tabController.index;
    final folder = _folders[idx];

    if (folder == 'requests') {
      final res = await ApiService.instance.fetchPhotoOrContactRequests(folder: 'received');
      if (mounted) setState(() { _items = res; _isLoading = false; });
    } else {
      final res = await ApiService.instance.fetchInbox(folder: folder);
      if (mounted) setState(() { _items = res; _isLoading = false; });
    }
  }

  Future<void> _executeBulkAction(String action) async {
    if (_selectedIds.isEmpty) return;
    final success = await ApiService.instance.bulkInboxAction(action, _selectedIds.toList());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Bulk action $action completed.' : 'Action failed.'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
      _selectedIds.clear();
      _loadFolderData();
    }
  }

  Future<void> _respondPhotoContactRequest(String reqId, String status) async {
    final success = await ApiService.instance.respondPhotoOrContactRequest(reqId, status);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Request $status.' : 'Failed to update request.'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
      _loadFolderData();
    }
  }

  Widget _buildBulkActionBar() {
    if (_selectedIds.isEmpty) return const SizedBox.shrink();
    return Container(
      color: Colors.amber.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_selectedIds.length} Selected',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
          ),
          Row(
            children: [
              TextButton.icon(
                icon: const Icon(Icons.check, size: 16, color: Colors.green),
                label: const Text('Accept', style: TextStyle(color: Colors.green)),
                onPressed: () => _executeBulkAction('accept'),
              ),
              TextButton.icon(
                icon: const Icon(Icons.close, size: 16, color: Colors.red),
                label: const Text('Decline', style: TextStyle(color: Colors.red)),
                onPressed: () => _executeBulkAction('decline'),
              ),
              TextButton.icon(
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.black54),
                label: const Text('Delete', style: TextStyle(color: Colors.black54)),
                onPressed: () => _executeBulkAction('delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredOutBanner() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt_off_rounded, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filtered by your "Must-have" criteria',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Text(
                  'These members sent interest but fell outside your strict preferences.',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: widget.onNavigateToPreferences,
            child: const Text('Edit Filters', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentFolder = _folders[_tabController.index];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.black54,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: '1. Interests Received'),
            Tab(text: '2. Filtered Out'),
            Tab(text: '3. Requests Tab'),
            Tab(text: '4. Accepted Members'),
            Tab(text: '5. Deleted Folder'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Bulk Action Bar (Page 5)
          _buildBulkActionBar(),

          // Filtered Out notice with link to edit partner preferences (Page 5)
          if (currentFolder == 'filtered_out') _buildFilteredOutBanner(),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No records in ${currentFolder.replaceAll('_', ' ')}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadFolderData,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _items.length,
                          separatorBuilder: (_, index) => const Divider(height: 1),
                          itemBuilder: (context, idx) {

                            final item = _items[idx];

                            // Requests tab (Photo/Contact)
                            if (currentFolder == 'requests') {
                              final senderProfile = item['sender_profile'] ?? {};
                              final reqType = item['request_type'] ?? 'contact';
                              final status = item['status'] ?? 'pending';

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: (senderProfile['avatar_url'] != null)
                                      ? CachedNetworkImageProvider(senderProfile['avatar_url'])
                                      : null,
                                  child: senderProfile['avatar_url'] == null ? const Icon(Icons.person) : null,
                                ),
                                title: Text(
                                  senderProfile['display_name'] ?? 'Member',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'Requested: ${reqType.toUpperCase()} ($status)',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: status == 'pending'
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.check_circle, color: Colors.green),
                                            tooltip: 'Approve',
                                            onPressed: () => _respondPhotoContactRequest(item['id'], 'accepted'),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.cancel, color: Colors.red),
                                            tooltip: 'Decline',
                                            onPressed: () => _respondPhotoContactRequest(item['id'], 'declined'),
                                          ),
                                        ],
                                      )
                                    : Chip(
                                        label: Text(status.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white)),
                                        backgroundColor: status == 'accepted' ? Colors.green : Colors.grey,
                                      ),
                              );
                            }

                            // Interests Received, Filtered Out, Accepted, Deleted
                            final profileData = item['sender_profile'] ?? item['receiver_profile'] ?? {};
                            final reqId = item['id']?.toString() ?? '';
                            final isSelected = _selectedIds.contains(reqId);

                            return ListTile(
                              leading: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (currentFolder == 'received' || currentFolder == 'filtered_out')
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: (val) {
                                        setState(() {
                                          if (val == true) {
                                            _selectedIds.add(reqId);
                                          } else {
                                            _selectedIds.remove(reqId);
                                          }
                                        });
                                      },
                                    ),
                                  CircleAvatar(
                                    backgroundImage: (profileData['avatar_url'] != null)
                                        ? CachedNetworkImageProvider(profileData['avatar_url'])
                                        : null,
                                    child: profileData['avatar_url'] == null ? const Icon(Icons.person) : null,
                                  ),
                                ],
                              ),
                              title: Text(
                                profileData['display_name'] ?? 'Member',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Text(
                                '${profileData['age'] != null ? "${profileData['age']} yrs • " : ""}${profileData['city'] ?? "India"}\nStatus: ${item['status'] ?? "pending"}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              isThreeLine: true,
                              trailing: currentFolder == 'accepted'
                                  ? ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ChatScreen(
                                              otherUserId: profileData['id'] ?? '',
                                              otherUserName: profileData['display_name'] ?? 'Member',
                                              otherUserAvatar: profileData['avatar_url'],
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.chat_bubble_outline, size: 14),
                                      label: const Text('Chat', style: TextStyle(fontSize: 11)),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.check, color: Colors.green),
                                          tooltip: 'Accept',
                                          onPressed: () async {
                                            await ApiService.instance.bulkInboxAction('accept', [reqId]);
                                            _loadFolderData();
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close, color: Colors.red),
                                          tooltip: 'Decline',
                                          onPressed: () async {
                                            await ApiService.instance.bulkInboxAction('decline', [reqId]);
                                            _loadFolderData();
                                          },
                                        ),
                                      ],
                                    ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
