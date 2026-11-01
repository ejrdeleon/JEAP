import 'package:jeap_mobile/features/tasks/presentation/screens/rider_fleet_screen.dart';
import 'package:jeap_mobile/features/tasks/presentation/screens/rider_vehicle_screen.dart';
import 'package:jeap_mobile/features/tasks/presentation/screens/rider_documents_screen.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jeap_mobile/core/network/api_exception.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/jeap_avatar.dart';
import 'package:jeap_mobile/core/storage/auth_session.dart';
import 'package:jeap_mobile/core/widgets/jeap_logo.dart';
import 'package:jeap_mobile/features/chat/presentation/screens/rider_chat_screen.dart';
import 'package:jeap_mobile/features/account/presentation/screens/change_password_screen.dart';
import 'package:jeap_mobile/features/account/presentation/screens/edit_profile_screen.dart';
import 'package:jeap_mobile/features/account/presentation/screens/help_support_screen.dart';
import 'package:jeap_mobile/features/notifications/presentation/screens/notification_settings_screen.dart';
import 'package:jeap_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:jeap_mobile/features/auth/services/auth_service.dart';
import 'package:jeap_mobile/features/tasks/models/delivery_task.dart';
import 'package:jeap_mobile/features/tasks/services/rider_assignment_service.dart';
import 'package:jeap_mobile/core/theme/rider_theme.dart';
import 'package:jeap_mobile/features/tasks/presentation/widgets/proof_of_delivery_sheet.dart';

enum _AssignmentPage { pickup, delivery, history }

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _RiderDashboard(onSelectPage: _open),
      const _RiderChatInbox(),
      const _RiderProfile(),
      _RiderMore(onSelectPage: _open),
    ];
    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.jeapPurple.withValues(alpha: .12),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Profile'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }

  void _open(_AssignmentPage page) => Navigator.push<void>(
        context,
        MaterialPageRoute(
            builder: (_) => _RiderAssignmentListScreen(page: page)),
      );
}

class _RiderDashboard extends StatefulWidget {
  const _RiderDashboard({required this.onSelectPage});
  final ValueChanged<_AssignmentPage> onSelectPage;

  @override
  State<_RiderDashboard> createState() => _RiderDashboardState();
}

class _RiderDashboardState extends State<_RiderDashboard> {
  final _service = RiderAssignmentService();
  late Future<RiderAssignmentsResult> _assignments;
  bool _isOnline = true;
  bool _safetyCheckCompleted = false;

  @override
  void initState() {
    super.initState();
    _assignments = _service.list();
  }

  void _refresh() => setState(() => _assignments = _service.list());

  void _toggleOnline(bool value) {
    if (value && !_safetyCheckCompleted) {
      _showSafetyCheckDialog();
    } else {
      setState(() => _isOnline = value);
    }
  }

