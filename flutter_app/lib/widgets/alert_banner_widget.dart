import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../models/vital_model.dart';
import '../../services/voice_service.dart';
import '../../theme/app_theme.dart';

class AlertBannerWidget extends ConsumerStatefulWidget {
  final VitalReading vital;
  const AlertBannerWidget({super.key, required this.vital});

  @override
  ConsumerState<AlertBannerWidget> createState() => _AlertBannerWidgetState();
}

class _AlertBannerWidgetState extends ConsumerState<AlertBannerWidget> {
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _speakAlert();
  }

  void _speakAlert() async {
    final voice = ref.read(voiceServiceProvider);
    final msg = voice.buildAlertMessage(
      heartRate: widget.vital.heartRate,
      spo2: widget.vital.spo2,
      temperature: widget.vital.temperature,
      severity: widget.vital.overallStatus.name,
    );
    if (msg.isNotEmpty) {
      await voice.speakAlert(msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final isCritical = widget.vital.overallStatus == VitalStatus.critical;
    final color = isCritical ? VitalSenseTheme.alertRed : VitalSenseTheme.alertAmber;

    return GestureDetector(
      onTap: () => context.push('/home/alerts'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Icon(
              isCritical ? Icons.warning_rounded : Icons.info_rounded,
              color: color, size: 20,
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 0.9, end: 1.1, duration: 600.ms),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isCritical
                    ? 'CRITICAL: Vitals need immediate attention!'
                    : 'WARNING: Some vitals are outside normal range',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _dismissed = true),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
              child: Text('Dismiss', style: TextStyle(color: color, fontSize: 12)),
            ),
          ],
        ),
      ).animate().slideY(begin: -0.5, duration: 300.ms).fadeIn(),
    );
  }
}
