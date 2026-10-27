import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/jeap_app_bar.dart';
import 'package:jeap_mobile/features/messaging/presentation/screens/buyer_conversations_screen.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  static const String _supportEmail = 'support@jeap.store';
  static const String _supportPhone = '+63 2 8123 4567';
  static const String _operatingHours = 'Mon - Sun: 8:00 AM - 8:00 PM PHT';

  final List<_FaqItem> _allFaqs = const [
    // Orders & Tracking
    _FaqItem(
      category: 'Orders & Tracking',
      question: 'How do I track my order?',
      answer:
          'Go to the "My Orders" tab on your bottom navigation bar or drawer. Tap on any order to view its real-time status, timeline, and assigned rider details.',
    ),
    _FaqItem(
      category: 'Orders & Tracking',
      question: 'Can I cancel an order after placing it?',
      answer:
          'Orders can be canceled while they are still in "Pending" status before the seller confirms and packs the package. Once out for delivery, cancellations are no longer permitted.',
    ),
    _FaqItem(
      category: 'Orders & Tracking',
      question: 'What if I receive a damaged or incorrect item?',
      answer:
          'Please report the item within 48 hours of delivery through Messages or email us at support@jeap.store with clear photos of the package and item.',
    ),

    // Delivery & Addresses
    _FaqItem(
      category: 'Delivery & Addresses',
      question: 'How do I change my delivery address?',
      answer:
          'Navigate to Account > Delivery Addresses. You can add, edit, or set default delivery addresses with full Philippine PSGC location validation.',
    ),
    _FaqItem(
      category: 'Delivery & Addresses',
      question: 'What happens if I am not available to receive my order?',
      answer:
          'Our delivery rider will attempt to contact you via phone or in-app message. You may designate an authorized representative or leave delivery instructions in your address notes.',
    ),

    // Rider & Logistics
    _FaqItem(
      category: 'Rider & Courier',
      question: 'How are delivery assignments dispatched?',
      answer:
          'Assignments are routed in real-time based on your active service area, pickup location, and delivery route availability. Keep your status active in the Rider portal to receive new dispatches.',
    ),
    _FaqItem(
      category: 'Rider & Courier',
      question: 'What should a rider do if the buyer is unreachable?',
      answer:
          'Attempt calling the recipient at least twice and message them through rider chat. If unreachable after the standard waiting window, mark the task as failed with the appropriate reason code.',
    ),
    _FaqItem(
      category: 'Rider & Courier',
      question: 'Is photo proof of delivery mandatory?',
      answer:
          'Yes. Every successful delivery requires a clear proof-of-delivery photo showing the delivered parcel at the doorstep or handed to the recipient.',
    ),

    // Account & Security
    _FaqItem(
      category: 'Account & Security',
      question: 'How do I update my profile picture or phone number?',
      answer:
          'Go to Account > Edit Profile. You can update your first and last name, mobile number, and upload a new profile photo directly from your camera or photo library.',
    ),
    _FaqItem(
      category: 'Account & Security',
      question: 'How do I change my password?',
      answer:
          'Go to Account > Change Password. Enter your current password and your new password to immediately secure your account.',
    ),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        backgroundColor: AppTheme.jeapPurple,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();
    final filteredFaqs = query.isEmpty
        ? _allFaqs
        : _allFaqs.where((f) {
            return f.question.toLowerCase().contains(query) ||
                f.answer.toLowerCase().contains(query) ||
                f.category.toLowerCase().contains(query);
          }).toList();

    // Group FAQs by category
    final Map<String, List<_FaqItem>> categories = {};
    for (final faq in filteredFaqs) {
      categories.putIfAbsent(faq.category, () => []).add(faq);
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const JeapAppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Page Header
            const Text(
              'Help & Support',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'We are here to assist you with orders, deliveries, and your account.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),

            // Contact Channels Card
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
                border: Border.all(color: AppTheme.borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.headset_mic_outlined,
                              color: AppTheme.jeapPurple, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Direct Contact Channels',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _ContactRow(
                        icon: Icons.email_outlined,
                        label: 'Email Support',
                        value: _supportEmail,
                        actionIcon: Icons.copy_outlined,
                        onTap: () =>
                            _copyToClipboard(_supportEmail, 'Support email'),
                      ),
                      const Divider(height: 16),
                      _ContactRow(
                        icon: Icons.phone_outlined,
                        label: 'Customer Hotline',
                        value: _supportPhone,
                        actionIcon: Icons.copy_outlined,
                        onTap: () =>
                            _copyToClipboard(_supportPhone, 'Hotline number'),
                      ),
                      const Divider(height: 16),
                      const _ContactRow(
                        icon: Icons.access_time_outlined,
                        label: 'Operating Hours',
                        value: _operatingHours,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          label: const Text('Open Support Messages'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.jeapPurple,
                            side: const BorderSide(color: AppTheme.jeapPurple),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.buyerRadius),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const BuyerConversationsScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search help topics & questions...',
                  hintStyle: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary),
                  prefixIcon: const Icon(Icons.search,
                      color: AppTheme.textSecondary, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // FAQ Header
            const Row(
              children: [
                Icon(Icons.help_outline, color: AppTheme.jeapPurple, size: 20),
                SizedBox(width: 8),
                Text(
                  'Frequently Asked Questions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Empty state if no search results
            if (categories.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.search_off,
                        size: 40, color: AppTheme.textSecondary),
                    const SizedBox(height: 8),
                    Text(
                      'No answers found for "$_searchQuery"',
                      style: const TextStyle(
                          fontSize: 14, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: const Text('Clear Search'),
                    ),
                  ],
                ),
              ),

            // FAQ Categories and Expandable Tiles
            for (final entry in categories.entries) ...[
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 6),
                child: Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.jeapPurple,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
                    child: Column(
                      children: [
                        for (int i = 0; i < entry.value.length; i++) ...[
                          Theme(
                            data: Theme.of(context).copyWith(
                              dividerColor: Colors.transparent,
                            ),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 2),
                              childrenPadding:
                                  const EdgeInsets.fromLTRB(14, 0, 14, 14),
                              leading: const Icon(Icons.help_outline,
                                  size: 18, color: AppTheme.jeapPurple),
                              title: Text(
                                entry.value[i].question,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    entry.value[i].answer,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppTheme.textSecondary,
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (i < entry.value.length - 1)
                            const Divider(height: 1, indent: 14, endIndent: 14),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final IconData? actionIcon;
  final VoidCallback? onTap;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.actionIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (actionIcon != null)
              Icon(actionIcon, size: 18, color: AppTheme.jeapPurple),
          ],
        ),
      ),
    );
  }
}

class _FaqItem {
  final String category;
  final String question;
  final String answer;

  const _FaqItem({
    required this.category,
    required this.question,
    required this.answer,
  });
}
