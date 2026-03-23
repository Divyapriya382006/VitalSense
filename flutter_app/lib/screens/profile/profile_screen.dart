import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/user_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final isDark = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('Not signed in'));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: VitalSenseTheme.primaryBlue.withOpacity(0.15),
                    border: Border.all(color: VitalSenseTheme.primaryBlue.withOpacity(0.4), width: 2),
                  ),
                  child: Center(
                    child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: VitalSenseTheme.primaryBlue)),
                  ),
                ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                const SizedBox(height: 12),
                Text(user.name, style: Theme.of(context).textTheme.displayMedium).animate(delay: 100.ms).fadeIn(),
                Text(user.email, style: Theme.of(context).textTheme.bodyMedium).animate(delay: 150.ms).fadeIn(),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: VitalSenseTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(user.role.name[0].toUpperCase() + user.role.name.substring(1),
                      style: const TextStyle(color: VitalSenseTheme.primaryBlue, fontWeight: FontWeight.w700, fontSize: 12)),
                ).animate(delay: 200.ms).fadeIn(),
                const SizedBox(height: 24),

                // Stats row
                Row(
                  children: [
                    _StatCard('Age', '${user.age}y', Icons.cake_rounded),
                    const SizedBox(width: 10),
                    _StatCard('BMI', user.bmi.toStringAsFixed(1), Icons.monitor_weight_outlined),
                    const SizedBox(width: 10),
                    _StatCard('Blood', _bloodGroupLabel(user.bloodGroup), Icons.water_drop_rounded),
                  ],
                ).animate(delay: 250.ms).fadeIn(),
                const SizedBox(height: 20),

                // Info cards
                _InfoSection('Body Metrics', [
                  _InfoRow('Height', '${user.heightCm.toInt()} cm'),
                  _InfoRow('Weight', '${user.weightKg.toInt()} kg'),
                  _InfoRow('BMI Category', user.bmiCategory),
                  _InfoRow('Gym Person', user.isGymPerson ? 'Yes' : 'No'),
                  _InfoRow('Athletic', user.isAthletic ? 'Yes' : 'No'),
                ]),
                const SizedBox(height: 12),

                if (user.emergencyContacts.isNotEmpty)
                  _InfoSection('Emergency Contacts', [
                    for (final c in user.emergencyContacts) _InfoRow('Contact', c),
                  ]),
                const SizedBox(height: 12),

                if (user.isFemale)
                  ListTile(
                    leading: const Text('🌸', style: TextStyle(fontSize: 24)),
                    title: const Text('Period Tracker'),
                    subtitle: user.nextPeriodDate != null
                        ? Text('Next: ${user.daysUntilNextPeriod} days away')
                        : const Text('Tap to set up'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: const Color(0xFFFF6B9D).withOpacity(0.08),
                    onTap: () => context.push('/home/period-tracker'),
                  ),

                const SizedBox(height: 20),

                // Role-specific
                if (user.role == UserRole.doctor)
                  ListTile(
                    leading: const Icon(Icons.monitor_heart_rounded, color: VitalSenseTheme.primaryGreen),
                    title: const Text('Doctor War Room'),
                    subtitle: const Text('Monitor all your patients'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: VitalSenseTheme.primaryGreen.withOpacity(0.08),
                    onTap: () => context.push('/home/warroom'),
                  ),

                if (user.role == UserRole.admin)
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings_rounded, color: VitalSenseTheme.accentPurple),
                    title: const Text('Admin Panel'),
                    subtitle: const Text('Manage users and staff'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: VitalSenseTheme.accentPurple.withOpacity(0.08),
                    onTap: () => context.push('/home/admin'),
                  ),

                const SizedBox(height: 20),

                // Theme toggle
                Card(
                  child: SwitchListTile(
                    secondary: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded),
                    title: Text(isDark ? 'Dark Mode' : 'Light Mode'),
                    subtitle: const Text('Toggle app theme'),
                    value: isDark,
                    onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(),
                    activeColor: VitalSenseTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 12),

                // Sign out
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.logout_rounded, color: VitalSenseTheme.alertRed),
                    label: const Text('Sign Out', style: TextStyle(color: VitalSenseTheme.alertRed)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: VitalSenseTheme.alertRed),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      await ref.read(authServiceProvider).signOut();
                      if (context.mounted) context.go('/login');
                    },
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  String _bloodGroupLabel(BloodGroup bg) {
    const labels = {'aPos': 'A+', 'aNeg': 'A−', 'bPos': 'B+', 'bNeg': 'B−',
        'oPos': 'O+', 'oNeg': 'O−', 'abPos': 'AB+', 'abNeg': 'AB−'};
    return labels[bg.name] ?? bg.name;
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _StatCard(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Icon(icon, size: 20, color: VitalSenseTheme.primaryBlue),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> rows;
  const _InfoSection(this.title, this.rows);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14)),
            const Divider(height: 16),
            ...rows,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
