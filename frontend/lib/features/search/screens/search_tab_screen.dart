import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../profile_creation/models/profile_model.dart';
import '../../matches/widgets/match_card_full_widget.dart';

class SearchTabScreen extends StatefulWidget {
  const SearchTabScreen({super.key});

  @override
  State<SearchTabScreen> createState() => _SearchTabScreenState();
}

class _SearchTabScreenState extends State<SearchTabScreen> {
  final _authController = AuthController();
  ProfileModel? _currentUserProfile;

  // Search Mode: 'form' | 'results' | 'saved' | 'history'
  String _activeView = 'form';
  bool _isLoading = false;
  List<ProfileModel> _searchResults = [];

  // Basic Search Fields (Page 5)
  double _minAge = 21;
  double _maxAge = 35;
  String _maritalStatus = '';
  String _religion = '';
  String _location = '';

  // Advanced Search Fields (Page 5)
  String _education = '';
  String _profession = '';
  String _keyword = '';
  bool _specialCasesOnly = false;
  bool _onlineOnly = false;
  String _sortBy = 'relevance'; // relevance, newest, recently_active

  // Saved Searches & History (Page 5)
  List<dynamic> _savedSearches = [];
  List<dynamic> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    _loadUserAndSavedData();
  }

  Future<void> _loadUserAndSavedData() async {
    _currentUserProfile = await _authController.getCurrentProfile();
    _savedSearches = await ApiService.instance.fetchSavedSearches();
    _searchHistory = await ApiService.instance.fetchSearchHistory();
    if (mounted) setState(() {});
  }

  Future<void> _executeSearch() async {
    setState(() {
      _isLoading = true;
      _activeView = 'results';
    });

    final params = <String, String>{
      'min_age': _minAge.toInt().toString(),
      'max_age': _maxAge.toInt().toString(),
      'sort_by': _sortBy,
    };
    if (_maritalStatus.isNotEmpty) params['marital_status'] = _maritalStatus;
    if (_religion.isNotEmpty) params['religion'] = _religion;
    if (_location.isNotEmpty) params['city'] = _location;
    if (_education.isNotEmpty) params['education'] = _education;
    if (_profession.isNotEmpty) params['profession'] = _profession;
    if (_keyword.isNotEmpty) params['keyword'] = _keyword;
    if (_specialCasesOnly) params['special_cases'] = 'true';
    if (_onlineOnly) params['online_only'] = 'true';

    final results = await ApiService.instance.searchProfiles(params);

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
      // Refresh search history
      _searchHistory = await ApiService.instance.fetchSearchHistory();
    }
  }

  Future<void> _handleSaveSearch() async {
    final titleController = TextEditingController(text: 'Search ${_minAge.toInt()}-${_maxAge.toInt()} ${_religion.isNotEmpty ? _religion : "All"}');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Save Search Filter (Up to 5)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: titleController,
          decoration: InputDecoration(
            labelText: 'Search Title',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              final filters = {
                'min_age': _minAge.toInt(),
                'max_age': _maxAge.toInt(),
                'religion': _religion,
                'city': _location,
                'education': _education,
                'profession': _profession,
                'keyword': _keyword,
                'special_cases': _specialCasesOnly,
                'online_only': _onlineOnly,
              };
              final success = await ApiService.instance.saveSearch(titleController.text.trim(), filters);
              if (mounted) {
                _savedSearches = await ApiService.instance.fetchSavedSearches();
                setState(() {});
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Search starred and saved!' : 'Failed to save (Max 5 allowed).'),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),

        ],
      ),
    );
  }

  void _applySavedSearch(Map<String, dynamic> filters) {
    setState(() {
      _minAge = (filters['min_age'] ?? 21).toDouble();
      _maxAge = (filters['max_age'] ?? 35).toDouble();
      _religion = filters['religion'] ?? '';
      _location = filters['city'] ?? '';
      _education = filters['education'] ?? '';
      _profession = filters['profession'] ?? '';
      _keyword = filters['keyword'] ?? '';
      _specialCasesOnly = filters['special_cases'] == true;
      _onlineOnly = filters['online_only'] == true;
    });
    _executeSearch();
  }

  Widget _buildSearchForm() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Basic Search Card (Page 5)
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.search, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('1. Basic Search', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Age Range: ${_minAge.toInt()} to ${_maxAge.toInt()} years',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                RangeSlider(
                  values: RangeValues(_minAge, _maxAge),
                  min: 18,
                  max: 65,
                  divisions: 47,
                  activeColor: AppColors.primary,
                  onChanged: (vals) => setState(() {
                    _minAge = vals.start;
                    _maxAge = vals.end;
                  }),
                ),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _religion.isEmpty ? null : _religion,
                        decoration: InputDecoration(
                          labelText: 'Religion',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: '', child: Text('All Religions')),
                          DropdownMenuItem(value: 'Hindu', child: Text('Hindu')),
                          DropdownMenuItem(value: 'Muslim', child: Text('Muslim')),
                          DropdownMenuItem(value: 'Sikh', child: Text('Sikh')),
                          DropdownMenuItem(value: 'Christian', child: Text('Christian')),
                          DropdownMenuItem(value: 'Jain', child: Text('Jain')),
                          DropdownMenuItem(value: 'Buddhist', child: Text('Buddhist')),
                        ],
                        onChanged: (val) => setState(() => _religion = val ?? ''),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _maritalStatus.isEmpty ? null : _maritalStatus,
                        decoration: InputDecoration(
                          labelText: 'Marital Status',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: '', child: Text('Any Status')),
                          DropdownMenuItem(value: 'Never Married', child: Text('Never Married')),
                          DropdownMenuItem(value: 'Divorced', child: Text('Divorced')),
                          DropdownMenuItem(value: 'Widowed', child: Text('Widowed')),
                          DropdownMenuItem(value: 'Awaiting Divorce', child: Text('Awaiting Divorce')),
                        ],
                        onChanged: (val) => setState(() => _maritalStatus = val ?? ''),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Location (City or State)',
                    hintText: 'e.g. Mumbai, Delhi, Gujarat',
                    prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (val) => _location = val.trim(),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Advanced Search Card (Page 5)
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.filter_list, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('2. Advanced Search', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Education',
                          hintText: 'e.g. B.Tech, MBA, MBBS',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (val) => _education = val.trim(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Profession',
                          hintText: 'e.g. Software, Banking',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (val) => _profession = val.trim(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Keyword in "About Me"',
                    hintText: 'e.g. traveling, reading, badminton',
                    prefixIcon: const Icon(Icons.menu_book_rounded, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (val) => _keyword = val.trim(),
                ),
                const SizedBox(height: 12),

                // Dedicated "Special Cases" Filter (Page 5: respectful language, not bundled with other filters)
                Material(
                  color: Colors.blue.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.blue.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Special Cases (Differently Abled Members)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                      ),
                      subtitle: const Text(
                        'Inclusive matching with verified, respectful community support.',
                        style: TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                      value: _specialCasesOnly,
                      onChanged: (val) => setState(() => _specialCasesOnly = val),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Who is Online filter (Page 5)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Who is Online (Active Members Only)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  value: _onlineOnly,
                  onChanged: (val) => setState(() => _onlineOnly = val),
                ),

                const SizedBox(height: 10),

                // Sort By
                DropdownButtonFormField<String>(
                  initialValue: _sortBy,
                  decoration: InputDecoration(
                    labelText: 'Sort Results By',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'relevance', child: Text('Relevance')),
                    DropdownMenuItem(value: 'newest', child: Text('Newest First')),
                    DropdownMenuItem(value: 'recently_active', child: Text('Recently Active')),
                  ],
                  onChanged: (val) => setState(() => _sortBy = val ?? 'relevance'),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Action Buttons: Search & Save Search
        Row(
          children: [
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _executeSearch,
                icon: const Icon(Icons.search),
                label: const Text('Search Profiles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _handleSaveSearch,
                icon: const Icon(Icons.star_border),
                label: const Text('Save Search', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // 3. Saved Searches Section (Page 5: up to 5)
        if (_savedSearches.isNotEmpty) ...[
          const Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text('3. Saved Searches (Starred)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _savedSearches.length,
            itemBuilder: (context, idx) {
              final s = _savedSearches[idx];
              return Card(
                child: ListTile(
                  title: Text(s['title'] ?? 'Saved Search', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    onPressed: () async {
                      await ApiService.instance.deleteSavedSearch(s['id']);
                      _savedSearches = await ApiService.instance.fetchSavedSearches();
                      setState(() {});
                    },
                  ),
                  onTap: () => _applySavedSearch(s['filters'] ?? {}),
                ),
              );
            },
          ),
        ],

        const SizedBox(height: 16),

        // 4. Search History Section (Page 5: last 20)
        if (_searchHistory.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.history, color: Colors.grey, size: 20),
                  SizedBox(width: 8),
                  Text('4. Search History (Recent Searches)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
              TextButton(
                onPressed: () async {
                  await ApiService.instance.fetchSearchHistory();
                  setState(() => _searchHistory = []);
                },
                child: const Text('Clear', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _searchHistory.take(8).length,
            itemBuilder: (context, idx) {
              final h = _searchHistory[idx];
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time, size: 16, color: Colors.grey),
                title: Text(h['query_summary'] ?? 'Search query', style: const TextStyle(fontSize: 12)),
                onTap: () => _applySavedSearch(h['filters'] ?? {}),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSearchResults() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.grey.shade100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Found ${_searchResults.length} Match(es)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              TextButton.icon(
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Modify Search'),
                onPressed: () => setState(() => _activeView = 'form'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _searchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('No members found matching your search.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: () => setState(() => _activeView = 'form'),
                            child: const Text('Adjust Search Criteria'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final p = _searchResults[index];
                        return MatchCardFullWidget(
                          profile: p,
                          currentUserProfile: _currentUserProfile,
                          onInterestSent: () => ApiService.instance.sendInterest(receiverId: p.id),
                        );

                      },
                    ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Members', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_activeView == 'results')
            IconButton(
              icon: const Icon(Icons.tune),
              onPressed: () => setState(() => _activeView = 'form'),
            ),
        ],
      ),
      body: _activeView == 'form' ? _buildSearchForm() : _buildSearchResults(),
    );
  }
}
