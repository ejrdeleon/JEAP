class RegionItem {
  final String code;
  final String psgc10Digit;
  final String name;
  final String regionName;
  final String islandGroup;

  const RegionItem({
    required this.code,
    required this.psgc10Digit,
    required this.name,
    required this.regionName,
    required this.islandGroup,
  });

  bool get isNcr => code.startsWith('13') || name.toUpperCase() == 'NCR';

  String get displayName => regionName.isNotEmpty && regionName != name
      ? '$name ($regionName)'
      : name;

  factory RegionItem.fromJson(Map<String, dynamic> json) => RegionItem(
        code: json['code']?.toString() ?? '',
        psgc10Digit: json['psgc_10_digit']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        regionName: json['region_name']?.toString() ?? '',
        islandGroup: json['island_group']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'psgc_10_digit': psgc10Digit,
        'name': name,
        'region_name': regionName,
        'island_group': islandGroup,
      };
}

class ProvinceItem {
  final String code;
  final String psgc10Digit;
  final String name;
  final String regionCode;

  const ProvinceItem({
    required this.code,
    required this.psgc10Digit,
    required this.name,
    required this.regionCode,
  });

  factory ProvinceItem.fromJson(Map<String, dynamic> json) => ProvinceItem(
        code: json['code']?.toString() ?? '',
        psgc10Digit: json['psgc_10_digit']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        regionCode: json['region_code']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'psgc_10_digit': psgc10Digit,
        'name': name,
        'region_code': regionCode,
      };
}

class LocalityItem {
  final String code;
  final String psgc10Digit;
  final String name;
  final String regionCode;
  final String provinceCode;
  final bool isCity;
  final bool isMunicipality;

  const LocalityItem({
    required this.code,
    required this.psgc10Digit,
    required this.name,
    required this.regionCode,
    required this.provinceCode,
    required this.isCity,
    required this.isMunicipality,
  });

  factory LocalityItem.fromJson(Map<String, dynamic> json) => LocalityItem(
        code: json['code']?.toString() ?? '',
        psgc10Digit: json['psgc_10_digit']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        regionCode: json['region_code']?.toString() ?? '',
        provinceCode: json['province_code']?.toString() ?? '',
        isCity: json['is_city'] as bool? ?? false,
        isMunicipality: json['is_municipality'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'psgc_10_digit': psgc10Digit,
        'name': name,
        'region_code': regionCode,
        'province_code': provinceCode,
        'is_city': isCity,
        'is_municipality': isMunicipality,
      };
}

class BarangayItem {
  final String code;
  final String psgc10Digit;
  final String name;
  final String cityCode;

  const BarangayItem({
    required this.code,
    required this.psgc10Digit,
    required this.name,
    required this.cityCode,
  });

  factory BarangayItem.fromJson(Map<String, dynamic> json) => BarangayItem(
        code: json['code']?.toString() ?? '',
        psgc10Digit: json['psgc_10_digit']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        cityCode: json['city_code']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'psgc_10_digit': psgc10Digit,
        'name': name,
        'city_code': cityCode,
      };
}

class SelectedPhilippineAddress {
  final RegionItem? region;
  final ProvinceItem? province;
  final LocalityItem? locality;
  final BarangayItem? barangay;

  const SelectedPhilippineAddress({
    this.region,
    this.province,
    this.locality,
    this.barangay,
  });

  bool get isComplete =>
      region != null &&
      (region!.isNcr || province != null) &&
      locality != null &&
      barangay != null;

  String get summary {
    final parts = <String>[];
    if (barangay != null) parts.add(barangay!.name);
    if (locality != null) parts.add(locality!.name);
    if (province != null && !region!.isNcr) parts.add(province!.name);
    if (region != null) parts.add(region!.name);
    return parts.join(', ');
  }

  SelectedPhilippineAddress copyWith({
    RegionItem? region,
    ProvinceItem? province,
    LocalityItem? locality,
    BarangayItem? barangay,
    bool clearProvince = false,
    bool clearLocality = false,
    bool clearBarangay = false,
  }) {
    return SelectedPhilippineAddress(
      region: region ?? this.region,
      province: clearProvince ? null : (province ?? this.province),
      locality: clearLocality ? null : (locality ?? this.locality),
      barangay: clearBarangay ? null : (barangay ?? this.barangay),
    );
  }
}
