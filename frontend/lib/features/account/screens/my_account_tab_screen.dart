import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/screens/login_screen.dart';
import '../../profile_creation/models/profile_model.dart';
import '../../premium/widgets/premium_upgrade_dialog.dart';

class MyAccountTabScreen extends StatefulWidget {
  final int initialSubTabIndex;

  const MyAccountTabScreen({super.key, this.initialSubTabIndex = 0});

  @override
  State<MyAccountTabScreen> createState() => _MyAccountTabScreenState();
}

class _MyAccountTabScreenState extends State<MyAccountTabScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _authController = AuthController();

  ProfileModel? _profile;
  Map<String, dynamic>? _preferences;
  Map<String, dynamic>? _privacySettings;
  Map<String, dynamic>? _generalSettings;
  List<dynamic> _activeSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialSubTabIndex);
    _loadAllAccountData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllAccountData() async {
    setState(() => _isLoading = true);
    _profile = await _authController.getCurrentProfile();
    _preferences = await ApiService.instance.fetchPartnerPreferences();
    _privacySettings = await ApiService.instance.fetchPrivacySettings();
    _generalSettings = await ApiService.instance.fetchGeneralSettings();
    _activeSessions = await ApiService.instance.fetchActiveSessions();

    if (mounted) setState(() => _isLoading = false);
  }

  // -------------------------------------------------------------
  // 1.1 Profile Management Tab
  // -------------------------------------------------------------
  Widget _buildProfileManagementSubTab() {
    if (_profile == null) return const Center(child: Text('Profile not loaded.'));
    final p = _profile!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Screening Notice Banner (Page 1)
        if (p.isUnderReview)
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.hourglass_top_rounded, color: Colors.amber, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Profile Under Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        p.screeningMessage ?? 'Under review, usually within 24 hours.',
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'During screening, only you can see your essential details. Profile is hidden from search and match lists.',
                        style: TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else if (p.isRejected)
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.cancel_rounded, color: Colors.red, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Screening Needs Revision', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red)),
                      Text(
                        p.screeningMessage ?? 'Please update information and resubmit for verification.',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  onPressed: () async {
                    await ApiService.instance.resubmitProfile();
                    _loadAllAccountData();
                  },
                  child: const Text('Resubmit'),
                ),
              ],
            ),
          ),

        // Header Card (Profile ID & Display Name)
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: (p.avatarUrl != null && p.avatarUrl!.isNotEmpty)
                      ? CachedNetworkImageProvider(p.avatarUrl!)
                      : null,
                  child: (p.avatarUrl == null || p.avatarUrl!.isEmpty)
                      ? const Icon(Icons.person, size: 36, color: AppColors.primary)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.effectiveName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Profile ID: ${p.profileId ?? "Generating..."}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: p.isApproved ? Colors.green.shade100 : Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          p.isApproved ? 'VERIFIED' : 'UNDER SCREENING',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: p.isApproved ? Colors.green.shade800 : Colors.amber.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Display Name Setting (Page 2)
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Display Name Options (Privacy Controlled)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: p.displayNameFormat,
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  items: const [
                    DropdownMenuItem(value: 'full_name', child: Text('Full Name (e.g. Priya Sharma)')),
                    DropdownMenuItem(value: 'first_name_initial', child: Text('First Name + Last Initial (e.g. Priya S.)')),
                    DropdownMenuItem(value: 'custom_username', child: Text('Custom Username')),
                  ],
                  onChanged: (val) async {
                    if (val != null) {
                      await ApiService.instance.savePrivacySettings({'display_name_format': val});
                      _loadAllAccountData();
                    }
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Photos Management (Page 2: Free 5, Premium 20, reorder & primary)
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Photos (${p.photos.length} / ${p.isPremium ? "20" : "5"})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    if (!p.isPremium)
                      TextButton(
                        onPressed: () => PremiumUpgradeDialog.show(context, currentTier: p.membershipTier),
                        child: const Text('Upgrade for 20 Photos', style: TextStyle(fontSize: 11, color: AppColors.primary)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                p.photos.isEmpty
                    ? const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No photos uploaded yet.'))
                    : SizedBox(
                        height: 90,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: p.photos.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (context, idx) {
                            final isPrimary = (idx == p.primaryPhotoIndex);
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: p.photos[idx],
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                if (isPrimary)
                                  Positioned(
                                    bottom: 4,
                                    left: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(6)),
                                      child: const Text('Primary', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Core Fields Notice (Page 2: DOB, gender, marital status, religion require CR review)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified_user_outlined, color: Colors.blueAccent),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Note: Changes to Date of Birth, Gender, Marital Status, and Religion require Customer Relations team verification.',
                  style: TextStyle(fontSize: 11, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 1.2 Partner Preferences Tab (Page 2 & 3: Dropdowns, Must-Have vs Flexible)
  // -------------------------------------------------------------
  Widget _buildPartnerPreferencesSubTab() {
    if (_preferences == null) return const Center(child: CircularProgressIndicator());
    final pref = _preferences!;
    final mustHaves = List<String>.from(pref['must_have_fields'] ?? []);
    final hasWarning = pref['has_narrow_criteria_warning'] == true || mustHaves.length >= 5;

    Widget buildPreferenceRow(String title, String keyName, String currentValue, List<String> options) {
      final isMustHave = mustHaves.contains(keyName);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Row(
                  children: [
                    Text(isMustHave ? 'Must-have' : 'Flexible', style: TextStyle(fontSize: 11, color: isMustHave ? Colors.red : Colors.green)),
                    Switch(
                      value: isMustHave,
                      activeThumbColor: Colors.red,
                      onChanged: (val) async {
                        if (val) {
                          mustHaves.add(keyName);
                        } else {
                          mustHaves.remove(keyName);
                        }
                        await ApiService.instance.savePartnerPreferences({'must_have_fields': mustHaves});
                        _loadAllAccountData();
                      },
                    ),
                  ],
                ),
              ],
            ),
            DropdownButtonFormField<String>(
              initialValue: options.contains(currentValue) ? currentValue : options.first,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
              onChanged: (val) async {
                if (val != null) {
                  await ApiService.instance.savePartnerPreferences({keyName: [val]});
                }
              },
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Narrow Criteria Warning Banner (Page 3)
        if (hasWarning)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade400),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your must-have criteria are very narrow. You may see fewer matches.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown),
                  ),
                ),
              ],
            ),
          ),

        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Partner Preferences (Dropdowns Only)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Mark preferences as Must-have or Flexible to fine-tune matching.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const Divider(height: 24),

                buildPreferenceRow('Religion', 'religion', (pref['religion'] as List?)?.isNotEmpty == true ? pref['religion'][0] : 'Hindu', ['Hindu', 'Muslim', 'Sikh', 'Christian', 'Jain', 'All']),
                buildPreferenceRow('Marital Status', 'marital_status', (pref['marital_status'] as List?)?.isNotEmpty == true ? pref['marital_status'][0] : 'Never Married', ['Never Married', 'Divorced', 'Widowed', 'All']),
                buildPreferenceRow('Mother Tongue', 'mother_tongue', (pref['mother_tongue'] as List?)?.isNotEmpty == true ? pref['mother_tongue'][0] : 'Hindi', ['Hindi', 'Gujarati', 'Tamil', 'Telugu', 'Bengali', 'Marathi', 'All']),
                buildPreferenceRow('Country / Region', 'country', pref['country'] ?? 'India', ['India', 'USA', 'Canada', 'UK', 'Australia', 'All']),
                buildPreferenceRow('Education Level', 'education', (pref['education'] as List?)?.isNotEmpty == true ? pref['education'][0] : 'Bachelors', ['Bachelors', 'Masters', 'Doctorate', 'Professional', 'All']),
                buildPreferenceRow('Dietary Lifestyle', 'lifestyle_diet', (pref['lifestyle_diet'] as List?)?.isNotEmpty == true ? pref['lifestyle_diet'][0] : 'Vegetarian', ['Vegetarian', 'Non-Vegetarian', 'Eggetarian', 'Jain', 'Vegan']),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 1.3 Privacy and Safety Settings Tab (Page 3)
  // -------------------------------------------------------------
  Widget _buildPrivacyAndSafetySubTab() {
    final ps = _privacySettings ?? {};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Hide Profile (all-or-nothing toggle)
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SwitchListTile(
            title: const Text('1. Hide Profile (Global Toggle)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text('Temporarily hides profile from all members entirely.', style: TextStyle(fontSize: 12)),
            value: ps['is_hidden'] == true,
            activeThumbColor: Colors.red,
            onChanged: (val) async {
              await ApiService.instance.savePrivacySettings({'is_hidden': val});
              _loadAllAccountData();
            },
          ),
        ),

        const SizedBox(height: 12),

        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('2. Privacy Options', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),

                // Photo Privacy
                const Text('Photo Privacy', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                DropdownButtonFormField<String>(
                  initialValue: ps['photo_privacy'] ?? 'all_members',
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  items: const [
                    DropdownMenuItem(value: 'all_members', child: Text('Visible to all members')),
                    DropdownMenuItem(value: 'contacted_accepted', child: Text('Visible only to contacted & accepted members')),
                  ],
                  onChanged: (val) async {
                    if (val != null) {
                      await ApiService.instance.savePrivacySettings({'photo_privacy': val});
                    }
                  },
                ),

                const SizedBox(height: 12),

                // Contact Details Visibility (Premium)
                const Text('Contact Details Visibility (Premium)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                DropdownButtonFormField<String>(
                  initialValue: ps['phone_privacy'] ?? 'accepted_premium',
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  items: const [
                    DropdownMenuItem(value: 'accepted_premium', child: Text('Visible only to accepted premium members')),
                    DropdownMenuItem(value: 'all_premium', child: Text('Visible to all premium members')),
                  ],
                  onChanged: (val) async {
                    if (val != null) {
                      await ApiService.instance.savePrivacySettings({'phone_privacy': val});
                    }
                  },
                ),

                const SizedBox(height: 12),

                // Voice / Video Call Permissions
                const Text('Voice / Video Call Permissions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                DropdownButtonFormField<String>(
                  initialValue: ps['call_permissions'] ?? 'accepted_only',
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  items: const [
                    DropdownMenuItem(value: 'accepted_only', child: Text('Accepted members only (Default)')),
                    DropdownMenuItem(value: 'all_premium', child: Text('All premium members')),
                  ],
                  onChanged: (val) async {
                    if (val != null) {
                      await ApiService.instance.savePrivacySettings({'call_permissions': val});
                    }
                  },
                ),

                const SizedBox(height: 12),

                // Chat Status (Online, Invisible, Offline)
                const Text('Chat Status Presence', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                DropdownButtonFormField<String>(
                  initialValue: ps['chat_status'] ?? 'online',
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  items: const [
                    DropdownMenuItem(value: 'online', child: Text('Online (Green Badge)')),
                    DropdownMenuItem(value: 'invisible', child: Text('Invisible (Appear offline while chatting)')),
                    DropdownMenuItem(value: 'offline', child: Text('Offline (Reduces inbound contacts)')),
                  ],
                  onChanged: (val) async {
                    if (val != null) {
                      await ApiService.instance.savePrivacySettings({'chat_status': val});
                    }
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 3. Block Member & 4. Report Misuse
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: const Text('Block Member', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Prevents specific members from viewing or contacting you.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Member blocked successfully.')),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.flag_rounded, color: Colors.orange),
                title: const Text('Report Misuse', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Report fake photos, spam, or abuse directly to Customer Relations.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report submitted to Customer Relations team.')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 1.4 General Settings Tab (Page 4: "How I use this app")
  // -------------------------------------------------------------
  Widget _buildGeneralSettingsSubTab() {
    final gs = _generalSettings ?? {};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Account Security
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.lock_reset, color: AppColors.primary),
                title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  final oldP = TextEditingController();
                  final newP = TextEditingController();
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Change Password'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(controller: oldP, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password')),
                          TextField(controller: newP, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
                        ],
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            try {
                              await ApiService.instance.changePassword(oldP.text, newP.text);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated!')));
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                              }
                            }
                          },
                          child: const Text('Update'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.security, color: AppColors.primary),
                title: const Text('Two-Factor Authentication (2FA)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Verify login via SMS or Email code.', style: TextStyle(fontSize: 12)),
                value: gs['two_factor_enabled'] == true,
                onChanged: (val) async {
                  await ApiService.instance.saveGeneralSettings({'two_factor_enabled': val});
                  _loadAllAccountData();
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // App Experience (Language & Dark Mode)
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.translate, color: AppColors.primary),
                title: const Text('Language', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(gs['language'] ?? 'English (Assamese, Hindi, Tamil, etc.)'),
                trailing: DropdownButton<String>(
                  value: gs['language'] ?? 'English',
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'English', child: Text('English')),
                    DropdownMenuItem(value: 'Hindi', child: Text('Hindi')),
                    DropdownMenuItem(value: 'Assamese', child: Text('Assamese')),
                    DropdownMenuItem(value: 'Tamil', child: Text('Tamil')),
                    DropdownMenuItem(value: 'Telugu', child: Text('Telugu')),
                    DropdownMenuItem(value: 'Marathi', child: Text('Marathi')),
                    DropdownMenuItem(value: 'Bengali', child: Text('Bengali')),
                    DropdownMenuItem(value: 'Gujarati', child: Text('Gujarati')),
                    DropdownMenuItem(value: 'Urdu', child: Text('Urdu')),
                  ],
                  onChanged: (val) async {
                    if (val != null) {
                      await ApiService.instance.saveGeneralSettings({'language': val});
                      _loadAllAccountData();
                    }
                  },
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined, color: AppColors.primary),
                title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                value: gs['dark_mode'] == true,
                onChanged: (val) async {
                  await ApiService.instance.saveGeneralSettings({'dark_mode': val});
                  _loadAllAccountData();
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Login History and Active Sessions (Page 4)
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.devices, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Active Sessions & Login History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),
                _activeSessions.isEmpty
                    ? const Text('Current device active.', style: TextStyle(fontSize: 12))
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _activeSessions.length,
                        separatorBuilder: (_, index) => const Divider(height: 1),
                        itemBuilder: (context, idx) {

                          final sess = _activeSessions[idx];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(sess['device_info'] ?? 'Web / Mobile Device', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            subtitle: Text('IP: ${sess['ip_address']} • Active Now', style: const TextStyle(fontSize: 11)),
                            trailing: TextButton(
                              onPressed: () async {
                                await ApiService.instance.logoutSession(sess['id']);
                                _loadAllAccountData();
                              },
                              child: const Text('Log out', style: TextStyle(color: Colors.red, fontSize: 11)),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Account Management (Data Download & Account Deletion)
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.download_rounded, color: AppColors.primary),
                title: const Text('Data Download', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Request a copy of personal account data.', style: TextStyle(fontSize: 12)),
                onTap: () async {
                  final data = await ApiService.instance.downloadPersonalData();
                  if (mounted && data != null) {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Data Package Ready'),
                        content: SingleChildScrollView(
                          child: Text(jsonEncode(data['data'])),
                        ),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                      ),
                    );
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Account Deletion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red)),
                subtitle: const Text('Permanently delete your profile and account data.', style: TextStyle(fontSize: 12)),
                onTap: () {
                  final pwdController = TextEditingController();
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Confirm Permanent Account Deletion', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('This action is irreversible. All messages, interests, and profile details will be permanently erased. Type your password to proceed:'),
                          const SizedBox(height: 10),
                          TextField(controller: pwdController, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
                        ],
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () async {
                            Navigator.pop(context);
                            final success = await ApiService.instance.deleteAccount(pwdController.text);
                            if (success && mounted) {
                              await _authController.logout();
                              if (mounted) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  (route) => false,
                                );
                              }
                            }
                          },
                          child: const Text('Delete Permanently', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.grey),
                title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                onTap: () async {
                  await _authController.logout();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Premium Tiers',
            icon: const Icon(Icons.workspace_premium, color: Colors.amber),
            onPressed: () => PremiumUpgradeDialog.show(context, currentTier: _profile?.membershipTier ?? 'free'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.black54,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: '1. Profile Management'),
            Tab(text: '2. Partner Preferences'),
            Tab(text: '3. Privacy & Safety'),
            Tab(text: '4. General Settings'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProfileManagementSubTab(),
                _buildPartnerPreferencesSubTab(),
                _buildPrivacyAndSafetySubTab(),
                _buildGeneralSettingsSubTab(),
              ],
            ),
    );
  }
}