  void _showSafetyCheckDialog() {
    bool tires = false;
    bool lights = false;
    bool brakes = false;
    bool fuel = false;
    bool cargo = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.checklist, color: AppTheme.jeapPurple),
              SizedBox(width: 8),
              Expanded(
                child: Text('Pre-Trip Safety Inspection',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Complete your 5-point vehicle safety checklist before accepting delivery tasks:',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  value: tires,
                  title: const Text('Tires & Air Pressure Checked', style: TextStyle(fontSize: 13)),
                  dense: true,
                  activeColor: AppTheme.jeapPurple,
                  onChanged: (v) => setDlg(() => tires = v ?? false),
                ),
                CheckboxListTile(
                  value: lights,
                  title: const Text('Headlights, Signals & Horn Working', style: TextStyle(fontSize: 13)),
                  dense: true,
                  activeColor: AppTheme.jeapPurple,
                  onChanged: (v) => setDlg(() => lights = v ?? false),
                ),
                CheckboxListTile(
                  value: brakes,
                  title: const Text('Brakes & Brake Fluid Responsive', style: TextStyle(fontSize: 13)),
                  dense: true,
                  activeColor: AppTheme.jeapPurple,
                  onChanged: (v) => setDlg(() => brakes = v ?? false),
                ),
                CheckboxListTile(
                  value: fuel,
                  title: const Text('Fuel Level or Battery Charge Sufficient', style: TextStyle(fontSize: 13)),
                  dense: true,
                  activeColor: AppTheme.jeapPurple,
                  onChanged: (v) => setDlg(() => fuel = v ?? false),
                ),
                CheckboxListTile(
                  value: cargo,
                  title: const Text('Thermal Cargo Bag / Top Box Clean & Locked', style: TextStyle(fontSize: 13)),
                  dense: true,
                  activeColor: AppTheme.jeapPurple,
                  onChanged: (v) => setDlg(() => cargo = v ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: (tires && lights && brakes && fuel && cargo)
                  ? () {
                      Navigator.pop(ctx);
                      setState(() {
                        _safetyCheckCompleted = true;
                        _isOnline = true;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Safety inspection passed! You are now ONLINE.'),
                          backgroundColor: AppTheme.statusGreen,
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.jeapPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Pass & Go Online'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRemittanceDialog(double codAmount) {
    final noteCtrl = TextEditingController(text: 'Shift COD remittance');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit COD Remittance', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount to remit: ₱${codAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.priceRed)),
            const SizedBox(height: 12),
            const Text('Notes / Reference:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'e.g. Drop reference or Cash Handover receipt',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.jeapPurple, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _service.submitRemittance(amount: codAmount, notes: noteCtrl.text.trim());
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('COD Remittance submitted for confirmation!'),
                      backgroundColor: AppTheme.statusGreen,
                    ),
                  );
                  _refresh();
                }
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to submit remittance.'), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            child: const Text('Confirm Remit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const JeapLogo(height: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Courier',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
            ),
            ValueListenableBuilder<Map<String, dynamic>?>(
              valueListenable: AuthSession.instance.userNotifier,
              builder: (context, user, _) {
                final avatarUrl = AuthSession.instance.avatarUrl;
                final name = AuthSession.instance.displayName;
                return Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: JeapAvatar(
                    radius: 15,
                    imageUrl: avatarUrl,
                    name: name,
                    backgroundColor: Colors.white,
                    cacheBust: true,
                  ),
                );
              },
            ),
          ],
        ),
        body: FutureBuilder<RiderAssignmentsResult>(
          future: _assignments,
          builder: (context, snapshot) {
            final tasks = snapshot.data?.tasks ?? const <DeliveryTask>[];
            final pickups = tasks
                .where((task) =>
                    task.isPickup &&
                    task.status != TaskStatus.pickedUp &&
                    task.status != TaskStatus.delivered &&
                    task.status != TaskStatus.failed)
                .length;
            final deliveries = tasks
                .where((task) =>
                    !task.isPickup &&
                    task.status != TaskStatus.delivered &&
                    task.status != TaskStatus.failed)
                .length;

            final completedPickups = tasks
                .where((t) => t.isPickup && (t.status == TaskStatus.pickedUp || t.status == TaskStatus.delivered))
                .length;
            final completedDeliveries = tasks
                .where((t) => !t.isPickup && t.status == TaskStatus.delivered)
                .length;
            final totalEarnings = (completedPickups * 30.0) + (completedDeliveries * 50.0);
            final codHeld = tasks
                .where((t) => !t.isPickup && t.status == TaskStatus.delivered && t.codAmount > 0)
                .fold(0.0, (sum, t) => sum + t.codAmount);

            return RefreshIndicator(
              onRefresh: () async => _refresh(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  // Online / Offline Status Card
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
                      border: Border.all(
                        color: _isOnline ? AppTheme.statusGreen : AppTheme.borderColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isOnline ? AppTheme.statusGreen : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _isOnline ? 'ONLINE • Ready to receive deliveries' : 'OFFLINE • Shift paused',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _isOnline ? AppTheme.statusGreen : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        Switch(
                          value: _isOnline,
                          activeThumbColor: AppTheme.statusGreen,
                          onChanged: _toggleOnline,
                        ),
                      ],
                    ),
                  ),

                  const Text('Today’s Earnings',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 4),
                  _DashboardCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Estimated Shift Payout',
                                      style: TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12)),
                                  const SizedBox(height: 5),
                                  Text('₱${totalEarnings.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          color: AppTheme.priceRed,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 22)),
                                  const SizedBox(height: 3),
                                  Text(
                                    '$completedPickups pickups (₱30) • $completedDeliveries deliveries (₱50)',
                                    style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.trending_up,
                                color: AppTheme.jeapPurple.withValues(alpha: .8)),
                          ],
                        ),
                        if (codHeld > 0) ...[
                          const Divider(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Unremitted COD Cash',
                                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                  Text('₱${codHeld.toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: () => _showRemittanceDialog(codHeld),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.jeapPurple,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  minimumSize: const Size(0, 32),
                                ),
                                child: const Text('REMIT COD', style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                      child: _CountCard(
                        title: 'Items for Pickup',
                        count:
                            snapshot.connectionState == ConnectionState.waiting
                                ? '—'
                                : '$pickups',
                        onTap: () =>
                            widget.onSelectPage(_AssignmentPage.pickup),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CountCard(
                        title: 'Items for Delivery',
                        count:
                            snapshot.connectionState == ConnectionState.waiting
                                ? '—'
                                : '$deliveries',
                        onTap: () =>
                            widget.onSelectPage(_AssignmentPage.delivery),
                      ),
                    ),
                  ]),
                  if (snapshot.hasError) ...[
                    const SizedBox(height: 12),
                    _InlineNotice(
                      text: _errorText(snapshot.error),
                      onRetry: _refresh,
                    ),
                  ] else if (snapshot.hasData && tasks.isEmpty) ...[
                    const SizedBox(height: 12),
                    _InlineNotice(
                      text: snapshot.data!.message ?? 'No active assignments.',
                      onRetry: _refresh,
                    ),
                  ],
                  const SizedBox(height: 22),
                  const Text('Quick Actions',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.inventory_2_outlined,
                        label: 'Pickup',
                        onTap: () =>
                            widget.onSelectPage(_AssignmentPage.pickup),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.local_shipping_outlined,
                        label: 'Deliver',
                        onTap: () =>
                            widget.onSelectPage(_AssignmentPage.delivery),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.alt_route,
                        label: 'Linehaul',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const _LinehaulTripScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.history,
                        label: 'History',
                        onTap: () =>
                            widget.onSelectPage(_AssignmentPage.history),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.chat_bubble_outline,
                        label: 'Chat',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RiderChatScreen(
                                buyerName: 'Support Desk',
                                trackingNumber: 'General Inquiries',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ]),
                ],
              ),
            );
          },
        ),
      );
}

