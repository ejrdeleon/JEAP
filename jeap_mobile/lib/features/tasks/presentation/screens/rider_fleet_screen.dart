import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jeap_mobile/core/network/api_client.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/features/messaging/presentation/screens/buyer_conversations_screen.dart';

class RiderFleetScreen extends StatefulWidget {
  const RiderFleetScreen({super.key});

  @override
  State<RiderFleetScreen> createState() => _RiderFleetScreenState();
}

class _RiderFleetScreenState extends State<RiderFleetScreen> {
  final _api = const ApiClient();
  Map<String, dynamic>? _fleetData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFleet();
  }

  Future<void> _loadFleet() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get('/rider/fleet');
      if (res is Map<String, dynamic>) {
        setState(() {
          _fleetData = res;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _fleetData = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _fleetData;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Fleet & Hub Assignment',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: _buildBody(d),
    );
  }

  Widget _buildBody(Map<String, dynamic>? d) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (d == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Could not load fleet assignment.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _loadFleet, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fleet Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF334155)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.greenAccent),
                              ),
                              child: Text(
                                d['rider_status'] ?? 'Offline',
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              d['fleet_code'] ?? 'HUB',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          d['fleet_name'] ?? 'JEAP Dash',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.two_wheeler,
                                color: Colors.white70, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '${d['active_riders_count'] ?? 0} fleet riders',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Hub Station Details
                  _buildCard(
                    title: 'Assigned Dispatch Station',
                    icon: Icons.store_mall_directory_outlined,
                    children: [
                      _buildInfoRow(
                        'Station Address',
                        d['station_address'] ?? '—',
                        Icons.place_outlined,
                      ),
                      _buildInfoRow(
                        'Assigned Zone',
                        d['assigned_zone'] ?? '—',
                        Icons.map_outlined,
                      ),
                      _buildInfoRow(
                        'Operating Hours',
                        d['operating_hours'] ?? '—',
                        Icons.access_time_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Fleet Management Contacts
                  _buildCard(
                    title: 'Hub Supervisors & Dispatch Team',
                    icon: Icons.support_agent_outlined,
                    children: [
                      _buildInfoRow(
                        'Hub Manager',
                        d['fleet_manager'] ?? '—',
                        Icons.person_outline,
                      ),
                      _buildInfoRow(
                        'Hub contact',
                        d['contact_phone'] ?? '—',
                        Icons.phone_outlined,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final raw =
                                    d['contact_phone']?.toString().trim() ?? '';
                                if (raw.isEmpty || raw == '—') {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'No hub phone number is on file.'),
                                    ),
                                  );
                                  return;
                                }
                                final uri = Uri(scheme: 'tel', path: raw);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                }
                              },
                              icon: const Icon(Icons.call, size: 16),
                              label: const Text('Call hub'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.jeapPurple,
                                side: const BorderSide(
                                    color: AppTheme.jeapPurple),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const BuyerConversationsScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.chat, size: 16),
                              label: const Text('Message Hub'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.jeapPurple,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.jeapPurple),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style:
                  const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
