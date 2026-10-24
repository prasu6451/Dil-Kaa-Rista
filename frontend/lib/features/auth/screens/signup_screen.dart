import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../profile_creation/models/profile_model.dart';
import '../../profile_creation/screens/profile_wizard_screen.dart';
import '../controllers/auth_controller.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authController = AuthController();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _profileFor = 'Self';
  String _gender = 'Female';
  bool _isLoading = false;
  bool _obscurePassword = true;

  final List<String> _profileForOptions = [
    'Self',
    'Son',
    'Daughter',
    'Brother',
    'Sister',
    'Friend',
    'Relative'
  ];

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final res = await _authController.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _nameController.text.trim(),
        gender: _gender,
      );

      if (!mounted) return;

      if (res.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.error!),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      if (res.user != null) {
        final initialProfile = res.profile ?? ProfileModel(
          id: res.user!.id,
          fullName: _nameController.text.trim(),
          gender: _gender,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created! Let\'s setup your profile.'),
            backgroundColor: AppColors.success,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileWizardScreen(initialProfile: initialProfile),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign up error: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start your journey today',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Fill in the details to create a free matrimony profile',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),

                // Profile For Dropdown
                const Text(
                  'Creating Profile For',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _profileFor,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.people_outline),
                  ),
                  items: _profileForOptions
                      .map((opt) =>
                          DropdownMenuItem(value: opt, child: Text(opt)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _profileFor = val;
                        if (val == 'Son' || val == 'Brother') {
                          _gender = 'Male';
                        } else if (val == 'Daughter' || val == 'Sister') {
                          _gender = 'Female';
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Gender Selection
                const Text(
                  'Gender',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Female / Bride')),
                        selected: _gender == 'Female',
                        selectedColor: AppColors.primaryLight,
                        onSelected: (selected) {
                          if (selected) setState(() => _gender = 'Female');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Male / Groom')),
                        selected: _gender == 'Male',
                        selectedColor: AppColors.primaryLight,
                        onSelected: (selected) {
                          if (selected) setState(() => _gender = 'Male');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Full Name
                const Text(
                  'Full Name',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Anjali Sharma',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Please enter name' : null,
                ),
                const SizedBox(height: 16),

                // Email
                const Text(
                  'Email Address',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'e.g. anjali@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter email';
                    }
                    if (!val.contains('@') || !val.contains('.')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                const Text(
                  'Password',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Minimum 6 characters',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (val) =>
                      val == null || val.length < 6 ? 'Password must be at least 6 characters' : null,
                ),
                const SizedBox(height: 28),

                // Register Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignup,
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Register & Continue'),
                  ),
                ),
                const SizedBox(height: 16),

                // Already have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? '),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
