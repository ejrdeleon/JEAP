import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/jeap_app_bar.dart';
import 'package:jeap_mobile/core/widgets/primary_button.dart';
import 'package:jeap_mobile/features/account/models/address.dart';
import 'package:jeap_mobile/features/account/services/address_service.dart';
import 'package:jeap_mobile/features/location/models/psgc_models.dart';
import 'package:jeap_mobile/features/location/presentation/widgets/philippine_address_selector.dart';
import 'package:jeap_mobile/features/location/services/location_service.dart';

class AddressFormScreen extends StatefulWidget {
  final Address? initialAddress;

  const AddressFormScreen({super.key, this.initialAddress});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressService = AddressService();
  final _locationService = LocationService();

  late TextEditingController _labelController;
  late TextEditingController _recipientController;
  late TextEditingController _phoneController;
  late TextEditingController _streetController;
  late TextEditingController _subdivisionController;
  late TextEditingController _postalCodeController;
  late TextEditingController _landmarkController;
  late TextEditingController _instructionsController;

  RegionItem? _selectedRegion;
  ProvinceItem? _selectedProvince;
  LocalityItem? _selectedLocality;
  BarangayItem? _selectedBarangay;
  bool _isDefault = false;
  bool _isSaving = false;
  String? _locationError;

  bool get _isEditing => widget.initialAddress != null;