class _RiderAssignmentListScreen extends StatefulWidget {
  const _RiderAssignmentListScreen({required this.page});
  final _AssignmentPage page;

  @override
  State<_RiderAssignmentListScreen> createState() =>
      _RiderAssignmentListScreenState();
}

class _RiderAssignmentListScreenState
    extends State<_RiderAssignmentListScreen> {
  final _service = RiderAssignmentService();
  late Future<RiderAssignmentsResult> _result;

  @override
  void initState() {
    super.initState();
    _result = _service.list();
  }

  String get _title => switch (widget.page) {
        _AssignmentPage.pickup => 'Items for Pickup',
        _AssignmentPage.delivery => 'Items for Delivery',
        _AssignmentPage.history => 'Delivery History',
      };

  List<DeliveryTask> _filter(List<DeliveryTask> tasks) => switch (widget.page) {
        _AssignmentPage.pickup => tasks
            .where((task) =>
                task.isPickup &&
                task.status != TaskStatus.pickedUp &&
                task.status != TaskStatus.delivered &&
                task.status != TaskStatus.failed)
            .toList(),
        _AssignmentPage.delivery => tasks
            .where((task) =>
                !task.isPickup &&
                task.status != TaskStatus.delivered &&
                task.status != TaskStatus.failed)
            .toList(),
        _AssignmentPage.history => tasks
            .where((task) =>
                task.status == TaskStatus.delivered ||
                task.status == TaskStatus.failed ||
                (task.isPickup && task.status == TaskStatus.pickedUp))
            .toList(),
      };

  Future<void> _refresh() async => setState(() => _result = _service.list());

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text(_title),
          actions: [
            IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
          ],
        ),
        body: FutureBuilder<RiderAssignmentsResult>(
          future: _result,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _EmptyPanel(
                  message: _errorText(snapshot.error), onRetry: _refresh);
            }
            final tasks = _filter(snapshot.data?.tasks ?? const []);
            if (tasks.isEmpty) {
              return _EmptyPanel(
                message: snapshot.data?.message ?? 'Nothing to show yet.',
                onRetry: _refresh,
              );
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: tasks.length,
                itemBuilder: (context, index) => _AssignmentCard(
                  task: tasks[index],
                  onTap: () async {
                    final changed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RiderDeliveryDetailScreen(
                          task: tasks[index],
                        ),
                      ),
                    );
                    if (changed == true) _refresh();
                  },
                ),
              ),
            );
          },
        ),
      );
}

