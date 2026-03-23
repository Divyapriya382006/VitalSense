import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VoiceService {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _sttAvailable = false;
  bool _isSpeaking = false;
  bool _isListening = false;

  Future<void> init() async {
    // TTS setup
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.85);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setStartHandler(() => _isSpeaking = true);
    _tts.setCompletionHandler(() => _isSpeaking = false);
    _tts.setErrorHandler((msg) => _isSpeaking = false);

    // STT setup
    _sttAvailable = await _stt.initialize(
      onError: (error) => _isListening = false,
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _isListening = false;
        }
      },
    );
  }

  bool get isSpeaking => _isSpeaking;
  bool get isListening => _isListening;
  bool get sttAvailable => _sttAvailable;

  /// Speak a vital alert message
  Future<void> speakAlert(String message) async {
    if (_isSpeaking) await _tts.stop();
    await _tts.speak(message);
  }

  /// Speak a general message
  Future<void> speak(String text) async {
    if (_isSpeaking) await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
  }

  /// Generate alert text from vitals
  String buildAlertMessage({
    required double heartRate,
    required double spo2,
    required double temperature,
    required String severity,
  }) {
    final alerts = <String>[];

    if (heartRate > 110) {
      alerts.add('Heart rate is critically high at ${heartRate.toInt()} beats per minute');
    } else if (heartRate < 50) {
      alerts.add('Heart rate is dangerously low at ${heartRate.toInt()} beats per minute');
    }

    if (spo2 < 90) {
      alerts.add('Oxygen saturation is critically low at ${spo2.toInt()} percent');
    } else if (spo2 < 94) {
      alerts.add('Oxygen saturation is below normal at ${spo2.toInt()} percent');
    }

    if (temperature > 38.5) {
      alerts.add('Body temperature is elevated at ${temperature.toStringAsFixed(1)} degrees Celsius');
    } else if (temperature < 36.0) {
      alerts.add('Body temperature is dangerously low at ${temperature.toStringAsFixed(1)} degrees Celsius');
    }

    if (alerts.isEmpty) return '';

    final intro = severity == 'critical'
        ? 'Warning! Emergency health alert. '
        : 'Health alert. ';

    final body = alerts.join('. ');
    final action = severity == 'critical'
        ? ' Please seek immediate medical attention or call emergency services.'
        : ' Please rest and monitor your vitals closely.';

    return '$intro$body.$action';
  }

  /// Start listening for speech input
  Future<void> startListening({
    required Function(String text) onResult,
    required Function() onListenStart,
  }) async {
    if (!_sttAvailable || _isListening) return;

    _isListening = true;
    onListenStart();

    await _stt.listen(
      onResult: (result) {
        if (result.finalResult) {
          _isListening = false;
          onResult(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: false,
      localeId: 'en_US',
      cancelOnError: true,
    );
  }

  Future<void> stopListening() async {
    await _stt.stop();
    _isListening = false;
  }

  void dispose() {
    _tts.stop();
    _stt.cancel();
  }
}

final voiceServiceProvider = Provider<VoiceService>((ref) {
  final service = VoiceService();
  service.init();
  ref.onDispose(() => service.dispose());
  return service;
});
