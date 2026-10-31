
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'maintenance_planner.dart';

class SavedPlannerScreen extends StatefulWidget {
  const SavedPlannerScreen({super.key});

  @override
  State<SavedPlannerScreen> createState() =>
      _SavedPlannerScreenState();
}

class _SavedPlannerScreenState extends State<SavedPlannerScreen> {
  final db = DatabaseHelper.instance;

  List<Map<String, Object?>> vehicles = [];
  List<Map<String, Object?>> services = [];
  List<MaintenanceResult> results = [];

  int? selectedVehicleId;
  bool loading = true;
  String? error;
  bool calculated = false;

  final intervals = <String, int>{
    'Oil Change': 5000,
    'Tire Rotation': 6000,
    'Brake Inspection': 12000,
    'Air Filter': 15000,
  };

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final savedVehicles = await db.getVehicles();
      final savedServices = await db.getServices();

      if (!mounted) return;

      setState(() {
        vehicles = savedVehicles;
        services = savedServices;
        if (!savedVehicles.any(
          (v) => v['id'] == selectedVehicleId,
        )) {
          selectedVehicleId = savedVehicles.isEmpty
              ? null
              : savedVehicles.first['id'] as int;
        }
        loading = false;
        error = null;
        calculated = false;
        results = [];
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = 'Could not load maintenance records: $e';
      });
    }
  }

  void calculate() {
    if (selectedVehicleId == null) return;

    final vehicle = vehicles.firstWhere(
      (v) => v['id'] == selectedVehicleId,
    );

    final mileage = vehicle['mileage'] as int;
    final history = <ServiceHistory>[];

    for (final entry in intervals.entries) {
      final matching = services.where(
        (service) =>
            service['vehicle_id'] == selectedVehicleId &&
            service['service_type'] == entry.key &&
            (service['mileage'] as int) <= mileage,
      );

      int? lastMileage;

      for (final service in matching) {
        final recordedMileage = service['mileage'] as int;

        if (lastMileage == null ||
            recordedMileage > lastMileage) {
          lastMileage = recordedMileage;
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
        currentMileage: mileage,
        services: history,
      );

      setState(() {
        results = answer;
        calculated = true;
        error = null;
      });
    } catch (e) {
      setState(() {
        error = 'Could not calculate maintenance: $e';
        calculated = false;
      });
    }
  }

  Widget resultCard(MaintenanceResult result) {
    final milesLeft = result.milesLeft;
    final status = result.status;

    String description;
    Color? color;

    if (milesLeft == null) {
      description = 'No previous service recorded';
    } else if (milesLeft < 0) {
      description = '${milesLeft.abs()} miles overdue';
      color = Colors.red;
    } else if (milesLeft <= 500) {
      description = '$milesLeft miles remaining';
      color = Colors.orange;
    } else {
      description = '$milesLeft miles remaining';
      color = Colors.green;
    }

    return Card(
      child: ListTile(
        leading: Icon(
          milesLeft == null
              ? Icons.help_outline
              : milesLeft <= 500
                  ? Icons.warning_amber
                  : Icons.check_circle_outline,
          color: color,
        ),
        title: Text(result.name),
        subtitle: Text(
          '$status\n'
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
      return const Center(child: CircularProgressIndicator());
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Add a vehicle first to calculate maintenance.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final selectedVehicle = vehicles.firstWhere(
      (v) => v['id'] == selectedVehicleId,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Maintenance Planner',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Check what services are coming up based on '
          'your saved vehicle mileage and maintenance records.',
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<int>(
          initialValue: selectedVehicleId,
          decoration: const InputDecoration(
            labelText: 'Select Vehicle',
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
              results = [];
              error = null;
            });
          },
        ),
        const SizedBox(height: 16),
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
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
        if (calculated) ...[
          const SizedBox(height: 20),
          Text(
            'Maintenance Results',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          for (final result in results)
            resultCard(result),
          const SizedBox(height: 12),
          const Text(
            'These are estimated maintenance intervals. '
            'Always follow your vehicle manufacturer\'s '
            'recommendations.',
          ),
        ],
      ],
    );
  }
}
