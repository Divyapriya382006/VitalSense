import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bluetooth Mesh Emergency Messaging
/// Uses BLE advertising to broadcast SOS to nearby devices running VitalSense
class BluetoothMeshService {
  static const String _serviceUUID = '0000FF00-0000-1000-8000-00805F9B34FB';
  static const String _sosCharUUID = '0000FF01-0000-1000-8000-00805F9B34FB';
  static const String _appIdentifier = 'VITALSENSE_SOS';

  StreamController<SOSMessage>? _sosController;
  final List<BluetoothDevice> _connectedDevices = [];
  bool _isScanning = false;
  bool _isBroadcasting = false;

  Stream<SOSMessage> get sosStream {
    _sosController ??= StreamController<SOSMessage>.broadcast();
    return _sosController!.stream;
  }

  Future<bool> checkPermissions() async {
    final state = await FlutterBluePlus.adapterState.first;
    return state == BluetoothAdapterState.on;
  }

  /// Start scanning for nearby VitalSense devices
  Future<void> startScanning() async {
    if (_isScanning) return;
    _isScanning = true;

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        withServices: [Guid(_serviceUUID)],
      );

      FlutterBluePlus.scanResults.listen((results) async {
        for (final result in results) {
          if (!_connectedDevices.contains(result.device)) {
            await _connectAndListen(result.device);
          }
        }
      });
    } catch (e) {
      _isScanning = false;
    }
  }

  Future<void> _connectAndListen(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 5));
      _connectedDevices.add(device);

      final services = await device.discoverServices();
      for (final service in services) {
        if (service.uuid.toString().toUpperCase().contains('FF00')) {
          for (final char in service.characteristics) {
            if (char.uuid.toString().toUpperCase().contains('FF01')) {
              await char.setNotifyValue(true);
              char.onValueReceived.listen((data) {
                try {
                  final json = utf8.decode(data);
                  final map = jsonDecode(json) as Map<String, dynamic>;
                  if (map['id'] == _appIdentifier) {
                    _sosController?.add(SOSMessage.fromMap(map));
                  }
                } catch (_) {}
              });
            }
          }
        }
      }
    } catch (e) {
      _connectedDevices.remove(device);
    }
  }

  /// Send SOS to all connected nearby devices
  Future<void> sendSOS({
    required String senderName,
    required String userId,
    required double heartRate,
    required double spo2,
    required double lat,
    required double lng,
  }) async {
    final message = SOSMessage(
      id: _appIdentifier,
      senderName: senderName,
      userId: userId,
      heartRate: heartRate,
      spo2: spo2,
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
    );

    final data = utf8.encode(jsonEncode(message.toMap()));

    for (final device in _connectedDevices) {
      try {
        final services = await device.discoverServices();
        for (final service in services) {
          if (service.uuid.toString().toUpperCase().contains('FF00')) {
            for (final char in service.characteristics) {
              if (char.properties.write) {
                await char.write(data, withoutResponse: false);
              }
            }
          }
        }
      } catch (e) {
        // Device may have disconnected
        _connectedDevices.remove(device);
      }
    }
  }

  Future<void> stopScanning() async {
    await FlutterBluePlus.stopScan();
    _isScanning = false;
  }

  void dispose() {
    stopScanning();
    for (final device in _connectedDevices) {
      device.disconnect();
    }
    _sosController?.close();
  }
}

class SOSMessage {
  final String id;
  final String senderName;
  final String userId;
  final double heartRate;
  final double spo2;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  SOSMessage({
    required this.id,
    required this.senderName,
    required this.userId,
    required this.heartRate,
    required this.spo2,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory SOSMessage.fromMap(Map<String, dynamic> d) => SOSMessage(
        id: d['id'],
        senderName: d['senderName'],
        userId: d['userId'],
        heartRate: (d['heartRate'] as num).toDouble(),
        spo2: (d['spo2'] as num).toDouble(),
        latitude: (d['latitude'] as num).toDouble(),
        longitude: (d['longitude'] as num).toDouble(),
        timestamp: DateTime.parse(d['timestamp']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'senderName': senderName,
        'userId': userId,
        'heartRate': heartRate,
        'spo2': spo2,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp.toIso8601String(),
      };
}

final bluetoothMeshProvider = Provider<BluetoothMeshService>((ref) {
  final service = BluetoothMeshService();
  ref.onDispose(() => service.dispose());
  return service;
});
