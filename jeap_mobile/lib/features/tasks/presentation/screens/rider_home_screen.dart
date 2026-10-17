import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jeap_mobile/core/network/api_exception.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/features/account/presentation/screens/change_password_screen.dart';
import 'package:jeap_mobile/features/account/presentation/screens/edit_profile_screen.dart';
import 'package:jeap_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:jeap_mobile/features/auth/services/auth_service.dart';
import 'package:jeap_mobile/features/tasks/models/delivery_task.dart';
import 'package:jeap_mobile/features/tasks/services/rider_assignment_service.dart';

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

  @override
  void initState() {
    super.initState();
    _assignments = _service.list();
  }

  void _refresh() => setState(() => _assignments = _service.list());

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('JEAP Courier'),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.account_circle_outlined),
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
                    task.status != TaskStatus.delivered &&
                    task.status != TaskStatus.failed)
                .length;
            final deliveries = tasks
                .where((task) =>
                    !task.isPickup &&
                    task.status != TaskStatus.delivered &&
                    task.status != TaskStatus.failed)
                .length;
            return RefreshIndicator(
              onRefresh: () async => _refresh(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  const Text('Today’s Earnings',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 4),
                  _DashboardCard(
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Earnings summary',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12)),
                              SizedBox(height: 5),
                              Text('Not available',
                                  style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 20)),
                              SizedBox(height: 3),
                              Text('Earnings data is not provided by the API',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 10)),
                            ],
                          ),
                        ),
                        Icon(Icons.trending_up,
                            color: AppTheme.jeapPurple.withValues(alpha: .8)),
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
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Rider chat is not connected to the API yet.')),
                        ),
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
                task.status == TaskStatus.failed)
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
          await _service.confirmPickup(widget.task.id);
        case TaskStatus.pickedUp:
          await _service.startDelivery(widget.task.id);
        case TaskStatus.outForDelivery:
          await _service.completeDelivery(widget.task.id);
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

  String? get _action => switch (widget.task.status) {
        TaskStatus.pending => 'Accept assignment',
        TaskStatus.accepted => 'Start pickup',
        TaskStatus.pickedUp => 'Start delivery',
        TaskStatus.outForDelivery => 'Complete delivery',
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
                Text(task.buyerName,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                _IconText(
                    icon: Icons.location_on_outlined,
                    text: task.deliveryAddress),
                if (task.buyerPhone.isNotEmpty) ...[
                  const Divider(height: 24),
                  _IconText(icon: Icons.phone_outlined, text: task.buyerPhone),
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
            if (task.buyerPhone.isNotEmpty)
              OutlinedButton.icon(
                onPressed: () async {
                  final uri = Uri(scheme: 'tel', path: task.buyerPhone);
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
                icon: const Icon(Icons.call_outlined),
                label: const Text('Call Customer'),
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
        body: const _EmptyPanel(
          message:
              'Rider conversations will appear here when chat is enabled for the rider API.',
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

  @override
  void initState() {
    super.initState();
    _user = _auth.me();
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
                : const <String, dynamic>{};
            final name = (user['name'] ?? 'Rider').toString();
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _DashboardCard(
                  child: Row(children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.jeapPurple,
                      foregroundColor: Colors.white,
                      child:
                          Text(name.isNotEmpty ? name[0].toUpperCase() : 'R'),
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
                  icon: Icons.two_wheeler_outlined,
                  title: 'Vehicle Information',
                  subtitle: [rider['vehicle_type'], rider['vehicle_number']]
                      .whereType<String>()
                      .where((value) => value.isNotEmpty)
                      .join(' · '),
                  onTap: () => _showUnavailable(context, 'Vehicle details'),
                ),
                _ProfileItem(
                  icon: Icons.description_outlined,
                  title: 'Documents',
                  subtitle: user['has_documents'] == true
                      ? 'Documents submitted for review'
                      : 'No documents on file',
                  onTap: () => _showUnavailable(context, 'Document management'),
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
                  onTap: () =>
                      _showUnavailable(context, 'Notification settings'),
                ),
                _ProfileItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () => _showUnavailable(context, 'Help & Support'),
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
              title: 'Profit Dashboard',
              subtitle: 'Earnings API is unavailable',
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const _ProfitScreen()),
              ),
            ),
          ],
        ),
      );
}

class _ProfitScreen extends StatelessWidget {
  const _ProfitScreen();
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Profit Dashboard')),
        body: const _EmptyPanel(
          message:
              'Earnings and profit data are not available in the current Laravel API.',
        ),
      );
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({required this.task, required this.onTap});
  final DeliveryTask task;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Expanded(
              child: InkWell(
                onTap: onTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.trackingNumber,
                        style: const TextStyle(
                            color: AppTheme.jeapPurple,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 5),
                    Text(task.buyerName,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(task.deliveryAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                minimumSize: const Size(68, 38),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: const Text('View'),
            ),
          ]),
        ),
      );
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

void _showUnavailable(BuildContext context, String feature) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$feature is not available from the current API.')),
  );
}
