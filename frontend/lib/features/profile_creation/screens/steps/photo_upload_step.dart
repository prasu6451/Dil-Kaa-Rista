import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';

class PhotoUploadStep extends StatelessWidget {
  final File? selectedImage;
  final String? existingAvatarUrl;
  final ValueChanged<File> onImageSelected;
  final TextEditingController aboutMeController;
  final bool isPhotoLocked;
  final ValueChanged<bool> onPhotoLockChanged;

  const PhotoUploadStep({
    super.key,
    required this.selectedImage,
    required this.existingAvatarUrl,
    required this.onImageSelected,
    required this.aboutMeController,
    required this.isPhotoLocked,
    required this.onPhotoLockChanged,
  });

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      onImageSelected(File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Photo & About You',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Profiles with photos get 5x more responses and interest',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // Photo Picker Box
          Center(
            child: GestureDetector(
              onTap: () => _pickImage(context),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary,
                        width: 3,
                      ),
                      image: selectedImage != null
                          ? DecorationImage(
                              image: FileImage(selectedImage!),
                              fit: BoxFit.cover,
                            )
                          : (existingAvatarUrl != null &&
                                  existingAvatarUrl!.isNotEmpty)
                              ? DecorationImage(
                                  image: NetworkImage(existingAvatarUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                    ),
                    child: (selectedImage == null &&
                            (existingAvatarUrl == null ||
                                existingAvatarUrl!.isEmpty))
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                size: 40,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add Photo',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Tap to upload your display picture',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Photo Privacy Toggle
          Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Protect / Lock Photo',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: const Text(
                  'Visible only to members whose interest you accept',
                  style: TextStyle(fontSize: 12),
                ),
                value: isPhotoLocked,
                activeThumbColor: AppColors.primary,
                onChanged: onPhotoLockChanged,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // About Me Bio
          const Text(
            'About Myself (Bio)',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: aboutMeController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText:
                  'Describe your personality, hobbies, family background, and what you are looking for in a life partner...',
            ),
          ),
        ],
      ),
    );
  }
}
