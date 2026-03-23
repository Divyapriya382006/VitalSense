import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_provider.dart';
import '../doctor/patient_vitals_viewer.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';

// Hardcoded demo users for admin panel
final _allDemoUsers = [
  {'name': 'Test Patient', 'email': 'patient@test.com', 'role': 'patient', 'uid': 'demo_patient_001'},
  {'name': 'Priya Patient', 'email': 'female@test.com', 'role': 'patient', 'uid': 'demo_female_001'},
  {'name': 'Dr. Kannan', 'email': 'doctor@test.com', 'role': 'doctor', 'uid': 'demo_doctor_001'},
  {'name': 'Admin User', 'email': 'admin@test.com', 'role': 'admin', 'uid': 'demo_admin_001'},
];

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});
  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _tabIndex = 0;
  final TextEditingController _searchCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchCtrl.addListener(() {
      ref.read(adminSearchQueryProvider.notifier).state = _searchCtrl.text;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _doctors = [
    {'name': 'Dr. Sarah Jenkins', 'specialty': 'Cardiology', 'revenue': 12450, 'status': 'Online', 'hours': 8.5, 'attendance': 'On Time'},
    {'name': 'Dr. James Wilson', 'specialty': 'Neurology', 'revenue': 9800, 'status': 'Offline', 'hours': 0.0, 'attendance': 'Absent'},
    {'name': 'Dr. Elena Rossi', 'specialty': 'Dermatology', 'revenue': 15200, 'status': 'Away', 'hours': 4.2, 'attendance': 'Late'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060d14),
      appBar: AppBar(
        title: const Text('ADMIN CONSOLE', style: TextStyle(color: Color(0xFFffab00), fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2)),
        backgroundColor: const Color(0xFF0a1520),
        elevation: 0,
        actions: [
          IconButton(onPressed: () => context.go('/login'), icon: const Icon(Icons.logout, color: Colors.redAccent)),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: const BoxDecoration(
          color: Color(0xFF0a1520),
          border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavIcon(Icons.dashboard_rounded, 'Overview', 0, _tabIndex, (i) => setState(() { _tabIndex = i; _tabController.animateTo(i); })),
            _NavIcon(Icons.medical_services, 'Doctors', 1, _tabIndex, (i) => setState(() { _tabIndex = i; _tabController.animateTo(i); })),
            _NavIcon(Icons.people_alt, 'Patients', 2, _tabIndex, (i) => setState(() { _tabIndex = i; _tabController.animateTo(i); })),
            _NavIcon(Icons.analytics, 'Insights', 3, _tabIndex, (i) => setState(() { _tabIndex = i; _tabController.animateTo(i); })),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildOverview(),
          _buildDoctors(),
          _buildPatients(),
          _buildAnalytics(),
        ],
      ),
    );
  }

  Widget _buildOverview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SYSTEM SNAPSHOT', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          _StatGrid(),
          const SizedBox(height: 24),
          const Text('GLOBAL REVENUE TREND', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Container(
            height: 160,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF0c1824), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))),
            child: _buildSmallGraph(),
          ),
          const SizedBox(height: 24),
          const Text('CRITICAL LOGS', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          _LogTile('Intrusion Detection bypass alert', '12:45 PM', Colors.orange),
          _LogTile('Backup server routine complete', '11:20 AM', Colors.green),
          _LogTile('Emergency SOS triggered - Patient #03', '09:12 AM', Colors.red),
        ],
      ),
    );
  }

  Widget _buildDoctors() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF0a1520),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('STATS FOR: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: const TextStyle(color: Color(0xFFffab00), fontWeight: FontWeight.bold, fontSize: 12)),
              TextButton.icon(
                onPressed: () async {
                  final d = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2023), lastDate: DateTime.now());
                  if (d != null) setState(() => _selectedDate = d);
                },
                icon: const Icon(Icons.date_range, size: 16, color: Color(0xFFffab00)),
                label: const Text('FILTER DATE', style: TextStyle(color: Color(0xFFffab00), fontSize: 11)),
              )
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _doctors.length,
            itemBuilder: (context, index) {
              final d = _doctors[index];
              final isOnline = d['status'] == 'Online';
              return Card(
                color: const Color(0xFF0c1824),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white.withOpacity(0.05))),
                child: ExpansionTile(
                  iconColor: const Color(0xFFffab00),
                  collapsedIconColor: Colors.white24,
                  title: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: isOnline ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                        child: Icon(Icons.person, color: isOnline ? Colors.green : Colors.grey, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(d['specialty'], style: const TextStyle(color: Colors.white54, fontSize: 11)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: isOnline ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text(d['status'], style: TextStyle(color: isOnline ? Colors.green : Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Divider(height: 1, color: Colors.white10),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _DocMetric('Clock-in', d['attendance'], Icons.access_time),
                              _DocMetric('Hrs Worked', '${d['hours']}h', Icons.timer_outlined),
                              _DocMetric('Session Revenue', '\$${(d['revenue'] as int) / 20}', Icons.payments_outlined),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text('PHYSICIAN NOTES (ADMIN ONLY)', style: TextStyle(color: Colors.white38, fontSize: 9, letterSpacing: 1)),
                          const SizedBox(height: 4),
                          const Text('Performance exceeds quarterly average. Patient satisfaction 94%.', style: TextStyle(color: Colors.white70, fontSize: 11, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPatients() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF0a1520),
            border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
          ),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search patients by name or ID...',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
              prefixIcon: const Icon(Icons.search, color: Color(0xFFffab00), size: 18),
              filled: true,
              fillColor: const Color(0xFF0c1824),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ),
          ),
        ),
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  indicatorColor: Color(0xFFffab00),
                  indicatorWeight: 3,
                  labelColor: Color(0xFFffab00),
                  unselectedLabelColor: Colors.white24,
                  labelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                  tabs: [
                    Tab(text: 'ACTIVE PERSONAS'),
                    Tab(text: 'REVENUE USERS'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildPatientList(filteredAdminPatientsProvider),
                      _buildPatientList(premiumPatientsProvider),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientList(Provider<AsyncValue<List<UserModel>>> provider) {
    final patientsAsync = ref.watch(provider);
    
    return patientsAsync.when(
      data: (patients) => patients.isEmpty 
        ? const Center(child: Text('No matching records found.', style: TextStyle(color: Colors.white24)))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: patients.length,
            itemBuilder: (context, index) => _PatientAdminTile(patients[index]),
          ),
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFffab00))),
      error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
    );
  }

  Widget _PatientAdminTile(UserModel user) {
    return Card(
      color: const Color(0xFF0c1824),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white.withOpacity(0.05))),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF00e5ff).withOpacity(0.1),
          child: const Icon(Icons.person, color: Color(0xFF00e5ff), size: 20),
        ),
        title: Text(user.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text('ID: ${user.uid} • Joined: ${user.createdAt.day}/${user.createdAt.month}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white24, size: 18),
          color: const Color(0xFF0c1824),
          onSelected: (val) {
            if (val == 'vitals') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => PatientVitalsViewer(patientId: user.uid, patientName: user.name)));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action: $val initiated for ${user.name}'), backgroundColor: const Color(0xFFffab00)));
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'vitals', child: Text('View Clinical Record', style: TextStyle(color: Colors.white, fontSize: 12))),
            const PopupMenuItem(value: 'edit', child: Text('Manage Account', style: TextStyle(color: Colors.white, fontSize: 12))),
            const PopupMenuItem(value: 'suspend', child: Text('Suspend Access', style: TextStyle(color: Colors.redAccent, fontSize: 12))),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalytics() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DOCTOR-PATIENT MESH (LIVE TOPOLOGY)', style: TextStyle(color: Color(0xFFffab00), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(color: const Color(0xFF0c1824), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))),
            child: Stack(
              children: [
                Center(child: Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFffab00).withOpacity(0.1), border: Border.all(color: const Color(0xFFffab00).withOpacity(0.3))))),
                ...List.generate(6, (i) {
                  final angle = (i * 60) * (math.pi / 180);
                  return Positioned(
                    left: 160 + 100 * math.cos(angle),
                    top: 100 + 80 * math.sin(angle),
                    child: const CircleAvatar(radius: 14, backgroundColor: Color(0xFF00e5ff), child: Icon(Icons.person, size: 16, color: Colors.black)),
                  ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds, color: Colors.white24);
                }),
                Center(child: const Icon(Icons.hub, color: Color(0xFFffab00), size: 36).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1.seconds)),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text('INTERACTIVE REVENUE GROWTH', style: TextStyle(color: Color(0xFF69ff47), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF0c1824), borderRadius: BorderRadius.circular(16)),
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => const Color(0xFF0a1520),
                    getTooltipItems: (items) => items.map((i) => LineTooltipItem('\$${i.y}k\nMonth ${i.x.toInt() + 1}', const TextStyle(color: Color(0xFF69ff47), fontWeight: FontWeight.bold, fontSize: 10))).toList(),
                  ),
                ),
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 3.2), const FlSpot(1, 4.8), const FlSpot(2, 3.9),
                      const FlSpot(3, 6.1), const FlSpot(4, 5.2), const FlSpot(5, 8.4),
                    ],
                    isCurved: true,
                    color: const Color(0xFF69ff47),
                    barWidth: 4,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: const Color(0xFF69ff47).withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Text('STAFF CHAT LOAD ANNOTATIONS', style: TextStyle(color: Color(0xFF00e5ff), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF0c1824), borderRadius: BorderRadius.circular(16)),
            child: BarChart(
              BarChartData(
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => const Color(0xFF0a1520),
                    getTooltipItem: (g, gi, r, ri) => BarTooltipItem('Load: ${r.toY}\nStatus: High', const TextStyle(color: Color(0xFF00e5ff))),
                  ),
                ),
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 8, color: const Color(0xFF00e5ff))]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 10, color: const Color(0xFF00e5ff))]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 7, color: const Color(0xFF00e5ff))]),
                  BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 15, color: const Color(0xFFffab00))]),
                  BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 9, color: const Color(0xFF00e5ff))]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Text('LOCALIZED MESH ACTIVITY', style: TextStyle(color: Color(0xFF69ff47), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          _MeshLog('SOS Broadcast via node #102', '3 hops', 'ACTIVE'),
          _MeshLog('Mesh Heartbeat - sector 7G', 'P2P', 'STABLE'),
        ],
      ),
    );
  }

  Widget _buildSmallGraph() {
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => const Color(0xFF0a1520),
            getTooltipItems: (items) => items.map((i) => LineTooltipItem('\$${i.y}k', const TextStyle(color: Color(0xFFffab00), fontWeight: FontWeight.bold))).toList(),
          ),
        ),
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [const FlSpot(0, 5), const FlSpot(1, 8), const FlSpot(2, 4), const FlSpot(3, 9)],
            isCurved: true,
            color: const Color(0xFFffab00),
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final Function(int) onTap;

  const _NavIcon(this.icon, this.label, this.index, this.currentIndex, this.onTap);

  @override
  Widget build(BuildContext context) {
    final sel = index == currentIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: sel ? const Color(0xFFffab00) : Colors.white38, size: 22),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: sel ? const Color(0xFFffab00) : Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      childAspectRatio: 2.2, // MORE COMPACT
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _MetricCard('Total Revenue', '\$42.8k', Icons.account_balance_wallet, Colors.green, '+14%'),
        _MetricCard('Active Staff', '12/15', Icons.medical_services, Colors.blue, '92%'),
        _MetricCard('Server Load', '24%', Icons.dns, Colors.orange, 'Opt'),
        _MetricCard('Uptime', '99.9%', Icons.bolt, Colors.purple, 'Top'),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label, value, trend;
  final IconData icon;
  final Color color;
  const _MetricCard(this.label, this.value, this.icon, this.color, this.trend);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0c1824),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 18),
              Text(trend, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final String text, time;
  final Color color;
  const _LogTile(this.text, this.time, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF0c1824), borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        Container(width: 4, height: 24, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12))),
        Text(time, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ]),
    );
  }
}

