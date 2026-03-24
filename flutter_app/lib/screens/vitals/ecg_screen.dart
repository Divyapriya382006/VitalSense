import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../models/vital_model.dart';
import '../ai_chat/ai_chat_screen.dart';
import '../alerts/alerts_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/sos_button_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/hardware_provider.dart';
import '../../widgets/mode_banner_widget.dart';

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

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  int _tabIndex = 0;
  late PageController _pageController;
  late AnimationController _ecgController;
  late AnimationController _heartController;
  late AnimationController _lungController;

  final List<double> _ecgData = [];
  double _ecgPhase = 0;
  static const int _ecgMax = 300;

  double _hr = 75, _spo2 = 98, _temp = 36.8, _ambTemp = 26.5, _humidity = 62;
  String _status = 'Normal';

  final List<Map<String, dynamic>> _history = [];
  final List<double> _hrHistory = [];
  final List<double> _spo2History = [];
  final List<double> _tempHistory = [];
  final List<String> _timeLabels = [];
  final List<Map<String, dynamic>> _alerts = [];
  int _warnCount = 0, _critCount = 0, _infoCount = 1;

  final List<String> _tabs = ['Dashboard', 'AI Chat', 'Trends', 'Alerts', 'Config'];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    for (int i = 0; i < _ecgMax; i++) _ecgData.add(0.0);

    _ecgController = AnimationController(vsync: this, duration: const Duration(milliseconds: 33))
  ..addListener(_ecgTick)..repeat();

    _heartController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);

    _lungController = AnimationController(vsync: this, duration: const Duration(milliseconds: 4000))
      ..repeat(reverse: true);

    _startAutoSim();
  }

  void _ecgTick() {
    if (!mounted) return;
    setState(() {
      // Phase increment: (33 ms frame / 1000 ms) × (HR / 60)
      // Ensures exactly 1 waveform cycle per heartbeat at any HR.
      _ecgPhase += (0.033 * _hr / 60);
      _ecgData.add(_ecgValue(_ecgPhase));
      if (_ecgData.length > _ecgMax) _ecgData.removeAt(0);
    });
  }

  double _ecgValue(double t) {
    final p = t % 1.0;
    if (p >= 0.05 && p < 0.18) return 0.12 * sin(pi * (p - 0.05) / 0.13);
    if (p >= 0.22 && p < 0.25) return -0.08 * sin(pi * (p - 0.22) / 0.03);
    if (p >= 0.25 && p < 0.29) return 0.9 * sin(pi * (p - 0.25) / 0.04);
    if (p >= 0.29 && p < 0.33) return -0.12 * sin(pi * (p - 0.29) / 0.04);
    if (p >= 0.33 && p < 0.42) return 0.02;
    if (p >= 0.42 && p < 0.62) return 0.22 * sin(pi * (p - 0.42) / 0.20);
    return (Random().nextDouble() - 0.5) * 0.005;
  }

  void _startAutoSim() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      final hwState = ref.read(hardwareProvider);
      setState(() {
        if (hwState.isRealTimeMode) {
          _hr   = hwState.latestHr;
          _spo2 = hwState.latestSpo2;
          _temp = hwState.latestTemp;
        } else {
          _hr   = (_hr   + (Random().nextDouble() - 0.48) * 3).clamp(40, 160);
          _spo2 = (_spo2 + (Random().nextDouble() - 0.45) * 0.5).clamp(85, 100);
          _temp = (_temp + (Random().nextDouble() - 0.5) * 0.05).clamp(35, 40);
          _hr   = _hr.roundToDouble();
          _spo2 = _spo2.roundToDouble();
        }
        _status = (_spo2 < 88 || _hr > 140 || _hr < 40) ? 'Critical'
            : (_spo2 < 92 || _hr > 110) ? 'Warning' : 'Normal';

        final ts = '${DateTime.now().hour.toString().padLeft(2,'0')}:${DateTime.now().minute.toString().padLeft(2,'0')}';
        if (_hrHistory.length >= 30) { _hrHistory.removeAt(0); _spo2History.removeAt(0); _tempHistory.removeAt(0); _timeLabels.removeAt(0); }
        _hrHistory.add(_hr); _spo2History.add(_spo2); _tempHistory.add(_temp); _timeLabels.add(ts);
        _history.insert(0, {'hr': _hr, 'spo2': _spo2, 'temp': _temp, 'ts': ts, 'status': _status,
            'source': hwState.isRealTimeMode ? hwState.sourceLabel : 'DEMO'});
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
  }

  void _switchTab(int i) {
    setState(() => _tabIndex = i);
    _pageController.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _pageController.dispose(); _ecgController.dispose();
    _heartController.dispose(); _lungController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: SOSButtonWidget(),
      body: SafeArea(child: Column(children: [
        _Header(status: _status, hr: _hr),
        _TabBar(tabs: _tabs, currentIndex: _tabIndex, onTap: _switchTab),
        Expanded(child: PageView(
          controller: _pageController,
          onPageChanged: (i) => setState(() => _tabIndex = i),
          children: [
            _DashboardPage(
              hr: _hr, spo2: _spo2, temp: _temp, ambTemp: _ambTemp, humidity: _humidity,
              status: _status, ecgData: _ecgData, hrHistory: _hrHistory,
              spo2History: _spo2History, tempHistory: _tempHistory, timeLabels: _timeLabels,
              heartCtrl: _heartController, lungCtrl: _lungController,
            ),
            const AIChatScreen(),
            _TrendsPage(hrHistory: _hrHistory, spo2History: _spo2History, tempHistory: _tempHistory, timeLabels: _timeLabels, history: _history),
            _AlertsPage(alerts: _alerts, warnCount: _warnCount, critCount: _critCount, infoCount: _infoCount),
            _ConfigPage(hr: _hr, spo2: _spo2, temp: _temp),
          ],
        )),
      ])),
    );
  }
}