class RiderDeliveryDetailScreen extends StatefulWidget {
  const RiderDeliveryDetailScreen({super.key, required this.task});
  final DeliveryTask task;

  @override
  State<RiderDeliveryDetailScreen> createState() =>
      _RiderDeliveryDetailScreenState();
}

class _RiderDeliveryDetailScreenState extends State<RiderDeliveryDetailScreen> {
  final _service = RiderAssignmentService();
  bool _working = false;

  Future<void> _advance() async {
    setState(() => _working = true);
    try {
      switch (widget.task.status) {
        case TaskStatus.pending:
          await _service.accept(widget.task.id);
        case TaskStatus.accepted:
          if (widget.task.isPickup) {
            await _service.confirmPickup(widget.task.id);
          } else {
            await _service.startDelivery(widget.task.id);
          }
        case TaskStatus.pickedUp:
          if (!widget.task.isPickup) {
            await _service.startDelivery(widget.task.id);
          } else {
            return;
          }
        case TaskStatus.outForDelivery:
          if (widget.task.codAmount > 0) {
            final confirmedCod = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Confirm Cash Collection',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                content: Text(
                  'Please confirm that you have collected ₱${widget.task.codAmount.toStringAsFixed(2)} in cash from ${widget.task.contactName}.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.statusGreen,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Confirm Received'),
                  ),
                ],
              ),
            );
            if (confirmedCod != true) return;
          }
          final proof = await ImagePicker().pickImage(
            source: ImageSource.camera,
            imageQuality: 78,
            maxWidth: 1600,
          );
          if (proof == null || !mounted) return;
          final confirmed = await ProofOfDeliverySheet.show(
            context,
            task: widget.task,
            imagePath: proof.path,
            onRetake: () => _advance(),
          );
          if (confirmed == true && mounted) {
            Navigator.pop(context, true);
          }
          return;
        case TaskStatus.delivered:
        case TaskStatus.failed:
          return;
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.message), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _reportDeliveryFailure() async {
    String selectedReason = 'Buyer not available / Not home';
    final reasons = [
      'Buyer not available / Not home',
      'Incorrect or incomplete delivery address',
      'Buyer refused parcel',
      'Customer requested rescheduled delivery',
      'Unreachable phone number / unattended',
    ];
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
              'Report Delivery Issue (Attempt ${widget.task.attemptNumber} of 3)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.task.attemptNumber >= 3
                    ? 'Note: This is attempt 3 of 3. Marking this attempt failed will return the parcel to the hub.'
                    : 'Select reason for failed delivery attempt:',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              ...reasons.map((r) => InkWell(
                    onTap: () => setDialogState(() => selectedReason = r),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(
                            selectedReason == r
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: selectedReason == r
                                ? AppTheme.jeapPurple
                                : AppTheme.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(r, style: const TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, selectedReason),
              child: const Text('Submit Failure'),
            ),
          ],
        ),
      ),
    );
    if (reason == null || !mounted) return;

    setState(() => _working = true);
    try {
      await _service.failDelivery(widget.task.id, reason);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.message), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  String? get _action => switch (widget.task.status) {
        TaskStatus.pending =>
          widget.task.isPickup ? 'Accept pickup' : 'Accept delivery',
        TaskStatus.accepted =>
          widget.task.isPickup ? 'Confirm pickup' : 'Start delivery',
        TaskStatus.pickedUp => widget.task.isPickup ? null : 'Start delivery',
        TaskStatus.outForDelivery => 'Capture proof & complete delivery',
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final progress = switch (task.status) {
      TaskStatus.pending || TaskStatus.accepted => 0,
      TaskStatus.pickedUp || TaskStatus.outForDelivery => 1,
      TaskStatus.delivered => 2,
      TaskStatus.failed => 1,
    };
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar:
          AppBar(title: Text(task.isPickup ? 'Pickup Order' : 'Deliver Order')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProgressCard(
              progress: progress, failed: task.status == TaskStatus.failed),
          const SizedBox(height: 14),
          _DashboardCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.trackingNumber,
                    style: const TextStyle(
                        color: AppTheme.jeapPurple,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(task.contactName,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                _IconText(
                    icon: Icons.location_on_outlined,
                    text: task.deliveryAddress),
                if (task.contactPhone.isNotEmpty) ...[
                  const Divider(height: 24),
                  _IconText(
                      icon: Icons.phone_outlined, text: task.contactPhone),
                ],
              ],
            ),
          ),
          if (_action != null) ...[
            const SizedBox(height: 18),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _working ? null : _advance,
                child: _working
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_action!),
              ),
            ),
            const SizedBox(height: 9),
            if (task.latitude != null &&
                task.longitude != null &&
                task.latitude! >= -90 &&
                task.latitude! <= 90 &&
                task.longitude! >= -180 &&
                task.longitude! <= 180)
              OutlinedButton.icon(
                onPressed: () async {
                  final uri = Uri.https('www.google.com', '/maps/dir/', {
                    'api': '1',
                    'destination': '${task.latitude},${task.longitude}',
                  });
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.map_outlined),
                label: Text(task.isPickup
                    ? 'Navigate to seller'
                    : 'Navigate to customer'),
              ),
            if (task.contactPhone.isNotEmpty)
              OutlinedButton.icon(
                onPressed: () async {
                  final uri = Uri(scheme: 'tel', path: task.contactPhone);
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
                icon: const Icon(Icons.call_outlined),
                label: Text(task.isPickup ? 'Call Seller' : 'Call Customer'),
              ),
            if (!task.isPickup && task.status == TaskStatus.outForDelivery)
              TextButton.icon(
                onPressed: _working ? null : _reportDeliveryFailure,
                icon: const Icon(Icons.report_outlined),
                label: const Text('Report delivery issue'),
              ),
          ],
        ],
      ),
    );
  }
}

