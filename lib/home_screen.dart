
import 'package:flutter/material.dart';
import 'database_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final db = DatabaseHelper.instance;

  List<Map<String, Object?>> vehicles = [];
  List<Map<String, Object?>> services = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    try {
      final savedVehicles = await db.getVehicles();
      final savedServices = await db.getServices();

      if (!mounted) return;

      setState(() {
        vehicles = savedVehicles;
        services = savedServices;
        error = null;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = 'Could not load dashboard: $e';
        loading = false;
      });
    }
  }

  Widget summaryCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                setState(() => loading = true);
                loadDashboard();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final totalCost = services.fold<double>(
      0,
      (total, service) =>
          total + (service['cost'] as num).toDouble(),
    );

    return RefreshIndicator(
      onRefresh: loadDashboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Vehicle Maintenance Log',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Keep track of your vehicles, service history, '
            'and maintenance expenses.',
          ),
          const SizedBox(height: 20),
          summaryCard(
            'Vehicles',
            vehicles.length.toString(),
            Icons.directions_car,
          ),
          summaryCard(
            'Service Records',
            services.length.toString(),
            Icons.build,
          ),
          summaryCard(
            'Total Maintenance Cost',
            '\$${totalCost.toStringAsFixed(2)}',
            Icons.attach_money,
          ),
          const SizedBox(height: 20),
          Text(
            'Your Vehicles',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (vehicles.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No vehicles yet. Open the Vehicles tab to add one.',
                ),
              ),
            ),
          for (final vehicle in vehicles)
            Card(
              child: ListTile(
                leading: const Icon(Icons.directions_car),
                title: Text(
                  '${vehicle['year']} '
                  '${vehicle['make']} '
                  '${vehicle['model']}',
                ),
                subtitle: Text(
                  '${vehicle['mileage']} miles',
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'Recent Services',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (services.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No maintenance records added yet.'),
              ),
            ),
          for (final service in services.take(5))
            Card(
              child: ListTile(
                leading: const Icon(Icons.build_circle_outlined),
                title: Text(
                  service['service_type'] as String,
                ),
                subtitle: Text(
                  '${service['make']} ${service['model']}'
                  ' - ${service['service_date']}',
                ),
                trailing: Text(
                  '\$${(service['cost'] as num).toStringAsFixed(2)}',
                ),
              ),
            ),
          const SizedBox(height: 12),
          const Text(
            'Pull down to refresh the dashboard.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