class _Header extends StatelessWidget {
  final String status; final double hr;
  const _Header({required this.status, required this.hr});
  @override
  Widget build(BuildContext context) {
    final sc = status == 'Critical' ? _crit : status == 'Warning' ? _warn : _accentG;
    return Container(
      height: 54, color: const Color(0xFF040b12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _border))),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Container(width: 30, height: 30,
          decoration: BoxDecoration(border: Border.all(color: _accent, width: 1.5), borderRadius: BorderRadius.circular(8)),
          child: const Center(child: Text('⚕', style: TextStyle(fontSize: 15)))),
        const SizedBox(width: 8),
        RichText(text: const TextSpan(text: 'VitalSense', style: TextStyle(color: _accent, fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.w700),
          children: [TextSpan(text: ' AI', style: TextStyle(color: _text, fontWeight: FontWeight.w300))])),
        const Spacer(),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1a0a2e), Color(0xFF2a1a4e)]),
            border: Border.all(color: const Color(0xFF6030a0)), borderRadius: BorderRadius.circular(20)),
          child: const Text('VIT', style: TextStyle(color: Color(0xFFc084fc), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1))),
        const SizedBox(width: 10),
        Row(children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: sc, shape: BoxShape.circle))
            .animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 600.ms).then().fadeOut(duration: 600.ms),
          const SizedBox(width: 4),
          Text(status.toUpperCase(), style: TextStyle(color: sc, fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }
}

class _TabBar extends StatelessWidget {
  final List<String> tabs; final int currentIndex; final Function(int) onTap;
  const _TabBar({required this.tabs, required this.currentIndex, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Container(height: 42, color: _bg2,
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _border))),
      child: SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(children: tabs.asMap().entries.map((e) {
          final sel = currentIndex == e.key;
          return GestureDetector(onTap: () => onTap(e.key),
            child: AnimatedContainer(duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: sel ? _accent : Colors.transparent, width: 2))),
              child: Text(e.value, style: TextStyle(color: sel ? _accent : _muted, fontSize: 10, fontFamily: 'monospace', fontWeight: sel ? FontWeight.w700 : FontWeight.normal, letterSpacing: 0.8))));
        }).toList())));
  }
}

class _DashboardPage extends StatelessWidget {
  final double hr, spo2, temp, ambTemp, humidity;
  final String status;
  final List<double> ecgData, hrHistory, spo2History, tempHistory;
  final List<String> timeLabels;
  final AnimationController heartCtrl, lungCtrl;

