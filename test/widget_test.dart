
import 'package:flutter_test/flutter_test.dart';
import 'package:vehicle_maintenance_log/maintenance_planner.dart';

void main() {
  test('Oil change due soon', () {
    final results = calculateMaintenance(
      currentMileage: 100000,
      services: [
        ServiceHistory(
          name: 'Oil Change',
          lastMileage: 95400,
          interval: 5000,
        ),
      ],
    );

    expect(results.first.milesLeft, 400);
    expect(results.first.status, 'Due soon');
  });

  test('Oil change overdue', () {
    final results = calculateMaintenance(
      currentMileage: 101000,
      services: [
        ServiceHistory(
          name: 'Oil Change',
          lastMileage: 95400,
          interval: 5000,
        ),
      ],
    );

    expect(results.first.milesLeft, -600);
    expect(results.first.status, 'Overdue');
  });
}
