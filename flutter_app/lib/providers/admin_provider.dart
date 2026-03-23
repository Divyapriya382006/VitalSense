import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

/// Fetches all users from the local database. 
/// If the database is empty, returns a set of seed demo users for Admin visibility.
final allUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  final users = await db.getAllUsers();
  
  if (users.isEmpty) {
    // Seed data for demo purposes
    return [
      UserModel(
        uid: 'demo_p1',
        name: 'Arjun Kumar',
        email: 'arjun@vitalsense.ai',
        dateOfBirth: DateTime(1992, 5, 12),
        bloodGroup: BloodGroup.aPos,
        heightCm: 178,
        weightKg: 75,
        isGymPerson: true,
        isAthletic: true,
        isFemale: false,
        role: UserRole.patient,
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
      UserModel(
        uid: 'demo_p2',
        name: 'Priya Sharma',
        email: 'priya@vitalsense.ai',
        dateOfBirth: DateTime(1995, 8, 22),
        bloodGroup: BloodGroup.oPos,
        heightCm: 165,
        weightKg: 58,
        isGymPerson: false,
        isAthletic: false,
        isFemale: true,
        role: UserRole.patient,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      UserModel(
        uid: 'demo_p3',
        name: 'Rahul Singh',
        email: 'rahul@vitalsense.ai',
        dateOfBirth: DateTime(1988, 12, 05),
        bloodGroup: BloodGroup.bPos,
        heightCm: 182,
        weightKg: 82,
        isGymPerson: true,
        isAthletic: false,
        isFemale: false,
        role: UserRole.patient,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      UserModel(
        uid: 'demo_p4',
        name: 'Ananya Reddy',
        email: 'ananya@vitalsense.ai',
        dateOfBirth: DateTime(1993, 3, 15),
        bloodGroup: BloodGroup.abPos,
        heightCm: 160,
        weightKg: 52,
        isGymPerson: false,
        isAthletic: false,
        isFemale: true,
        role: UserRole.patient,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      UserModel(
        uid: 'demo_p5',
        name: 'Vikram Nair',
        email: 'vikram@vitalsense.ai',
        dateOfBirth: DateTime(1990, 7, 01),
        bloodGroup: BloodGroup.oNeg,
        heightCm: 175,
        weightKg: 70,
        isGymPerson: false,
        isAthletic: true,
        isFemale: false,
        role: UserRole.patient,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }
  return users;
});

final adminSearchQueryProvider = StateProvider<String>((ref) => '');

/// Provides a filtered list of patients based on the admin search query.
final filteredAdminPatientsProvider = Provider<AsyncValue<List<UserModel>>>((ref) {
  final usersAsync = ref.watch(allUsersProvider);
  final query = ref.watch(adminSearchQueryProvider).toLowerCase();
  
  return usersAsync.whenData((users) {
    return users.where((u) => 
      u.role == UserRole.patient && 
      (u.name.toLowerCase().contains(query) || u.email.toLowerCase().contains(query))
    ).toList();
  });
});

/// Provides a list of "Premium" patients (those with an active subscription in this demo).
final premiumPatientsProvider = Provider<AsyncValue<List<UserModel>>>((ref) {
  return ref.watch(filteredAdminPatientsProvider).whenData((patients) {
    // For simulation, even IDs are "Premium"
    return patients.asMap().entries
        .where((e) => e.key % 2 == 0)
        .map((e) => e.value)
        .toList();
  });
});