  const _DashboardPage({
    required this.hr, required this.spo2, required this.temp,
    required this.ambTemp, required this.humidity, required this.status,
    required this.ecgData, required this.hrHistory, required this.spo2History,
    required this.tempHistory, required this.timeLabels,
    required this.heartCtrl, required this.lungCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final sc = status == 'Critical' ? _crit : status == 'Warning' ? _warn : _accentG;
    final pp = (30 + (hr - 60) * 0.5 + (spo2 - 95) * 2).clamp(10, 80).round();
    final stress = ((hr - 72).abs() * 1.5 + (95 - spo2).clamp(0, 20) * 3 + (temp - 36.6).abs() * 8).clamp(0, 100).round();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Status banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: status == 'Critical' ? const Color(0xFF1a0500) : status == 'Warning' ? const Color(0xFF1a0f00) : const Color(0xFF001a0a),
            borderRadius: BorderRadius.circular(10), border: Border.all(color: sc.withOpacity(0.5))),
          child: Row(children: [
            Text(status == 'Critical' ? '⛔' : status == 'Warning' ? '⚠' : '✓', style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(child: Text(status == 'Critical' ? 'CRITICAL — IMMEDIATE ATTENTION REQUIRED' : status == 'Warning' ? 'ATTENTION — VITALS ABNORMAL' : 'ALL VITALS NORMAL',
              style: TextStyle(color: sc, fontFamily: 'monospace', fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.5))),
          ]),
        ),
        const SizedBox(height: 14),

        // Vitals grid 3x2
        GridView.count(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8,
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 0.95,
          children: [
            _VCard('Heart Rate', '${hr.toInt()}', 'BPM', _hrCol),
            _VCard('SpO₂', '${spo2.toInt()}', '%', _spo2Col),
            _VCard('Temp', temp.toStringAsFixed(1), '°C', _tempCol),
            _VCard('Ambient', ambTemp.toStringAsFixed(1), '°C', _ambCol),
            _VCard('Pulse P.', '$pp', 'mmHg', const Color(0xFF4dd0e1)),
            _VCard('Stress', '$stress', '/100', const Color(0xFFef9a9a)),
          ]),
        const SizedBox(height: 14),

        // Trend chart
        _CCard('HR · SpO₂ Trend', SizedBox(height: 150,
          child: hrHistory.length > 1 ? LineChart(LineChartData(
            gridData: FlGridData(show: true, drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => const FlLine(color: _border, strokeWidth: 0.5)),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28,
                  getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(color: _muted, fontSize: 8)))),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28,
                  getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(color: _spo2Col, fontSize: 8)))),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(spots: hrHistory.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                isCurved: true, color: _hrCol, barWidth: 2, dotData: FlDotData(show: false),
                belowBarData: BarAreaData(show: true, color: _hrCol.withOpacity(0.08))),
              LineChartBarData(spots: spo2History.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                isCurved: true, color: _spo2Col, barWidth: 2, dotData: FlDotData(show: false),
                belowBarData: BarAreaData(show: true, color: _spo2Col.withOpacity(0.08))),
            ],
          )) : const Center(child: Text('Collecting data...', style: TextStyle(color: _muted, fontSize: 11))))),
        const SizedBox(height: 14),

        // Hospital ECG
        _ECGBox(data: ecgData, hr: hr),
        const SizedBox(height: 14),

        // Heart + Lungs
        _CCard('Live Organ Visualization', Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(children: [
              AnimatedBuilder(animation: heartCtrl, builder: (_, __) => Transform.scale(
                scale: 1.0 + heartCtrl.value * 0.15,
                child: SizedBox(width: 90, height: 90,
                  child: CustomPaint(painter: _HeartP(color: _hrCol, pulse: heartCtrl.value, hr: hr))))),
              const SizedBox(height: 4),
              Text('${hr.toInt()} BPM', style: const TextStyle(color: _hrCol, fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
            Container(width: 1, height: 100, color: _border),
            Column(children: [
              AnimatedBuilder(animation: lungCtrl, builder: (_, __) => SizedBox(width: 90, height: 90,
                child: CustomPaint(painter: _LungP(color: _spo2Col, breath: lungCtrl.value, spo2: spo2)))),
              const SizedBox(height: 4),
              Text('${spo2.toInt()}% SpO₂', style: const TextStyle(color: _spo2Col, fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ],
        )),
        const SizedBox(height: 14),

        // ML Risk bars
        _CCard('ML Risk Prediction', _MLRisk(hr: hr, spo2: spo2, temp: temp)),
        const SizedBox(height: 80),
      ]),
    );
  }
}

class _TrendsPage extends StatelessWidget {
  final List<double> hrHistory, spo2History, tempHistory;
  final List<String> timeLabels;
  final List<Map<String, dynamic>> history;
  const _TrendsPage({required this.hrHistory, required this.spo2History, required this.tempHistory, required this.timeLabels, required this.history});

  Widget _chart(List<double> data, Color color, double min, double max) {
    if (data.length < 2) return const SizedBox(height: 140, child: Center(child: Text('Collecting...', style: TextStyle(color: _muted, fontSize: 11))));
    return SizedBox(height: 140, child: LineChart(LineChartData(
      minY: min, maxY: max,
      gridData: FlGridData(show: true, drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(color: _border, strokeWidth: 0.5)),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28,
            getTitlesWidget: (v, _) => Text(v.toStringAsFixed(v < 40 ? 1 : 0), style: const TextStyle(color: _muted, fontSize: 8)))),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [LineChartBarData(
        spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
        isCurved: true, color: color, barWidth: 2, dotData: FlDotData(show: false),
        belowBarData: BarAreaData(show: true, gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.2), Colors.transparent])),
      )],
    )));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.all(14), child: Column(children: [
      _CCard('30-Point HR History', _chart(hrHistory, _hrCol, 40, 160)),
      const SizedBox(height: 12),
      _CCard('30-Point SpO₂ History', _chart(spo2History, _spo2Col, 85, 101)),
      const SizedBox(height: 12),
      _CCard('Temperature History', _chart(tempHistory, _tempCol, 35, 40)),
      const SizedBox(height: 12),
      _CCard('Session Log', Column(children: history.take(20).map((r) {
        final c = r['status'] == 'Critical' ? _crit : r['status'] == 'Warning' ? _warn : _accentG;
        return Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: _bg3, borderRadius: BorderRadius.circular(8), border: Border(left: BorderSide(color: c, width: 3))),
          child: Row(children: [
            Text('${(r['hr'] as double).toInt()} BPM', style: const TextStyle(color: _hrCol, fontFamily: 'monospace', fontSize: 10)),
            const SizedBox(width: 10),
            Text('${(r['spo2'] as double).toInt()}%', style: const TextStyle(color: _spo2Col, fontFamily: 'monospace', fontSize: 10)),
            const SizedBox(width: 10),
            Text('${(r['temp'] as double).toStringAsFixed(1)}°C', style: const TextStyle(color: _tempCol, fontFamily: 'monospace', fontSize: 10)),
            const Spacer(),
            Text(r['ts'], style: const TextStyle(color: _muted, fontFamily: 'monospace', fontSize: 9)),
          ]));
      }).toList())),
      const SizedBox(height: 80),
    ]));
  }
}

