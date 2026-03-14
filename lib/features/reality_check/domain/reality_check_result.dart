class RealityCheckResult {
  final int brainRotScore;
  final Map<String, double> categoryPercentages;
  final String status; // Healthy / Caution / Danger
  final String message;
  final bool shouldSuggestReset;

  RealityCheckResult({
    required this.brainRotScore,
    required this.categoryPercentages,
    required this.status,
    required this.message,
    required this.shouldSuggestReset,
  });
}
