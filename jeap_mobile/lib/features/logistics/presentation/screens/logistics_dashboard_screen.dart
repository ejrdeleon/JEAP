import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/storage/auth_session.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:jeap_mobile/features/logistics/models/logistics_parcel.dart';
import 'package:jeap_mobile/features/logistics/presentation/screens/logistics_scanner_screen.dart';
import 'package:jeap_mobile/features/logistics/presentation/screens/scan_result_screen.dart';
import 'package:jeap_mobile/features/logistics/services/logistics_service.dart';

class LogisticsDashboardScreen extends StatefulWidget {
  const LogisticsDashboardScreen({super.key});

  @override
  State<LogisticsDashboardScreen> createState() =>
      _LogisticsDashboardScreenState();
}

class _LogisticsDashboardScreenState extends State<LogisticsDashboardScreen> {
  final LogisticsService _service = LogisticsService();
  bool _loading = true;
  LogisticsHubStats _stats = const LogisticsHubStats(
    incoming: 3,
    received: 3,
    awaitingSorting: 3,
    readyForDispatch: 2,
    outgoing: 1,
  );
  List<LogisticsActivity> _recentActivity = [];
  String _hubName = 'Laguna Central Hub';
  String _hubCode = 'HUB-LAG-01';

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _loading = true);
    final data = await _service.getDashboard();
    if (!mounted) return;

    if (data != null) {
      final statsMap = data['stats'] as Map<String, dynamic>?;
      final actsList = data['recent_activity'] as List?;
      setState(() {
        if (statsMap != null) _stats = LogisticsHubStats.fromJson(statsMap);
        if (actsList != null) {
          _recentActivity = actsList
              .whereType<Map>()
              .map((e) => LogisticsActivity.fromJson(
                  Map<String, dynamic>.from(e)))
              .toList();
        }
        if (data['hub_name'] != null) {
          _hubName = data['hub_name'].toString();
        }
        if (data['hub_code'] != null) {
          _hubCode = data['hub_code'].toString();
        }
        _loading = false;
      });
    } else {
      // Fallback activities for immediate offline responsiveness
      setState(() {
        _recentActivity = [
          const LogisticsActivity(
            trackingNumber: 'JEPLGN1001IN',
            orderNumber: 'JEAP-LGN-1001',
            status: 'AT_SORTING_CENTER',
            action: 'Received at Hub & In Sorting',
            timestamp: '10 mins ago',
            location: 'Central Hub - Laguna',
          ),
          const LogisticsActivity(
            trackingNumber: 'JEPLGN1003DSP',
            orderNumber: 'JEAP-LGN-1003',
            status: 'SORTED',
            action: 'Sorted & Staged for Dispatch',
            timestamp: '25 mins ago',
            location: 'Staging Bay A',
          ),
          const LogisticsActivity(
            trackingNumber: 'JEPLGN1006DSP',
            orderNumber: 'JEAP-LGN-1006',
            status: 'SORTED',
            action: 'Sorted to Biñan City Bin',
            timestamp: '45 mins ago',
            location: 'Staging Bay B',
          ),
        ];
        _loading = false;
      });
    }
  }

  void _handleLogout() async {
    await AuthSession.instance.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _openParcelDetails(String trackingNumber) async {
    final parcel = await _service.getParcel(trackingNumber);
    if (!mounted) return;

    if (parcel != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScanResultScreen(parcel: parcel),
        ),
      ).then((_) => _loadDashboard());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Looking up parcel $trackingNumber...'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _showStageParcelsModal(String stageTitle, String filterStatus) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final matching = _recentActivity.where((a) {
          final s = a.status.toUpperCase();
          if (filterStatus == 'ALL') return true;
          return s.contains(filterStatus);
        }).toList();

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$stageTitle Parcels',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(),
                if (matching.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No parcels currently in $stageTitle stage.',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: matching.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final act = matching[i];
                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFEDE9FE),
                            child: Icon(Icons.inventory_2, color: AppTheme.jeapPurple, size: 20),
                          ),
                          title: Text(
                            act.trackingNumber,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          subtitle: Text('${act.orderNumber} • ${act.action}', style: const TextStyle(fontSize: 11)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pop(ctx);
                            _openParcelDetails(act.trackingNumber);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PLACED':
      case 'CONFIRMED':
      case 'PREPARING':
        return Colors.blue;
      case 'READY_FOR_PICKUP':
      case 'PICKED_UP':
        return Colors.indigo;
      case 'AT_SORTING_CENTER':
        return Colors.orange;
      case 'SORTED':
        return Colors.teal;
      case 'ASSIGNED_TO_RIDER':
      case 'OUT_FOR_DELIVERY':
        return AppTheme.jeapPurple;
      case 'DELIVERED':
      case 'COMPLETED':
        return Colors.green;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'JEAP Logistics Hub',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            Text(
              '$_hubName • $_hubCode',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            tooltip: 'Refresh Hub Data',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDashboard,
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHubBanner(),
                    const SizedBox(height: 16),
                    _buildOperationalMetrics(),
                    const SizedBox(height: 16),
                    _buildQuickActions(),
                    const SizedBox(height: 16),
                    _buildRecentScanActivity(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.jeapPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text(
          'Scan Parcel',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const LogisticsScannerScreen(),
            ),
          ).then((_) => _loadDashboard());
        },
      ),
    );
  }

  Widget _buildHubBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.jeapPurple.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warehouse, color: Colors.amber, size: 30),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Warehouse Hub Operations',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Manage arrival, sorting, parcel scanning & fleet dispatch',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Operational Overview',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Incoming',
                count: _stats.incoming,
                color: Colors.blue,
                icon: Icons.flight_land,
                onTap: () => _showStageParcelsModal('Incoming', 'PICKUP'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricTile(
                title: 'Received',
                count: _stats.received,
                color: Colors.teal,
                icon: Icons.archive,
                onTap: () => _showStageParcelsModal('Received', 'AT_SORTING'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricTile(
                title: 'Sorting',
                count: _stats.awaitingSorting,
                color: Colors.orange,
                icon: Icons.alt_route,
                onTap: () => _showStageParcelsModal('Sorting Bay', 'SORT'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Ready Dispatch',
                count: _stats.readyForDispatch,
                color: Colors.indigo,
                icon: Icons.inventory_2,
                onTap: () => _showStageParcelsModal('Ready Dispatch', 'SORTED'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricTile(
                title: 'Outgoing Fleet',
                count: _stats.outgoing,
                color: AppTheme.jeapPurple,
                icon: Icons.local_shipping,
                onTap: () => _showStageParcelsModal('Outgoing Fleet', 'RIDER'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(icon, color: color, size: 16),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.jeapPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LogisticsScannerScreen(),
                ),
              ).then((_) => _loadDashboard());
            },
            icon: const Icon(Icons.qr_code_scanner, size: 18),
            label: const Text(
              'Scan Barcode / QR',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.jeapPurple,
              side: const BorderSide(color: AppTheme.jeapPurple),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LogisticsScannerScreen(),
                ),
              ).then((_) => _loadDashboard());
            },
            icon: const Icon(Icons.search, size: 18),
            label: const Text(
              'Manual Lookup',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentScanActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Hub Scan Activity',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              '${_recentActivity.length} events',
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _recentActivity.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final act = _recentActivity[i];
            return InkWell(
              onTap: () => _openParcelDetails(act.trackingNumber),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.jeapPurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.qr_code,
                        color: AppTheme.jeapPurple,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            act.trackingNumber,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${act.action} • ${act.timestamp}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _getStatusColor(act.status).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        act.status.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(act.status),
                          fontWeight: FontWeight.bold,
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
