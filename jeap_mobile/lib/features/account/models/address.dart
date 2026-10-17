class Address {
  final int? id;
  final String label;
  final String houseStreet;
  final String barangay;
  final String city;
  final String province;
  final String zipCode;
  final String? subdivision;
  final String? buildingUnit;
  final String? otherDetails;
  final bool isDefault;
  final String? recipientName;
  final String? phone;

  const Address({
    this.id,
    required this.label,
    required this.houseStreet,
    required this.barangay,
    required this.city,
    required this.province,
    required this.zipCode,
    this.subdivision,
    this.buildingUnit,
    this.otherDetails,
    this.isDefault = false,
    this.recipientName,
    this.phone,
    this.regionName,
    this.countryName,
  });

  String get fullAddress {
    final parts = [
      if (buildingUnit != null && buildingUnit!.isNotEmpty) buildingUnit,
      houseStreet,
      if (subdivision != null && subdivision!.isNotEmpty) subdivision,
      barangay,
      city,
      province,
      if (regionName != null && regionName!.isNotEmpty) regionName,
      if (countryName != null && countryName!.isNotEmpty) countryName,
      zipCode,
    ];
    return parts.join(', ');
  }

  final String? regionName;
  final String? countryName;

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        id: (json['id'] as num?)?.toInt(),
        label: json['label'] as String? ??
            json['recipient_name'] as String? ??
            'Home',
        houseStreet: (json['street_line'] ??
            json['house_street'] ??
            json['address_line'] ??
            '') as String,
        barangay: (json['barangay_name'] ?? json['barangay'] ?? '') as String,
        city: (json['city_name'] ?? json['city'] ?? '') as String,
        province: (json['province_name'] ?? json['province'] ?? '') as String,
        zipCode: (json['postal_code'] ?? json['zip_code'] ?? '') as String,
        subdivision: json['subdivision'] as String?,
        buildingUnit: json['building_unit'] as String?,
        otherDetails: json['other_details'] as String?,
        isDefault: json['is_default'] as bool? ?? false,
        recipientName: json['recipient_name'] as String?,
        phone: json['phone'] as String?,
        regionName: json['region_name'] as String?,
        countryName: json['country_name'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'recipient_name': recipientName ?? '',
        'phone': phone ?? '',
        if (regionName != null) 'region_name': regionName,
        if (countryName != null) 'country_name': countryName,
        'street_line': houseStreet,
        'barangay_name': barangay,
        'city_name': city,
        'province_name': province,
        'postal_code': zipCode,
        if (subdivision != null) 'subdivision': subdivision,
        if (buildingUnit != null) 'building_unit': buildingUnit,
        if (otherDetails != null) 'other_details': otherDetails,
        'is_default': isDefault,
      };
}
