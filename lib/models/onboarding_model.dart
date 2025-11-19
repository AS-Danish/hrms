class OnboardingData {
  String? fullName;
  String? dateOfBirth;
  String? gender;
  String? phoneNumber;
  String? address;
  String? city;
  String? state;
  String? zipCode;

  // Verification Details
  String? panNumber;
  String? aadharNumber;
  String? passportNumber;

  // Bank Details
  String? bankName;
  String? accountNumber;
  String? ifscCode;
  String? accountHolderName;

  // Employment Details
  String? department;
  String? designation;
  String? joiningDate;
  String? employeeId;

  OnboardingData({
    this.fullName,
    this.dateOfBirth,
    this.gender,
    this.phoneNumber,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.panNumber,
    this.aadharNumber,
    this.passportNumber,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.accountHolderName,
    this.department,
    this.designation,
    this.joiningDate,
    this.employeeId,
  });

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'phoneNumber': phoneNumber,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'panNumber': panNumber,
      'aadharNumber': aadharNumber,
      'passportNumber': passportNumber,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'accountHolderName': accountHolderName,
      'department': department,
      'designation': designation,
      'joiningDate': joiningDate,
      'employeeId': employeeId,
    };
  }

  factory OnboardingData.fromMap(Map<String, dynamic> map) {
    return OnboardingData(
      fullName: map['fullName'],
      dateOfBirth: map['dateOfBirth'],
      gender: map['gender'],
      phoneNumber: map['phoneNumber'],
      address: map['address'],
      city: map['city'],
      state: map['state'],
      zipCode: map['zipCode'],
      panNumber: map['panNumber'],
      aadharNumber: map['aadharNumber'],
      passportNumber: map['passportNumber'],
      bankName: map['bankName'],
      accountNumber: map['accountNumber'],
      ifscCode: map['ifscCode'],
      accountHolderName: map['accountHolderName'],
      department: map['department'],
      designation: map['designation'],
      joiningDate: map['joiningDate'],
      employeeId: map['employeeId'],
    );
  }
}