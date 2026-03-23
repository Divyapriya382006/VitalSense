import 'package:flutter/material.dart';
import '../../models/vital_model.dart';
import '../../theme/app_theme.dart';

class VitalCardWidget extends StatelessWidget {
  final String label, value, unit, normalRange;
  final IconData icon;
  final VitalStatus status;
  final VoidCallback? onTap;

  const VitalCardWidget({
    super.key,
    required this.label, required this.value, required this.unit,
    required this.icon, required this.status, required this.normalRange,
    this.onTap,
  });

  Color get _color => VitalSenseTheme.getStatusColor(status.name);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isDark ? VitalSenseTheme.darkCard : VitalSenseTheme.lightCard,
          border: Border.all(
            color: status == VitalStatus.critical ? _color.withOpacity(0.6)
                : isDark ? VitalSenseTheme.darkBorder : VitalSenseTheme.lightBorder,
            width: status == VitalStatus.critical ? 2 : 1,
          ),
          boxShadow: status == VitalStatus.critical
              ? [BoxShadow(color: _color.withOpacity(0.2), blurRadius: 8)] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: _color, size: 12),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: _color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(status.name.toUpperCase(),
                      style: TextStyle(color: _color, fontSize: 7, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _color)),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2, left: 2),
                      child: Text(unit, style: TextStyle(color: _color.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87)),
                Text('Normal: $normalRange', style: TextStyle(fontSize: 8, color: Colors.grey.withOpacity(0.6))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
