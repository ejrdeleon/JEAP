class Address {
  final int? id;
  final String label;
  final String recipientName;
  final String phone;
  final String streetLine;
  final String? subdivision;
  final String barangay;
  final String? barangayCode;
  final String city;
  final String? cityCode;
  final String province;
  final String? provinceCode;
  final String? regionName;
  final String? regionCode;
  final String? countryName;
  final String zipCode;
  final String? landmark;
  final String? deliveryInstructions;
  final String? buildingUnit;
  final String? otherDetails;
  final bool isDefault;
  final double? latitude;
  final double? longitude;

  const Address({
    this.id,
    required this.label,
    required this.recipientName,
    required this.phone,
    required this.streetLine,
    this.subdivision,
    required this.barangay,
    this.barangayCode,
    required this.city,
    this.cityCode,
    required this.province,
    this.provinceCode,
    this.regionName,
    this.regionCode,
    this.countryName = 'Philippines',
    required this.zipCode,
    this.landmark,
    this.deliveryInstructions,
    this.buildingUnit,
    this.otherDetails,
    this.isDefault = false,
    this.latitude,
    this.longitude,
  });

  // Backward compatibility getter for older screens
  String get houseStreet => streetLine;

  String get fullAddress {
    final parts = <String>[];
    if (buildingUnit != null && buildingUnit!.isNotEmpty) {
      parts.add(buildingUnit!);
    }
    if (streetLine.isNotEmpty) {
      parts.add(streetLine);
    }
    if (subdivision != null && subdivision!.isNotEmpty) {
      parts.add(subdivision!);
    }
    if (barangay.isNotEmpty) {
      parts.add(barangay.toLowerCase().startsWith('brgy')
          ? barangay
          : 'Brgy. $barangay');
    }
    if (city.isNotEmpty) {
      parts.add(city);
    }
    if (province.isNotEmpty && province.toLowerCase() != city.toLowerCase()) {
      parts.add(province);
    }
    if (regionName != null &&
        regionName!.isNotEmpty &&
        regionName != province &&
        regionName != city) {
      parts.add(regionName!);
    }
    if (zipCode.isNotEmpty) {
      parts.add(zipCode);
    }
    return parts.join(', ');
  }

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        id: (json['id'] as num?)?.toInt(),
        label: json['label'] as String? ?? 'Home',
        recipientName: (json['recipient_name'] ?? json['name'] ?? '') as String,
        phone: (json['phone'] ?? json['contact_number'] ?? '') as String,
        streetLine: (json['street_line'] ??
            json['house_street'] ??
            json['address_line'] ??
            '') as String,
        subdivision: json['subdivision'] as String?,
        barangay: (json['barangay_name'] ?? json['barangay'] ?? '') as String,
        barangayCode: json['barangay_code']?.toString(),
        city: (json['city_name'] ?? json['city'] ?? '') as String,
        cityCode: json['city_code']?.toString(),
        province: (json['province_name'] ?? json['province'] ?? '') as String,
        provinceCode: json['province_code']?.toString(),
        regionName: (json['region_name'] ?? json['region']) as String?,
        regionCode: json['region_code']?.toString(),
        countryName: json['country_name'] as String? ?? 'Philippines',
        zipCode: (json['postal_code'] ?? json['zip_code'] ?? '') as String,
        landmark: json['landmark'] as String?,
        deliveryInstructions: json['delivery_instructions'] as String?,
        buildingUnit: json['building_unit'] as String?,
        otherDetails: json['other_details'] as String?,
        isDefault: json['is_default'] as bool? ?? false,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'recipient_name': recipientName,
        'phone': phone,
        'street_line': streetLine,
        if (subdivision != null && subdivision!.isNotEmpty)
          'subdivision': subdivision,
        'barangay_name': barangay,
        if (barangayCode != null && barangayCode!.isNotEmpty)
          'barangay_code': barangayCode,
        'city_name': city,
        if (cityCode != null && cityCode!.isNotEmpty) 'city_code': cityCode,
        'province_name': province,
        if (provinceCode != null && provinceCode!.isNotEmpty)
          'province_code': provinceCode,
        if (regionName != null && regionName!.isNotEmpty)
          'region_name': regionName,
        if (regionCode != null && regionCode!.isNotEmpty)
          'region_code': regionCode,
        'country_name': countryName ?? 'Philippines',
        'postal_code': zipCode,
        if (landmark != null && landmark!.isNotEmpty) 'landmark': landmark,
        if (deliveryInstructions != null && deliveryInstructions!.isNotEmpty)
          'delivery_instructions': deliveryInstructions,
        if (buildingUnit != null && buildingUnit!.isNotEmpty)
          'building_unit': buildingUnit,
        if (otherDetails != null && otherDetails!.isNotEmpty)
          'other_details': otherDetails,
        'is_default': isDefault,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };
}
