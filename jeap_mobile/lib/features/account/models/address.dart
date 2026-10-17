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
  });

  String get fullAddress {
    final parts = [
      if (buildingUnit != null && buildingUnit!.isNotEmpty) buildingUnit,
      houseStreet,
      if (subdivision != null && subdivision!.isNotEmpty) subdivision,
      barangay,
      city,
      province,
      zipCode,
    ];
    return parts.join(', ');
  }

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        id: json['id'] as int?,
        label: json['label'] as String? ??
            json['recipient_name'] as String? ??
            'Home',
        houseStreet:
            (json['house_street'] ?? json['address_line'] ?? '') as String,
        barangay: (json['barangay'] ?? '') as String,
        city: (json['city'] ?? '') as String,
        province: (json['province'] ?? '') as String,
        zipCode: (json['zip_code'] ?? json['postal_code'] ?? '') as String,
        subdivision: json['subdivision'] as String?,
        buildingUnit: json['building_unit'] as String?,
        otherDetails: json['other_details'] as String?,
        isDefault: json['is_default'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'house_street': houseStreet,
        'barangay': barangay,
        'city': city,
        'province': province,
        'zip_code': zipCode,
        if (subdivision != null) 'subdivision': subdivision,
        if (buildingUnit != null) 'building_unit': buildingUnit,
        if (otherDetails != null) 'other_details': otherDetails,
        'is_default': isDefault,
      };
}
