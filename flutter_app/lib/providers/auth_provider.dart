import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

// ─── Hardcoded demo users ───
final _demoUsers = <String, Map<String, dynamic>>{
  'patient@test.com': {
    'password': '123456',
    'user': UserModel(
      uid: 'demo_patient_001',
      name: 'Test Patient',
      email: 'patient@test.com',
      dateOfBirth: DateTime(2000, 6, 15),
      bloodGroup: BloodGroup.oPos,
      heightCm: 170,
      weightKg: 65,
      isGymPerson: false,
      isAthletic: false,
      isFemale: false,
      role: UserRole.patient,
      emergencyContacts: ['9999999999'],
      createdAt: DateTime.now(),
    ),
  },
  'doctor@test.com': {
    'password': '123456',
    'user': UserModel(
      uid: 'demo_doctor_001',
      name: 'Dr. Kannan',
      email: 'doctor@test.com',
      dateOfBirth: DateTime(1985, 3, 20),
      bloodGroup: BloodGroup.aPos,
      heightCm: 175,
      weightKg: 72,
      isGymPerson: true,
      isAthletic: false,
      isFemale: false,
      role: UserRole.doctor,
      emergencyContacts: [],
      createdAt: DateTime.now(),
    ),
  },
  'admin@test.com': {
    'password': '123456',
    'user': UserModel(
      uid: 'demo_admin_001',
      name: 'Admin User',
      email: 'admin@test.com',
      dateOfBirth: DateTime(1990, 1, 1),
      bloodGroup: BloodGroup.bPos,
      heightCm: 172,
      weightKg: 68,
      isGymPerson: false,
      isAthletic: false,
      isFemale: false,
      role: UserRole.admin,
      emergencyContacts: [],
      createdAt: DateTime.now(),
    ),
  },
  'female@test.com': {
    'password': '123456',
    'user': UserModel(
      uid: 'demo_female_001',
      name: 'Priya Patient',
      email: 'female@test.com',
      dateOfBirth: DateTime(1998, 8, 10),
      bloodGroup: BloodGroup.abPos,
      heightCm: 160,
      weightKg: 55,
      isGymPerson: false,
      isAthletic: false,
      isFemale: true,
      role: UserRole.patient,
      emergencyContacts: ['8888888888'],
      createdAt: DateTime.now(),
      lastPeriodDate: DateTime.now().subtract(const Duration(days: 14)),
      periodCycleDays: 28,
    ),
  },
};

UserModel? _loggedInUser;

class AuthService {
  Future<void> signInWithEmail(String email, String password) async {
    final key = email.trim().toLowerCase();
    final data = _demoUsers[key];
    if (data == null) {
      throw Exception(
          'Account not found.\nTry: patient@test.com / doctor@test.com / admin@test.com\nPassword: 123456');
    }
    if (data['password'] != password) {
      throw Exception('Wrong password. Use: 123456');
    }
    _loggedInUser = data['user'] as UserModel;
  }

  Future<void> signUpWithEmail(String email, String password) async {
    await signInWithEmail(email, password);
  }

  Future<void> saveUserProfile(UserModel user) async {
    _loggedInUser = user;
  }

  Future<UserModel?> getUserProfile(String uid) async {
    return _loggedInUser;
  }

  Future<void> signOut() async {
    _loggedInUser = null;
  }

  UserModel? get currentUser => _loggedInUser;
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// StreamProvider returning UserModel? — keeps .valueOrNull and .when working
final currentUserProvider = StreamProvider<UserModel?>((ref) async* {
  yield _loggedInUser;
});


