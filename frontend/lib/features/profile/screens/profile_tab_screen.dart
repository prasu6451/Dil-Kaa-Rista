import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/screens/welcome_screen.dart';
import '../../profile_creation/models/profile_model.dart';
import '../../profile_creation/screens/profile_wizard_screen.dart';

class ProfileTabScreen extends StatefulWidget {
  const ProfileTabScreen({super.key});

  @override
  State<ProfileTabScreen> createState() => _ProfileTabScreenState();
}

class _ProfileTabScreenState extends State<ProfileTabScreen> {
  final _authController = AuthController();
  ProfileModel? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final p = await _authController.getCurrentProfile();
    if (mounted) {
      setState(() {
        _profile = p;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final p = _profile;
    if (p == null) {
      return const Scaffold(
        body: Center(child: Text('Could not load profile')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileWizardScreen(initialProfile: p),
                ),
              );
              _loadProfile();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Profile Header Avatar & Name
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 54,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage:
                        (p.avatarUrl != null && p.avatarUrl!.isNotEmpty)
                            ? CachedNetworkImageProvider(p.avatarUrl!)
                            : null,
                    child: (p.avatarUrl == null || p.avatarUrl!.isEmpty)
                        ? const Icon(Icons.person,
                            size: 60, color: AppColors.primary)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    p.fullName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${p.age != null ? '${p.age} yrs' : ''}${p.city != null && p.city!.isNotEmpty ? ' • ${p.city}' : ''}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Edit Profile Button
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileWizardScreen(initialProfile: p),
                        ),
                      );
                      _loadProfile();
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit Profile & Photos'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(180, 38),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Info Cards
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profile Summary',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Divider(height: 20),
                  _buildRow('Religion', p.religion ?? 'Not specified'),
                  _buildRow('Mother Tongue', p.motherTongue ?? 'Not specified'),
                  _buildRow('Caste', p.caste ?? 'Not specified'),
                  _buildRow('Education', p.education ?? 'Not specified'),
                  _buildRow('Profession', p.occupation ?? 'Not specified'),
                  _buildRow('Annual Income', p.annualIncome ?? 'Not specified'),
                  _buildRow('Marital Status', p.maritalStatus ?? 'Never Married'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Settings & Logout
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined,
                        color: AppColors.primary),
                    title: const Text('Photo Privacy'),
                    subtitle: Text(
                      p.isPhotoLocked
                          ? 'Photo is locked for privacy'
                          : 'Photo is visible to everyone',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Switch(
                      value: p.isPhotoLocked,
                      activeThumbColor: AppColors.primary,
                      onChanged: (locked) async {
                        final updated = p.copyWith(isPhotoLocked: locked);
                        await _authController.saveProfile(updated);
                        _loadProfile();
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading:
                        const Icon(Icons.logout, color: AppColors.error),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: AppColors.error),
                    ),
                    onTap: () async {
                      await _authController.signOut();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WelcomeScreen(),
                        ),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
