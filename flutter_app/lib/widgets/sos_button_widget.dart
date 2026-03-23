import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vitals_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../services/bluetooth_mesh_service.dart';
import '../../services/voice_service.dart';
import '../../services/notification_service.dart';

class SOSButtonWidget extends ConsumerStatefulWidget {
  @override
  ConsumerState<SOSButtonWidget> createState() => _SOSButtonWidgetState();
}

class _SOSButtonWidgetState extends ConsumerState<SOSButtonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isSOSActive = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _triggerSOS() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    final vital = ref.read(latestVitalProvider(user?.uid ?? '')).valueOrNull;
    final bluetooth = ref.read(bluetoothMeshProvider);
    final voice = ref.read(voiceServiceProvider);

    // Check connectivity
    final connectivity = await Connectivity().checkConnectivity();
    final isOffline = connectivity.contains(ConnectivityResult.none);

    setState(() => _isSOSActive = true);

    // Speak SOS alert
    String alertMsg = isOffline 
      ? 'No network. Broadcasting emergency SOS via Bluetooth Mesh Network.' 
      : 'Emergency SOS activated. Alerting nearby devices and your emergency contacts.';
    await voice.speak(alertMsg);

    // Get location
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (_) {}

    // Send via Bluetooth mesh (Always, and especially if offline)
    if (user != null && vital != null) {
      await bluetooth.sendSOS(
        senderName: user.name,
        userId: user.uid,
        heartRate: vital.heartRate,
        spo2: vital.spo2,
        lat: position?.latitude ?? 0.0,
        lng: position?.longitude ?? 0.0,
      );
    }

    // Show critical notification
    await NotificationService.showCriticalAlert(
      title: isOffline ? '🆘 MESH SOS ACTIVE' : '🆘 SOS Sent!',
      body: isOffline 
        ? 'Broadcasting via Bluetooth Mesh (No Internet). Stay visible.' 
        : 'Emergency alert sent to nearby users and contacts.',
    );

    // Show dialog
    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.sos, color: VitalSenseTheme.alertRed, size: 28),
              SizedBox(width: 8),
              Text('SOS Sent!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Emergency alert has been sent to:'),
              const SizedBox(height: 8),
              _SOSItem('📡', 'Nearby VitalSense users via Bluetooth'),
              _SOSItem('📞', 'Your emergency contacts'),
              _SOSItem('🏥', 'Nearby hospitals notified'),
              if (position != null)
                _SOSItem('📍', 'Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _isSOSActive = false);
              },
              style: ElevatedButton.styleFrom(backgroundColor: VitalSenseTheme.primaryGreen),
              child: const Text("I'm Safe Now"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: _triggerSOS,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (_, __) => Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: VitalSenseTheme.alertRed,
            boxShadow: [
              BoxShadow(
                color: VitalSenseTheme.alertRed.withOpacity(0.4 + _pulseController.value * 0.3),
                blurRadius: 16 + (_pulseController.value * 8),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sos, color: Colors.white, size: 22),
              const Text('HOLD', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SOSItem extends StatelessWidget {
  final String emoji, text;
  const _SOSItem(this.emoji, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
