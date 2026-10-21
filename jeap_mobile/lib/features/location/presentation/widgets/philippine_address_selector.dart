import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/features/location/models/psgc_models.dart';
import 'package:jeap_mobile/features/location/services/location_service.dart';

class PhilippineAddressSelector extends StatefulWidget {
  final RegionItem? initialRegion;
  final ProvinceItem? initialProvince;
  final LocalityItem? initialLocality;
  final BarangayItem? initialBarangay;
  final void Function(SelectedPhilippineAddress selection) onAddressSelected;

  const PhilippineAddressSelector({
    super.key,
    this.initialRegion,
    this.initialProvince,
    this.initialLocality,
    this.initialBarangay,
    required this.onAddressSelected,
  });

  static Future<SelectedPhilippineAddress?> show({
    required BuildContext context,
    RegionItem? initialRegion,
    ProvinceItem? initialProvince,
    LocalityItem? initialLocality,
    BarangayItem? initialBarangay,
  }) {
    return showModalBottomSheet<SelectedPhilippineAddress>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PhilippineAddressSelectorSheet(
        initialRegion: initialRegion,
        initialProvince: initialProvince,
        initialLocality: initialLocality,
        initialBarangay: initialBarangay,
      ),
    );
  }

  @override
  State<PhilippineAddressSelector> createState() =>
      _PhilippineAddressSelectorState();
}

class _PhilippineAddressSelectorState extends State<PhilippineAddressSelector> {
  RegionItem? _region;
  ProvinceItem? _province;
  LocalityItem? _locality;
  BarangayItem? _barangay;

