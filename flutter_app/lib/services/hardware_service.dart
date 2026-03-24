import 'dart:convert';
import 'dart:io';

/// Thin HTTP client for all ESP32 API calls.
/// ESP32 exposes:
///   GET /json     → { hr, spo2, bodyTemp, status, statusLevel, fingerDetected, uptime }
///   GET /history  → { readings: [{hr, spo2, bodyTemp, ts}], count }
///   GET /pulse    → raw IR integer (plain text)
///   GET /bpm      → heart-rate integer (plain text)
///   GET /vitals   → "hr,spo2,temp" CSV (plain text)
class HardwareService {
  final HttpClient _client;

  HardwareService()
      : _client = HttpClient()
          ..connectionTimeout = const Duration(seconds: 2)
          ..idleTimeout = const Duration(seconds: 3);

  Future<Map<String, dynamic>?> fetchJson(String ip) async {
    try {
      final req = await _client.getUrl(Uri.parse('http://$ip/json'));
      final res = await req.close();
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        return json.decode(body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchHistory(String ip) async {
    try {
      final req = await _client.getUrl(Uri.parse('http://$ip/history'));
      final res = await req.close();
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        final data = json.decode(body) as Map<String, dynamic>;
        final readings = data['readings'] as List<dynamic>? ?? [];
        return readings.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  void dispose() => _client.close(force: true);
}
