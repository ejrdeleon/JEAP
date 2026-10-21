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
      if (res is Map && res['data'] is List) {
        final list = (res['data'] as List)
            .map((item) => RegionItem.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        _cachedRegions = list;
        return list;
      }
    } catch (_) {}
    return [];
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
      if (res is Map && res['data'] is List) {
        final list = (res['data'] as List)
            .map((item) =>
                ProvinceItem.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        _cachedProvinces[regionCode] = list;
        return list;
      }
    } catch (_) {}
    return [];
  }

  Future<List<LocalityItem>> getCitiesForRegion(String regionCode) async {
    final cacheKey = 'region_$regionCode';
    if (_cachedCities.containsKey(cacheKey)) {
      return _cachedCities[cacheKey]!;
    }
    try {
      final res = await _api
          .get('/locations/regions/$regionCode/cities-municipalities');
      if (res is Map && res['data'] is List) {
        final list = (res['data'] as List)
            .map((item) =>
                LocalityItem.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        _cachedCities[cacheKey] = list;
        return list;
      }
    } catch (_) {}
    return [];
  }

  Future<List<LocalityItem>> getCitiesForProvince(String provinceCode) async {
    final cacheKey = 'province_$provinceCode';
    if (_cachedCities.containsKey(cacheKey)) {
      return _cachedCities[cacheKey]!;
    }
    try {
      final res = await _api
          .get('/locations/provinces/$provinceCode/cities-municipalities');
      if (res is Map && res['data'] is List) {
        final list = (res['data'] as List)
            .map((item) =>
                LocalityItem.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        _cachedCities[cacheKey] = list;
        return list;
      }
    } catch (_) {}
    return [];
  }

  Future<List<BarangayItem>> getBarangays(String localityCode) async {
    if (_cachedBarangays.containsKey(localityCode)) {
      return _cachedBarangays[localityCode]!;
    }
    try {
      final res = await _api
          .get('/locations/cities-municipalities/$localityCode/barangays');
      if (res is Map && res['data'] is List) {
        final list = (res['data'] as List)
            .map((item) =>
                BarangayItem.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        _cachedBarangays[localityCode] = list;
        return list;
      }
    } catch (_) {}
    return [];
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
    return null;
  }
}
