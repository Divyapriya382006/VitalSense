enum UserRole { patient, doctor, admin }
enum BloodGroup { aPos, aNeg, bPos, bNeg, oPos, oNeg, abPos, abNeg }

class UserModel {
  final String uid;
  final String name;
  final String email;
  final DateTime dateOfBirth;
  final int age; // auto-calculated
  final BloodGroup bloodGroup;
  final double heightCm;
  final double weightKg;
  final double bmi; // auto-calculated
  final bool isGymPerson;
  final bool isAthletic;
  final bool isFemale;
  final UserRole role;
  final String? doctorId;
  final List<String> emergencyContacts; // phone numbers
  final List<String> familyMemberIds;
  final String? profileImageUrl;
  final DateTime createdAt;

  // Female specific
  final DateTime? lastPeriodDate;
  final int? periodCycleDays;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.dateOfBirth,
    required this.bloodGroup,
    required this.heightCm,
    required this.weightKg,
    required this.isGymPerson,
    required this.isAthletic,
    required this.isFemale,
    required this.role,
    this.doctorId,
    this.emergencyContacts = const [],
    this.familyMemberIds = const [],
    this.profileImageUrl,
    required this.createdAt,
    this.lastPeriodDate,
    this.periodCycleDays,
  })  : age = _calculateAge(dateOfBirth),
        bmi = _calculateBMI(weightKg, heightCm);

  static int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  static double _calculateBMI(double weight, double height) {
    final heightM = height / 100;
    return double.parse((weight / (heightM * heightM)).toStringAsFixed(1));
  }

  String get bmiCategory {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
  }

  DateTime? get nextPeriodDate {
    if (lastPeriodDate == null || periodCycleDays == null) return null;
    return lastPeriodDate!.add(Duration(days: periodCycleDays!));
  }

  int? get daysUntilNextPeriod {
    if (nextPeriodDate == null) return null;
    return nextPeriodDate!.difference(DateTime.now()).inDays;
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'bloodGroup': bloodGroup.name,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'isGymPerson': isGymPerson ? 1 : 0,
      'isAthletic': isAthletic ? 1 : 0,
      'isFemale': isFemale ? 1 : 0,
      'role': role.name,
      'doctorId': doctorId,
      'emergencyContacts': emergencyContacts.join(','),
      'familyMemberIds': familyMemberIds.join(','),
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastPeriodDate': lastPeriodDate?.toIso8601String(),
      'periodCycleDays': periodCycleDays,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> d) {
    return UserModel(
      uid: d['uid'] ?? '',
      name: d['name'] ?? '',
      email: d['email'] ?? '',
      dateOfBirth: DateTime.parse(d['dateOfBirth']),
      bloodGroup: BloodGroup.values.firstWhere((e) => e.name == d['bloodGroup']),
      heightCm: (d['heightCm'] as num).toDouble(),
      weightKg: (d['weightKg'] as num).toDouble(),
      isGymPerson: d['isGymPerson'] == 1 || d['isGymPerson'] == true,
      isAthletic: d['isAthletic'] == 1 || d['isAthletic'] == true,
      isFemale: d['isFemale'] == 1 || d['isFemale'] == true,
      role: UserRole.values.firstWhere((e) => e.name == d['role']),
      doctorId: d['doctorId'],
      emergencyContacts: d['emergencyContacts'] is String
          ? (d['emergencyContacts'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : List<String>.from(d['emergencyContacts'] ?? []),
      familyMemberIds: d['familyMemberIds'] is String
          ? (d['familyMemberIds'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : List<String>.from(d['familyMemberIds'] ?? []),
      profileImageUrl: d['profileImageUrl'],
      createdAt: DateTime.parse(d['createdAt']),
      lastPeriodDate: d['lastPeriodDate'] != null
          ? DateTime.parse(d['lastPeriodDate'])
          : null,
      periodCycleDays: d['periodCycleDays'],
    );
  }

  UserModel copyWith({
    String? name,
    double? heightCm,
    double? weightKg,
    String? doctorId,
    List<String>? emergencyContacts,
    List<String>? familyMemberIds,
    String? profileImageUrl,
    DateTime? lastPeriodDate,
    int? periodCycleDays,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      dateOfBirth: dateOfBirth,
      bloodGroup: bloodGroup,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      isGymPerson: isGymPerson,
      isAthletic: isAthletic,
      isFemale: isFemale,
      role: role,
      doctorId: doctorId ?? this.doctorId,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      familyMemberIds: familyMemberIds ?? this.familyMemberIds,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt,
      lastPeriodDate: lastPeriodDate ?? this.lastPeriodDate,
      periodCycleDays: periodCycleDays ?? this.periodCycleDays,
    );
  }
}
