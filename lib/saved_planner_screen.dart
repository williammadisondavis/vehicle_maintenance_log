
import 'package:flutter/material.dart';

import 'database_helper.dart';
import 'maintenance_planner.dart';
import 'settings_screen.dart';
import 'smart_helper.dart';

class SavedPlannerScreen extends StatefulWidget {
  const SavedPlannerScreen({super.key});

  @override
  State<SavedPlannerScreen> createState() => _SavedPlannerScreenState();
}

class _SavedPlannerScreenState extends State<SavedPlannerScreen> {
  final db = DatabaseHelper.instance;
  final settings = AppSettings.instance;

  List<Map<String, Object?>> vehicles = [];
  List<Map<String, Object?>> services = [];
  List<MaintenanceResult> results = [];

  int? selectedVehicleId;
  double? temporaryWarningMiles;
  bool loading = true;
  bool calculated = false;
  bool dismissed = false;
  String? error;

  final intervals = <String, int>{
    'Oil Change': 5000,
    'Tire Rotation': 6000,
    'Brake Inspection': 12000,
    'Air Filter': 15000,
  };

  int get warningMiles =>
      (temporaryWarningMiles ?? settings.warningMiles).round();

  @override
  void initState() {
    super.initState();
    settings.addListener(refresh);
    loadData();
  }

