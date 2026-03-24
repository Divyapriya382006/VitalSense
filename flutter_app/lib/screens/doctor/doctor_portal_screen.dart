import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/medication_provider.dart';
import '../../providers/vitals_provider.dart';
import '../../providers/hardware_provider.dart';
import '../../widgets/mode_banner_widget.dart';
import '../profile_screen.dart'; // For DoctorChatScreen and styles
import 'patient_vitals_viewer.dart';

class DoctorPortalScreen extends ConsumerStatefulWidget {
  const DoctorPortalScreen({super.key});
  @override
  ConsumerState<DoctorPortalScreen> createState() => _DoctorPortalScreenState();
}

class _DoctorPortalScreenState extends ConsumerState<DoctorPortalScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060d14),
      appBar: AppBar(
        title: const Text('DOCTOR PORTAL', style: TextStyle(color: Color(0xFF00e5ff), fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2)),
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
            _NavIcon(Icons.dashboard_rounded, 'Dashboard', 0, _tabIndex, (i) => setState(() { _tabIndex = i; _tabController.animateTo(i); })),
            _NavIcon(Icons.people_rounded, 'Patients', 1, _tabIndex, (i) => setState(() { _tabIndex = i; _tabController.animateTo(i); })),
            _NavIcon(Icons.insights_rounded, 'Stats', 2, _tabIndex, (i) => setState(() { _tabIndex = i; _tabController.animateTo(i); })),
            _NavIcon(Icons.monetization_on_rounded, 'Revenue', 3, _tabIndex, (i) => setState(() { _tabIndex = i; _tabController.animateTo(i); })),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildDashboard(),
          _buildPatients(),
          _buildPatientStats(),
          _buildRevenue(),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Mode banner — allows doctor to toggle Demo / Real-Time ──
          const ModeBannerWidget(showToggle: true),
          const SizedBox(height: 12),
          const Text('DAILY OVERVIEW', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          _DocStatGrid(),
          const SizedBox(height: 30),
          const Text('UPCOMING CONSULTATIONS', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          _AppointmentTile('Jane Doe', '10:30 AM', 'Follow-up'),
          _AppointmentTile('John Smith', '11:45 AM', 'New Consult'),
          _AppointmentTile('Michael Scott', '02:00 PM', 'Scan Review'),
        ],
      ),
    );
  }

  Widget _buildPatients() {
    final patientsAsync = ref.watch(doctorPatientsProvider);
    
    return patientsAsync.when(
      data: (patients) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: patients.length,
        itemBuilder: (context, index) {
          final p = patients[index];
          return _buildPatientCard(
            context, 
            p.name, 
            p.userId == 'p1' ? 'Yearly Plan (\$490/yr)' : 'Monthly Plan (\$49/mo)', 
            'Expires in ${300 - index * 20} Days', 
            index % 2 == 0,
            p.userId,
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading patients: $err')),
    );
  }

  Widget _buildRevenue() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('EARNINGS ANALYTICS', style: TextStyle(color: Color(0xFF69ff47), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 20),
          _RevenueCard('Monthly Revenue', '\$12,450', '+12% from last month'),
          const SizedBox(height: 16),
          _RevenueCard('Pending Payout', '\$1,200', 'Scheduled for Friday'),
          const SizedBox(height: 30),
          const Text('RECENT TRANSACTIONS', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          _TxTile('Subscription: Jane Doe', '+\$490', 'Yesterday'),
          _TxTile('Consultation: John Smith', '+\$49', '2 hrs ago'),
        ],
      ),
    );
  }

  Widget _buildPatientCard(BuildContext context, String name, String plan, String expiry, bool isInternal, String patientId) {
    return Card(
      color: const Color(0xFF0c1824),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF1a3040))),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(backgroundColor: Color(0xFF1a3040), child: Icon(Icons.person, color: Color(0xFF00e5ff))),
              title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text('$plan\n$expiry', style: const TextStyle(color: Colors.white54, fontSize: 11)),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.medical_services_outlined, color: Color(0xFF69ff47), size: 20),
                onPressed: () => _showPrescriptionForm(context, name),
                tooltip: 'Prescribe Medication',
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.chat_bubble, size: 16),
                  label: const Text('Chat & Calls', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorChatScreen(doctorName: name, isDoctorView: true))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1a3040),
                    foregroundColor: const Color(0xFF00e5ff),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16))),
                  ),
                ),
              ),
              const VerticalDivider(width: 1, color: Colors.white10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.history, size: 16),
                  label: const Text('View Vitals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => 
                    PatientVitalsViewer(patientId: patientId, patientName: name))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D2137),
                    foregroundColor: const Color(0xFF69ff47),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(bottomRight: Radius.circular(16))),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _showPrescriptionForm(BuildContext context, String patientName) {
    final nameController = TextEditingController();
    final purposeController = TextEditingController();
    final instrController = TextEditingController();
    String selectedTime = '08:00 AM';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0a1520),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PRESCRIBE FOR $patientName', style: const TextStyle(color: Color(0xFF00e5ff), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 20),
            _buildField('Tablet Name', nameController, Icons.medication),
            _buildField('Purpose (e.g. Blood Pressure)', purposeController, Icons.info_outline),
            _buildField('Instructions (e.g. After Lunch)', instrController, Icons.description_outlined),
            const SizedBox(height: 10),
            const Text('TIME FOR MEDICATION', style: TextStyle(color: Colors.white54, fontSize: 10)),
            DropdownButton<String>(
              isExpanded: true,
              value: selectedTime,
              dropdownColor: const Color(0xFF0c1824),
              style: const TextStyle(color: Colors.white),
              items: ['08:00 AM', '12:00 PM', '04:00 PM', '08:00 PM', '10:00 PM']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => selectedTime = v!,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final med = Medication(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    purpose: purposeController.text,
                    instructions: instrController.text,
                    time: selectedTime,
                  );
                  ref.read(medicationProvider.notifier).addMedication(med);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Prescribed ${nameController.text} to $patientName'), backgroundColor: const Color(0xFF69ff47)),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF69ff47), foregroundColor: Colors.black),
                child: const Text('CONFIRM PRESCRIPTION'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38),
          prefixIcon: Icon(icon, color: const Color(0xFF00e5ff), size: 20),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00e5ff))),
        ),
      ),
    );
  }

  Widget _buildPatientStats() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('POPULATION HEALTH ANALYTICS', style: TextStyle(color: Color(0xFF00e5ff), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 24),
          
          // Big Health Indicators
          Row(
            children: [
              Expanded(child: _BigIndicator('Chronic', '12', Colors.redAccent, Icons.warning_amber_rounded)),
              const SizedBox(width: 16),
              Expanded(child: _BigIndicator('Recovery', '84%', Colors.greenAccent, Icons.auto_graph_rounded)),
            ],
          ),
          const SizedBox(height: 30),
          
          const Text('PATIENT ADMISSION TRENDS', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          Container(
            height: 220,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF0c1824), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))),
            child: _buildPopulationChart(),
          ),
          
          const SizedBox(height: 30),
          const Text('HEALTH RISK DISTRIBUTION', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(height: 150, width: 150, child: _buildRiskPieChart()),
              const SizedBox(width: 24),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RiskLegend('Normal', Colors.greenAccent),
                    _RiskLegend('Monitoring', Colors.orangeAccent),
                    _RiskLegend('Critical', Colors.redAccent),
                  ],
                ),
              )
            ],
          ),
          
          const SizedBox(height: 40),
          const Text('SERVICE PRODUCTIVITY', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          Container(
            height: 180,
            decoration: BoxDecoration(color: const Color(0xFF0c1824), borderRadius: BorderRadius.circular(20)),
            clipBehavior: Clip.antiAlias,
            child: _buildProductivityBarChart(),
          ),
        ],
      ),
    );
  }

  Widget _BigIndicator(String label, String val, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0c1824),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2), width: 2),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 20, spreadRadius: 2)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 16),
          Text(val, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 32)),
          Text(label, style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildPopulationChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [FlSpot(0, 5), FlSpot(1, 8), FlSpot(2, 4), FlSpot(3, 12), FlSpot(4, 9), FlSpot(5, 15)],
            isCurved: true,
            color: const Color(0xFF00e5ff),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: const Color(0xFF00e5ff).withOpacity(0.1)),
          )
        ],
      ),
    );
  }

  Widget _buildRiskPieChart() {
    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 30,
        sections: [
          PieChartSectionData(value: 60, color: Colors.greenAccent, radius: 20, showTitle: false),
          PieChartSectionData(value: 25, color: Colors.orangeAccent, radius: 25, showTitle: false),
          PieChartSectionData(value: 15, color: Colors.redAccent, radius: 30, showTitle: false),
        ],
      ),
    );
  }

  Widget _buildProductivityBarChart() {
    return BarChart(
      BarChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 8, color: const Color(0xFF69ff47), width: 12)]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 5, color: const Color(0xFF69ff47), width: 12)]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 10, color: const Color(0xFFffab00), width: 12)]),
          BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 7, color: const Color(0xFF69ff47), width: 12)]),
          BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 9, color: const Color(0xFF69ff47), width: 12)]),
        ],
      ),
    );
  }

  Widget _buildTrendTile(String label, String val, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF0c1824), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
            Text(status, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ]),
          Text(val, style: const TextStyle(color: Color(0xFF00e5ff), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _RiskLegend extends StatelessWidget {
  final String label;
  final Color color;
  const _RiskLegend(this.label, this.color);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index, currentIndex;
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
          Icon(icon, color: sel ? const Color(0xFF00e5ff) : Colors.white24, size: 22),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: sel ? const Color(0xFF00e5ff) : Colors.white12, fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _DocStatGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      childAspectRatio: 2.0, // MORE COMPACT
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _MetricBox('Patients', '142', Icons.people, Colors.blue, '+12%'),
        _MetricBox('Revenue', '\$12.4k', Icons.payments, Colors.green, 'Live'),
        _MetricBox('Avg Rating', '4.9', Icons.star, Colors.orange, 'Top'),
        _MetricBox('Chat Hrs', '32h', Icons.forum, Colors.purple, 'Peak'),
      ],
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label, value, trend;
  final IconData icon;
  final Color color;
  const _MetricBox(this.label, this.value, this.icon, this.color, this.trend);
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

class _AppointmentTile extends StatelessWidget {
  final String name, time, type;
  const _AppointmentTile(this.name, this.time, this.type);
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF0c1824), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(width: 4, height: 30, decoration: BoxDecoration(color: const Color(0xFF00e5ff), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              Text(type, style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ]),
          ),
          Text(time, style: const TextStyle(color: Color(0xFF00e5ff), fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final String label, value, trend;
  const _RevenueCard(this.label, this.value, this.trend);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF0a1520), const Color(0xFF0c1824)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.trending_up, color: Color(0xFF69ff47), size: 14),
            const SizedBox(width: 4),
            Text(trend, style: const TextStyle(color: Color(0xFF69ff47), fontSize: 11, fontWeight: FontWeight.bold)),
          ]),
        ],
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  final String title, amount, date;
  const _TxTile(this.title, this.amount, this.date);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            Text(date, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ]),
          Text(amount, style: const TextStyle(color: Color(0xFF69ff47), fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