  @override
  void initState() {
    super.initState();
    final addr = widget.initialAddress;

    _labelController = TextEditingController(text: addr?.label ?? 'Home');
    _recipientController =
        TextEditingController(text: addr?.recipientName ?? '');
    _phoneController = TextEditingController(text: addr?.phone ?? '');
    _streetController = TextEditingController(
        text: addr?.streetLine ?? addr?.houseStreet ?? '');
    _subdivisionController =
        TextEditingController(text: addr?.subdivision ?? '');
    _postalCodeController = TextEditingController(text: addr?.zipCode ?? '');
    _landmarkController = TextEditingController(text: addr?.landmark ?? '');
    _instructionsController =
        TextEditingController(text: addr?.deliveryInstructions ?? '');
    _isDefault = addr?.isDefault ?? false;

    if (addr != null && addr.regionName != null) {
      _selectedRegion = RegionItem(
        code: addr.regionCode ?? '',
        psgc10Digit: '',
        name: addr.regionName!,
        regionName: addr.regionName!,
        islandGroup: '',
      );
      if (addr.province.isNotEmpty) {
        _selectedProvince = ProvinceItem(
          code: addr.provinceCode ?? '',
          psgc10Digit: '',
          name: addr.province,
          regionCode: addr.regionCode ?? '',
        );
      }
      if (addr.city.isNotEmpty) {
        _selectedLocality = LocalityItem(
          code: addr.cityCode ?? '',
          psgc10Digit: '',
          name: addr.city,
          regionCode: addr.regionCode ?? '',
          provinceCode: addr.provinceCode ?? '',
          isCity: true,
          isMunicipality: false,
        );
      }
      if (addr.barangay.isNotEmpty) {
        _selectedBarangay = BarangayItem(
          code: addr.barangayCode ?? '',
          psgc10Digit: '',
          name: addr.barangay,
          cityCode: addr.cityCode ?? '',
        );
      }
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _recipientController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _subdivisionController.dispose();
    _postalCodeController.dispose();
    _landmarkController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _onAddressSelected(SelectedPhilippineAddress selection) async {
    setState(() {
      _selectedRegion = selection.region;
      _selectedProvince = selection.province;
      _selectedLocality = selection.locality;
      _selectedBarangay = selection.barangay;
      _locationError = null;
    });

    // Auto-fetch postal code if empty
    if (_postalCodeController.text.trim().isEmpty &&
        selection.locality != null) {
      final postal =
          await _locationService.getPostalCode(selection.locality!.code);
      if (postal != null && mounted) {
        setState(() {
          _postalCodeController.text = postal;
        });
      }
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRegion == null ||
        (_selectedRegion?.isNcr == false && _selectedProvince == null) ||
        _selectedLocality == null ||
        _selectedBarangay == null) {
      setState(() {
        _locationError =
            'Please complete the official Philippine address selection.';
      });
      return;
    }

    setState(() => _isSaving = true);

    final newAddress = Address(
      id: widget.initialAddress?.id,
      label: _labelController.text.trim(),
      recipientName: _recipientController.text.trim(),
      phone: _phoneController.text.trim(),
      regionName: _selectedRegion?.displayName,
      regionCode: _selectedRegion?.code,
      province: _selectedProvince?.name ??
          (_selectedRegion?.isNcr == true ? 'Metro Manila' : ''),
      provinceCode: _selectedProvince?.code,
      city: _selectedLocality!.name,
      cityCode: _selectedLocality!.code,
      barangay: _selectedBarangay!.name,
      barangayCode: _selectedBarangay!.code,
      streetLine: _streetController.text.trim(),
      subdivision: _subdivisionController.text.trim().isNotEmpty
          ? _subdivisionController.text.trim()
          : null,
      zipCode: _postalCodeController.text.trim(),
      landmark: _landmarkController.text.trim().isNotEmpty
          ? _landmarkController.text.trim()
          : null,
      deliveryInstructions: _instructionsController.text.trim().isNotEmpty
          ? _instructionsController.text.trim()
          : null,
      isDefault: _isDefault,
    );

    try {
      if (_isEditing) {
        await _addressService.updateAddress(
            widget.initialAddress!.id!, newAddress);
      } else {
        await _addressService.addAddress(newAddress);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Address updated successfully.'
              : 'Address added successfully.'),
          backgroundColor: AppTheme.statusGreen,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save address: ${e.toString()}'),
          backgroundColor: AppTheme.priceRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const JeapAppBar(),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              Text(
                _isEditing ? 'Edit Delivery Address' : 'New Delivery Address',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Uses authoritative Philippine Standard Geographic Code (PSGC).',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),

              // Contact Info Section
              _sectionHeader('Contact Information'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _recipientController,
                      decoration: const InputDecoration(
                        labelText: 'Recipient Full Name *',
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Name is required'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      initialValue: ['Home', 'Work', 'Office', 'Other']
                              .contains(_labelController.text)
                          ? _labelController.text
                          : 'Home',
                      decoration: const InputDecoration(labelText: 'Label'),
                      items: ['Home', 'Work', 'Office', 'Other']
                          .map(
                              (l) => DropdownMenuItem(value: l, child: Text(l)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) _labelController.text = val;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  hintText: '09171234567',
                  prefixIcon: Icon(Icons.phone_outlined, size: 20),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  if (val.trim().length < 7) return 'Invalid phone number';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Administrative Location (PSGC)
              _sectionHeader('Administrative Location (PSGC)'),
              const SizedBox(height: 8),
              PhilippineAddressSelector(
                initialRegion: _selectedRegion,
                initialProvince: _selectedProvince,
                initialLocality: _selectedLocality,
                initialBarangay: _selectedBarangay,
                onAddressSelected: _onAddressSelected,
              ),
              if (_locationError != null) ...[
                const SizedBox(height: 6),
                Text(
                  _locationError!,
                  style:
                      const TextStyle(fontSize: 12, color: AppTheme.priceRed),
                ),
              ],
              const SizedBox(height: 16),

              // Detailed Address Fields
              _sectionHeader('Specific Address Details'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _streetController,
                decoration: const InputDecoration(
                  labelText: 'House / Unit / Street *',
                  hintText: 'e.g. Blk 10 Lot 15 Rizal Street',
                  prefixIcon: Icon(Icons.home_outlined, size: 20),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Street address is required'
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _subdivisionController,
                      decoration: const InputDecoration(
                        labelText: 'Subdivision / Purok / Sitio',
                        hintText: 'Optional',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _postalCodeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Postal Code',
                        hintText: 'e.g. 1630',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _landmarkController,
                decoration: const InputDecoration(
                  labelText: 'Landmark',
                  hintText: 'e.g. Near Barangay Hall or Blue Gate (Optional)',
                  prefixIcon: Icon(Icons.pin_drop_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _instructionsController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Delivery Instructions',
                  hintText:
                      'e.g. Call upon arrival, leave with guard (Optional)',
                  prefixIcon: Icon(Icons.notes_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 16),

              // Default Toggle
              SwitchListTile(
                value: _isDefault,
                activeThumbColor: AppTheme.jeapPurple,
                title: const Text(
                  'Set as default delivery address',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _isDefault = val),
              ),
              const SizedBox(height: 24),

              // Submit Button
              PrimaryButton(
                label: _isEditing ? 'UPDATE ADDRESS' : 'SAVE ADDRESS',
                loading: _isSaving,
                onPressed: _saveAddress,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppTheme.jeapPurple,
        letterSpacing: 0.2,
      ),
    );
  }
}