class _AlertsPage extends StatelessWidget {
  final List<Map<String, dynamic>> alerts;
  final int warnCount, critCount, infoCount;
  const _AlertsPage({required this.alerts, required this.warnCount, required this.critCount, required this.infoCount});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.all(14), child: Column(children: [
      Row(children: [
        _AStat('Total', '${warnCount + critCount + infoCount}', _accent),
        const SizedBox(width: 8),
        _AStat('Warn', '$warnCount', _warn),
        const SizedBox(width: 8),
        _AStat('Crit', '$critCount', _crit),
        const SizedBox(width: 8),
        _AStat('Info', '$infoCount', _accent),
      ]),
      const SizedBox(height: 14),
      _CCard('Live Alert Feed', Column(children: (alerts.isEmpty
          ? [{'type': 'info', 'msg': 'VitalSense AI initialized. Monitoring active.', 'ts': '--:--'}]
          : alerts).take(20).map((a) {
        final c = a['type'] == 'crit' ? _crit : a['type'] == 'warn' ? _warn : _accent;
        return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _bg3, borderRadius: BorderRadius.circular(8), border: Border(left: BorderSide(color: c, width: 3))),
          child: Row(children: [
            Text(a['ts'] ?? '', style: const TextStyle(color: _muted, fontFamily: 'monospace', fontSize: 9)),
            const SizedBox(width: 10),
            Expanded(child: Text(a['msg'] ?? '', style: const TextStyle(color: _text, fontSize: 12))),
          ])).animate().fadeIn().slideY(begin: -0.05);
      }).toList())),
      const SizedBox(height: 80),
    ]));
  }
}

