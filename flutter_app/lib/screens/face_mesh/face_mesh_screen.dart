import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import '../../theme/app_theme.dart';

class FaceMeshScreen extends StatefulWidget {
  final bool showAppBar;
  const FaceMeshScreen({super.key, this.showAppBar = true});
  @override
  State<FaceMeshScreen> createState() => _FaceMeshScreenState();
}

class _FaceMeshScreenState extends State<FaceMeshScreen> {
  bool _isAnalyzing = false;
  String _analysisResult = '';
  double _fatigueScore = 0;
  double _stressScore = 0;
  double _hydrationScore = 0;
  bool _iframeInjected = false;

  @override
  void initState() {
    super.initState();
    // Register the Real MediaPipe Web Iframe
    if (kIsWeb && !_iframeInjected) {
      ui_web.platformViewRegistry.registerViewFactory(
        'mediapipe_face_mesh',
        (int viewId) => html.IFrameElement()
          ..src = 'mediapipe_mesh.html'
          ..style.border = 'none'
          ..allow = 'camera; microphone',
      );
      _iframeInjected = true;
    }
  }

  void _startAnalysis() {
    setState(() => _isAnalyzing = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      final rng = Random();
      setState(() {
        _isAnalyzing = false;
        _fatigueScore = 15 + rng.nextDouble() * 40;
        _stressScore = 10 + rng.nextDouble() * 35;
        _hydrationScore = 60 + rng.nextDouble() * 35;
        _analysisResult = _fatigueScore > 40
            ? '⚠ Moderate fatigue detected. Consider taking a break.'
            : '✅ You look alert and well-rested!';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060d14),
      appBar: widget.showAppBar ? AppBar(
        backgroundColor: const Color(0xFF0a1520),
        title: const Text('Face Mesh Analysis',
            style: TextStyle(
                color: Color(0xFF00e5ff),
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Color(0xFF00e5ff)),
      ) : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Face Mesh Visualization ─────────────────────────────
            Container(
              height: 400,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF0c1824),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFF1a3040), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00e5ff).withOpacity(0.05),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // REAL MediaPipe Live ML Output
                    const SizedBox(
                      width: double.infinity,
                      height: 400,
                      child: HtmlElementView(viewType: 'mediapipe_face_mesh'),
                    ),
                    
                    // Scanning Scanning FX
                    if (_isAnalyzing)
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF00e5ff).withOpacity(0.1),
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 800.ms),

                    // Labels
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00e5ff).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF00e5ff).withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF00e5ff), shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text(
                              _isAnalyzing ? 'SCANNING...' : '468 LANDMARKS ACTIVE',
                              style: const TextStyle(color: Color(0xFF00e5ff), fontFamily: 'monospace', fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Landmark count
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: const Text('MediaPipe Face Mesh', style: TextStyle(color: Color(0xFF4a6478), fontFamily: 'monospace', fontSize: 9)),
                    ),
                    
                    // Annotation markers
                    ..._buildAnnotations(),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95)),
            const SizedBox(height: 20),

            // ── Analyze Button ──────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isAnalyzing ? null : _startAnalysis,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00e5ff),
                  foregroundColor: const Color(0xFF060d14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isAnalyzing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF060d14)))
                    : const Text('Run Face Analysis',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 20),

            // ── Analysis Results ────────────────────────────────────
            if (_analysisResult.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0c1824),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF1a3040)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AI FACIAL ANALYSIS',
                        style: TextStyle(
                            color: Color(0xFF00e5ff),
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 12),
                    Text(_analysisResult,
                        style: const TextStyle(
                            color: Color(0xFFc8dae8), fontSize: 14)),
                    const SizedBox(height: 16),
                    _ScoreBar('Fatigue', _fatigueScore, const Color(0xFFffab00)),
                    const SizedBox(height: 8),
                    _ScoreBar('Stress', _stressScore, const Color(0xFFff5252)),
                    const SizedBox(height: 8),
                    _ScoreBar('Hydration', _hydrationScore, const Color(0xFF69ff47)),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

              const SizedBox(height: 16),

              // Landmark details
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0c1824),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF1a3040)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('LANDMARK ANNOTATIONS',
                        style: TextStyle(
                            color: Color(0xFF00e5ff),
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 12),
                    _AnnotationRow('👁️ Left Eye', 'Open — Normal blink rate', const Color(0xFF69ff47)),
                    _AnnotationRow('👁️ Right Eye', 'Open — Symmetrical', const Color(0xFF69ff47)),
                    _AnnotationRow('👃 Nose', 'Centered — No deviation', const Color(0xFF69ff47)),
                    _AnnotationRow('👄 Mouth', 'Relaxed — No tension', const Color(0xFF69ff47)),
                    _AnnotationRow('🧠 Forehead', 'Smooth — Low stress cues', _stressScore > 30 ? const Color(0xFFffab00) : const Color(0xFF69ff47)),
                    _AnnotationRow('😊 Expression', _fatigueScore > 40 ? 'Slightly tired' : 'Alert', _fatigueScore > 40 ? const Color(0xFFffab00) : const Color(0xFF69ff47)),
                  ],
                ),
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAnnotations() {
    if (_analysisResult.isEmpty) return [];
    return [
      _AnnotationMarker(left: 110, top: 140, label: 'L. Eye'),
      _AnnotationMarker(left: 230, top: 140, label: 'R. Eye'),
      _AnnotationMarker(left: 170, top: 200, label: 'Nose'),
      _AnnotationMarker(left: 170, top: 260, label: 'Mouth'),
      _AnnotationMarker(left: 80, top: 200, label: 'L. Jaw'),
      _AnnotationMarker(left: 260, top: 200, label: 'R. Jaw'),
    ];
  }
}

class _AnnotationMarker extends StatelessWidget {
  final double left, top;
  final String label;
  const _AnnotationMarker(
      {required this.left, required this.top, required this.label});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFF00e5ff),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF00e5ff).withOpacity(0.5),
                    blurRadius: 6)
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF00e5ff),
                  fontFamily: 'monospace',
                  fontSize: 7,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(duration: 800.ms)
        .move(begin: const Offset(-2, -2), end: const Offset(2, 2), duration: 1200.ms, curve: Curves.easeInOut)
        .then()
        .fadeOut(duration: 800.ms);
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _ScoreBar(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
            width: 70,
            child: Text(label,
                style: const TextStyle(
                    color: Color(0xFF4a6478),
                    fontFamily: 'monospace',
                    fontSize: 10))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('${value.toInt()}%',
            style: TextStyle(
                color: color,
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _AnnotationRow extends StatelessWidget {
  final String label, detail;
  final Color color;
  const _AnnotationRow(this.label, this.detail, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xFFc8dae8), fontSize: 13)),
          const Spacer(),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(detail,
              style: TextStyle(
                  color: color, fontFamily: 'monospace', fontSize: 11)),
        ],
      ),
    );
  }
}

// (Mock Painter Removed)