  @override
  void initState() {
    super.initState();
    _region = widget.initialRegion;
    _province = widget.initialProvince;
    _locality = widget.initialLocality;
    _barangay = widget.initialBarangay;
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = _region != null;
    final summary = _buildSummaryText();

    return InkWell(
      onTap: () async {
        final result = await PhilippineAddressSelector.show(
          context: context,
          initialRegion: _region,
          initialProvince: _province,
          initialLocality: _locality,
          initialBarangay: _barangay,
        );
        if (result != null) {
          setState(() {
            _region = result.region;
            _province = result.province;
            _locality = result.locality;
            _barangay = result.barangay;
          });
          widget.onAddressSelected(result);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(
            color: hasSelection ? AppTheme.jeapPurple : Colors.grey.shade300,
            width: hasSelection ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              color: hasSelection ? AppTheme.jeapPurple : Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Administrative Location (PSGC)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasSelection
                        ? summary
                        : 'Tap to select Region, Province, City & Barangay',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          hasSelection ? FontWeight.w600 : FontWeight.normal,
                      color: hasSelection
                          ? AppTheme.textPrimary
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  String _buildSummaryText() {
    final parts = <String>[];
    if (_barangay != null) parts.add('Brgy. ${_barangay!.name}');
    if (_locality != null) parts.add(_locality!.name);
    if (_province != null && (_region == null || !_region!.isNcr)) {
      parts.add(_province!.name);
    }
    if (_region != null) parts.add(_region!.name);
    return parts.join(', ');
  }
}

class _PhilippineAddressSelectorSheet extends StatefulWidget {
  final RegionItem? initialRegion;
  final ProvinceItem? initialProvince;
  final LocalityItem? initialLocality;
  final BarangayItem? initialBarangay;

  const _PhilippineAddressSelectorSheet({
    this.initialRegion,
    this.initialProvince,
    this.initialLocality,
    this.initialBarangay,
  });

  @override
  State<_PhilippineAddressSelectorSheet> createState() =>
      _PhilippineAddressSelectorSheetState();
}

enum _Step { region, province, locality, barangay }

class _PhilippineAddressSelectorSheetState
    extends State<_PhilippineAddressSelectorSheet> {
  final _service = LocationService();
  final _searchController = TextEditingController();

  _Step _currentStep = _Step.region;
  bool _isLoading = false;
  String _searchQuery = '';

  RegionItem? _selectedRegion;
  ProvinceItem? _selectedProvince;
  LocalityItem? _selectedLocality;
  BarangayItem? _selectedBarangay;

  List<RegionItem> _regions = [];
  List<ProvinceItem> _provinces = [];
  List<LocalityItem> _localities = [];
  List<BarangayItem> _barangays = [];

  @override
  void initState() {
    super.initState();
    _selectedRegion = widget.initialRegion;
    _selectedProvince = widget.initialProvince;
    _selectedLocality = widget.initialLocality;
    _selectedBarangay = widget.initialBarangay;

    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final regions = await _service.getRegions();
    if (mounted) {
      setState(() {
        _regions = regions;
        _isLoading = false;
      });
      if (_selectedRegion != null) {
        if (_selectedRegion!.isNcr) {
          _fetchLocalities();
          _currentStep = _Step.locality;
        } else {
          _fetchProvinces();
          _currentStep = _Step.province;
        }
      }
    }
  }

  Future<void> _fetchProvinces() async {
    if (_selectedRegion == null) return;
    setState(() => _isLoading = true);
    final provinces = await _service.getProvinces(_selectedRegion!.code);
    if (mounted) {
      setState(() {
        _provinces = provinces;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchLocalities() async {
    if (_selectedRegion == null) return;
    setState(() => _isLoading = true);
    List<LocalityItem> list;
    if (_selectedRegion!.isNcr || _selectedProvince == null) {
      list = await _service.getCitiesForRegion(_selectedRegion!.code);
    } else {
      list = await _service.getCitiesForProvince(_selectedProvince!.code);
    }
    if (mounted) {
      setState(() {
        _localities = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchBarangays() async {
    if (_selectedLocality == null) return;
    setState(() => _isLoading = true);
    final list = await _service.getBarangays(_selectedLocality!.code);
    if (mounted) {
      setState(() {
        _barangays = list;
        _isLoading = false;
      });
    }
  }

  void _onRegionPicked(RegionItem item) {
    setState(() {
      _selectedRegion = item;
      _selectedProvince = null;
      _selectedLocality = null;
      _selectedBarangay = null;
      _searchController.clear();
      _searchQuery = '';
      if (item.isNcr) {
        // NCR does not have provinces, jump directly to locality
        _currentStep = _Step.locality;
        _fetchLocalities();
      } else {
        _currentStep = _Step.province;
        _fetchProvinces();
      }
    });
  }

  void _onProvincePicked(ProvinceItem item) {
    setState(() {
      _selectedProvince = item;
      _selectedLocality = null;
      _selectedBarangay = null;
      _searchController.clear();
      _searchQuery = '';
      _currentStep = _Step.locality;
      _fetchLocalities();
    });
  }

  void _onLocalityPicked(LocalityItem item) {
    setState(() {
      _selectedLocality = item;
      _selectedBarangay = null;
      _searchController.clear();
      _searchQuery = '';
      _currentStep = _Step.barangay;
      _fetchBarangays();
    });
  }

  void _onBarangayPicked(BarangayItem item) {
    setState(() {
      _selectedBarangay = item;
    });

    final result = SelectedPhilippineAddress(
      region: _selectedRegion,
      province: _selectedProvince,
      locality: _selectedLocality,
      barangay: _selectedBarangay,
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Container(
      height: media.size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Philippine Address',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _stepSubtitle(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.jeapPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Step Progress Pills / Breadcrumbs
          _buildBreadcrumbs(),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: _searchPlaceholder(),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const Divider(height: 1),

          // Body List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Fetching official PSGC data...'),
                      ],
                    ),
                  )
                : _buildCurrentList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    final isNcr = _selectedRegion?.isNcr ?? false;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          _breadcrumbChip(
            label: _selectedRegion?.name ?? '1. Region',
            isSelected: _currentStep == _Step.region,
            isSet: _selectedRegion != null,
            onTap: () {
              setState(() {
                _currentStep = _Step.region;
                _searchController.clear();
                _searchQuery = '';
              });
            },
          ),
          if (!isNcr) ...[
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            _breadcrumbChip(
              label: _selectedProvince?.name ?? '2. Province',
              isSelected: _currentStep == _Step.province,
              isSet: _selectedProvince != null,
              onTap: _selectedRegion != null
                  ? () {
                      setState(() {
                        _currentStep = _Step.province;
                        _searchController.clear();
                        _searchQuery = '';
                        _fetchProvinces();
                      });
                    }
                  : null,
            ),
          ],
          const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          _breadcrumbChip(
            label: _selectedLocality?.name ??
                (isNcr ? '2. City/Municipality' : '3. City/Municipality'),
            isSelected: _currentStep == _Step.locality,
            isSet: _selectedLocality != null,
            onTap: (_selectedRegion != null &&
                    (isNcr || _selectedProvince != null))
                ? () {
                    setState(() {
                      _currentStep = _Step.locality;
                      _searchController.clear();
                      _searchQuery = '';
                      _fetchLocalities();
                    });
                  }
                : null,
          ),
          const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          _breadcrumbChip(
            label: _selectedBarangay?.name ??
                (isNcr ? '3. Barangay' : '4. Barangay'),
            isSelected: _currentStep == _Step.barangay,
            isSet: _selectedBarangay != null,
            onTap: _selectedLocality != null
                ? () {
                    setState(() {
                      _currentStep = _Step.barangay;
                      _searchController.clear();
                      _searchQuery = '';
                      _fetchBarangays();
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _breadcrumbChip({
    required String label,
    required bool isSelected,
    required bool isSet,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.jeapPurple
              : (isSet ? Colors.blue.shade50 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.jeapPurple
                : (isSet ? Colors.blue.shade200 : Colors.grey.shade300),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isSet ? AppTheme.jeapPurple : Colors.grey.shade600),
          ),
        ),
      ),
    );
  }

  String _stepSubtitle() {
    switch (_currentStep) {
      case _Step.region:
        return 'Step 1: Choose Region';
      case _Step.province:
        return 'Step 2: Choose Province in ${_selectedRegion?.name}';
      case _Step.locality:
        return _selectedRegion?.isNcr == true
            ? 'Step 2: Choose City or Municipality in NCR'
            : 'Step 3: Choose City or Municipality in ${_selectedProvince?.name}';
      case _Step.barangay:
        return 'Step ${_selectedRegion?.isNcr == true ? '3' : '4'}: Choose Barangay in ${_selectedLocality?.name}';
    }
  }

  String _searchPlaceholder() {
    switch (_currentStep) {
      case _Step.region:
        return 'Search region (e.g. NCR, Central Luzon, CALABARZON)...';
      case _Step.province:
        return 'Search province (e.g. Laguna, Cavite, Cebu)...';
      case _Step.locality:
        return 'Search city / municipality (e.g. Taguig, Quezon City)...';
      case _Step.barangay:
        return 'Search barangay...';
    }
  }

  Widget _buildCurrentList() {
    switch (_currentStep) {
      case _Step.region:
        final filtered = _regions.where((r) {
          if (_searchQuery.isEmpty) return true;
          return r.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              r.regionName.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        if (filtered.isEmpty) {
          return _emptyPlaceholder('No matching regions found.');
        }

        return ListView.separated(
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final item = filtered[i];
            final isChosen = _selectedRegion?.code == item.code;
            return ListTile(
              title: Text(
                item.name,
                style: TextStyle(
                  fontWeight: isChosen ? FontWeight.bold : FontWeight.normal,
                  color: isChosen ? AppTheme.jeapPurple : Colors.black87,
                ),
              ),
              subtitle: item.regionName.isNotEmpty &&
                      item.regionName != item.name
                  ? Text(item.regionName, style: const TextStyle(fontSize: 12))
                  : null,
              trailing: isChosen
                  ? const Icon(Icons.check, color: AppTheme.jeapPurple)
                  : const Icon(Icons.chevron_right,
                      size: 18, color: Colors.grey),
              onTap: () => _onRegionPicked(item),
            );
          },
        );

      case _Step.province:
        final filtered = _provinces.where((p) {
          if (_searchQuery.isEmpty) return true;
          return p.name.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        if (filtered.isEmpty) {
          return _emptyPlaceholder('No matching provinces found.');
        }

        return ListView.separated(
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final item = filtered[i];
            final isChosen = _selectedProvince?.code == item.code;
            return ListTile(
              title: Text(
                item.name,
                style: TextStyle(
                  fontWeight: isChosen ? FontWeight.bold : FontWeight.normal,
                  color: isChosen ? AppTheme.jeapPurple : Colors.black87,
                ),
              ),
              trailing: isChosen
                  ? const Icon(Icons.check, color: AppTheme.jeapPurple)
                  : const Icon(Icons.chevron_right,
                      size: 18, color: Colors.grey),
              onTap: () => _onProvincePicked(item),
            );
          },
        );

      case _Step.locality:
        final filtered = _localities.where((c) {
          if (_searchQuery.isEmpty) return true;
          return c.name.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        if (filtered.isEmpty) {
          return _emptyPlaceholder(
              'No matching cities or municipalities found.');
        }

        return ListView.separated(
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final item = filtered[i];
            final isChosen = _selectedLocality?.code == item.code;
            return ListTile(
              title: Text(
                item.name,
                style: TextStyle(
                  fontWeight: isChosen ? FontWeight.bold : FontWeight.normal,
                  color: isChosen ? AppTheme.jeapPurple : Colors.black87,
                ),
              ),
              subtitle: Text(
                item.isCity ? 'City' : 'Municipality',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              trailing: isChosen
                  ? const Icon(Icons.check, color: AppTheme.jeapPurple)
                  : const Icon(Icons.chevron_right,
                      size: 18, color: Colors.grey),
              onTap: () => _onLocalityPicked(item),
            );
          },
        );

      case _Step.barangay:
        final filtered = _barangays.where((b) {
          if (_searchQuery.isEmpty) return true;
          return b.name.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        if (filtered.isEmpty) {
          return _emptyPlaceholder('No matching barangays found.');
        }

        return ListView.separated(
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final item = filtered[i];
            final isChosen = _selectedBarangay?.code == item.code;
            return ListTile(
              title: Text(
                item.name,
                style: TextStyle(
                  fontWeight: isChosen ? FontWeight.bold : FontWeight.normal,
                  color: isChosen ? AppTheme.jeapPurple : Colors.black87,
                ),
              ),
              trailing: isChosen
                  ? const Icon(Icons.check_circle, color: AppTheme.jeapPurple)
                  : const Icon(Icons.chevron_right,
                      size: 18, color: Colors.grey),
              onTap: () => _onBarangayPicked(item),
            );
          },
        );
    }
  }

  Widget _emptyPlaceholder(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
