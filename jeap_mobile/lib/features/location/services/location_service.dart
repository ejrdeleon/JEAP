import 'package:jeap_mobile/core/network/api_client.dart';
import 'package:jeap_mobile/features/location/models/psgc_models.dart';

class LocationService {
  LocationService({ApiClient? api}) : _api = api ?? const ApiClient();

  final ApiClient _api;

  // In-memory cache for fast UI cascading
  static List<RegionItem>? _cachedRegions;
  static final Map<String, List<ProvinceItem>> _cachedProvinces = {};
  static final Map<String, List<LocalityItem>> _cachedCities = {};
  static final Map<String, List<BarangayItem>> _cachedBarangays = {};
  static final Map<String, String?> _cachedPostalCodes = {};

  Future<List<RegionItem>> getRegions() async {
    if (_cachedRegions != null && _cachedRegions!.isNotEmpty) {
      return _cachedRegions!;
    }
    try {
      final res = await _api.get('/locations/regions');
      if (res is Map && res['data'] is List && (res['data'] as List).isNotEmpty) {
        final list = (res['data'] as List)
            .map((item) => RegionItem.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        _cachedRegions = list;
        return list;
      }
    } catch (_) {}

    final fallback = _localFallbackRegions();
    _cachedRegions = fallback;
    return fallback;
  }

  Future<List<ProvinceItem>> getProvinces(String regionCode) async {
    if (regionCode.startsWith('13')) {
      return []; // NCR has no provinces
    }
    if (_cachedProvinces.containsKey(regionCode)) {
      return _cachedProvinces[regionCode]!;
    }
    try {
      final res = await _api.get('/locations/regions/$regionCode/provinces');
      if (res is Map && res['data'] is List && (res['data'] as List).isNotEmpty) {
        final list = (res['data'] as List)
            .map((item) =>
                ProvinceItem.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        _cachedProvinces[regionCode] = list;
        return list;
      }
    } catch (_) {}

    final fallback = _localFallbackProvinces(regionCode);
    _cachedProvinces[regionCode] = fallback;
    return fallback;
  }

  Future<List<LocalityItem>> getCitiesForRegion(String regionCode) async {
    final cacheKey = 'region_$regionCode';
    if (_cachedCities.containsKey(cacheKey)) {
      return _cachedCities[cacheKey]!;
    }
    try {
      final res = await _api
          .get('/locations/regions/$regionCode/cities-municipalities');
      if (res is Map && res['data'] is List && (res['data'] as List).isNotEmpty) {
        final list = (res['data'] as List)
            .map((item) =>
                LocalityItem.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        _cachedCities[cacheKey] = list;
        return list;
      }
    } catch (_) {}

    final fallback = _localFallbackRegionCities(regionCode);
    _cachedCities[cacheKey] = fallback;
    return fallback;
  }

  Future<List<LocalityItem>> getCitiesForProvince(String provinceCode) async {
    final cacheKey = 'province_$provinceCode';
    if (_cachedCities.containsKey(cacheKey)) {
      return _cachedCities[cacheKey]!;
    }
    try {
      final res = await _api
          .get('/locations/provinces/$provinceCode/cities-municipalities');
      if (res is Map && res['data'] is List && (res['data'] as List).isNotEmpty) {
        final list = (res['data'] as List)
            .map((item) =>
                LocalityItem.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        _cachedCities[cacheKey] = list;
        return list;
      }
    } catch (_) {}

    final fallback = _localFallbackProvinceCities(provinceCode);
    _cachedCities[cacheKey] = fallback;
    return fallback;
  }

  Future<List<BarangayItem>> getBarangays(String localityCode) async {
    if (_cachedBarangays.containsKey(localityCode)) {
      return _cachedBarangays[localityCode]!;
    }
    try {
      final res = await _api
          .get('/locations/cities-municipalities/$localityCode/barangays');
      if (res is Map && res['data'] is List && (res['data'] as List).isNotEmpty) {
        final list = (res['data'] as List)
            .map((item) =>
                BarangayItem.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        _cachedBarangays[localityCode] = list;
        return list;
      }
    } catch (_) {}

    final fallback = _localFallbackBarangays(localityCode);
    _cachedBarangays[localityCode] = fallback;
    return fallback;
  }

  Future<String?> getPostalCode(String localityCode) async {
    if (_cachedPostalCodes.containsKey(localityCode)) {
      return _cachedPostalCodes[localityCode];
    }
    try {
      final res = await _api
          .get('/locations/cities-municipalities/$localityCode/postal-code');
      if (res is Map && res['postal_code'] != null) {
        final code = res['postal_code']?.toString();
        _cachedPostalCodes[localityCode] = code;
        return code;
      }
    } catch (_) {}

    final code = _localFallbackPostal(localityCode);
    _cachedPostalCodes[localityCode] = code;
    return code;
  }

  // --- Local Fallback Data (Client-side safety) ---

  List<RegionItem> _localFallbackRegions() {
    return const [
      RegionItem(code: '130000000', psgc10Digit: '1300000000', name: 'NCR', regionName: 'National Capital Region', islandGroup: 'luzon'),
      RegionItem(code: '040000000', psgc10Digit: '0400000000', name: 'Region IV-A', regionName: 'CALABARZON', islandGroup: 'luzon'),
      RegionItem(code: '030000000', psgc10Digit: '0300000000', name: 'Region III', regionName: 'Central Luzon', islandGroup: 'luzon'),
      RegionItem(code: '070000000', psgc10Digit: '0700000000', name: 'Region VII', regionName: 'Central Visayas', islandGroup: 'visayas'),
      RegionItem(code: '110000000', psgc10Digit: '1100000000', name: 'Region XI', regionName: 'Davao Region', islandGroup: 'mindanao'),
    ];
  }

  List<ProvinceItem> _localFallbackProvinces(String regionCode) {
    if (regionCode == '040000000') {
      return const [
        ProvinceItem(code: '043400000', psgc10Digit: '0403400000', name: 'Laguna', regionCode: '040000000'),
        ProvinceItem(code: '042100000', psgc10Digit: '0402100000', name: 'Cavite', regionCode: '040000000'),
        ProvinceItem(code: '041000000', psgc10Digit: '0401000000', name: 'Batangas', regionCode: '040000000'),
        ProvinceItem(code: '045800000', psgc10Digit: '0405800000', name: 'Rizal', regionCode: '040000000'),
        ProvinceItem(code: '045600000', psgc10Digit: '0405600000', name: 'Quezon', regionCode: '040000000'),
      ];
    }
    return [];
  }

  List<LocalityItem> _localFallbackRegionCities(String regionCode) {
    if (regionCode.startsWith('13')) {
      return const [
        LocalityItem(code: '133900000', psgc10Digit: '1303900000', name: 'City of Manila', regionCode: '130000000', provinceCode: '', isCity: true, isMunicipality: false),
        LocalityItem(code: '137404000', psgc10Digit: '1307404000', name: 'Quezon City', regionCode: '130000000', provinceCode: '', isCity: true, isMunicipality: false),
        LocalityItem(code: '137607000', psgc10Digit: '1307607000', name: 'City of Taguig', regionCode: '130000000', provinceCode: '', isCity: true, isMunicipality: false),
        LocalityItem(code: '137601000', psgc10Digit: '1307601000', name: 'City of Makati', regionCode: '130000000', provinceCode: '', isCity: true, isMunicipality: false),
        LocalityItem(code: '137403000', psgc10Digit: '1307403000', name: 'City of Pasig', regionCode: '130000000', provinceCode: '', isCity: true, isMunicipality: false),
      ];
    }
    return [];
  }

  List<LocalityItem> _localFallbackProvinceCities(String provinceCode) {
    if (provinceCode == '043400000') {
      return const [
        LocalityItem(code: '043426000', psgc10Digit: '0403426000', name: 'Santa Cruz (Capital)', regionCode: '040000000', provinceCode: '043400000', isCity: false, isMunicipality: true),
        LocalityItem(code: '043405000', psgc10Digit: '0403405000', name: 'City of Calamba', regionCode: '040000000', provinceCode: '043400000', isCity: true, isMunicipality: false),
        LocalityItem(code: '043403000', psgc10Digit: '0403403000', name: 'City of Biñan', regionCode: '040000000', provinceCode: '043400000', isCity: true, isMunicipality: false),
        LocalityItem(code: '043425000', psgc10Digit: '0403425000', name: 'City of San Pedro', regionCode: '040000000', provinceCode: '043400000', isCity: true, isMunicipality: false),
        LocalityItem(code: '043428000', psgc10Digit: '0403428000', name: 'City of Santa Rosa', regionCode: '040000000', provinceCode: '043400000', isCity: true, isMunicipality: false),
        LocalityItem(code: '043404000', psgc10Digit: '0403404000', name: 'City of Cabuyao', regionCode: '040000000', provinceCode: '043400000', isCity: true, isMunicipality: false),
        LocalityItem(code: '043424000', psgc10Digit: '0403424000', name: 'City of San Pablo', regionCode: '040000000', provinceCode: '043400000', isCity: true, isMunicipality: false),
        LocalityItem(code: '043411000', psgc10Digit: '0403411000', name: 'Los Baños', regionCode: '040000000', provinceCode: '043400000', isCity: false, isMunicipality: true),
        LocalityItem(code: '043402000', psgc10Digit: '0403402000', name: 'Bay', regionCode: '040000000', provinceCode: '043400000', isCity: false, isMunicipality: true),
        LocalityItem(code: '043420000', psgc10Digit: '0403420000', name: 'Pagsanjan', regionCode: '040000000', provinceCode: '043400000', isCity: false, isMunicipality: true),
      ];
    }
    return [];
  }

  List<BarangayItem> _localFallbackBarangays(String localityCode) {
    if (localityCode == '043426000') {
      return const [
        BarangayItem(code: '043426001', psgc10Digit: '0403426001', name: 'Poblacion I', cityCode: '043426000'),
        BarangayItem(code: '043426002', psgc10Digit: '0403426002', name: 'Poblacion II', cityCode: '043426000'),
        BarangayItem(code: '043426003', psgc10Digit: '0403426003', name: 'Bagumbayan', cityCode: '043426000'),
        BarangayItem(code: '043426004', psgc10Digit: '0403426004', name: 'Bubukal', cityCode: '043426000'),
        BarangayItem(code: '043426005', psgc10Digit: '0403426005', name: 'Gatid', cityCode: '043426000'),
        BarangayItem(code: '043426006', psgc10Digit: '0403426006', name: 'Pagsawitan', cityCode: '043426000'),
        BarangayItem(code: '043426007', psgc10Digit: '0403426007', name: 'Santisima Cruz', cityCode: '043426000'),
      ];
    }
    return const [
      BarangayItem(code: 'brgy_01', psgc10Digit: '', name: 'Poblacion', cityCode: ''),
      BarangayItem(code: 'brgy_02', psgc10Digit: '', name: 'Barangay 1', cityCode: ''),
      BarangayItem(code: 'brgy_03', psgc10Digit: '', name: 'Barangay 2', cityCode: ''),
      BarangayItem(code: 'brgy_04', psgc10Digit: '', name: 'San Isidro', cityCode: ''),
    ];
  }

  String? _localFallbackPostal(String localityCode) {
    switch (localityCode) {
      case '043426000':
        return '4009'; // Santa Cruz
      case '043405000':
        return '4027'; // Calamba
      case '043403000':
        return '4024'; // Biñan
      case '043425000':
        return '4023'; // San Pedro
      case '043428000':
        return '4026'; // Santa Rosa
      case '043404000':
        return '4025'; // Cabuyao
      case '043424000':
        return '4000'; // San Pablo
      case '043411000':
        return '4030'; // Los Baños
      case '133900000':
        return '1000'; // Manila
      case '137607000':
        return '1630'; // Taguig
      default:
        return '4000';
    }
  }
}
