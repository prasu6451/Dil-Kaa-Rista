import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/match_controller.dart';

class SearchFilterBottomSheet extends StatefulWidget {
  final MatchFilter filter;
  final ValueChanged<MatchFilter> onApply;

  const SearchFilterBottomSheet({
    super.key,
    required this.filter,
    required this.onApply,
  });

  @override
  State<SearchFilterBottomSheet> createState() =>
      _SearchFilterBottomSheetState();
}

class _SearchFilterBottomSheetState extends State<SearchFilterBottomSheet> {
  late double _minAge;
  late double _maxAge;
  String? _religion;
  String? _maritalStatus;
  final _cityController = TextEditingController();

  final List<String> _religions = [
    'All Religions',
    'Hindu',
    'Muslim',
    'Christian',
    'Sikh',
    'Jain',
    'Buddhist',
    'Other'
  ];

  final List<String> _maritalStatuses = [
    'Any Status',
    'Never Married',
    'Divorced',
    'Widowed',
    'Awaiting Divorce'
  ];

  @override
  void initState() {
    super.initState();
    _minAge = widget.filter.minAge.toDouble();
    _maxAge = widget.filter.maxAge.toDouble();
    _religion = widget.filter.religion ?? 'All Religions';
    _maritalStatus = widget.filter.maritalStatus ?? 'Any Status';
    _cityController.text = widget.filter.city ?? '';
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Search & Filters',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _minAge = 18;
                      _maxAge = 60;
                      _religion = 'All Religions';
                      _maritalStatus = 'Any Status';
                      _cityController.clear();
                    });
                  },
                  child: const Text('Reset All'),
                ),
              ],
            ),
            const Divider(),

            // Age Range Slider
            Text(
              'Age Range: ${_minAge.toInt()} to ${_maxAge.toInt()} years',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            RangeSlider(
              values: RangeValues(_minAge, _maxAge),
              min: 18,
              max: 70,
              divisions: 52,
              activeColor: AppColors.primary,
              inactiveColor: AppColors.primaryLight,
              labels: RangeLabels('${_minAge.toInt()}', '${_maxAge.toInt()}'),
              onChanged: (values) {
                setState(() {
                  _minAge = values.start;
                  _maxAge = values.end;
                });
              },
            ),
            const SizedBox(height: 14),

            // Religion
            const Text(
              'Religion',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _religion,
              items: _religions
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (val) => setState(() => _religion = val),
            ),
            const SizedBox(height: 14),

            // Marital Status
            const Text(
              'Marital Status',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _maritalStatus,
              items: _maritalStatuses
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (val) => setState(() => _maritalStatus = val),
            ),
            const SizedBox(height: 14),

            // City
            const Text(
              'City / Location',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                hintText: 'e.g. Mumbai, Pune, Delhi',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 24),

            // Apply Button
            ElevatedButton(
              onPressed: () {
                final applied = MatchFilter(
                  minAge: _minAge.toInt(),
                  maxAge: _maxAge.toInt(),
                  religion:
                      _religion == 'All Religions' ? null : _religion,
                  maritalStatus:
                      _maritalStatus == 'Any Status' ? null : _maritalStatus,
                  city: _cityController.text.trim().isEmpty
                      ? null
                      : _cityController.text.trim(),
                );
                widget.onApply(applied);
                Navigator.pop(context);
              },
              child: const Text('Apply Filters'),
            ),
          ],
        ),
      ),
    );
  }
}