class _DocMetric extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _DocMetric(this.label, this.value, this.icon);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFffab00), size: 16),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
      ],
    );
  }
}

class _MeshLog extends StatelessWidget {
  final String text, hops, status;
  const _MeshLog(this.text, this.hops, this.status);
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF0c1824), borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        const Icon(Icons.hub, color: Color(0xFF69ff47), size: 16),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12))),
        Text(hops, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        const SizedBox(width: 8),
        Text(status, style: const TextStyle(color: Color(0xFF69ff47), fontSize: 9, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _UserSection extends StatelessWidget {
  final String title;
  final List<Map<String, String>> users;
  final Color color;
  final Function(String) onDelete;

  const _UserSection(this.title, this.users, this.color, this.onDelete);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
          child: Text('${users.length}', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
      ]),
      const SizedBox(height: 8),
      ...users.asMap().entries.map((entry) {
        final u = entry.value;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Text(
                (u['name'] ?? '?').isNotEmpty ? u['name']![0].toUpperCase() : '?',
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
            ),
            title: Text(u['name'] ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            subtitle: Text(u['email'] ?? '', style: const TextStyle(fontSize: 11)),
            trailing: PopupMenuButton<String>(
              onSelected: (action) async {
                if (action == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete User?'),
                      content: Text('Delete ${u['name']}?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(backgroundColor: VitalSenseTheme.alertRed),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) onDelete(u['uid'] ?? '');
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'view',
                    child: Row(children: [Icon(Icons.visibility_outlined, size: 16), SizedBox(width: 8), Text('View')])),
                const PopupMenuItem(value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline, size: 16, color: VitalSenseTheme.alertRed),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: VitalSenseTheme.alertRed)),
                    ])),
              ],
            ),
          ),
        ).animate(delay: (entry.key * 50).ms).fadeIn().slideY(begin: 0.1);
      }),
    ]);
  }
}

class _SummaryChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(children: [
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
          Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 10)),
        ]),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatsCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ]),
        ),
      ),
    );
  }
}