class _ConfigPage extends ConsumerStatefulWidget {
  final double hr, spo2, temp;
  const _ConfigPage({required this.hr, required this.spo2, required this.temp});
  @override
  ConsumerState<_ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends ConsumerState<_ConfigPage> {
  late TextEditingController _ipCtrl;

  @override
  void initState() {
    super.initState();
    _ipCtrl = TextEditingController(text: ref.read(hardwareProvider).ipAddress);
  }

  @override
  void dispose() { _ipCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final hw = ref.watch(hardwareProvider);
    final notifier = ref.read(hardwareProvider.notifier);
    final isRt = hw.isRealTimeMode;
    final statusColor = hw.connectionStatus == HwConnectionStatus.connected
        ? _accentG
        : hw.connectionStatus == HwConnectionStatus.fingerNotDetected
            ? _warn
            : hw.connectionStatus == HwConnectionStatus.connecting
                ? _accent
                : _crit;

    return SingleChildScrollView(padding: const EdgeInsets.all(14), child: Column(children: [
      const ModeBannerWidget(),
      const SizedBox(height: 12),
      _CCard('ESP32 Hardware Connection', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(isRt ? 'Real-Time Hardware' : 'Demo Mode',
              style: TextStyle(color: isRt ? _accentG : _muted,
                  fontFamily: 'monospace', fontWeight: FontWeight.w700, fontSize: 12))),
          Switch.adaptive(
            value: isRt, activeColor: _accent,
            onChanged: (val) {
              if (val && hw.ipAddress.isEmpty) _showIpDialog(context, notifier);
              else notifier.setRealTimeMode(val);
            },
          ),
        ]),
        const SizedBox(height: 8),
        const Text('ESP32 IP Address', style: TextStyle(color: _muted, fontSize: 9, fontFamily: 'monospace', letterSpacing: 1)),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: TextField(
            controller: _ipCtrl,
            style: const TextStyle(color: _text, fontFamily: 'monospace', fontSize: 12),
            decoration: InputDecoration(hintText: '192.168.x.x', hintStyle: const TextStyle(color: _muted),
              filled: true, fillColor: _bg3, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _accent, width: 1.5))),
          )),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () { notifier.setIpAddress(_ipCtrl.text.trim()); notifier.setRealTimeMode(!isRt || true); },
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: isRt ? _crit : _accentG),
                borderRadius: BorderRadius.circular(8),
                color: (isRt ? _crit : _accentG).withOpacity(0.08),
              ),
              child: Text(isRt ? 'Disconnect' : 'Connect',
                  style: TextStyle(color: isRt ? _crit : _accentG, fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w700)))),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.07), borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor.withOpacity(0.35)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(_sIcon(hw.connectionStatus), color: statusColor, size: 14),
              const SizedBox(width: 6),
              Expanded(child: Text(_sText(hw, isRt), style: TextStyle(color: statusColor, fontFamily: 'monospace', fontSize: 11))),
            ]),
            if (isRt && hw.isConnected) ...[ 
              const SizedBox(height: 6),
              Text('HR: ${hw.latestHr.toInt()} BPM  ·  SpO₂: ${hw.latestSpo2.toInt()}%  ·  Temp: ${hw.latestTemp.toStringAsFixed(1)}°C',
                  style: const TextStyle(color: _text, fontFamily: 'monospace', fontSize: 10)),
            ],
          ]),
        ),
        const SizedBox(height: 16),
        const Text('WIRING REFERENCE', style: TextStyle(color: _muted, fontSize: 9, fontFamily: 'monospace', letterSpacing: 1.5)),
        const SizedBox(height: 8),
        _WR('MAX30102',      'SDA:GPIO21, SCL:GPIO22',              _accent),
        _WR('DS18B20',       'GPIO4 + 4.7kΩ pull-up to 3.3V',      _tempCol),
        _WR('DHT11',         'GPIO15 + 4.7kΩ pull-up to 3.3V',     _ambCol),
        _WR('Required libs', 'MAX30105, DallasTemp, DHT, ArduinoJson', _muted),
      ])),
      const SizedBox(height: 80),
    ]));
  }

  IconData _sIcon(HwConnectionStatus s) {
    switch (s) {
      case HwConnectionStatus.connected: return Icons.sensors_rounded;
      case HwConnectionStatus.fingerNotDetected: return Icons.touch_app_rounded;
      case HwConnectionStatus.connecting: return Icons.sync_rounded;
      case HwConnectionStatus.disconnected: return Icons.sensors_off_rounded;
    }
  }

  String _sText(HardwareState hw, bool isRt) {
    if (!isRt) return '⊙ DEMO MODE — simulated sensor data';
    switch (hw.connectionStatus) {
      case HwConnectionStatus.connected: return '✓ LIVE SENSOR — ${hw.ipAddress}';
      case HwConnectionStatus.fingerNotDetected: return '⦿ CONNECTED — place finger on MAX30102';
      case HwConnectionStatus.connecting: return '⦾ CONNECTING to ${hw.ipAddress}…';
      case HwConnectionStatus.disconnected: return '✗ DISCONNECTED — cached values shown';
    }
  }

  void _showIpDialog(BuildContext ctx, HardwareNotifier n) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: _bg2,
        title: const Text('ESP32 IP Address', style: TextStyle(color: _text, fontFamily: 'monospace', fontSize: 14)),
        content: TextField(controller: _ipCtrl,
          style: const TextStyle(color: _text, fontFamily: 'monospace'),
          decoration: InputDecoration(hintText: '192.168.x.x', hintStyle: const TextStyle(color: _muted),
            filled: true, fillColor: _bg3,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _accent, width: 1.5)))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: _muted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _accent),
            onPressed: () { n.setIpAddress(_ipCtrl.text.trim()); n.setRealTimeMode(true); Navigator.pop(ctx); },
            child: const Text('Connect', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

// ── Painters ──
class _HeartP extends CustomPainter {
  final Color color; final double pulse, hr;
  _HeartP({required this.color, required this.pulse, required this.hr});
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width/2, cy = size.height/2, r = size.width*0.38, s = r/45;
    canvas.drawCircle(Offset(cx,cy), r*1.3, Paint()..color=color.withOpacity(0.1+pulse*0.15)..maskFilter=const MaskFilter.blur(BlurStyle.normal,12));
    final path = Path()..moveTo(cx,cy+25*s)..cubicTo(cx-45*s,cy,cx-45*s,cy-30*s,cx,cy-15*s)..cubicTo(cx+45*s,cy-30*s,cx+45*s,cy,cx,cy+25*s)..close();
    canvas.drawPath(path, Paint()..color=color.withOpacity(0.25)..maskFilter=const MaskFilter.blur(BlurStyle.normal,5));
    canvas.drawPath(path, Paint()..color=color);
    final tp = TextPainter(text: TextSpan(text:'${hr.toInt()}',style:TextStyle(color:Colors.white,fontSize:15*s,fontWeight:FontWeight.w900)),textDirection:TextDirection.ltr);
    tp.layout(); tp.paint(canvas, Offset(cx-tp.width/2, cy-tp.height/2+2*s));
  }
  @override bool shouldRepaint(_HeartP o) => o.pulse!=pulse;
}

