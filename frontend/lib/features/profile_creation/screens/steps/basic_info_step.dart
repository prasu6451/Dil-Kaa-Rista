import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BasicInfoStep extends StatelessWidget {
  final DateTime? dateOfBirth;
  final ValueChanged<DateTime> onDateChanged;
  final String maritalStatus;
  final ValueChanged<String> onMaritalStatusChanged;
  final int? heightCm;
  final ValueChanged<int> onHeightChanged;
  final TextEditingController cityController;
  final TextEditingController stateController;

  const BasicInfoStep({
    super.key,
    required this.dateOfBirth,
    required this.onDateChanged,
    required this.maritalStatus,
    required this.onMaritalStatusChanged,
    required this.heightCm,
    required this.onHeightChanged,
    required this.cityController,
    required this.stateController,
  });

  static const List<String> maritalStatuses = [
    'Never Married',
    'Divorced',
    'Widowed',
    'Awaiting Divorce',
    'Annulled'
  ];

  static const List<int> heightsInCm = [
    140, 142, 145, 147, 150, 152, 155, 157, 160, 162, 165, 168, 170, 172, 175,
    178, 180, 183, 185, 188, 190, 193, 195, 198, 200
  ];

  String _formatHeight(int cm) {
    final totalInches = (cm / 2.54).round();
    final feet = totalInches ~/ 12;
    final inches = totalInches % 12;
    return '$feet\' $inches" ($cm cm)';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Details',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Help matches know the vital basics about you',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // Date of Birth
          const Text(
            'Date of Birth',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: dateOfBirth ?? DateTime(1998, 1, 1),
                firstDate: DateTime(1950),
                lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
              );
              if (picked != null) {
                onDateChanged(picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 20, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text(
                    dateOfBirth != null
                        ? DateFormat('dd MMMM yyyy').format(dateOfBirth!)
                        : 'Select Date of Birth (Min 18 yrs)',
                    style: TextStyle(
                      color: dateOfBirth != null ? Colors.black87 : Colors.grey.shade600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Marital Status
          const Text(
            'Marital Status',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: maritalStatus,
            items: maritalStatuses
                .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                .toList(),
            onChanged: (val) {
              if (val != null) onMaritalStatusChanged(val);
            },
          ),
          const SizedBox(height: 20),

          // Height
          const Text(
            'Height',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: heightCm ?? 165,
            items: heightsInCm
                .map((h) => DropdownMenuItem(value: h, child: Text(_formatHeight(h))))
                .toList(),
            onChanged: (val) {
              if (val != null) onHeightChanged(val);
            },
          ),
          const SizedBox(height: 20),

          // City
          const Text(
            'Current City',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: cityController,
            decoration: const InputDecoration(
              hintText: 'e.g. Mumbai, Pune, Bengaluru',
              prefixIcon: Icon(Icons.location_city_outlined),
            ),
          ),
          const SizedBox(height: 20),

          // State
          const Text(
            'State / Province',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: stateController,
            decoration: const InputDecoration(
              hintText: 'e.g. Maharashtra, Karnataka, Delhi',
              prefixIcon: Icon(Icons.map_outlined),
            ),
          ),
        ],
      ),
    );
  }
}
