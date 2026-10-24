import 'package:flutter/material.dart';

class CareerEducationStep extends StatelessWidget {
  final TextEditingController educationController;
  final TextEditingController occupationController;
  final String? annualIncome;
  final ValueChanged<String> onIncomeChanged;

  const CareerEducationStep({
    super.key,
    required this.educationController,
    required this.occupationController,
    required this.annualIncome,
    required this.onIncomeChanged,
  });

  static const List<String> incomeRanges = [
    'Not Disclosed',
    'Under ₹3 Lakh',
    '₹3 Lakh - ₹5 Lakh',
    '₹5 Lakh - ₹7.5 Lakh',
    '₹7.5 Lakh - ₹10 Lakh',
    '₹10 Lakh - ₹15 Lakh',
    '₹15 Lakh - ₹25 Lakh',
    '₹25 Lakh - ₹50 Lakh',
    '₹50 Lakh - ₹1 Crore',
    'Above ₹1 Crore',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Education & Career',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tell matches about your academic and professional life',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // Highest Education
          const Text(
            'Highest Degree / Qualification',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: educationController,
            decoration: const InputDecoration(
              hintText: 'e.g. B.Tech in CS, MBA, MBBS, CA, MS',
              prefixIcon: Icon(Icons.school_outlined),
            ),
          ),
          const SizedBox(height: 20),

          // Profession / Occupation
          const Text(
            'Profession / Job Title',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: occupationController,
            decoration: const InputDecoration(
              hintText: 'e.g. Software Engineer, Doctor, Business Owner',
              prefixIcon: Icon(Icons.work_outline),
            ),
          ),
          const SizedBox(height: 20),

          // Annual Income
          const Text(
            'Annual Income (₹ INR)',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: annualIncome ?? incomeRanges[3],
            items: incomeRanges
                .map((inc) => DropdownMenuItem(value: inc, child: Text(inc)))
                .toList(),
            onChanged: (val) {
              if (val != null) onIncomeChanged(val);
            },
          ),
        ],
      ),
    );
  }
}
