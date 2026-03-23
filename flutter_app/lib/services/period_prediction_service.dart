import 'dart:math';
import '../models/user_model.dart';

class PeriodPredictionResult {
  final int daysUntil;
  final String phase;
  final double confidence;
  final List<String> insights;

  PeriodPredictionResult({
    required this.daysUntil,
    required this.phase,
    required this.confidence,
    required this.insights,
  });
}

class PeriodPredictionService {
  PeriodPredictionResult predict({
    required UserModel user,
    required double currentHR,
    required double currentHRV,
    required double tempFlux,
  }) {
    if (!user.isFemale || user.lastPeriodDate == null) {
      return PeriodPredictionResult(
        daysUntil: 0,
        phase: 'N/A',
        confidence: 0,
        insights: ['No period data available for this profile.'],
      );
    }

    final cycleDays = user.periodCycleDays ?? 28;
    final now = DateTime.now();
    final daysSinceLast = now.difference(user.lastPeriodDate!).inDays % cycleDays;
    
    // Mathematical prediction
    int predictedDaysUntil = cycleDays - daysSinceLast;
    
    // Determine biological phase based on history
    String phase = 'Follicular';
    if (daysSinceLast >= 1 && daysSinceLast <= 5) phase = 'Menstrual';
    else if (daysSinceLast >= 13 && daysSinceLast <= 15) phase = 'Ovulation';
    else if (daysSinceLast > 15) phase = 'Luteal';

    // Biomarker adjustments (Simplified for demo analytics)
    // Luteal phase usually has higher HR and lower HRV
    bool biomarkersSuggestLuteal = currentHR > 75 && currentHRV < 50 && tempFlux > 0.5;
    bool biomarkersSuggestFollicular = currentHR < 70 && currentHRV > 60;

    double confidence = 85.0; // Base confidence
    List<String> insights = [];

    if (phase == 'Luteal') {
      if (biomarkersSuggestLuteal) {
        confidence += 10;
        insights.add('Bio-rhythms confirm Luteal phase. Period likely in $predictedDaysUntil days.');
      } else {
        confidence -= 15;
        insights.add('Hormonal flux detected. Cycle may be slightly delayed.');
      }
    } else if (phase == 'Follicular') {
      if (biomarkersSuggestFollicular) {
        confidence += 5;
        insights.add('Vitals are stable. Cycle is in regular Follicular phase.');
      }
    }

    if (predictedDaysUntil <= 3) {
      insights.add('Dermal flux detected: Skin sensitivity increasing.');
    }

    return PeriodPredictionResult(
      daysUntil: max(0, predictedDaysUntil),
      phase: phase,
      confidence: confidence.clamp(0, 100),
      insights: insights,
    );
  }
}