class _LungP extends CustomPainter {
  final Color color; final double breath, spo2;
  _LungP({required this.color, required this.breath, required this.spo2});
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width/2, cy = size.height/2;
    canvas.drawCircle(Offset(cx,cy), size.width*0.38, Paint()..color=color.withOpacity(0.07+breath*0.1)..maskFilter=const MaskFilter.blur(BlurStyle.normal,10));
    final lp = Paint()..color=color.withOpacity(0.7)..strokeWidth=2..style=PaintingStyle.stroke..strokeCap=StrokeCap.round;
    canvas.drawLine(Offset(cx,cy-35),Offset(cx,cy-16),lp);
    canvas.drawLine(Offset(cx,cy-16),Offset(cx-14,cy-8),lp);
    canvas.drawLine(Offset(cx,cy-16),Offset(cx+14,cy-8),lp);
    final exp = breath*5;
    for (final isLeft in [true,false]) {
      final ox = isLeft ? cx-18.0 : cx+18.0;
      canvas.drawOval(Rect.fromCenter(center:Offset(ox,cy+4),width:20+exp,height:32+exp), Paint()..color=color.withOpacity(0.6+breath*0.2));
    }
    final tp = TextPainter(text:TextSpan(text:'${spo2.toInt()}%',style:const TextStyle(color:Colors.white,fontSize:12,fontWeight:FontWeight.w900)),textDirection:TextDirection.ltr);
    tp.layout(); tp.paint(canvas,Offset(cx-tp.width/2,cy+26));
  }
  @override bool shouldRepaint(_LungP o) => o.breath!=breath;
}

// ── ECG ──
class _ECGBox extends StatelessWidget {
  final List<double> data; final double hr;
  const _ECGBox({required this.data, required this.hr});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF011200),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.25)),
      ),
      child: Column(children: [
        // Header row
        Padding(padding: const EdgeInsets.fromLTRB(14,12,14,0), child: Row(children: [
          const Text('LEAD II', style: TextStyle(color: Color(0xFF00CC33), fontFamily: 'monospace', fontSize: 10, letterSpacing: 1.5)),
          const SizedBox(width: 8),
          const Text('25mm/s · 10mm/mV', style: TextStyle(color: Color(0xFF005510), fontFamily: 'monospace', fontSize: 9)),
          const Spacer(),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 6, height: 6,
              decoration: const BoxDecoration(color: Color(0xFF00FF41), shape: BoxShape.circle)),
            const SizedBox(width: 4),
            const Text('LIVE', style: TextStyle(color: Color(0xFF00CC33), fontFamily: 'monospace', fontSize: 9, letterSpacing: 2)),
          ]),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Text('HR', style: TextStyle(color: Color(0xFF00AA22), fontFamily: 'monospace', fontSize: 8, letterSpacing: 2)),
            Text('${hr.toInt()}', style: const TextStyle(color: Color(0xFF00FF41), fontFamily: 'monospace', fontSize: 26, fontWeight: FontWeight.w900, height: 1)),
            const Text('BPM', style: TextStyle(color: Color(0xFF00AA22), fontFamily: 'monospace', fontSize: 8, letterSpacing: 2)),
          ]),
        ])),

        // ECG canvas — ClipRRect keeps trace inside the box
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

        // Footer stats
        Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
            _ES('PR', '160ms'), _ES('QRS', '82ms'), _ES('QT', '380ms'),
            _ES('QTc', '398ms'), _ES('Axis', '+60°'), _ES('Rhythm', 'SR'),
          ])),
      ]),
    );
  }
}

class _ECGP extends CustomPainter {
  final List<double> data;
  final double hr;
  _ECGP({required this.data, required this.hr});

  static const _green     = Color(0xFF00FF41);
  static const _gridMinor = Color(0xFF002800);
  static const _gridMajor = Color(0xFF004400);
  static const _gridLabel = Color(0xFF004015);
  static const _bg        = Color(0xFF010E01);

  // Each small square = 1mm = 0.04s at 25mm/s
  // We render at 2px per mm → 1 small square = 10px, 1 large = 50px
  static const double _mmPx   = 2.0;   // px per mm
  static const double _small  = 10.0;  // 1mm grid square in px
  static const double _large  = 50.0;  // 5mm grid square in px
  static const double _leftMargin = 28.0; // room for mV axis labels

  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width;
    final H = size.height;

    // ── Background ──
    canvas.drawRect(Rect.fromLTWH(0, 0, W, H),
        Paint()..color = _bg);

