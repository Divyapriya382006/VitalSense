import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../face_mesh/face_mesh_screen.dart';
import '../wellness/wellness_screen.dart';
import '../ai_chat/ai_chat_screen.dart';
import '../reports/reports_screen.dart';
import '../profile_screen.dart';
import '../upload_screen.dart';
import '../../theme/app_theme.dart';

// ── Colour tokens ──────────────────────────────────────────────────────────────
const _bg     = Color(0xFF060d14);
const _bg2    = Color(0xFF0c1824);
const _bg3    = Color(0xFF111f2e);
const _border = Color(0xFF1a3040);
const _accent = Color(0xFF00e5ff);
const _accentG= Color(0xFF69ff47);
const _warn   = Color(0xFFffab00);
const _crit   = Color(0xFFff3d00);
const _hrCol  = Color(0xFFff5252);
const _spo2Col= Color(0xFFce93d8);
const _tempCol= Color(0xFFffcc02);
const _ambCol = Color(0xFF40c4ff);
const _muted  = Color(0xFF4a6478);
const _text   = Color(0xFFc8dae8);

// ── ECG green palette ──────────────────────────────────────────────────────────
const _ecgBg        = Color(0xFF010E01);
const _ecgGreen     = Color(0xFF00FF41);
const _ecgGridMinor = Color(0xFF002800);
const _ecgGridMajor = Color(0xFF004400);
const _ecgGridLabel = Color(0xFF004015);
const _ecgDim       = Color(0xFF00AA22);
const _ecgMid       = Color(0xFF00CC33);
const _ecgBorder    = Color(0xFF006618);

