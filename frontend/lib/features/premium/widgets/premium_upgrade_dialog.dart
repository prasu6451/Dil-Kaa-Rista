import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class PremiumUpgradeDialog extends StatelessWidget {
  final String currentTier;

  const PremiumUpgradeDialog({super.key, this.currentTier = 'free'});

  static void show(BuildContext context, {String currentTier = 'free'}) {
    showDialog(
      context: context,
      builder: (_) => PremiumUpgradeDialog(currentTier: currentTier),
    );
  }

  Widget _buildCheckRow(String feature, bool free, bool tier1, bool tier2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              feature,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: free
                  ? const Icon(Icons.check_circle, color: AppColors.success, size: 18)
                  : const Icon(Icons.remove_circle_outline, color: Colors.grey, size: 18),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: tier1
                  ? const Icon(Icons.check_circle, color: AppColors.primary, size: 18)
                  : const Icon(Icons.remove_circle_outline, color: Colors.grey, size: 18),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: tier2
                  ? const Icon(Icons.check_circle, color: Colors.amber, size: 18)
                  : const Icon(Icons.remove_circle_outline, color: Colors.grey, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.workspace_premium, color: Colors.amber, size: 28),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dil Ka Rishta Premium',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          Text(
                            'Unlock high-response matchmaking',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(height: 28),

              // Comparison Table Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Text('Features', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(child: Text('Free', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text(
                          'Tier 1',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text(
                          'Tier 2',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Rows according to Page 6
              _buildCheckRow('Browse Profiles & Express Interest', true, true, true),
              _buildCheckRow('Receive Inbound Messages', true, true, true),
              _buildCheckRow('Photos Limit', false, true, true), // Free 5, Premium 20
              _buildCheckRow('Initiate New Chats', false, true, true),
              _buildCheckRow('Premium Interest (Wall & Email)', false, true, true),
              _buildCheckRow('Higher Visibility in Search', false, true, true),
              _buildCheckRow('Direct SMS to Member', false, false, true),
              _buildCheckRow('Contact Details Direct Access', false, false, true),
              _buildCheckRow('Kundli / Horoscope Compatibility Matching', false, false, true),

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tier 1 Membership Activated!'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Upgrade Tier 1', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('₹1,499 / 3 mos', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tier 2 All-Inclusive Membership Activated!'),
                            backgroundColor: Colors.amber,
                          ),
                        );
                      },
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Upgrade Tier 2 (VIP)', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('₹2,999 / 3 mos', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
