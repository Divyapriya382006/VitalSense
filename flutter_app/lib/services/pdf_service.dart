import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/vital_model.dart';
import '../models/user_model.dart';

class PDFReportService {
  static Future<File> generateReport({
    required UserModel user,
    required List<VitalReading> readings,
    required VitalReading latest,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    final now = DateTime.now();

    final primaryColor = PdfColors.blue700;
    final bgColor = PdfColors.grey100;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Container(
            decoration: pw.BoxDecoration(
              color: primaryColor,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            padding: const pw.EdgeInsets.all(20),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('VitalSense Health Report',
                        style: pw.TextStyle(color: PdfColors.white, fontSize: 22, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('Generated: ${dateFormat.format(now)}',
                        style: const pw.TextStyle(color: PdfColors.white, fontSize: 11)),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.circular(20)),
                  child: pw.Text('PHI: ${latest.phiScore.toInt()}/100',
                      style: pw.TextStyle(color: primaryColor, fontWeight: pw.FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Patient Info
          _sectionTitle('Patient Information', primaryColor),
          pw.Container(
            decoration: pw.BoxDecoration(color: bgColor, borderRadius: pw.BorderRadius.circular(8)),
            padding: const pw.EdgeInsets.all(16),
            child: pw.Row(
              children: [
                pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  _infoRow('Name', user.name),
                  _infoRow('Age', '${user.age} years'),
                  _infoRow('Blood Group', user.bloodGroup.name.toUpperCase()),
                ])),
                pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  _infoRow('Height', '${user.heightCm} cm'),
                  _infoRow('Weight', '${user.weightKg} kg'),
                  _infoRow('BMI', '${user.bmi} (${user.bmiCategory})'),
                ])),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Latest Vitals
          _sectionTitle('Current Vital Signs', primaryColor),
          pw.Row(
            children: [
              _vitalCard('Heart Rate', '${latest.heartRate.toInt()} BPM', '40–100 BPM', _statusColor(latest.heartRateStatus)),
              pw.SizedBox(width: 8),
              _vitalCard('SpO₂', '${latest.spo2.toInt()}%', '95–100%', _statusColor(latest.spo2Status)),
              pw.SizedBox(width: 8),
              _vitalCard('Temperature', '${latest.temperature.toStringAsFixed(1)}°C', '36–37.5°C', _statusColor(latest.temperatureStatus)),
              pw.SizedBox(width: 8),
              if (latest.stressLevel != null)
                _vitalCard('Stress (HRV)', '${latest.stressLevel!.toInt()}%', '0–40% Normal', PdfColors.orange700),
            ],
          ),
          pw.SizedBox(height: 20),

          // Trend Table
          if (readings.isNotEmpty) ...[
            _sectionTitle('Vital Trends (Last ${readings.length} Readings)', primaryColor),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: primaryColor),
                  children: [
                    _tableHeader('Time'), _tableHeader('HR (BPM)'),
                    _tableHeader('SpO₂ (%)'), _tableHeader('Temp (°C)'),
                    _tableHeader('PHI'), _tableHeader('Status'),
                  ],
                ),
                ...readings.take(20).map((r) => pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: readings.indexOf(r) % 2 == 0 ? PdfColors.white : bgColor,
                  ),
                  children: [
                    _tableCell(DateFormat('HH:mm').format(r.timestamp)),
                    _tableCell('${r.heartRate.toInt()}'),
                    _tableCell('${r.spo2.toInt()}'),
                    _tableCell(r.temperature.toStringAsFixed(1)),
                    _tableCell('${r.phiScore.toInt()}'),
                    _tableCellColored(r.overallStatus.name.toUpperCase(), _statusColor(r.overallStatus)),
                  ],
                )),
              ],
            ),
            pw.SizedBox(height: 20),
          ],

          // XAI Explanation
          if (latest.xaiExplanation != null) ...[
            _sectionTitle('AI Analysis Explanation', primaryColor),
            pw.Container(
              decoration: pw.BoxDecoration(border: pw.Border.all(color: primaryColor), borderRadius: pw.BorderRadius.circular(8)),
              padding: const pw.EdgeInsets.all(16),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(latest.xaiExplanation!['summary'] ?? 'No explanation available',
                      style: const pw.TextStyle(fontSize: 12)),
                  pw.SizedBox(height: 8),
                  if (latest.xaiExplanation!['factors'] != null)
                    ...((latest.xaiExplanation!['factors'] as List)
                        .map((f) => pw.Text('• $f', style: const pw.TextStyle(fontSize: 11)))),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
          ],

          // Disclaimer
          pw.Container(
            decoration: pw.BoxDecoration(color: PdfColors.amber50, borderRadius: pw.BorderRadius.circular(8)),
            padding: const pw.EdgeInsets.all(12),
            child: pw.Text(
              '⚠️ This report is generated by AI and is for informational purposes only. '
              'It does not constitute medical advice. Please consult a qualified healthcare '
              'professional for diagnosis and treatment.',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.orange900),
            ),
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/vitalsense_report_${now.millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<void> shareReport(File file, String patientName) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'VitalSense Health Report - $patientName',
      text: 'Health report generated by VitalSense AI Health Monitor',
    );
  }

  static pw.Widget _sectionTitle(String title, PdfColor color) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color)),
      pw.Divider(color: color, thickness: 1),
      pw.SizedBox(height: 8),
    ]);
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(children: [
        pw.Text('$label: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
        pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
      ]),
    );
  }

  static pw.Widget _vitalCard(String label, String value, String range, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border(left: pw.BorderSide(color: color, width: 3)),
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        padding: const pw.EdgeInsets.all(10),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color)),
          pw.Text(range, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
        ]),
      ),
    );
  }

  static pw.Widget _tableHeader(String text) => pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(text, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
  );

  static pw.Widget _tableCell(String text) => pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
  );

  static pw.Widget _tableCellColored(String text, PdfColor color) => pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(text, style: pw.TextStyle(fontSize: 10, color: color, fontWeight: pw.FontWeight.bold)),
  );

  static PdfColor _statusColor(VitalStatus status) {
    switch (status) {
      case VitalStatus.critical: return PdfColors.red700;
      case VitalStatus.warning: return PdfColors.orange700;
      case VitalStatus.low: return PdfColors.purple700;
      case VitalStatus.normal: return PdfColors.green700;
    }
  }
}