// ══════════════════════════════════════════════════════════════════════════════
//  HOME SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _tabIndex = 0;
  late PageController _pageController;
  late AnimationController _ecgController;
  late AnimationController _heartController;
  late AnimationController _lungController;

  // ECG ring buffer
  final List<double> _ecgData = [];
  double _ecgPhase = 0;
  static const int _ecgMax = 300;

  // Vitals
  double _hr = 73, _spo2 = 98, _temp = 36.8, _ambTemp = 26.5, _humidity = 62;
  String _status = 'Normal';

  // History & alerts
  final List<Map<String, dynamic>> _history   = [];
  final List<double> _hrHistory               = [];
  final List<double> _spo2History             = [];
  final List<double> _tempHistory             = [];
  final List<String> _timeLabels              = [];
  final List<Map<String, dynamic>> _alerts    = [];
  int _warnCount = 0, _critCount = 0, _infoCount = 1;

  final List<String> _tabs = ['Home', 'Mesh', 'Wellness', 'Reports', 'Upload', 'Telemed', 'Profile'];
  final List<IconData> _tabIcons = [
    Icons.home_filled, Icons.face_retouching_natural_rounded,
    Icons.spa_rounded, Icons.analytics_rounded, Icons.upload_file_rounded, Icons.chat_outlined, Icons.person_pin
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Pre-fill ECG buffer with silence
    for (int i = 0; i < _ecgMax; i++) _ecgData.add(0.0);

    // ~30 fps ECG tick
    _ecgController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 33))
      ..addListener(_ecgTick)
      ..repeat();

    _heartController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);

    _lungController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 4000))
      ..repeat(reverse: true);

    _startAutoSim();
  }

  // ── ECG tick (called ~30× per second) ──────────────────────────────────────
  void _ecgTick() {
    if (!mounted) return;
    setState(() {
      // Phase increment: (33ms / 1000ms) * (HR / 60)
      // This ensures 1 phase cycle per heartbeat
      _ecgPhase += (0.033 * _hr / 60);
      _ecgData.add(_ecgValue(_ecgPhase));
      if (_ecgData.length > _ecgMax) _ecgData.removeAt(0);
    });
  }

  // Synthetic Lead-II waveform (P · QRS · T)
  double _ecgValue(double t) {
    // Current ECG phase (0.0 to 1.0)
    final p = t % 1.0;
    
    // Scale wave parts to look realistic across different heart rates
    // Lower HR means longer TP interval (baseline), but P-QRS-T width remains relatively stable
    if (p >= 0.0 && p < 0.12) return 0.15 * sin(pi * p / 0.12); // P wave
    if (p >= 0.12 && p < 0.15) return 0.0; // PR segment
    if (p >= 0.15 && p < 0.18) return -0.1 * sin(pi * (p - 0.15) / 0.03); // Q wave
    if (p >= 0.18 && p < 0.22) return 1.0 * sin(pi * (p - 0.18) / 0.04);  // R spike
    if (p >= 0.22 && p < 0.26) return -0.15 * sin(pi * (p - 0.22) / 0.04); // S wave
    if (p >= 0.26 && p < 0.32) return 0.0; // ST segment
    if (p >= 0.32 && p < 0.52) return 0.25 * sin(pi * (p - 0.32) / 0.20); // T wave
    
    // Baseline noise
    return (Random().nextDouble() - 0.5) * 0.01;
  }

  // ── Vital-signs simulation (every 2 s) ─────────────────────────────────────
  void _startAutoSim() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _hr   = (_hr   + (Random().nextDouble() - 0.48) * 3).clamp(40, 160);
        _spo2 = (_spo2 + (Random().nextDouble() - 0.45) * 0.5).clamp(85, 100);
        _temp = (_temp + (Random().nextDouble() - 0.5)  * 0.05).clamp(35, 40);
        _hr   = _hr.roundToDouble();
        _spo2 = _spo2.roundToDouble();

        _status = (_spo2 < 88 || _hr > 140 || _hr < 40)
            ? 'Critical'
            : (_spo2 < 92 || _hr > 110)
                ? 'Warning'
                : 'Normal';

        final ts =
            '${DateTime.now().hour.toString().padLeft(2, '0')}:'
            '${DateTime.now().minute.toString().padLeft(2, '0')}';

        if (_hrHistory.length >= 30) {
          _hrHistory.removeAt(0);
          _spo2History.removeAt(0);
          _tempHistory.removeAt(0);
          _timeLabels.removeAt(0);
        }
        _hrHistory.add(_hr);
        _spo2History.add(_spo2);
        _tempHistory.add(_temp);
        _timeLabels.add(ts);

        _history.insert(0, {
          'hr': _hr, 'spo2': _spo2, 'temp': _temp,
          'ts': ts,  'status': _status
        });
        if (_history.length > 50) _history.removeLast();

        if (_spo2 < 88) _addAlert('crit', '🚨 Critical SpO₂ — ${_spo2.toInt()}%', ts);
        else if (_spo2 < 92) _addAlert('warn', '⚠ Low SpO₂ — ${_spo2.toInt()}%', ts);
        if (_hr > 140) _addAlert('crit', '🚨 Severe Tachycardia — ${_hr.toInt()} BPM', ts);
        else if (_hr > 110) _addAlert('warn', '⚠ Elevated HR — ${_hr.toInt()} BPM', ts);
      });
      _startAutoSim();
    });
  }

  void _addAlert(String type, String msg, String ts) {
    _alerts.insert(0, {'type': type, 'msg': msg, 'ts': ts});
    if (_alerts.length > 30) _alerts.removeLast();
    if (type == 'warn') _warnCount++;
    else if (type == 'crit') _critCount++;
    
    // Auto-save to DB if needed (simulation)
  }

  void _triggerSOS() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _bg2,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: _crit, size: 30),
                SizedBox(width: 10),
                Text('EMERGENCY SOS', style: TextStyle(color: _crit, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Alerting Emergency Contacts...', style: TextStyle(color: _text)),
            const SizedBox(height: 10),
            LinearProgressIndicator(color: _crit, backgroundColor: _bg3),
            const SizedBox(height: 20),
            const Text('NEARBY HOSPITALS (RADIUS: 5KM)', style: TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.local_hospital, color: _tempCol),
              title: const Text('City General Hospital', style: TextStyle(color: _text)),
              subtitle: const Text('1.2 km away • ETA: 4 mins', style: TextStyle(color: _accent)),
              trailing: IconButton(icon: const Icon(Icons.directions, color: _accent), onPressed: (){}),
            ),
            ListTile(
              leading: const Icon(Icons.local_hospital, color: _tempCol),
              title: const Text('St. Jude Medical', style: TextStyle(color: _text)),
              subtitle: const Text('3.4 km away • ETA: 9 mins', style: TextStyle(color: _accent)),
              trailing: IconButton(icon: const Icon(Icons.directions, color: _accent), onPressed: (){}),
            ),
          ],
        ),
      ),
    );
    setState(() {
      final ts = '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}';
      _addAlert('crit', '🚨 SOS TRIGGERED — Broadcasted to Contacts & Hospitals', ts);
    });
  }

  void _switchTab(int i) {
    setState(() => _tabIndex = i);
    _pageController.animateToPage(i,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ecgController.dispose();
    _heartController.dispose();
    _lungController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      // ── SOS FAB (inline, no external widget) ────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: _triggerSOS,
        backgroundColor: _crit,
        shape: const CircleBorder(),
        child: const Text('SOS',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w900,
                fontSize: 13)),
      ),
      body: SafeArea(
        child: Column(children: [
          _Header(status: _status, hr: _hr),
          _TabBar(tabs: _tabs, icons: _tabIcons, currentIndex: _tabIndex, onTap: _switchTab),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _tabIndex = i),
              children: [
                // ① Home (Dashboard)
                _DashboardPage(
                  hr: _hr, spo2: _spo2, temp: _temp,
                  ambTemp: _ambTemp, humidity: _humidity,
                  status: _status, ecgData: _ecgData,
                  hrHistory: _hrHistory, spo2History: _spo2History,
                  tempHistory: _tempHistory, timeLabels: _timeLabels,
                  heartCtrl: _heartController, lungCtrl: _lungController,
                ),
                // ② Face Mesh
                const FaceMeshScreen(showAppBar: false),
                // ③ Wellness
                const WellnessScreen(showAppBar: false),
                // ④ Reports
                const ReportsScreen(showAppBar: false),
                // ⑤ Upload Reports
                const UploadReportScreen(),
                // ⑥ Telemed Chat
                const DoctorChatScreen(doctorName: 'Dr. Sarah Jenkins', isTab: true),
                // ⑦ Profile
                const ProfileScreen(),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  HEADER
// ══════════════════════════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  final String status;
  final double hr;
  const _Header({required this.status, required this.hr});

  @override
  Widget build(BuildContext context) {
    final sc = VitalSenseTheme.getStatusColor(status);
    return Container(
      height: 60,
      decoration: BoxDecoration(
          color: _bg.withOpacity(0.8),
          border: const Border(bottom: BorderSide(color: _border, width: 0.5))),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_accent, Color(0xFF0091ff)]),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: _accent.withOpacity(0.3), blurRadius: 8)]),
          child: const Center(child: Icon(Icons.hub_rounded, color: Colors.white, size: 18))),
        const SizedBox(width: 12),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: const TextSpan(
                text: 'VitalSense',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                children: [TextSpan(text: ' AI', style: TextStyle(color: _accent, fontWeight: FontWeight.w400))],
              ),
            ),
            const Row(
              children: [
                Icon(Icons.wifi, color: _accentG, size: 10),
                SizedBox(width: 4),
                Text('WS CONNECTED', style: TextStyle(color: _accentG, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ],
            ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.5, end: 1.0, duration: 1.seconds),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: () {}, // Theme toggle simulated
          icon: const Icon(Icons.dark_mode_rounded, color: _text, size: 18),
        ),
        IconButton(
          onPressed: () => context.go('/login'),
          icon: const Icon(Icons.logout, color: _hrCol, size: 18),
        ),
        _BlinkDot(color: sc),
        const SizedBox(width: 6),
        Text(status.toUpperCase(),
            style: TextStyle(color: sc, fontSize: 10,
                fontFamily: 'monospace', fontWeight: FontWeight.w800, letterSpacing: 1)),
      ]),
    );
  }
}

