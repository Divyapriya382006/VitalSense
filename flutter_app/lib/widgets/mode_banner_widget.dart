import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/hardware_provider.dart';

// ── Color palette consistent with app ─────────────────────────────────────────
const _accentG = Color(0xFF69ff47);
const _warn    = Color(0xFFffab00);
const _crit    = Color(0xFFff3d00);
const _accent  = Color(0xFF00e5ff);
const _bg2     = Color(0xFF0c1824);
const _bg3     = Color(0xFF111f2e);
const _border  = Color(0xFF1a3040);
const _muted   = Color(0xFF4a6478);
const _text    = Color(0xFFc8dae8);

/// Mode toggle banner shown at the top of every portal screen.
///
/// Pass [showToggle: false] on screens where you only want the status badge
/// without the full toggle UI (e.g., inside a tab that already has a Config tab).
class ModeBannerWidget extends ConsumerWidget {
  final bool showToggle;
  const ModeBannerWidget({super.key, this.showToggle = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hw = ref.watch(hardwareProvider);
    final notifier = ref.read(hardwareProvider.notifier);

    final (statusColor, icon, label, sublabel) = _statusInfo(hw);

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _bg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.35), width: 1),
      ),
      child: Row(children: [
        // Animated dot
        _PulseDot(color: statusColor),
        const SizedBox(width: 8),
        // Status text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      fontFamily: 'monospace')),
              if (sublabel.isNotEmpty)
                Text(sublabel,
                    style: const TextStyle(
                        color: _muted, fontSize: 9, fontFamily: 'monospace')),
            ],
          ),
        ),

        // Source chip
        _SourceChip(hw: hw),
        const SizedBox(width: 8),

        if (showToggle) ...[
          // Toggle
          SizedBox(
            height: 24,
            child: Switch.adaptive(
              value: hw.isRealTimeMode,
              activeColor: _accent,
              onChanged: (val) {
                if (val && hw.ipAddress.isEmpty) {
                  _showIpDialog(context, notifier);
                } else {
                  notifier.setRealTimeMode(val);
                }
              },
            ),
          ),
          const SizedBox(width: 4),
          Text(hw.isRealTimeMode ? 'REAL' : 'DEMO',
              style: const TextStyle(
                  color: _muted,
                  fontSize: 9,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700)),
          if (hw.isRealTimeMode) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _showIpDialog(context, notifier),
              child: const Icon(Icons.settings_ethernet,
                  color: _accent, size: 16),
            ),
          ],
        ],
      ]),
    );
  }

  (Color, IconData, String, String) _statusInfo(HardwareState hw) {
    if (!hw.isRealTimeMode) {
      return (_muted, Icons.science_outlined, 'DEMO MODE', 'Simulated sensor data');
    }
    switch (hw.connectionStatus) {
      case HwConnectionStatus.connecting:
        return (_warn, Icons.sync_rounded, 'REAL-TIME — CONNECTING…', hw.ipAddress);
      case HwConnectionStatus.connected:
        return (_accentG, Icons.sensors_rounded, 'REAL-TIME — LIVE SENSOR', hw.ipAddress);
      case HwConnectionStatus.fingerNotDetected:
        return (_warn, Icons.touch_app_rounded, 'REAL-TIME — PLACE FINGER', hw.ipAddress);
      case HwConnectionStatus.disconnected:
        final ago = hw.lastReadingTime != null
            ? _ago(hw.lastReadingTime!)
            : 'never';
        return (_crit, Icons.sensors_off_rounded, 'REAL-TIME — DISCONNECTED', 'Cached: $ago');
    }
  }

  String _ago(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  void _showIpDialog(BuildContext context, HardwareNotifier notifier) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bg2,
        title: const Text('ESP32 IP Address',
            style: TextStyle(color: _text, fontFamily: 'monospace', fontSize: 14)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: _text, fontFamily: 'monospace'),
          decoration: InputDecoration(
            hintText: '192.168.x.x',
            hintStyle: const TextStyle(color: _muted),
            filled: true,
            fillColor: _bg3,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _accent, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: _muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _accent),
            onPressed: () {
              notifier.setIpAddress(ctrl.text.trim());
              notifier.setRealTimeMode(true);
              Navigator.pop(ctx);
            },
            child: const Text('Connect',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

// ── Source chip: SENSOR / CACHED / DEMO ───────────────────────────────────────
class SourceChip extends ConsumerWidget {
  const SourceChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hw = ref.watch(hardwareProvider);
    return _SourceChip(hw: hw);
  }
}

class _SourceChip extends StatelessWidget {
  final HardwareState hw;
  const _SourceChip({required this.hw});

  @override
  Widget build(BuildContext context) {
    final label = hw.sourceLabel;
    final color = label == 'SENSOR'
        ? _accentG
        : label == 'CACHED'
            ? _warn
            : _muted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4), width: 0.8),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              fontFamily: 'monospace')),
    );
  }
}

// ── Pulsing dot ───────────────────────────────────────────────────────────────
class _PulseDot extends StatelessWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fade(begin: 0.3, end: 1.0, duration: 700.ms);
  }
}
