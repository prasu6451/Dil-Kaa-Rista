import 'package:flutter/material.dart';

class CulturalInfoStep extends StatelessWidget {
  final String? religion;
  final ValueChanged<String> onReligionChanged;
  final String? motherTongue;
  final ValueChanged<String> onMotherTongueChanged;
  final TextEditingController casteController;
  final TextEditingController gotraController;

  const CulturalInfoStep({
    super.key,
    required this.religion,
    required this.onReligionChanged,
    required this.motherTongue,
    required this.onMotherTongueChanged,
    required this.casteController,
    required this.gotraController,
  });

  static const List<String> religions = [
    'Hindu',
    'Muslim',
    'Christian',
    'Sikh',
    'Jain',
    'Buddhist',
    'Parsi',
    'Jewish',
    'Spiritual - Not Religious',
    'Other'
  ];

  static const List<String> motherTongues = [
    'Hindi',
    'Marathi',
    'Gujarati',
    'Bengali',
    'Punjabi',
    'Tamil',
    'Telugu',
    'Kannada',
    'Malayalam',
    'Odia',
    'Marwari',
    'Urdu',
    'English',
    'Other'
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Religion & Community',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Important for community preferences and horoscope matching',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // Religion
          const Text(
            'Religion',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: religion ?? religions.first,
            items: religions
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (val) {
              if (val != null) onReligionChanged(val);
            },
          ),
          const SizedBox(height: 20),

          // Mother Tongue
          const Text(
            'Mother Tongue',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: motherTongue ?? motherTongues.first,
            items: motherTongues
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (val) {
              if (val != null) onMotherTongueChanged(val);
            },
          ),
          const SizedBox(height: 20),

          // Caste / Sub-caste
          const Text(
            'Caste / Sub-caste (Optional)',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: casteController,
            decoration: const InputDecoration(
              hintText: 'e.g. Brahmin, Maratha, Agarwal, Gupta',
              prefixIcon: Icon(Icons.group_outlined),
            ),
          ),
          const SizedBox(height: 20),

          // Gotra
          const Text(
            'Gotra / Gothram (Optional)',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: gotraController,
            decoration: const InputDecoration(
              hintText: 'e.g. Kashyap, Bharadwaj, Vashishta',
              prefixIcon: Icon(Icons.brightness_7_outlined),
            ),
          ),
        ],
      ),
    );
  }
}
