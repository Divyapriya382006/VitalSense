import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';

class UploadReportScreen extends StatefulWidget {
  const UploadReportScreen({super.key});
  @override
  State<UploadReportScreen> createState() => _UploadReportScreenState();
}

class _UploadReportScreenState extends State<UploadReportScreen> {
  bool _isUploading = false;
  bool _fileSelected = false;
  bool _isAnalyzing = false;
  bool _showReport = false;
  bool _isSending = false;

  void _simulateFileSelection() {
    setState(() => _isUploading = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() { _isUploading = false; _fileSelected = true; });
    });
  }

  void _simulateAnalysis() {
    setState(() => _isAnalyzing = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() { _isAnalyzing = false; _showReport = true; });
    });
  }

  void _simulateSend() {
    setState(() => _isSending = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report Sent to Dr. Sarah Jenkins!'), backgroundColor: Color(0xFF69ff47)),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060d14),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI MEDICAL REPORT ANALYSIS', style: TextStyle(color: Color(0xFF00e5ff), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontFamily: 'monospace')),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF0c1824),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00e5ff), style: BorderStyle.solid, width: 2),
              ),
              child: Column(
                children: [
                  const Icon(Icons.cloud_upload_outlined, color: Color(0xFF00e5ff), size: 50),
                  const SizedBox(height: 16),
                  const Text('Upload Medical Report', style: TextStyle(color: Color(0xFFc8dae8), fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('PDF, JPG, PNG, DICOM supported', style: TextStyle(color: Color(0xFF4a6478), fontSize: 12)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: (_isUploading || _fileSelected) ? null : _simulateFileSelection,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00e5ff), foregroundColor: const Color(0xFF060d14)),
                    child: _isUploading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF060d14)))
                        : Text(_fileSelected ? 'File: health_report.pdf' : 'Select File'),
                  ),
                  if (_fileSelected) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isAnalyzing ? null : _simulateAnalysis,
                            icon: _isAnalyzing ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Icon(Icons.psychology, size: 18),
                            label: const Text('AI ANALYZE'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF69ff47), foregroundColor: Colors.black),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isSending ? null : _simulateSend,
                            icon: _isSending ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send, size: 18),
                            label: const Text('SEND DOCTOR'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1a3040), foregroundColor: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ]
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            if (_showReport) ...[
              const Text('AI VISUALIZATION (RECENT UPLOAD)', style: TextStyle(color: Color(0xFF4a6478), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0c1824),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1a3040)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('CBC Blood Test (Sept 12)', style: TextStyle(color: Color(0xFFc8dae8), fontSize: 14, fontWeight: FontWeight.bold)),
                      Icon(Icons.check_circle, color: Color(0xFF69ff47), size: 16)
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 150,
                    child: BarChart(
                      BarChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) => Text(['RBC', 'WBC', 'HGB', 'PLT'][v.toInt()], style: const TextStyle(color: Color(0xFF4a6478), fontSize: 10)))),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 8, color: const Color(0xFF00e5ff), width: 15)]),
                          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 6, color: const Color(0xFF69ff47), width: 15)]),
                          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 4, color: const Color(0xFFffab00), width: 15)]),
                          BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 9, color: const Color(0xFFce93d8), width: 15)]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('AI Finding: Hemoglobin levels are slightly below optimal range. Iron-rich diet recommended.', style: TextStyle(color: Color(0xFFffab00), fontSize: 12)),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
            ]
          ],
        ),
      ),
    );
  }
}