    // ── Clip everything inside bounds ──
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, W, H));

    // ── ECG grid ──
    final paintMinor = Paint()..color = _gridMinor..strokeWidth = 0.5;
    final paintMajor = Paint()..color = _gridMajor..strokeWidth = 1.0;

    // Vertical lines
    for (double x = _leftMargin; x <= W; x += _small) {
      final isMajor = ((x - _leftMargin) % _large).abs() < 0.5;
      canvas.drawLine(Offset(x, 0), Offset(x, H), isMajor ? paintMajor : paintMinor);
    }
    // Horizontal lines
    for (double y = 0; y <= H; y += _small) {
      final isMajor = (y % _large).abs() < 0.5;
      canvas.drawLine(Offset(_leftMargin, y), Offset(W, y), isMajor ? paintMajor : paintMinor);
    }

    // ── Calibration pulse: 1mV = 50px tall, 0.2s = 10px wide ──
    final calX = 4.0;
    final calMid = H / 2;
    final calPaint = Paint()
      ..color = const Color(0xFF009922)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    final calPath = Path()
      ..moveTo(calX,     calMid)
      ..lineTo(calX,     calMid - 50)
      ..lineTo(calX + 10, calMid - 50)
      ..lineTo(calX + 10, calMid);
    canvas.drawPath(calPath, calPaint);

    // ── mV axis labels ──
    void drawAxisLabel(String text, double y) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: const TextStyle(color: _gridLabel, fontFamily: 'monospace', fontSize: 8)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }
    final mid = H / 2;
    drawAxisLabel('+1', mid - 50);
    drawAxisLabel(' 0', mid - 6);
    drawAxisLabel('-1', mid + 44);

    // ── Time axis labels (bottom) ──
    final timePainterStyle = const TextStyle(color: _gridLabel, fontFamily: 'monospace', fontSize: 7);
    for (double x = _leftMargin + _large; x < W; x += _large) {
      final secs = (x - _leftMargin) / (_mmPx * 25); // 25mm/s
      final tp = TextPainter(
        text: TextSpan(text: '${secs.toStringAsFixed(1)}s', style: timePainterStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, H - tp.height - 1));
    }

    // ── Waveform ──
    if (data.length < 2) { canvas.restore(); return; }

    final amp     = H * 0.38;
    final drawW   = W - _leftMargin;

    // Glow pass
    final glowPaint = Paint()
      ..color = _green.withOpacity(0.18)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    // Crisp pass
    final linePaint = Paint()
      ..color = _green
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = _leftMargin + (i / (data.length - 1)) * drawW;
      final y = (mid - data[i] * amp).clamp(3.0, H - 10.0);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);

    // ── Scan-head dot at right edge ──
    if (data.isNotEmpty) {
      final ly = (mid - data.last * amp).clamp(3.0, H - 10.0);
      canvas.drawCircle(Offset(W - 2, ly), 3.5,
          Paint()..color = _green);
      canvas.drawCircle(Offset(W - 2, ly), 6,
          Paint()..color = _green.withOpacity(0.25)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    }

    // ── P, QRS, T wave annotation labels ──
    // Detect where in the buffer the current beat's waves are
    _drawAnnotations(canvas, size, mid, amp, drawW);

    canvas.restore();
  }

  void _drawAnnotations(Canvas canvas, Size size, double mid, double amp, double drawW) {
    if (data.length < 20) return;

    // Scan backward from tip to find R peak (highest positive value)
    int rIdx = data.length - 1;
    double rMax = -999;
    // Search in last 2/3 of buffer (skip very fresh samples)
    final searchEnd = (data.length * 0.95).toInt();
    final searchStart = (data.length * 0.3).toInt();
    for (int i = searchStart; i < searchEnd; i++) {
      if (data[i] > rMax) { rMax = data[i]; rIdx = i; }
    }

    if (rMax < 0.4) return; // no clear R peak found

    // Approximate wave positions relative to R peak index
    // At 72 BPM, 1 RR = ~833ms. Phase increment 0.00055 per 33ms tick
    // One full cycle = 1.0/0.00055 * 33ms ≈ 833ms ✓ matches 72 BPM
    // In buffer indices: ~300 samples per RR at full buffer.
    final rrSamples = data.length; // buffer holds ~1 full RR
    final waveOffsets = {
      'P': -0.72,   // P wave centre relative to R (fraction of RR back)
      'Q': -0.12,
      'R':  0.0,
      'S':  0.10,
      'T':  0.30,
    };

    final labelStyle = const TextStyle(
      color: Color(0xFF00AA22),
      fontFamily: 'monospace',
      fontSize: 9,
      fontWeight: FontWeight.w700,
    );

    for (final entry in waveOffsets.entries) {
      final idxOffset = (entry.value * rrSamples * 0.28).toInt();
      final idx = (rIdx + idxOffset).clamp(0, data.length - 1);
      final x = _leftMargin + (idx / (data.length - 1)) * drawW;
      final y = (mid - data[idx] * amp).clamp(3.0, size.height - 10.0);

      // Place label above peak, below trough, or above midline
      final labelY = data[idx] > 0.15
          ? y - 13.0
          : data[idx] < -0.05
              ? y + 14.0
              : mid - amp * 0.55;

      final tp = TextPainter(
        text: TextSpan(text: entry.key, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, labelY.clamp(2.0, size.height - 12.0)));

      // Small tick mark
      canvas.drawLine(
        Offset(x, y + (data[idx] > 0.1 ? -6.0 : 5.0)),
        Offset(x, y),
        Paint()..color = const Color(0xFF006618)..strokeWidth = 0.8,
      );
    }
  }

  @override
  bool shouldRepaint(_ECGP old) => old.data != data;
}