class _RiderChatInbox extends StatelessWidget {
  const _RiderChatInbox();
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.jeapPurple.withValues(alpha: .1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat_bubble_outline,
                      size: 40, color: AppTheme.jeapPurple),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Buyer & Support Messages',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Message buyers regarding active deliveries or reach out to the support desk.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RiderChatScreen(
                          buyerName: 'Support Desk',
                          trackingNumber: 'General Inquiries',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat, size: 16),
                  label: const Text('Open Messages'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.jeapPurple,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _RiderProfile extends StatefulWidget {
  const _RiderProfile();
  @override
  State<_RiderProfile> createState() => _RiderProfileState();
}

class _RiderProfileState extends State<_RiderProfile> {
  final _auth = AuthService();
  late Future<Map<String, dynamic>?> _user;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _user = _auth.me();
  }

  Future<void> _pickAndUploadPhoto(String? currentAvatarUrl) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Change Profile Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined,
                    color: AppTheme.jeapPurple),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppTheme.jeapPurple),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (picked == null || !mounted) return;

      setState(() => _uploadingPhoto = true);
      final result = await _auth.updateProfilePhoto(picked.path);
      if (!mounted) return;

      setState(() {
        _uploadingPhoto = false;
        _user = _auth.me();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor:
              result.success ? AppTheme.statusGreen : Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update photo: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (shouldLogout != true) return;
    await _auth.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Account')),
        body: FutureBuilder<Map<String, dynamic>?>(
          future: _user,
          builder: (context, snapshot) {
            final user = snapshot.data ?? const <String, dynamic>{};
            final rider = user['rider_profile'] is Map
                ? Map<String, dynamic>.from(user['rider_profile'] as Map)
                : (user['courier_profile'] is Map
                    ? Map<String, dynamic>.from(user['courier_profile'] as Map)
                    : const <String, dynamic>{});
            final name = (user['name'] ?? 'Rider').toString();
            final avatarUrl = user['avatar_url']?.toString();
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _DashboardCard(
                  child: Row(children: [
                    InkWell(
                      onTap: _uploadingPhoto
                          ? null
                          : () => _pickAndUploadPhoto(avatarUrl),
                      borderRadius: BorderRadius.circular(28),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          JeapAvatar(
                            radius: 28,
                            imageUrl: avatarUrl,
                            name: name,
                            backgroundColor:
                                AppTheme.jeapPurple.withValues(alpha: 0.15),
                            cacheBust: true,
                          ),
                          if (_uploadingPhoto)
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(alpha: .45),
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppTheme.jeapPurple,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt,
                                  size: 11, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          Text(user['email']?.toString() ?? '',
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const EditProfileScreen()),
                        );
                        if (mounted) setState(() => _user = _auth.me());
                      },
                      child: const Text('Edit Profile'),
                    ),
                  ]),
                ),
                const SizedBox(height: 14),
                _ProfileItem(
                  icon: Icons.person_outline,
                  title: 'Personal Information',
                  subtitle: user['phone']?.toString() ?? 'Contact information',
                  onTap: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EditProfileScreen()),
                  ),
                ),
                _ProfileItem(
                  icon: Icons.business_outlined,
                  title: 'Logistics Fleet',
                  subtitle: rider['company_name']?.toString() ?? 'JEAP Logistics Partner',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RiderFleetScreen())),
                ),
                _ProfileItem(
                  icon: Icons.two_wheeler_outlined,
                  title: 'Vehicle Information',
                  subtitle: [
                    rider['vehicle_type'],
                    rider['plate_number'] ?? rider['vehicle_number'],
                  ]
                      .whereType<String>()
                      .where((value) => value.isNotEmpty)
                      .join(' · '),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RiderVehicleScreen())),
                ),
                _ProfileItem(
                  icon: Icons.description_outlined,
                  title: 'Documents',
                  subtitle: user['has_documents'] == true
                      ? 'Documents submitted for review'
                      : 'No documents on file',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RiderDocumentsScreen())),
                ),
                _ProfileItem(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  onTap: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ChangePasswordScreen()),
                  ),
                ),
                _ProfileItem(
                  icon: Icons.notifications_none,
                  title: 'Notification Settings',
                  onTap: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationSettingsScreen()),
                  ),
                ),
                _ProfileItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const HelpSupportScreen()),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  label: const Text('Log Out',
                      style: TextStyle(color: AppTheme.textPrimary)),
                ),
              ],
            );
          },
        ),
      );
}

