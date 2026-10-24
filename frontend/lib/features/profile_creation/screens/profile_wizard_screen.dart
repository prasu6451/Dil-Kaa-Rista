import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../home/screens/home_nav_screen.dart';
import '../models/profile_model.dart';
import 'steps/basic_info_step.dart';
import 'steps/cultural_info_step.dart';
import 'steps/career_education_step.dart';
import 'steps/photo_upload_step.dart';

class ProfileWizardScreen extends StatefulWidget {
  final ProfileModel? initialProfile;

  const ProfileWizardScreen({super.key, this.initialProfile});

  @override
  State<ProfileWizardScreen> createState() => _ProfileWizardScreenState();
}

class _ProfileWizardScreenState extends State<ProfileWizardScreen> {
  final _pageController = PageController();
  final _authController = AuthController();
  int _currentStep = 0;
  bool _isSaving = false;

  // Step 1: Basic
  DateTime? _dateOfBirth;
  String _maritalStatus = 'Never Married';
  int _heightCm = 165;
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  // Step 2: Cultural
  String _religion = 'Hindu';
  String _motherTongue = 'Hindi';
  final _casteController = TextEditingController();
  final _gotraController = TextEditingController();

  // Step 3: Career
  final _educationController = TextEditingController();
  final _occupationController = TextEditingController();
  String _annualIncome = '₹5 Lakh - ₹7.5 Lakh';

  // Step 4: Photo & Bio
  File? _selectedImage;
  String? _avatarUrl;
  bool _isPhotoLocked = false;
  final _aboutMeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _populateInitialData();
  }

  void _populateInitialData() {
    final p = widget.initialProfile;
    if (p != null) {
      _dateOfBirth = p.dateOfBirth;
      _maritalStatus = p.maritalStatus ?? 'Never Married';
      _heightCm = p.heightCm ?? 165;
      _cityController.text = p.city ?? '';
      _stateController.text = p.state ?? '';
      _religion = p.religion ?? 'Hindu';
      _motherTongue = p.motherTongue ?? 'Hindi';
      _casteController.text = p.caste ?? '';
      _gotraController.text = p.gotra ?? '';
      _educationController.text = p.education ?? '';
      _occupationController.text = p.occupation ?? '';
      _annualIncome = p.annualIncome ?? '₹5 Lakh - ₹7.5 Lakh';
      _avatarUrl = p.avatarUrl;
      _isPhotoLocked = p.isPhotoLocked;
      _aboutMeController.text = p.aboutMe ?? '';
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _casteController.dispose();
    _gotraController.dispose();
    _educationController.dispose();
    _occupationController.dispose();
    _aboutMeController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveAndFinish() async {
    final user = _authController.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      // 1. Upload photo if newly chosen
      String? finalAvatarUrl = _avatarUrl;
      if (_selectedImage != null) {
        final uploadedUrl = await _authController.uploadProfilePhoto(
          _selectedImage!,
          user.id,
        );
        if (uploadedUrl != null) {
          finalAvatarUrl = uploadedUrl;
        }
      }

      // 2. Construct profile object
      final updatedProfile = ProfileModel(
        id: user.id,
        fullName: widget.initialProfile?.fullName ??
            (user.fullName.isNotEmpty ? user.fullName : 'Member'),
        gender: widget.initialProfile?.gender ??
            (user.gender.isNotEmpty ? user.gender : 'Female'),
        dateOfBirth: _dateOfBirth,
        maritalStatus: _maritalStatus,
        heightCm: _heightCm,
        religion: _religion,
        motherTongue: _motherTongue,
        caste: _casteController.text.trim(),
        gotra: _gotraController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        education: _educationController.text.trim(),
        occupation: _occupationController.text.trim(),
        annualIncome: _annualIncome,
        aboutMe: _aboutMeController.text.trim(),
        avatarUrl: finalAvatarUrl,
        isPhotoLocked: _isPhotoLocked,
      );

      // 3. Save to Django / PostgreSQL
      await _authController.saveProfile(updatedProfile);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile created successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeNavScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _handleSaveAndFinish();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const totalSteps = 4;
    final stepTitles = ['Basic', 'Culture', 'Career', 'Photo & Bio'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _prevStep,
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Step ${_currentStep + 1} of $totalSteps: ${stepTitles[_currentStep]}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        '${((_currentStep + 1) / totalSteps * 100).toInt()}% Done',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (_currentStep + 1) / totalSteps,
                    backgroundColor: Colors.grey.shade200,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 6,
                  ),
                ],
              ),
            ),

            // Wizard Step Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (idx) => setState(() => _currentStep = idx),
                children: [
                  BasicInfoStep(
                    dateOfBirth: _dateOfBirth,
                    onDateChanged: (d) => setState(() => _dateOfBirth = d),
                    maritalStatus: _maritalStatus,
                    onMaritalStatusChanged: (s) =>
                        setState(() => _maritalStatus = s),
                    heightCm: _heightCm,
                    onHeightChanged: (h) => setState(() => _heightCm = h),
                    cityController: _cityController,
                    stateController: _stateController,
                  ),
                  CulturalInfoStep(
                    religion: _religion,
                    onReligionChanged: (r) => setState(() => _religion = r),
                    motherTongue: _motherTongue,
                    onMotherTongueChanged: (m) =>
                        setState(() => _motherTongue = m),
                    casteController: _casteController,
                    gotraController: _gotraController,
                  ),
                  CareerEducationStep(
                    educationController: _educationController,
                    occupationController: _occupationController,
                    annualIncome: _annualIncome,
                    onIncomeChanged: (i) => setState(() => _annualIncome = i),
                  ),
                  PhotoUploadStep(
                    selectedImage: _selectedImage,
                    existingAvatarUrl: _avatarUrl,
                    onImageSelected: (img) =>
                        setState(() => _selectedImage = img),
                    aboutMeController: _aboutMeController,
                    isPhotoLocked: _isPhotoLocked,
                    onPhotoLockChanged: (locked) =>
                        setState(() => _isPhotoLocked = locked),
                  ),
                ],
              ),
            ),

            // Bottom Navigation Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentStep > 0) ...[
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: _prevStep,
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _nextStep,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _currentStep == 3 ? 'Complete Profile' : 'Save & Continue',
                            ),
                    ),
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
