
import 'maintenance_planner.dart';

class MaintenanceSuggestion {
  final String service;
  final String message;
  final String reason;
  final int? milesLeft;
  final String priority;

  const MaintenanceSuggestion({
    required this.service,
    required this.message,
    required this.reason,
    required this.milesLeft,
    required this.priority,
  });
}

class SmartMaintenanceHelper {
  static MaintenanceSuggestion? recommend(
    List<MaintenanceResult> results, {
    int warningMiles = 500,
  }) {
    if (results.isEmpty) return null;

    final known = results
        .where((result) => result.milesLeft != null)
        .toList();

    if (known.isEmpty) return null;

    known.sort(
      (a, b) => a.milesLeft!.compareTo(b.milesLeft!),
    );

    final next = known.first;
    final remaining = next.milesLeft!;

    if (remaining < 0) {
      return MaintenanceSuggestion(
        service: next.name,
        message: 'Check ${next.name} soon',
        reason:
            'This service is ${remaining.abs()} miles past '
            'its estimated maintenance interval.',
        milesLeft: remaining,
        priority: 'Overdue',
      );
    }

    if (remaining <= warningMiles) {
      return MaintenanceSuggestion(
        service: next.name,
        message: 'Plan your next ${next.name}',
        reason:
            'This service is due in $remaining miles. '
            'Your warning distance is $warningMiles miles.',
        milesLeft: remaining,
        priority: 'Upcoming',
      );
    }

    return MaintenanceSuggestion(
      service: next.name,
      message: 'No immediate maintenance warning',
      reason:
          'The nearest recorded service is ${next.name}, '
          'estimated in $remaining miles.',
      milesLeft: remaining,
      priority: 'On track',
    );
  }

  static MaintenanceSuggestion? baseline(
    List<MaintenanceResult> results,
  ) {
    return recommend(results, warningMiles: 500);
  }
}