class _RiderMore extends StatelessWidget {
  const _RiderMore({required this.onSelectPage});
  final ValueChanged<_AssignmentPage> onSelectPage;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('More')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ProfileItem(
              icon: Icons.inventory_2_outlined,
              title: 'Items for Pickup',
              onTap: () => onSelectPage(_AssignmentPage.pickup),
            ),
            _ProfileItem(
              icon: Icons.local_shipping_outlined,
              title: 'Items for Delivery',
              onTap: () => onSelectPage(_AssignmentPage.delivery),
            ),
            _ProfileItem(
              icon: Icons.history,
              title: 'Delivery History',
              onTap: () => onSelectPage(_AssignmentPage.history),
            ),
            _ProfileItem(
              icon: Icons.payments_outlined,
              title: 'Earnings & Remittance',
              subtitle: 'View payout rates & COD policies',
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const _ProfitScreen()),
              ),
            ),
            _ProfileItem(
              icon: Icons.alt_route,
              title: 'Linehaul Hub Trips',
              subtitle: 'Hub-to-hub linehaul transfer manifests',
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const _LinehaulTripScreen()),
              ),
            ),
            _ProfileItem(
              icon: Icons.notifications_none,
              title: 'Notification Settings',
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                    builder: (_) => const NotificationSettingsScreen()),
              ),
            ),
            _ProfileItem(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
              ),
            ),
          ],
        ),
      );
}

