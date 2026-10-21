class RegistrationData {
  final String firstName;
  final String lastName;
  final String? middleInitial;
  final String email;
  final String mobileNumber;
  final String? dateOfBirth;
  final int? age;
  final String gender;
  // Address — PSGC
  final String? regionName;
  final String? regionCode;
  final String province;
  final String? provinceCode;
  final String city;
  final String? cityCode;
  final String barangay;
  final String? barangayCode;
  // Address — manual
  final String houseNumber;
  final String street;
  final String? subdivision;
  final String? buildingUnit;
  final String? otherDetails;
  final String zipCode;
  // ID
  final String? idImagePath;
  final String password;

  const RegistrationData({
    required this.firstName,
    required this.lastName,
    this.middleInitial,
    required this.email,
    required this.mobileNumber,
    this.dateOfBirth,
    this.age,
    required this.gender,
    this.regionName,
    this.regionCode,
    required this.province,
    this.provinceCode,
    required this.city,
    this.cityCode,
    required this.barangay,
    this.barangayCode,
    required this.houseNumber,
    required this.street,
    this.subdivision,
    this.buildingUnit,
    this.otherDetails,
    required this.zipCode,
    this.idImagePath,
    required this.password,
  });

  String get fullName {
    final mi = middleInitial != null && middleInitial!.isNotEmpty
        ? ' ${middleInitial!}.'
        : '';
    return '$firstName$mi $lastName'.trim();
  }

  String get formattedAddress {
    final parts = [
      if (buildingUnit != null && buildingUnit!.isNotEmpty) buildingUnit,
      if (houseNumber.isNotEmpty) houseNumber,
      if (street.isNotEmpty) street,
      if (subdivision != null && subdivision!.isNotEmpty) subdivision,
      if (barangay.isNotEmpty)
        (barangay.toLowerCase().startsWith('brgy')
            ? barangay
            : 'Brgy. $barangay'),
      if (city.isNotEmpty) city,
      if (province.isNotEmpty && province.toLowerCase() != city.toLowerCase())
        province,
      if (regionName != null &&
          regionName!.isNotEmpty &&
          regionName != province &&
          regionName != city)
        regionName,
      if (zipCode.isNotEmpty) zipCode,
    ];
    return parts.join(', ');
  }

  String get maskedPassword => '•' * 8;

  Map<String, dynamic> toJson() => {
        'first_name': firstName,
        'last_name': lastName,
        if (middleInitial != null) 'middle_initial': middleInitial,
        'email': email,
        'phone': mobileNumber,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
        'gender': gender,
        if (regionName != null) 'region_name': regionName,
        if (regionCode != null) 'region_code': regionCode,
        'province': province,
        if (provinceCode != null) 'province_code': provinceCode,
        'city': city,
        if (cityCode != null) 'city_code': cityCode,
        'barangay': barangay,
        if (barangayCode != null) 'barangay_code': barangayCode,
        'house_number': houseNumber,
        'street': street,
        if (subdivision != null) 'subdivision': subdivision,
        if (buildingUnit != null) 'building_unit': buildingUnit,
        if (otherDetails != null) 'other_details': otherDetails,
        'zip_code': zipCode,
        'password': password,
        'password_confirmation': password,
      };
}