class _ES extends StatelessWidget {
  final String l, v;
  const _ES(this.l, this.v);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(l, style: const TextStyle(color: Color(0xFF006600), fontFamily: 'monospace', fontSize: 8, letterSpacing: 1)),
    Text(v, style: const TextStyle(color: Color(0xFF00CC33), fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w700)),
  ]);
}

class _MLRisk extends StatelessWidget {
  final double hr, spo2, temp;
  const _MLRisk({required this.hr, required this.spo2, required this.temp});
  @override
  Widget build(BuildContext context) {
    final risks = [
      ['Hypoxia', (spo2<88?90:spo2<92?60:spo2<95?25:5).toDouble(), _spo2Col],
      ['Tachycardia', (hr>140?95:hr>120?70:hr>100?35:5).toDouble(), _hrCol],
      ['Bradycardia', (hr<40?95:hr<50?65:hr<60?25:3).toDouble(), const Color(0xFFff8a65)],
      ['Fever', (temp>39.5?95:temp>38.5?65:temp>37.5?30:5).toDouble(), _tempCol],
      ['Cardiac Stress', ((hr>110&&spo2<95)?80:(hr>100||spo2<95)?40:8).toDouble(), const Color(0xFFf48fb1)],
    ];
    return Column(children: risks.map((r) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
      SizedBox(width: 90, child: Text(r[0] as String, style: const TextStyle(color: _text, fontFamily: 'monospace', fontSize: 10))),
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(value: (r[1] as double)/100, backgroundColor: _bg3, valueColor: AlwaysStoppedAnimation(r[2] as Color), minHeight: 7))),
      const SizedBox(width: 8),
      SizedBox(width: 32, child: Text('${(r[1] as double).toInt()}%', style: TextStyle(color: r[2] as Color, fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w700))),
    ]))).toList());
  }
}

// ── Reusable atoms ──
Widget _CCard(String title, Widget child) => Container(
  decoration: BoxDecoration(color: _bg2, borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
  padding: const EdgeInsets.all(14),
  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Container(width: 3, height: 12, decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(title.toUpperCase(), style: const TextStyle(color: _muted, fontFamily: 'monospace', fontSize: 9, letterSpacing: 1.2)),
    ]),
    const SizedBox(height: 12),
    child,
  ]),
);

Widget _VCard(String label, String value, String unit, Color color) => Container(
  decoration: BoxDecoration(color: _bg2, borderRadius: BorderRadius.circular(10),
    border: Border(bottom: BorderSide(color: color, width: 2),
      top: const BorderSide(color: _border), left: const BorderSide(color: _border), right: const BorderSide(color: _border))),
  padding: const EdgeInsets.all(10),
  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(label, style: const TextStyle(color: _muted, fontFamily: 'monospace', fontSize: 8, letterSpacing: 0.8)),
    Text(value, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 22, fontWeight: FontWeight.w700, height: 1.1)),
    Row(children: [
      Text(unit, style: const TextStyle(color: _muted, fontFamily: 'monospace', fontSize: 9)),
      const Spacer(),
      Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    ]),
  ]),
);

class _AStat extends StatelessWidget {
  final String l, v; final Color c;
  const _AStat(this.l, this.v, this.c);
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: c.withOpacity(0.3))),
    child: Column(children: [
      Text(v, style: TextStyle(color: c, fontFamily: 'monospace', fontSize: 16, fontWeight: FontWeight.w800)),
      Text(l, style: TextStyle(color: c.withOpacity(0.7), fontFamily: 'monospace', fontSize: 8)),
    ]),
  ));
}

Widget _WR(String sensor, String conn, Color color) => Padding(padding: const EdgeInsets.only(bottom: 5), child: Row(children: [
  Text(sensor, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w700)),
  const Text(' → ', style: TextStyle(color: _muted, fontFamily: 'monospace', fontSize: 11)),
  Expanded(child: Text(conn, style: const TextStyle(color: _text, fontFamily: 'monospace', fontSize: 10))),
]));