class _ProfitScreen extends StatelessWidget {
  const _ProfitScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Earnings & Remittance')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Payout Structure by Role',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                _rateRow('Pickup Task (Rider)', '₱30.00 / parcel'),
                _rateRow('Delivery Task (Rider)', '₱50.00 / parcel'),
                _rateRow('Linehaul Van Trip (Courier)', '₱600.00 / trip'),
                _rateRow('Linehaul 4-Wheeler (Courier)', '₱1,000.00 / trip'),
                _rateRow('Linehaul 6-Wheeler (Courier)', '₱1,500.00 / trip'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('COD Remittance Policy',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 8),
                Text(
                  '1. All collected cash on delivery (COD) must be remitted by the end of each shift.\n'
                  '2. Remittances are submitted through the JEAP Mobile app and verified at the hub.\n'
                  '3. Failure to remit within 24 hours temporarily pauses new assignments.',
                  style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _rateRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({required this.task, required this.onTap});
  final DeliveryTask task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: RiderTheme.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.trackingNumber,
                      style: const TextStyle(
                        color: RiderTheme.brandPurple,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: RiderTheme.statusDeliveredBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Payout: ₱${task.payout.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: RiderTheme.statusDelivered,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: RiderTheme.textDark),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      task.contactName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: RiderTheme.textDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: RiderTheme.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      task.deliveryAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: RiderTheme.textMuted,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  RiderStatusBadge(status: task.status, isPickup: task.isPickup),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: task.codAmount > 0
                          ? RiderTheme.codOrangeBg
                          : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: task.codAmount > 0
                            ? RiderTheme.codOrange.withValues(alpha: 0.3)
                            : const Color(0xFF93C5FD),
                      ),
                    ),
                    child: Text(
                      task.codAmount > 0
                          ? 'COD: ₱${task.codAmount.toStringAsFixed(2)}'
                          : 'Prepaid',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: task.codAmount > 0
                            ? RiderTheme.codOrange
                            : const Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                  if (task.attemptNumber > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: RiderTheme.statusFailedBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Attempt ${task.attemptNumber} of 3',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: RiderTheme.statusFailed,
                        ),
                      ),
                    ),
                  FilledButton.icon(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: RiderTheme.primaryAction,
                      minimumSize: const Size(76, 34),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    icon: const Icon(Icons.arrow_forward, size: 14),
                    label: const Text('View', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

class _LinehaulTripScreen extends StatefulWidget {
  const _LinehaulTripScreen();

  @override
  State<_LinehaulTripScreen> createState() => _LinehaulTripScreenState();
}

class _LinehaulTripScreenState extends State<_LinehaulTripScreen> {
  final _sealCtrl = TextEditingController(text: 'BH-1049281');
  String _status = 'At Origin Hub';
  String? _sealError;

  bool _validateSeal(String seal) {
    final reg = RegExp(r'^BH-\d{7}$');
    return reg.hasMatch(seal.trim());
  }

  void _depart() {
    final seal = _sealCtrl.text.trim();
    if (!_validateSeal(seal)) {
      setState(() => _sealError = 'Seal must match format: BH- followed by 7 digits (e.g. BH-1234567)');
      return;
    }
    setState(() {
      _sealError = null;
      _status = 'In Transit';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Trip departed! Container sealed with verified seal.'),
        backgroundColor: AppTheme.statusGreen,
      ),
    );
  }

  void _reportDelay() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Linehaul Delay'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Heavy Traffic Congestion'),
              onTap: () {
                Navigator.pop(ctx);
                _notifyDelay('Heavy Traffic Congestion');
              },
            ),
            ListTile(
              title: const Text('Vehicle Mechanical Issue'),
              onTap: () {
                Navigator.pop(ctx);
                _notifyDelay('Vehicle Mechanical Issue');
              },
            ),
            ListTile(
              title: const Text('Severe Weather / Road Closure'),
              onTap: () {
                Navigator.pop(ctx);
                _notifyDelay('Severe Weather / Road Closure');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _notifyDelay(String reason) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Delay reported to Logistics Dispatch: $reason'),
        backgroundColor: Colors.orange.shade800,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Linehaul Hub Trip')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TRIP-MNL-042',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.jeapPurple)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _status == 'In Transit'
                            ? Colors.blue.withValues(alpha: 0.12)
                            : AppTheme.statusGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _status == 'In Transit'
                              ? Colors.blue.shade700
                              : AppTheme.statusGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Icon(Icons.trip_origin, size: 16, color: AppTheme.jeapPurple),
                    SizedBox(width: 8),
                    Text('Manila Central Sorting Hub (MNL)',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(left: 7),
                  height: 16,
                  width: 2,
                  color: AppTheme.borderColor,
                ),
                const Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('Quezon City Distribution Hub (QC)',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
                const Divider(height: 24),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Assigned Vehicle',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    Text('6-Wheeler Linehaul Truck (₱1,500/trip)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Manifest Loading',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    Text('5 / 5 Containers Loaded (100%)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.statusGreen,
                            fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Container Security Seal:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _sealCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. BH-1049281',
                    errorText: _sealError,
                    border: const OutlineInputBorder(),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (val) {
                    if (_sealError != null) {
                      setState(() {
                        _sealError = _validateSeal(val) ? null : _sealError;
                      });
                    }
                  },
                ),
                const SizedBox(height: 18),
                if (_status == 'At Origin Hub')
                  FilledButton.icon(
                    onPressed: _depart,
                    icon: const Icon(Icons.local_shipping),
                    label: const Text('DEPART FROM ORIGIN HUB'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  )
                else
                  FilledButton.icon(
                    onPressed: () {
                      setState(() => _status = 'Completed');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Trip marked arrived and completed!'),
                          backgroundColor: AppTheme.statusGreen,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('CONFIRM ARRIVAL AT DESTINATION HUB'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.statusGreen,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _reportDelay,
                  icon: const Icon(Icons.warning_amber_rounded,
                      color: Colors.orange),
                  label: const Text('REPORT TRIP DELAY / INCIDENT',
                      style: TextStyle(color: Colors.orange)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange),
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress, this.failed = false});
  final int progress;
  final bool failed;
  @override
  Widget build(BuildContext context) {
    const labels = ['Pickup', 'On the way', 'Delivered'];
    return _DashboardCard(
      child: Row(
        children: List.generate(labels.length * 2 - 1, (index) {
          if (index.isOdd) {
            return Expanded(
              child: Container(height: 2, color: AppTheme.borderColor),
            );
          }
          final step = index ~/ 2;
          final active = step <= progress;
          return Column(
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor:
                    active ? AppTheme.jeapPurple : const Color(0xFFE6E8F0),
                child: Text('${step + 1}',
                    style: TextStyle(
                        color: active ? Colors.white : AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 6),
              Text(labels[step],
                  style: TextStyle(
                      fontSize: 10,
                      color: failed && step == 2
                          ? Colors.redAccent
                          : AppTheme.textSecondary)),
            ],
          );
        }),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE9EAF1)),
        ),
        child: child,
      );
}

class _CountCard extends StatelessWidget {
  const _CountCard(
      {required this.title, required this.count, required this.onTap});
  final String title;
  final String count;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: _DashboardCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11)),
              const SizedBox(height: 8),
              Text(count,
                  style: const TextStyle(
                      color: AppTheme.jeapPurple,
                      fontWeight: FontWeight.w700,
                      fontSize: 23)),
            ],
          ),
        ),
      );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE9EAF1)),
          ),
          child: Column(children: [
            Icon(icon, size: 21, color: AppTheme.jeapPurple),
            const SizedBox(height: 7),
            Text(label,
                maxLines: 1,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}

class _ProfileItem extends StatelessWidget {
  const _ProfileItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: Icon(icon, color: AppTheme.jeapPurple, size: 20),
          title: Text(title,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: subtitle == null || subtitle!.isEmpty
              ? null
              : Text(subtitle!,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11)),
          trailing: const Icon(Icons.chevron_right, size: 19),
          onTap: onTap,
        ),
      );
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.text, required this.onRetry});
  final String text;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12))),
          IconButton(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, color: AppTheme.jeapPurple)),
        ]),
      );
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.inbox_outlined,
                color: AppTheme.textSecondary, size: 46),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary)),
            if (onRetry != null) ...[
              const SizedBox(height: 10),
              TextButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ]),
        ),
      );
}

class _IconText extends StatelessWidget {
  const _IconText({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12))),
        ],
      );
}

String _errorText(Object? error) => error is ApiException
    ? error.message
    : 'Could not load this information. Check your connection and try again.';

// ignore: unused_element
void _showUnavailable(BuildContext context, String feature) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$feature is not available from the current API.')),
  );
}
