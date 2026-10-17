class RegistrationData {
  final String firstName;
  final String lastName;
  final String? middleInitial;
  final String email;
  final String mobileNumber;
  final String? dateOfBirth;
  final int? age;
  final String gender;
  // Address — dropdown
  final String province;
  final String city;
  final String barangay;
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
    required this.province,
    required this.city,
    required this.barangay,
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
      houseNumber,
      street,
      if (subdivision != null && subdivision!.isNotEmpty) subdivision,
      barangay,
      city,
      province,
      zipCode,
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
        'province': province,
        'city': city,
        'barangay': barangay,
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
