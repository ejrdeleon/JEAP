import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/network/api_client.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/primary_button.dart';

class RiderVehicleScreen extends StatefulWidget {
  const RiderVehicleScreen({super.key});

  @override
  State<RiderVehicleScreen> createState() => _RiderVehicleScreenState();
}

class _RiderVehicleScreenState extends State<RiderVehicleScreen> {
  final _api = const ApiClient();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _typeCtrl;
  late TextEditingController _plateCtrl;
  late TextEditingController _licenseCtrl;
  late TextEditingController _modelCtrl;

  bool _isOnline = true;
  bool _isLoading = true;
  bool _isSaving = false;

  final Map<String, bool> _safetyChecklist = {
    'Brakes and Tires Inspection': true,
    'Headlights and Turn Signals': true,
    'Fuel / Battery Level OK': true,
    'Helmet and Safety Gear Worn': true,
    'Delivery Cargo Box Secured': true,
  };

  @override
  void initState() {
    super.initState();
    _typeCtrl = TextEditingController(text: 'Motorcycle');
    _plateCtrl = TextEditingController(text: 'ND-4110');
    _licenseCtrl = TextEditingController(text: 'N01-23-456789');
    _modelCtrl = TextEditingController(text: 'Yamaha NMAX 155');
    _loadVehicle();
  }

  @override
  void dispose() {
    _typeCtrl.dispose();
    _plateCtrl.dispose();
    _licenseCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadVehicle() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get('/rider/vehicle');
      if (res is Map<String, dynamic>) {
        setState(() {
          _typeCtrl.text = res['vehicle_type']?.toString() ?? 'Motorcycle';
          _plateCtrl.text = res['plate_number']?.toString() ?? 'ND-4110';
          _licenseCtrl.text =
              res['license_number']?.toString() ?? 'N01-23-456789';
          _modelCtrl.text = res['model_name']?.toString() ?? 'Yamaha NMAX 155';
          _isOnline = res['is_online'] == true;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      await _api.put('/rider/vehicle', {
        'vehicle_type': _typeCtrl.text.trim(),
        'plate_number': _plateCtrl.text.trim(),
        'license_number': _licenseCtrl.text.trim(),
        'is_online': _isOnline,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vehicle information saved successfully.'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update vehicle: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Vehicle Information',
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vehicle Status Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.jeapPurple.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.two_wheeler,
                              color: AppTheme.jeapPurple,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _modelCtrl.text,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Plate Number: ${_plateCtrl.text}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isOnline,
                            activeTrackColor: AppTheme.jeapPurple,
                            activeThumbColor: Colors.white,
                            onChanged: (val) => setState(() => _isOnline = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Vehicle Details Form Card
                    _buildSectionHeader('VEHICLE REGISTRATION'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _typeCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Vehicle Type',
                              hintText: 'e.g. Motorcycle, Scooter, Van',
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _plateCtrl,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Plate Number',
                              hintText: 'e.g. ND-4110',
                              prefixIcon: Icon(Icons.numbers),
                            ),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _licenseCtrl,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Driver\'s License Number',
                              hintText: 'e.g. N01-23-456789',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _modelCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Make & Model',
                              hintText: 'e.g. Yamaha NMAX 155',
                              prefixIcon: Icon(Icons.directions_bike),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 5-Point Daily Safety Checklist
                    _buildSectionHeader('5-POINT DAILY SAFETY CHECKLIST'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: _safetyChecklist.keys.map((check) {
                          final isChecked = _safetyChecklist[check] ?? false;
                          return CheckboxListTile(
                            title: Text(
                              check,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isChecked
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isChecked
                                    ? AppTheme.textPrimary
                                    : AppTheme.textSecondary,
                              ),
                            ),
                            value: isChecked,
                            activeColor: AppTheme.jeapPurple,
                            dense: true,
                            onChanged: (val) {
                              setState(() {
                                _safetyChecklist[check] = val ?? false;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    PrimaryButton(
                      label: _isSaving ? 'SAVING...' : 'SAVE VEHICLE DETAILS',
                      onPressed: _isSaving ? null : _saveVehicle,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade600,
        letterSpacing: 1,
      ),
    );
  }
}