  @override
  void dispose() {
    settings.removeListener(refresh);
    super.dispose();
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  Future<void> loadData() async {
    try {
      final savedVehicles = await db.getVehicles();
      final savedServices = await db.getServices();

      if (!mounted) return;

      setState(() {
        vehicles = savedVehicles;
        services = savedServices;

        if (!vehicles.any(
          (vehicle) => vehicle['id'] == selectedVehicleId,
        )) {
          selectedVehicleId = vehicles.isEmpty
              ? null
              : vehicles.first['id'] as int;
        }

        loading = false;
        calculated = false;
        dismissed = false;
        results = [];
        error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = 'Could not load saved records: $e';
      });
    }
  }

  void calculate() {
    if (selectedVehicleId == null) return;

    final vehicle = vehicles.firstWhere(
      (item) => item['id'] == selectedVehicleId,
    );

    final currentMileage = vehicle['mileage'] as int;
    final history = <ServiceHistory>[];

    for (final entry in intervals.entries) {
      int? lastMileage;

      for (final service in services) {
        if (service['vehicle_id'] != selectedVehicleId ||
            service['service_type'] != entry.key) {
          continue;
        }

        final serviceMileage = service['mileage'] as int;

        if (serviceMileage > currentMileage) continue;

        if (lastMileage == null ||
            serviceMileage > lastMileage) {
          lastMileage = serviceMileage;
        }
      }

      history.add(
        ServiceHistory(
          name: entry.key,
          lastMileage: lastMileage,
          interval: entry.value,
        ),
      );
    }

    try {
      final answer = calculateMaintenance(
        currentMileage: currentMileage,
        services: history,
      );

      setState(() {
        results = answer;
        calculated = true;
        dismissed = false;
        error = null;
      });
    } catch (e) {
      setState(() {
        calculated = false;
        error = 'Calculation failed: $e';
      });
    }
  }

  Widget suggestionCard(MaintenanceSuggestion suggestion) {
    final urgent = suggestion.priority == 'Overdue';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  urgent
                      ? Icons.warning_amber
                      : Icons.tips_and_updates_outlined,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Maintenance Suggestion',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              suggestion.message,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(suggestion.reason),
            const SizedBox(height: 8),
            Text('Status: ${suggestion.priority}'),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  dismissed = true;
                });
              },
              icon: const Icon(Icons.close),
              label: const Text('Dismiss Suggestion'),
            ),
          ],
        ),
      ),
    );
  }

  Widget resultCard(MaintenanceResult result) {
    final milesLeft = result.milesLeft;
    String description;

    if (milesLeft == null) {
      description = 'No service history recorded';
    } else if (milesLeft < 0) {
      description = '${milesLeft.abs()} miles overdue';
    } else {
      description = '$milesLeft miles remaining';
    }

    return Card(
      child: ListTile(
        leading: Icon(
          milesLeft == null
              ? Icons.help_outline
              : milesLeft <= warningMiles
                  ? Icons.warning_amber
                  : Icons.check_circle_outline,
        ),
        title: Text(result.name),
        subtitle: Text(
          '${result.status}\n'
          '$description\n'
          '${result.nextMileage == null ? "Next due: unknown" : "Next due: ${result.nextMileage} miles"}',
        ),
        isThreeLine: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null && vehicles.isEmpty) {
      return Center(
        child: FilledButton(
          onPressed: () {
            setState(() => loading = true);
            loadData();
          },
          child: const Text('Retry Loading Data'),
        ),
      );
    }

    if (vehicles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add a vehicle to start planning.'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                setState(() => loading = true);
                loadData();
              },
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    final selectedVehicle = vehicles.firstWhere(
      (item) => item['id'] == selectedVehicleId,
    );

    final suggestion = calculated
        ? SmartMaintenanceHelper.recommend(
            results,
            warningMiles: warningMiles,
          )
        : null;

    final baseline = calculated
        ? SmartMaintenanceHelper.baseline(results)
        : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Maintenance Planner',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Check upcoming maintenance using saved '
          'vehicle mileage and service records.',
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<int>(
          key: ValueKey(selectedVehicleId),
          initialValue: selectedVehicleId,
          decoration: const InputDecoration(
            labelText: 'Vehicle',
            border: OutlineInputBorder(),
          ),
          items: vehicles.map((vehicle) {
            return DropdownMenuItem<int>(
              value: vehicle['id'] as int,
              child: Text(
                '${vehicle['year']} '
                '${vehicle['make']} '
                '${vehicle['model']}',
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedVehicleId = value;
              calculated = false;
              dismissed = false;
              results = [];
            });
          },
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.speed),
            title: const Text('Current Mileage'),
            subtitle: Text(
              '${selectedVehicle['mileage']} miles',
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: calculate,
          icon: const Icon(Icons.calculate),
          label: const Text('Check Maintenance'),
        ),
        TextButton.icon(
          onPressed: () {
            setState(() => loading = true);
            loadData();
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Reload Saved Data'),
        ),
        if (error != null)
          Text(
            error!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        if (calculated) ...[
          const SizedBox(height: 18),
          Text(
            'Maintenance Results',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          for (final result in results)
            resultCard(result),
          const SizedBox(height: 16),
          if (settings.maintenanceReminders) ...[
            Text(
              'Smart Maintenance Helper',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (suggestion == null)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Not enough service history for a '
                    'recommendation. Add a maintenance record first.',
                  ),
                ),
              )
            else if (dismissed)
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => dismissed = false);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Show Suggestion Again'),
              )
            else
              suggestionCard(suggestion),
            const SizedBox(height: 16),
            Text(
              'Warning Distance: $warningMiles miles',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: warningMiles.toDouble(),
              min: 100,
              max: 2000,
              divisions: 19,
              label: '$warningMiles miles',
              onChanged: (value) {
                setState(() {
                  temporaryWarningMiles = value;
                  dismissed = false;
                });
              },
            ),
            const Text(
              'This overrides the warning distance for this '
              'screen only. Your saved setting is not changed.',
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  temporaryWarningMiles = null;
                  dismissed = false;
                });
              },
              child: const Text('Use Saved Warning Distance'),
            ),
            const SizedBox(height: 12),
            Text(
              'Helper Comparison',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Fixed 500-mile baseline: '
              '${baseline?.priority ?? "Not enough data"}',
            ),
            Text(
              'Adjustable helper ($warningMiles miles): '
              '${suggestion?.priority ?? "Not enough data"}',
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            'Estimates are based on example service '
            'intervals, not a vehicle-specific manual. '
            'The helper runs locally and does not '
            'automatically change maintenance records.',
          ),
        ],
      ],
    );
  }
}
