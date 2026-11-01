import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/network/api_client.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';

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
        _fleetData = {
          'fleet_name': 'JEAP Central Logistics Fleet',
          'fleet_code': 'FLEET-LAG-01',
          'fleet_manager': 'Carlos Antonio Mendoza',
          'contact_phone': '0917-888-4110',
          'station_address':
              'Santa Cruz Dispatch Center, Provincial Capitol Compound, Laguna',
          'operating_hours': 'Mon - Sat: 6:00 AM - 8:00 PM',
          'active_riders_count': 14,
          'rider_status': 'Active / On-Duty',
          'assigned_zone': 'Laguna Province - District 1, 2 & 4',
        };
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                                d?['rider_status'] ?? 'Active On-Duty',
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              d?['fleet_code'] ?? 'FLEET-LAG-01',
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
                          d?['fleet_name'] ?? 'JEAP Logistics Fleet',
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
                              '${d?['active_riders_count'] ?? 1} Registered Fleet Couriers',
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
                        d?['station_address'] ?? 'Santa Cruz, Laguna',
                        Icons.place_outlined,
                      ),
                      _buildInfoRow(
                        'Assigned Zone',
                        d?['assigned_zone'] ?? 'Laguna Province',
                        Icons.map_outlined,
                      ),
                      _buildInfoRow(
                        'Operating Hours',
                        d?['operating_hours'] ?? '6:00 AM - 8:00 PM',
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
                        d?['fleet_manager'] ?? 'Fleet Supervisor',
                        Icons.person_outline,
                      ),
                      _buildInfoRow(
                        'Dispatch Hotline',
                        d?['contact_phone'] ?? '0917-888-4110',
                        Icons.phone_outlined,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Dialing Dispatch Hotline...'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.call, size: 16),
                              label: const Text('Call Dispatch'),
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Opening Support Chat...'),
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
