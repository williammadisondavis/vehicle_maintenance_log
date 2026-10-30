
class ServiceHistory {
  final String name;
  final int? lastMileage;
  final int interval;

  ServiceHistory({
    required this.name,
    required this.lastMileage,
    required this.interval,
  });
}

class MaintenanceResult {
  final String name;
  final int? lastMileage;
  final int interval;
  final int currentMileage;
  final int dueSoonMiles;

  MaintenanceResult({
    required this.name,
    required this.lastMileage,
    required this.interval,
    required this.currentMileage,
    required this.dueSoonMiles,
  });

  int? get nextMileage {
    if (lastMileage == null) return null;
    return lastMileage! + interval;
  }

  int? get milesLeft {
    if (nextMileage == null) return null;
    return nextMileage! - currentMileage;
  }

  String get status {
    if (milesLeft == null) return 'Not enough service history';
    if (milesLeft! < 0) return 'Overdue';
    if (milesLeft! <= dueSoonMiles) return 'Due soon';
    return 'Not due yet';
  }
}

List<MaintenanceResult> calculateMaintenance({
  required int currentMileage,
  required List<ServiceHistory> services,
  int dueSoonMiles = 500,
}) {
  if (currentMileage < 0 || dueSoonMiles < 0) {
    throw ArgumentError('Mileage cannot be negative');
  }

  final results = <MaintenanceResult>[];

  for (final service in services) {
    if (service.interval <= 0) {
      throw ArgumentError('Service interval must be greater than zero');
    }

    if (service.lastMileage != null &&
        (service.lastMileage! < 0 ||
            service.lastMileage! > currentMileage)) {
      throw ArgumentError('Invalid service mileage');
    }

    results.add(
      MaintenanceResult(
        name: service.name,
        lastMileage: service.lastMileage,
        interval: service.interval,
        currentMileage: currentMileage,
        dueSoonMiles: dueSoonMiles,
      ),
    );
  }

  results.sort((a, b) {
    if (a.milesLeft == null) return b.milesLeft == null ? 0 : 1;
    if (b.milesLeft == null) return -1;
    return a.milesLeft!.compareTo(b.milesLeft!);
  });

  return results;
}