class _BlinkDot extends StatefulWidget {
  final Color color;
  const _BlinkDot({required this.color});
  @override
  State<_BlinkDot> createState() => _BlinkDotState();
}

class _BlinkDotState extends State<_BlinkDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _c,
    child: Container(
        width: 6, height: 6,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  TAB BAR
// ══════════════════════════════════════════════════════════════════════════════
class _TabBar extends StatelessWidget {
  final List<String> tabs;
  final List<IconData> icons;
  final int currentIndex;
  final Function(int) onTap;
  const _TabBar({required this.tabs, required this.icons, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            color: _bg2.withOpacity(0.6),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _border.withOpacity(0.3)),
          ),
          child: Row(
            children: tabs.asMap().entries.map((e) {
              final sel = currentIndex == e.key;
              return GestureDetector(
                onTap: () => onTap(e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: sel ? _accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: sel ? [BoxShadow(color: _accent.withOpacity(0.3), blurRadius: 12, spreadRadius: -2)] : null,
                  ),
                  child: Row(
                    children: [
                      Icon(icons[e.key], size: 18, color: sel ? _bg : _muted),
                      if (sel) ...[
                        const SizedBox(width: 8),
                        Text(e.value,
                            style: TextStyle(
                                color: _bg,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5)),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  DASHBOARD PAGE
// ══════════════════════════════════════════════════════════════════════════════
class _DashboardPage extends StatelessWidget {
  final double hr, spo2, temp, ambTemp, humidity;
  final String status;
  final List<double> ecgData, hrHistory, spo2History, tempHistory;
  final List<String> timeLabels;
  final AnimationController heartCtrl, lungCtrl;

  const _DashboardPage({
    required this.hr, required this.spo2, required this.temp,
    required this.ambTemp, required this.humidity, required this.status,
    required this.ecgData, required this.hrHistory,
    required this.spo2History, required this.tempHistory,
    required this.timeLabels,
    required this.heartCtrl, required this.lungCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final sc = status == 'Critical' ? _crit : status == 'Warning' ? _warn : _accentG;
    final pp = (30 + (hr - 60) * 0.5 + (spo2 - 95) * 2).clamp(10, 80).round();
    final stress = ((hr - 72).abs() * 1.5 +
        (95 - spo2).clamp(0, 20) * 3 +
        (temp - 36.6).abs() * 8).clamp(0, 100).round();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── PHI Score / Health Gauge ───────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [VitalSenseTheme.getPHIColor(pp.toDouble()).withOpacity(0.2), _bg2],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: VitalSenseTheme.getPHIColor(pp.toDouble()).withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: VitalSenseTheme.getPHIColor(pp.toDouble()).withOpacity(0.1),
                blurRadius: 20, spreadRadius: 2,
              )
            ],
          ),
          child: Column(children: [
            const Text('PERSONAL HEALTH INDEX', style: TextStyle(color: _muted, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Stack(alignment: Alignment.center, children: [
              SizedBox(
                width: 70, height: 70,
                child: CircularProgressIndicator(value: pp/100, strokeWidth: 6, backgroundColor: _bg3, color: VitalSenseTheme.getPHIColor(pp.toDouble())),
              ),
              Text('$pp', style: TextStyle(color: VitalSenseTheme.getPHIColor(pp.toDouble()), fontSize: 24, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 12),
            Text(status.toUpperCase(), style: TextStyle(color: VitalSenseTheme.getPHIColor(pp.toDouble()), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 20),
            // Scanning line simulation
            LayoutBuilder(
              builder: (context, constraints) => Container(
                height: 2,
                width: double.infinity,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: VitalSenseTheme.getPHIColor(pp.toDouble()).withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                  gradient: LinearGradient(
                    colors: [Colors.transparent, VitalSenseTheme.getPHIColor(pp.toDouble()), Colors.transparent],
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat())
               .shimmer(duration: 2000.ms, color: VitalSenseTheme.getPHIColor(pp.toDouble()).withOpacity(0.3))
               .moveX(begin: -constraints.maxWidth, end: constraints.maxWidth, duration: 2000.ms),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // ── Vitals 3×2 grid ────────────────────────────────────────────────
        GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 3, mainAxisSpacing: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.2,
          children: [
            _VCard('Heart Rate', '${hr.toInt()}', 'BPM',  _hrCol, Icons.favorite_rounded),
            _VCard('SpO₂',       '${spo2.toInt()}', '%',   _spo2Col, Icons.air_rounded),
            _VCard('Temp',       temp.toStringAsFixed(1), '°C', _tempCol, Icons.thermostat_rounded),
            _VCard('Ambient',    ambTemp.toStringAsFixed(1), '°C', _ambCol, Icons.cloud_outlined),
            _VCard('Humidity',   '${humidity.toInt()}', '%', const Color(0xFF4dd0e1), Icons.water_drop_outlined),
            _VCard('Stress',     '$stress', '/100', const Color(0xFFef9a9a), Icons.psychology_rounded),
          ],
        ),
        const SizedBox(height: 16),

        // ── HR / SpO₂ mini trend ───────────────────────────────────────────
        _CCard('HR · SpO₂ Trend', SizedBox(
          height: 150,
          child: hrHistory.length > 1
              ? LineChart(LineChartData(
                  gridData: FlGridData(
                    show: true, drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        const FlLine(color: _border, strokeWidth: 0.5),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                      showTitles: true, reservedSize: 28,
                      getTitlesWidget: (v, _) => Text('${v.toInt()}',
                          style: const TextStyle(color: _muted, fontSize: 8)),
                    )),
                    rightTitles: AxisTitles(
                        sideTitles: SideTitles(
                      showTitles: true, reservedSize: 28,
                      getTitlesWidget: (v, _) => Text('${v.toInt()}',
                          style: const TextStyle(color: _spo2Col, fontSize: 8)),
                    )),
                    bottomTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: hrHistory.asMap().entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true, color: _hrCol, barWidth: 2,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                          show: true,
                          color: _hrCol.withOpacity(0.08)),
                    ),
                    LineChartBarData(
                      spots: spo2History.asMap().entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true, color: _spo2Col, barWidth: 2,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                          show: true,
                          color: _spo2Col.withOpacity(0.08)),
                    ),
                  ],
                ))
              : const Center(
                  child: Text('Collecting data…',
                      style: TextStyle(color: _muted, fontSize: 11))),
        )),
        const SizedBox(height: 14),

        // ══════════════════════════════════════════════════════════════════
        //  HOSPITAL ECG  ← exact replica of the screenshot
        // ══════════════════════════════════════════════════════════════════
        _ECGBox(data: ecgData, hr: hr),
        const SizedBox(height: 14),

        // ── Heart + Lungs live visualization ──────────────────────────────
        _CCard('Live Organ Visualization', Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(children: [
              AnimatedBuilder(
                animation: heartCtrl,
                builder: (_, __) => Transform.scale(
                  scale: 1.0 + heartCtrl.value * 0.15,
                  child: SizedBox(
                    width: 90, height: 90,
                    child: CustomPaint(
                        painter: _HeartP(
                            color: _hrCol,
                            pulse: heartCtrl.value,
                            hr: hr)),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text('${hr.toInt()} BPM',
                  style: const TextStyle(
                      color: _hrCol, fontFamily: 'monospace',
                      fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
            Container(width: 1, height: 100, color: _border),
            Column(children: [
              AnimatedBuilder(
                animation: lungCtrl,
                builder: (_, __) => SizedBox(
                  width: 90, height: 90,
                  child: CustomPaint(
                      painter: _LungP(
                          color: _spo2Col,
                          breath: lungCtrl.value,
                          spo2: spo2)),
                ),
              ),
              const SizedBox(height: 4),
              Text('${spo2.toInt()}% SpO₂',
                  style: const TextStyle(
                      color: _spo2Col, fontFamily: 'monospace',
                      fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ],
        )),
        const SizedBox(height: 14),

        // ── ML Risk bars ──────────────────────────────────────────────────
        _CCard('ML Risk Prediction',
            _MLRisk(hr: hr, spo2: spo2, temp: temp)),
        const SizedBox(height: 14),

        // ── New Features: VR & Medical Analysis ───────────────────────────
        Row(children: [
          Expanded(
            child: _CCard('VR Sync', Column(
              children: [
                const Icon(Icons.view_in_ar_rounded, color: _accent, size: 30),
                const SizedBox(height: 8),
                const Text('HEALTH ROOM', style: TextStyle(color: _text, fontSize: 10, fontWeight: FontWeight.bold)),
                Text('CONNECTED', style: TextStyle(color: _accentG, fontSize: 9, fontFamily: 'monospace')),
              ],
            )),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _CCard('Medical AI', Column(
              children: [
                const Icon(Icons.description_rounded, color: _spo2Col, size: 30),
                const SizedBox(height: 8),
                const Text('REPORT ANALYZED', style: TextStyle(color: _text, fontSize: 10, fontWeight: FontWeight.bold)),
                Text('STABLE', style: TextStyle(color: _accentG, fontSize: 9, fontFamily: 'monospace')),
              ],
            )),
          ),
        ]),
        const SizedBox(height: 14),

        _CCard('Daily Wellness Summary', Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Water Intake', style: TextStyle(color: _muted, fontSize: 11)),
              Text('1.2L / 2.5L', style: TextStyle(color: _ambCol, fontWeight: FontWeight.bold, fontSize: 12)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(value: 0.48, backgroundColor: _bg3, valueColor: AlwaysStoppedAnimation(_ambCol), minHeight: 6),
            ),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Rituals Completed', style: TextStyle(color: _muted, fontSize: 11)),
              Text('3 / 8', style: TextStyle(color: _accentG, fontWeight: FontWeight.bold, fontSize: 12)),
            ]),
          ],
        )),

        const SizedBox(height: 80),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  ███████╗ ██████╗ ██████╗     HOSPITAL ECG WIDGET
//  ██╔════╝██╔════╝██╔════╝     Exact pixel-match of the screenshot
//  █████╗  ██║     ██║
//  ██╔══╝  ██║     ██║
//  ███████╗╚██████╗╚██████╗
// ══════════════════════════════════════════════════════════════════════════════

/// The outer card — dark green background, dashed border, header + canvas + footer.
class _ECGBox extends StatelessWidget {
  final List<double> data;
  final double hr;
  const _ECGBox({required this.data, required this.hr});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _ecgBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _ecgGreen.withOpacity(0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header row ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Row(children: [
            // Left: lead info
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('LEAD II',
                  style: TextStyle(
                      color: _ecgMid, fontFamily: 'monospace',
                      fontSize: 10, letterSpacing: 1.5,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              const Text('25mm/s · 10mm/mV',
                  style: TextStyle(
                      color: _ecgGridLabel, fontFamily: 'monospace',
                      fontSize: 9)),
            ]),
            const Spacer(),
            // LIVE indicator
            _LiveBadge(),
            const SizedBox(width: 16),
            // HR readout
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('HR',
                  style: TextStyle(
                      color: _ecgDim, fontFamily: 'monospace',
                      fontSize: 8, letterSpacing: 2)),
              Text('${hr.toInt()}',
                  style: const TextStyle(
                      color: _ecgGreen, fontFamily: 'monospace',
                      fontSize: 26, fontWeight: FontWeight.w900, height: 1)),
              const Text('BPM',
                  style: TextStyle(
                      color: _ecgDim, fontFamily: 'monospace',
                      fontSize: 8, letterSpacing: 2)),
            ]),
          ]),
        ),

        // ── ECG canvas ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: CustomPaint(painter: _ECGP(data: data, hr: hr)),
            ),
          ),
        ),

        // ── Footer stats ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _ES('PR',     '160ms'),
              _ES('QRS',    '82ms'),
              _ES('QT',     '380ms'),
              _ES('QTc',    '398ms'),
              _ES('Axis',   '+60°'),
              _ES('Rhythm', 'SR'),
            ],
          ),
        ),
      ]),
    );
  }
}

/// Blinking green LIVE dot + label
class _LiveBadge extends StatefulWidget {
  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Row(children: [
    FadeTransition(
      opacity: _c,
      child: Container(
          width: 6, height: 6,
          decoration: const BoxDecoration(
              color: _ecgGreen, shape: BoxShape.circle)),
    ),
    const SizedBox(width: 4),
    const Text('LIVE',
        style: TextStyle(
            color: _ecgMid, fontFamily: 'monospace',
            fontSize: 9, letterSpacing: 2)),
  ]);
}

// ── ECG CustomPainter ──────────────────────────────────────────────────────
class _ECGP extends CustomPainter {
  final List<double> data;
  final double hr;
  const _ECGP({required this.data, required this.hr});

  // Layout constants (mirrors the Figma/screenshot spec)
  static const double _mmPx        = 2.0;   // px per mm at 25 mm/s
  static const double _small       = 10.0;  // 1 mm grid square → 10 px
  static const double _large       = 50.0;  // 5 mm grid square → 50 px
  static const double _leftMargin  = 28.0;  // space for mV axis labels

  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width, H = size.height;

    // ── 1. Background ──────────────────────────────────────────────────
    canvas.drawRect(Rect.fromLTWH(0, 0, W, H),
        Paint()..color = _ecgBg);

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, W, H));

    // ── 2. Grid ────────────────────────────────────────────────────────
    final pMinor = Paint()
      ..color = _ecgGridMinor
      ..strokeWidth = 0.5;
    final pMajor = Paint()
      ..color = _ecgGridMajor
      ..strokeWidth = 1.0;

    for (double x = _leftMargin; x <= W; x += _small) {
      final major = ((x - _leftMargin) % _large).abs() < 0.5;
      canvas.drawLine(Offset(x, 0), Offset(x, H), major ? pMajor : pMinor);
    }
    for (double y = 0; y <= H; y += _small) {
      final major = (y % _large).abs() < 0.5;
      canvas.drawLine(
          Offset(_leftMargin, y), Offset(W, y), major ? pMajor : pMinor);
    }

    // ── 3. Calibration pulse (1 mV square, top-left) ──────────────────
    final calMid = H / 2;
    final calPaint = Paint()
      ..color = const Color(0xFF009922)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    canvas.drawPath(
      Path()
        ..moveTo(4, calMid)
        ..lineTo(4, calMid - 50)
        ..lineTo(14, calMid - 50)
        ..lineTo(14, calMid),
      calPaint,
    );

    // ── 4. mV axis labels ──────────────────────────────────────────────
    void drawMvLabel(String text, double y) {
      final tp = TextPainter(
        text: TextSpan(
            text: text,
            style: const TextStyle(
                color: _ecgGridLabel,
                fontFamily: 'monospace',
                fontSize: 8)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }
    final mid = H / 2;
    drawMvLabel('+1', mid - 50);
    drawMvLabel(' 0', mid - 6);
    drawMvLabel('-1', mid + 44);

    // ── 5. Time axis labels ────────────────────────────────────────────
    final drawW = W - _leftMargin;
    const tStyle = TextStyle(
        color: _ecgGridLabel, fontFamily: 'monospace', fontSize: 7);
    for (double x = _leftMargin + _large; x < W; x += _large) {
      final secs = (x - _leftMargin) / (_mmPx * 25);
      final tp = TextPainter(
        text: TextSpan(text: '${secs.toStringAsFixed(1)}s', style: tStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, H - tp.height - 1));
    }

    // ── 6. Waveform ────────────────────────────────────────────────────
    if (data.length < 2) {
      canvas.restore();
      return;
    }

    final amp = H * 0.38;
    // Calculate pulse intensity for "alive" glow (based on latest R-peak intensity)
    final latestVal = data.last;
    final pulseIntensity = (latestVal > 0.5 ? latestVal : 0.0).clamp(0.0, 1.0);

    // Build path
    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = _leftMargin + (i / (data.length - 1)) * drawW;
      final y = (mid - data[i] * amp).clamp(3.0, H - 10.0);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }

    // Interactive pulse background glow
    if (pulseIntensity > 0.1) {
       canvas.drawRect(
        Rect.fromLTWH(_leftMargin, 0, drawW, H),
        Paint()..shader = RadialGradient(
          colors: [_ecgGreen.withOpacity(0.08 * pulseIntensity), Colors.transparent],
        ).createShader(Rect.fromCenter(center: Offset(W - 10, mid - latestVal * amp), width: 100, height: 100))
      );
    }

    // Glow pass (intensifies with pulse)
    canvas.drawPath(path, Paint()
      ..color = _ecgGreen.withOpacity(0.18 + 0.2 * pulseIntensity)
      ..strokeWidth = 6 + 4 * pulseIntensity
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 + 2 * pulseIntensity));

    // Crisp green trace
    canvas.drawPath(path, Paint()
      ..color = _ecgGreen
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);

    // ── 7. Scan-head dot at the leading edge ───────────────────────────
    final ly = (mid - data.last * amp).clamp(3.0, H - 10.0);
    canvas.drawCircle(Offset(W - 2, ly), 3.5 + 2 * pulseIntensity,
        Paint()..color = _ecgGreen);
    canvas.drawCircle(Offset(W - 2, ly), 8 + 8 * pulseIntensity,
        Paint()
          ..color = _ecgGreen.withOpacity(0.3 + 0.4 * pulseIntensity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

    // ── 8. P · Q · R · S · T wave annotations ─────────────────────────
    _drawAnnotations(canvas, size, mid, amp, drawW);

    canvas.restore();
  }

  void _drawAnnotations(
      Canvas canvas, Size size, double mid, double amp, double drawW) {
    if (data.length < 20) return;

    // Find R peak (highest positive deflection in the middle 65% of buffer)
    int rIdx = data.length ~/ 2;
    double rMax = -999;
    final ss = (data.length * 0.30).toInt();
    final se = (data.length * 0.95).toInt();
    for (int i = ss; i < se; i++) {
      if (data[i] > rMax) {
        rMax = data[i];
        rIdx = i;
      }
    }
    if (rMax < 0.4) return; // no clear beat in buffer yet

    // Wave offsets as fraction of buffer length
    const waves = {
      'P': -0.72,
      'Q': -0.12,
      'R':  0.00,
      'S':  0.10,
      'T':  0.30,
    };

    const labelStyle = TextStyle(
        color: _ecgDim,
        fontFamily: 'monospace',
        fontSize: 9,
        fontWeight: FontWeight.w700);

    for (final entry in waves.entries) {
      final offset = (entry.value * data.length * 0.28).toInt();
      final idx = (rIdx + offset).clamp(0, data.length - 1);
      final x = _leftMargin + (idx / (data.length - 1)) * drawW;
      final y = (mid - data[idx] * amp).clamp(3.0, size.height - 10.0);

      // Position label above peaks, below troughs
      final rawLY = data[idx] > 0.15
          ? y - 13.0
          : data[idx] < -0.05
              ? y + 14.0
              : mid - amp * 0.55;
      final labelY = rawLY.clamp(2.0, size.height - 12.0);

      final tp = TextPainter(
        text: TextSpan(text: entry.key, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, labelY));

      // Small tick connecting label to waveform
      canvas.drawLine(
        Offset(x, y + (data[idx] > 0.1 ? -6.0 : 5.0)),
        Offset(x, y),
        Paint()
          ..color = _ecgBorder
          ..strokeWidth = 0.8,
      );
    }
  }

  @override
  bool shouldRepaint(_ECGP old) => old.data != data || old.hr != hr;
}

/// Single footer stat column
class _ES extends StatelessWidget {
  final String l, v;
  const _ES(this.l, this.v);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l,
              style: const TextStyle(
                  color: _ecgBorder,
                  fontFamily: 'monospace',
                  fontSize: 8,
                  letterSpacing: 1)),
          Text(v,
              style: const TextStyle(
                  color: _ecgMid,
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.w700)),
        ],
      );
}

// ══════════════════════════════════════════════════════════════════════════════
//  ORGAN PAINTERS
// ══════════════════════════════════════════════════════════════════════════════
class _HeartP extends CustomPainter {
  final Color color;
  final double pulse, hr;
  const _HeartP({required this.color, required this.pulse, required this.hr});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = size.width * 0.38, s = r / 45;
    canvas.drawCircle(
        Offset(cx, cy), r * 1.3,
        Paint()
          ..color = color.withOpacity(0.1 + pulse * 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
    final path = Path()
      ..moveTo(cx, cy + 25 * s)
      ..cubicTo(cx - 45 * s, cy, cx - 45 * s, cy - 30 * s, cx, cy - 15 * s)
      ..cubicTo(cx + 45 * s, cy - 30 * s, cx + 45 * s, cy, cx, cy + 25 * s)
      ..close();
    canvas.drawPath(path,
        Paint()
          ..color = color.withOpacity(0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.drawPath(path, Paint()..color = color);
    final tp = TextPainter(
      text: TextSpan(
          text: '${hr.toInt()}',
          style: TextStyle(
              color: Colors.white,
              fontSize: 15 * s,
              fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2 + 2 * s));
  }

  @override
  bool shouldRepaint(_HeartP o) => o.pulse != pulse || o.hr != hr;
}

class _LungP extends CustomPainter {
  final Color color;
  final double breath, spo2;
  const _LungP({required this.color, required this.breath, required this.spo2});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    canvas.drawCircle(
        Offset(cx, cy), size.width * 0.38,
        Paint()
          ..color = color.withOpacity(0.07 + breath * 0.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    final lp = Paint()
      ..color = color.withOpacity(0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, cy - 35), Offset(cx, cy - 16), lp);
    canvas.drawLine(Offset(cx, cy - 16), Offset(cx - 14, cy - 8), lp);
    canvas.drawLine(Offset(cx, cy - 16), Offset(cx + 14, cy - 8), lp);
    final exp = breath * 5;
    for (final isLeft in [true, false]) {
      final ox = isLeft ? cx - 18.0 : cx + 18.0;
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(ox, cy + 4),
              width: 20 + exp,
              height: 32 + exp),
          Paint()..color = color.withOpacity(0.6 + breath * 0.2));
    }
    final tp = TextPainter(
      text: TextSpan(
          text: '${spo2.toInt()}%',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy + 26));
  }

  @override
  bool shouldRepaint(_LungP o) => o.breath != breath || o.spo2 != spo2;
}

// ══════════════════════════════════════════════════════════════════════════════
//  TRENDS PAGE
// ══════════════════════════════════════════════════════════════════════════════
class _TrendsPage extends StatelessWidget {
  final List<double> hrHistory, spo2History, tempHistory;
  final List<String> timeLabels;
  final List<Map<String, dynamic>> history;
  const _TrendsPage({
    required this.hrHistory, required this.spo2History,
    required this.tempHistory, required this.timeLabels,
    required this.history,
  });

  Widget _chart(List<double> data, Color color, double min, double max) {
    if (data.length < 2) {
      return const SizedBox(
          height: 140,
          child: Center(
              child: Text('Collecting…',
                  style: TextStyle(color: _muted, fontSize: 11))));
    }
    return SizedBox(
      height: 140,
      child: LineChart(LineChartData(
        minY: min, maxY: max,
        gridData: FlGridData(
          show: true, drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: _border, strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
              sideTitles: SideTitles(
            showTitles: true, reservedSize: 28,
            getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(v < 40 ? 1 : 0),
                style: const TextStyle(color: _muted, fontSize: 8)),
          )),
          bottomTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries
                .map((e) => FlSpot(e.key.toDouble(), e.value))
                .toList(),
            isCurved: true, color: color, barWidth: 2,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [color.withOpacity(0.2), Colors.transparent],
              ),
            ),
          ),
        ],
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        _CCard('30-Point HR History',    _chart(hrHistory,   _hrCol,   40,  160)),
        const SizedBox(height: 12),
        _CCard('30-Point SpO₂ History',  _chart(spo2History, _spo2Col, 85,  101)),
        const SizedBox(height: 12),
        _CCard('Temperature History',    _chart(tempHistory, _tempCol, 35,  40)),
        const SizedBox(height: 12),
        _CCard('Session Log', Column(
          children: history.take(20).map((r) {
            final c = r['status'] == 'Critical' ? _crit
                    : r['status'] == 'Warning'  ? _warn
                    : _accentG;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _bg3,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: IntrinsicHeight(
                  child: Row(children: [
                    Container(width: 4, color: c),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(children: [
                Text('${(r['hr'] as double).toInt()} BPM',
                    style: const TextStyle(
                        color: _hrCol, fontFamily: 'monospace', fontSize: 10)),
                const SizedBox(width: 10),
                Text('${(r['spo2'] as double).toInt()}%',
                    style: const TextStyle(
                        color: _spo2Col, fontFamily: 'monospace', fontSize: 10)),
                const SizedBox(width: 10),
                Text('${(r['temp'] as double).toStringAsFixed(1)}°C',
                    style: const TextStyle(
                        color: _tempCol, fontFamily: 'monospace', fontSize: 10)),
                const Spacer(),
                Text(r['ts'],
                    style: const TextStyle(
                        color: _muted, fontFamily: 'monospace', fontSize: 9)),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ),
            );
          }).toList(),
        )),
        const SizedBox(height: 80),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  ALERTS PAGE
// ══════════════════════════════════════════════════════════════════════════════
class _AlertsPage extends StatelessWidget {
  final List<Map<String, dynamic>> alerts;
  final int warnCount, critCount, infoCount;
  const _AlertsPage({
    required this.alerts,
    required this.warnCount,
    required this.critCount,
    required this.infoCount,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        Row(children: [
          _AStat('Total', '${warnCount + critCount + infoCount}', _accent),
          const SizedBox(width: 8),
          _AStat('Warn',  '$warnCount', _warn),
          const SizedBox(width: 8),
          _AStat('Crit',  '$critCount', _crit),
          const SizedBox(width: 8),
          _AStat('Info',  '$infoCount', _accent),
        ]),
        const SizedBox(height: 14),
        _CCard('Live Alert Feed', Column(
          children: (alerts.isEmpty
              ? [{'type': 'info',
                  'msg': 'VitalSense AI initialized. Monitoring active.',
                  'ts': '--:--'}]
              : alerts)
              .take(20)
              .map((a) {
            final c = a['type'] == 'crit' ? _crit
                    : a['type'] == 'warn' ? _warn
                    : _accent;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: _bg3,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: IntrinsicHeight(
                  child: Row(children: [
                    Container(width: 5, color: c),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(children: [
                          Text(a['ts'] ?? '',
                              style: const TextStyle(
                                  color: _muted, fontFamily: 'monospace', fontSize: 10)),
                          const SizedBox(width: 12),
                          Expanded(child: Text(a['msg'] ?? '',
                              style: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w500))),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ),
            );
          }).toList(),
        )),
        const SizedBox(height: 80),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  CONFIG PAGE
// ══════════════════════════════════════════════════════════════════════════════
class _ConfigPage extends StatelessWidget {
  final double hr, spo2, temp;
  const _ConfigPage({required this.hr, required this.spo2, required this.temp});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        _CCard('ESP32 Connection', Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ESP32 IP Address',
                style: TextStyle(color: _muted, fontSize: 9,
                    fontFamily: 'monospace', letterSpacing: 1)),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(
                      color: _text, fontFamily: 'monospace', fontSize: 12),
                  decoration: InputDecoration(
                    hintText: '192.168.1.100',
                    hintStyle: const TextStyle(color: _muted),
                    filled: true, fillColor: _bg3,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: _border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: _border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: _accent, width: 1.5)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: _accentG),
                    borderRadius: BorderRadius.circular(8),
                    color: _accentG.withOpacity(0.08),
                  ),
                  child: const Text('Connect',
                      style: TextStyle(
                          color: _accentG, fontFamily: 'monospace',
                          fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1a0f00),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _warn.withOpacity(0.4)),
              ),
              child: const Text(
                '⊙ DEMO MODE — Using simulated sensor data. '
                'Enter ESP32 IP to connect live hardware.',
                style: TextStyle(color: _warn,
                    fontFamily: 'monospace', fontSize: 11),
              ),
            ),
            const SizedBox(height: 16),
            const Text('WIRING REFERENCE',
                style: TextStyle(color: _muted, fontSize: 9,
                    fontFamily: 'monospace', letterSpacing: 1.5)),
            const SizedBox(height: 8),
            _WR('MAX30102', 'SDA:GPIO21, SCL:GPIO22',              _accent),
            _WR('DS18B20',  'GPIO4 + 4.7kΩ to 3.3V',              _tempCol),
            _WR('DHT11',    'GPIO15 + 4.7kΩ to 3.3V',             _ambCol),
            _WR('Required libs',
                'MAX30105, DallasTemp, DHT, ArduinoJson',          _muted),
          ],
        )),
        const SizedBox(height: 80),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  ML RISK BARS
// ══════════════════════════════════════════════════════════════════════════════
class _MLRisk extends StatelessWidget {
  final double hr, spo2, temp;
  const _MLRisk({required this.hr, required this.spo2, required this.temp});

  @override
  Widget build(BuildContext context) {
    final risks = [
      ['Hypoxia',      (spo2 < 88 ? 90 : spo2 < 92 ? 60 : spo2 < 95 ? 25 : 5).toDouble(), _spo2Col],
      ['Tachycardia',  (hr > 140 ? 95 : hr > 120 ? 70 : hr > 100 ? 35 : 5).toDouble(),     _hrCol],
      ['Bradycardia',  (hr < 40 ? 95 : hr < 50 ? 65 : hr < 60 ? 25 : 3).toDouble(),        const Color(0xFFff8a65)],
      ['Fever',        (temp > 39.5 ? 95 : temp > 38.5 ? 65 : temp > 37.5 ? 30 : 5).toDouble(), _tempCol],
      ['Cardiac Stress',
          ((hr > 110 && spo2 < 95) ? 80 : (hr > 100 || spo2 < 95) ? 40 : 8).toDouble(),
          const Color(0xFFf48fb1)],
    ];
    return Column(
      children: risks.map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          SizedBox(
            width: 90,
            child: Text(r[0] as String,
                style: const TextStyle(
                    color: _text, fontFamily: 'monospace', fontSize: 10)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (r[1] as double) / 100,
                backgroundColor: _bg3,
                valueColor:
                    AlwaysStoppedAnimation<Color>(r[2] as Color),
                minHeight: 7,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 32,
            child: Text('${(r[1] as double).toInt()}%',
                style: TextStyle(
                    color: r[2] as Color, fontFamily: 'monospace',
                    fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ]),
      )).toList(),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  PLACEHOLDER (AI Chat tab — wire up your own screen here)
// ══════════════════════════════════════════════════════════════════════════════
class _PlaceholderPage extends StatelessWidget {
  final String label;
  const _PlaceholderPage({required this.label});

  @override
  Widget build(BuildContext context) => Center(
    child: Text(label,
        style: const TextStyle(
            color: _muted, fontFamily: 'monospace', fontSize: 16)),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  REUSABLE ATOMS
// ══════════════════════════════════════════════════════════════════════════════

/// Card container with accent-bar title
Widget _CCard(String title, Widget child) => Container(
  decoration: BoxDecoration(
    color: _bg2,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: _border),
  ),
  padding: const EdgeInsets.all(14),
  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Container(
          width: 3, height: 12,
          decoration: BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(title.toUpperCase(),
          style: const TextStyle(
              color: _muted, fontFamily: 'monospace',
              fontSize: 9, letterSpacing: 1.2)),
    ]),
    const SizedBox(height: 12),
    child,
  ]),
);

/// Vital value card
/// Vital value card
Widget _VCard(String label, String value, String unit, Color color, IconData icon) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [
          _bg2,
          color.withOpacity(0.05),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      boxShadow: [
        BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, spreadRadius: 2)
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
            const SizedBox(width: 2),
            Text(unit, style: const TextStyle(color: _muted, fontSize: 8, fontWeight: FontWeight.bold)),
          ],
        ),
        Text(label.toUpperCase(), style: const TextStyle(color: _text, fontSize: 7, letterSpacing: 0.5, fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

/// Alert summary stat chip
class _AStat extends StatelessWidget {
  final String l, v;
  final Color c;
  const _AStat(this.l, this.v, this.c);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Column(children: [
        Text(v,
            style: TextStyle(
                color: c, fontFamily: 'monospace',
                fontSize: 16, fontWeight: FontWeight.w800)),
        Text(l,
            style: TextStyle(
                color: c.withOpacity(0.7),
                fontFamily: 'monospace', fontSize: 8)),
      ]),
    ),
  );
}

/// Wiring reference row
Widget _WR(String sensor, String conn, Color color) => Padding(
  padding: const EdgeInsets.only(bottom: 5),
  child: Row(children: [
    Text(sensor,
        style: TextStyle(
            color: color, fontFamily: 'monospace',
            fontSize: 11, fontWeight: FontWeight.w700)),
    const Text(' → ',
        style: TextStyle(
            color: _muted, fontFamily: 'monospace', fontSize: 11)),
    Expanded(
      child: Text(conn,
          style: const TextStyle(color: _text, fontFamily: 'monospace',
              fontSize: 10)),
    ),
  ]),
);