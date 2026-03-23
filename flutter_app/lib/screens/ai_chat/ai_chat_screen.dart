import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dio/dio.dart';
import '../../theme/app_theme.dart';
import '../../services/voice_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vitals_provider.dart';

class _ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  _ChatMessage({required this.content, required this.isUser, required this.timestamp});
}

class AIChatScreen extends ConsumerStatefulWidget {
  final bool showAppBar;
  const AIChatScreen({super.key, this.showAppBar = true});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isListening = false;

  // TODO: Replace with your actual Claude API key before demo
  static const String _apiKey = 'API_KEY_PLACEHOLDER';
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages.add(_ChatMessage(
      content: "Hello! I'm your VitalSense AI health assistant. I can analyze your vitals, answer health questions, and help you understand your health data. How can I help you today?",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final user = ref.read(currentUserProvider).valueOrNull;
    final latestVital = ref.read(latestVitalProvider(user?.uid ?? '')).valueOrNull;

    setState(() {
      _messages.add(_ChatMessage(content: text, isUser: true, timestamp: DateTime.now()));
      _isLoading = true;
      _inputController.clear();
    });
    _scrollToBottom();

    final vitalContext = latestVital != null
        ? '''
Current patient vitals:
- Heart Rate: ${latestVital.heartRate.toInt()} BPM (${latestVital.heartRateStatus.name})
- SpO₂: ${latestVital.spo2.toInt()}% (${latestVital.spo2Status.name})
- Temperature: ${latestVital.temperature.toStringAsFixed(1)}°C (${latestVital.temperatureStatus.name})
- PHI Score: ${latestVital.phiScore.toInt()}/100
- Stress Level: ${latestVital.stressLevel?.toInt() ?? 'N/A'}%
- HRV: ${latestVital.hrv?.toInt() ?? 'N/A'} ms
'''
        : 'No current vitals available.';

    final userContext = user != null
        ? 'Patient: ${user.name}, Age: ${user.age}, BMI: ${user.bmi} (${user.bmiCategory}), Athletic: ${user.isAthletic}'
        : '';

    // If API key not set, use offline fallback response
    if (_apiKey == 'API_KEY_PLACEHOLDER') {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(
            content: _offlineFallbackResponse(text, latestVital),
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
      return;
    }

    try {
      final dio = Dio();
      final response = await dio.post(
        _apiUrl,
        options: Options(headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        }),
        data: jsonEncode({
          'model': 'claude-opus-4-6',
          'max_tokens': 600,
          'system': '''You are VitalSense AI, an intelligent health assistant integrated into a medical vitals monitoring app.
You have access to real-time patient vitals and provide clear, helpful, empathetic health guidance.
Always remind users to consult a doctor for serious concerns. Keep responses concise and clear.
$userContext
$vitalContext''',
          'messages': [
            ..._messages
                .where((m) => m.isUser || _messages.indexOf(m) > 0)
                .take(10)
                .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.content}),
            {'role': 'user', 'content': text},
          ],
        }),
      );

      final reply = response.data['content'][0]['text'] as String;

      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(content: reply, isUser: false, timestamp: DateTime.now()));
          _isLoading = false;
        });
        _scrollToBottom();
        final voice = ref.read(voiceServiceProvider);
        await voice.speak(reply);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(
            content: _offlineFallbackResponse(text, latestVital),
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
      }
    }
  }

  String _offlineFallbackResponse(String query, dynamic vital) {
    final q = query.toLowerCase();
    if (q.contains('heart') || q.contains('hr') || q.contains('bpm')) {
      return vital != null
          ? 'Your current heart rate is ${vital.heartRate.toInt()} BPM. ${vital.heartRate > 100 ? "This is slightly elevated. Try to rest and take deep breaths." : vital.heartRate < 60 ? "This is below average resting rate." : "This is within the normal range of 60–100 BPM. ✅"}'
          : 'Normal resting heart rate is 60–100 BPM. Athletes may have lower rates naturally.';
    }
    if (q.contains('spo2') || q.contains('oxygen')) {
      return vital != null
          ? 'Your SpO₂ is ${vital.spo2.toInt()}%. ${vital.spo2 < 95 ? "This is below normal. Try breathing fresh air and sitting upright." : "Normal! Healthy SpO₂ is 95–100%. ✅"}'
          : 'Normal SpO₂ is 95–100%. Below 90% requires immediate medical attention.';
    }
    if (q.contains('stress') || q.contains('hrv')) {
      return vital != null && vital.stressLevel != null
          ? 'Your current stress level is ${vital.stressLevel!.toInt()}%. ${vital.stressLevel! > 60 ? "High stress detected. Try meditation, deep breathing, or a short walk." : "Your stress levels look manageable. ✅"}'
          : 'HRV (Heart Rate Variability) is a key indicator of stress. Higher HRV generally means lower stress.';
    }
    if (q.contains('phi') || q.contains('score') || q.contains('health')) {
      return vital != null
          ? 'Your Personal Health Index (PHI) is ${vital.phiScore.toInt()}/100. ${vital.phiScore >= 75 ? "Excellent health status! Keep it up. ✅" : vital.phiScore >= 50 ? "Good but some vitals need monitoring." : "Some vitals need attention. Please consult your doctor."}'
          : 'The PHI score is a composite 0–100 score calculated from all your vitals using ML analysis.';
    }
    if (q.contains('water') || q.contains('hydrat')) {
      return 'You should drink at least 8 glasses (2 litres) of water daily. If you are active or in a hot climate, aim for 3 litres. Hydration directly affects your heart rate and temperature readings.';
    }
    return vital != null
        ? 'Based on your current vitals — HR: ${vital.heartRate.toInt()} BPM, SpO₂: ${vital.spo2.toInt()}%, Temp: ${vital.temperature.toStringAsFixed(1)}°C — your PHI score is ${vital.phiScore.toInt()}/100. ${vital.phiScore >= 75 ? "You are in good health!" : "Some parameters need attention. Please consult your doctor."}'
        : 'I am your VitalSense health assistant. Connect your sensors or use the face scan to get real-time vitals analysis. I can then give you personalized health insights!';
  }

  void _startVoiceInput() async {
    final voice = ref.read(voiceServiceProvider);
    await voice.startListening(
      onResult: (text) {
        if (text.isNotEmpty) {
          _inputController.text = text;
          _sendMessage(text);
        }
        setState(() => _isListening = false);
      },
      onListenStart: () => setState(() => _isListening = true),
    );
  }

  void _stopVoiceInput() async {
    final voice = ref.read(voiceServiceProvider);
    await voice.stopListening();
    setState(() => _isListening = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: widget.showAppBar ? AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: VitalSenseTheme.primaryBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy_rounded, color: VitalSenseTheme.primaryBlue, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('VitalSense AI', style: TextStyle(fontSize: 16)),
                Text(
                  _apiKey == 'API_KEY_PLACEHOLDER' ? 'Offline Mode' : 'Online',
                  style: TextStyle(
                    fontSize: 11,
                    color: _apiKey == 'API_KEY_PLACEHOLDER' ? Colors.orange : VitalSenseTheme.primaryGreen,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_rounded),
            onPressed: () async {
              final voice = ref.read(voiceServiceProvider);
              if (voice.isSpeaking) await voice.stop();
            },
          ),
        ],
      ) : null,
      body: Column(
        children: [
          // Quick prompts
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                _QuickPrompt('Analyze vitals', Icons.analytics_rounded,
                    () => _sendMessage('Analyze my current vitals')),
                _QuickPrompt('Stress tips', Icons.self_improvement_rounded,
                    () => _sendMessage('Tips to reduce stress')),
                _QuickPrompt('Heart health', Icons.favorite_rounded,
                    () => _sendMessage('How is my heart health?')),
                _QuickPrompt('Water intake', Icons.water_drop_rounded,
                    () => _sendMessage('How much water should I drink?')),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length) return _TypingIndicator();
                final msg = _messages[i];
                return _MessageBubble(message: msg)
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.1);
              },
            ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            decoration: BoxDecoration(
              color: isDark ? VitalSenseTheme.darkSurface : VitalSenseTheme.lightSurface,
              border: Border(
                top: BorderSide(
                  color: isDark ? VitalSenseTheme.darkBorder : VitalSenseTheme.lightBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onLongPress: _startVoiceInput,
                  onLongPressEnd: (_) => _stopVoiceInput(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _isListening ? VitalSenseTheme.alertRed.withOpacity(0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none_rounded,
                      color: _isListening ? VitalSenseTheme.alertRed : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    decoration: InputDecoration(
                      hintText: _isListening ? 'Listening...' : 'Ask about your health...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _sendMessage(_inputController.text),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: VitalSenseTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: VitalSenseTheme.primaryBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy_rounded, color: VitalSenseTheme.primaryBlue, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? VitalSenseTheme.primaryBlue
                    : isDark ? VitalSenseTheme.darkCard : VitalSenseTheme.lightCard,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: !isUser
                    ? Border.all(color: isDark ? VitalSenseTheme.darkBorder : VitalSenseTheme.lightBorder)
                    : null,
              ),
              child: Text(message.content, style: TextStyle(color: isUser ? Colors.white : null, fontSize: 14, height: 1.5)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: VitalSenseTheme.darkCard, borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 6, height: 6,
                decoration: const BoxDecoration(color: VitalSenseTheme.primaryBlue, shape: BoxShape.circle),
              ).animate(delay: (i * 200).ms, onPlay: (c) => c.repeat(reverse: true))
                  .scaleY(begin: 0.5, end: 1.5)),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickPrompt extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickPrompt(this.label, this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: VitalSenseTheme.primaryBlue.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(20),
          color: VitalSenseTheme.primaryBlue.withOpacity(0.07),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: VitalSenseTheme.primaryBlue),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12, color: VitalSenseTheme.primaryBlue, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
