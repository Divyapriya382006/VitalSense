import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Form data
  final _nameController = TextEditingController();
  DateTime? _dob;
  BloodGroup? _bloodGroup;
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  bool _isGym = false;
  bool _isAthletic = false;
  bool _isFemale = false;
  final _emergencyContact1 = TextEditingController();
  final _emergencyContact2 = TextEditingController();
  UserRole _role = UserRole.patient;
  bool _wantsDoctor = false;
  DateTime? _lastPeriodDate;
  int _periodCycleDays = 28;

  // Auto-calculated
  int get _age {
    if (_dob == null) return 0;
    final now = DateTime.now();
    int age = now.year - _dob!.year;
    if (now.month < _dob!.month || (now.month == _dob!.month && now.day < _dob!.day)) age--;
    return age;
  }

  double get _bmi {
    final h = double.tryParse(_heightController.text);
    final w = double.tryParse(_weightController.text);
    if (h == null || w == null || h == 0) return 0;
    return w / ((h / 100) * (h / 100));
  }

  String get _bmiCategory {
    if (_bmi < 18.5) return 'Underweight';
    if (_bmi < 25) return 'Normal';
    if (_bmi < 30) return 'Overweight';
    return 'Obese';
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _emergencyContact1.dispose();
    _emergencyContact2.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(duration: 400.ms, curve: Curves.easeInOutCubic);
      setState(() => _currentPage++);
    } else {
      _saveProfile();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(duration: 400.ms, curve: Curves.easeInOutCubic);
      setState(() => _currentPage--);
    }
  }

  Future<void> _saveProfile() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    final profile = UserModel(
      uid: user.uid,
      name: _nameController.text.trim(),
      email: user.email,
      dateOfBirth: _dob!,
      bloodGroup: _bloodGroup ?? BloodGroup.oPos,
      heightCm: double.parse(_heightController.text),
      weightKg: double.parse(_weightController.text),
      isGymPerson: _isGym,
      isAthletic: _isAthletic,
      isFemale: _isFemale,
      role: _role,
      emergencyContacts: [
        if (_emergencyContact1.text.isNotEmpty) _emergencyContact1.text,
        if (_emergencyContact2.text.isNotEmpty) _emergencyContact2.text,
      ],
      createdAt: DateTime.now(),
      lastPeriodDate: _isFemale ? _lastPeriodDate : null,
      periodCycleDays: _isFemale ? _periodCycleDays : null,
    );

    await ref.read(authServiceProvider).saveUserProfile(profile);
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Setup Profile', style: Theme.of(context).textTheme.displayMedium),
                      Text('${_currentPage + 1}/4',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_currentPage + 1) / 4,
                      backgroundColor: VitalSenseTheme.primaryBlue.withOpacity(0.15),
                      valueColor: const AlwaysStoppedAnimation(VitalSenseTheme.primaryBlue),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Page1BasicInfo(
                    nameController: _nameController,
                    dob: _dob,
                    age: _age,
                    isFemale: _isFemale,
                    role: _role,
                    onDobChanged: (d) => setState(() => _dob = d),
                    onGenderChanged: (v) => setState(() => _isFemale = v),
                    onRoleChanged: (r) => setState(() => _role = r),
                  ),
                  _Page2BodyMetrics(
                    heightController: _heightController,
                    weightController: _weightController,
                    bloodGroup: _bloodGroup,
                    bmi: _bmi,
                    bmiCategory: _bmiCategory,
                    isGym: _isGym,
                    isAthletic: _isAthletic,
                    onBloodGroupChanged: (bg) => setState(() => _bloodGroup = bg),
                    onGymChanged: (v) => setState(() => _isGym = v),
                    onAthleticChanged: (v) => setState(() => _isAthletic = v),
                    onMetricChanged: () => setState(() {}),
                  ),
                  _Page3Emergency(
                    contact1: _emergencyContact1,
                    contact2: _emergencyContact2,
                    wantsDoctor: _wantsDoctor,
                    onWantsDoctorChanged: (v) => setState(() => _wantsDoctor = v),
                  ),
                  _Page4FemalePeriod(
                    isFemale: _isFemale,
                    lastPeriodDate: _lastPeriodDate,
                    cycleDays: _periodCycleDays,
                    onLastPeriodChanged: (d) => setState(() => _lastPeriodDate = d),
                    onCycleDaysChanged: (v) => setState(() => _periodCycleDays = v),
                  ),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _prevPage,
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      child: Text(_currentPage == 3 ? 'Get Started 🚀' : 'Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Page1BasicInfo extends StatelessWidget {
  final TextEditingController nameController;
  final DateTime? dob;
  final int age;
  final bool isFemale;
  final UserRole role;
  final Function(DateTime) onDobChanged;
  final Function(bool) onGenderChanged;
  final Function(UserRole) onRoleChanged;

  const _Page1BasicInfo({
    required this.nameController, required this.dob, required this.age,
    required this.isFemale, required this.role, required this.onDobChanged,
    required this.onGenderChanged, required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Basic Information', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),

          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 16),

          // Date of Birth
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
                firstDate: DateTime(1920),
                lastDate: DateTime.now(),
              );
              if (picked != null) onDobChanged(picked);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: VitalSenseTheme.darkBorder),
                borderRadius: BorderRadius.circular(12),
                color: VitalSenseTheme.darkCard,
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 20, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Date of Birth', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(
                          dob != null ? DateFormat('MMM dd, yyyy').format(dob!) : 'Select date',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  if (dob != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: VitalSenseTheme.primaryBlue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Age: $age',
                          style: const TextStyle(color: VitalSenseTheme.primaryBlue, fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Gender
          Text('Gender', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              _ChoiceChip(label: '♂ Male', selected: !isFemale, onTap: () => onGenderChanged(false)),
              const SizedBox(width: 10),
              _ChoiceChip(label: '♀ Female', selected: isFemale, onTap: () => onGenderChanged(true)),
            ],
          ),
          const SizedBox(height: 16),

          // Role
          Text('Role', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: UserRole.values.map((r) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _ChoiceChip(
                  label: r.name[0].toUpperCase() + r.name.substring(1),
                  selected: role == r,
                  onTap: () => onRoleChanged(r),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _Page2BodyMetrics extends StatelessWidget {
  final TextEditingController heightController;
  final TextEditingController weightController;
  final BloodGroup? bloodGroup;
  final double bmi;
  final String bmiCategory;
  final bool isGym;
  final bool isAthletic;
  final Function(BloodGroup) onBloodGroupChanged;
  final Function(bool) onGymChanged;
  final Function(bool) onAthleticChanged;
  final VoidCallback onMetricChanged;

  const _Page2BodyMetrics({
    required this.heightController, required this.weightController,
    required this.bloodGroup, required this.bmi, required this.bmiCategory,
    required this.isGym, required this.isAthletic,
    required this.onBloodGroupChanged, required this.onGymChanged,
    required this.onAthleticChanged, required this.onMetricChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Body Metrics', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: heightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Height (cm)', prefixIcon: Icon(Icons.height_rounded)),
                  onChanged: (_) => onMetricChanged(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Weight (kg)', prefixIcon: Icon(Icons.monitor_weight_outlined)),
                  onChanged: (_) => onMetricChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // BMI auto-calculated
          if (bmi > 0)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: VitalSenseTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: VitalSenseTheme.primaryGreen.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calculate_rounded, color: VitalSenseTheme.primaryGreen),
                  const SizedBox(width: 10),
                  Text('BMI: ${bmi.toStringAsFixed(1)} — $bmiCategory',
                      style: const TextStyle(color: VitalSenseTheme.primaryGreen, fontWeight: FontWeight.w600)),
                ],
              ),
            ).animate().fadeIn(),
          const SizedBox(height: 16),

          // Blood group
          Text('Blood Group', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: BloodGroup.values.map((bg) {
              final labels = {'aPos': 'A+', 'aNeg': 'A−', 'bPos': 'B+', 'bNeg': 'B−',
                  'oPos': 'O+', 'oNeg': 'O−', 'abPos': 'AB+', 'abNeg': 'AB−'};
              return _ChoiceChip(
                label: labels[bg.name] ?? bg.name,
                selected: bloodGroup == bg,
                onTap: () => onBloodGroupChanged(bg),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          SwitchListTile(
            title: const Text('Gym Person 🏋️'),
            subtitle: const Text('Regular gym workouts'),
            value: isGym,
            onChanged: onGymChanged,
          ),
          SwitchListTile(
            title: const Text('Athletic 🏃'),
            subtitle: const Text('Sports or intensive training'),
            value: isAthletic,
            onChanged: onAthleticChanged,
          ),
        ],
      ),
    );
  }
}

class _Page3Emergency extends StatelessWidget {
  final TextEditingController contact1;
  final TextEditingController contact2;
  final bool wantsDoctor;
  final Function(bool) onWantsDoctorChanged;

  const _Page3Emergency({
    required this.contact1, required this.contact2,
    required this.wantsDoctor, required this.onWantsDoctorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Emergency & Doctor', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('These contacts will be alerted if your vitals go critical',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),

          TextField(
            controller: contact1,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Emergency Contact 1 (phone)',
              prefixIcon: Icon(Icons.emergency_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: contact2,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Emergency Contact 2 (phone)',
              prefixIcon: Icon(Icons.contact_phone_rounded),
            ),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: VitalSenseTheme.primaryBlue.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: VitalSenseTheme.primaryBlue.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Link a Doctor?', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
                    Switch(value: wantsDoctor, onChanged: onWantsDoctorChanged),
                  ],
                ),
                Text('Your doctor will receive alerts and can monitor your vitals',
                    style: Theme.of(context).textTheme.bodyMedium),
                if (wantsDoctor) ...[
                  const SizedBox(height: 12),
                  Text('You can add your doctor from the Profile screen after setup',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: VitalSenseTheme.primaryBlue)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Page4FemalePeriod extends StatelessWidget {
  final bool isFemale;
  final DateTime? lastPeriodDate;
  final int cycleDays;
  final Function(DateTime) onLastPeriodChanged;
  final Function(int) onCycleDaysChanged;

  const _Page4FemalePeriod({
    required this.isFemale, required this.lastPeriodDate,
    required this.cycleDays, required this.onLastPeriodChanged,
    required this.onCycleDaysChanged,
  });

  @override
  Widget build(BuildContext context) {
    final nextPeriod = lastPeriodDate?.add(Duration(days: cycleDays));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Final Step 🎉', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text("You're almost done!", style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),

          if (isFemale) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF6B9D).withOpacity(0.1),
                    const Color(0xFFC084FC).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFF6B9D).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Text('🌸', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text('Period Tracker', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
                  ]),
                  const SizedBox(height: 16),

                  // Last period date
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().subtract(const Duration(days: 14)),
                        firstDate: DateTime.now().subtract(const Duration(days: 90)),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) onLastPeriodChanged(picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: VitalSenseTheme.darkCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: VitalSenseTheme.darkBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            lastPeriodDate != null
                                ? 'Last period: ${DateFormat('MMM dd').format(lastPeriodDate!)}'
                                : 'Tap to set last period date',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Cycle days slider
                  Text('Cycle length: $cycleDays days',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  Slider(
                    value: cycleDays.toDouble(),
                    min: 21,
                    max: 35,
                    divisions: 14,
                    label: '$cycleDays days',
                    onChanged: (v) => onCycleDaysChanged(v.toInt()),
                    activeColor: const Color(0xFFFF6B9D),
                  ),

                  if (nextPeriod != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B9D).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event_rounded, color: Color(0xFFFF6B9D), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Next period: ${DateFormat('MMM dd, yyyy').format(nextPeriod)}',
                            style: const TextStyle(
                                color: Color(0xFFFF6B9D), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: VitalSenseTheme.primaryBlue.withOpacity(0.07),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_rounded, color: VitalSenseTheme.primaryGreen, size: 48),
                  const SizedBox(height: 12),
                  Text("You're all set!", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text("Tap Get Started to begin monitoring your health with VitalSense",
                      style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? VitalSenseTheme.primaryBlue : VitalSenseTheme.darkCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? VitalSenseTheme.primaryBlue : VitalSenseTheme.darkBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey,
            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
