
import 'package:flutter/material.dart';

import 'database_helper.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final db = DatabaseHelper.instance;
  final settings = AppSettings.instance;

  List<Map<String, Object?>> vehicles = [];
  List<Map<String, Object?>> services = [];

  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    settings.addListener(refresh);
    loadDashboard();
  }

  @override
  void dispose() {
    settings.removeListener(refresh);
    super.dispose();
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  Future<void> loadDashboard() async {
    try {
      final savedVehicles = await db.getVehicles();
      final savedServices = await db.getServices();

      if (!mounted) return;

      setState(() {
        vehicles = savedVehicles;
        services = savedServices;
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = 'Could not load dashboard: $e';
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
                  Text(title),
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
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null) {
      return Center(
        child: FilledButton(
          onPressed: () {
            setState(() => loading = true);
            loadDashboard();
          },
          child: const Text('Retry Loading Dashboard'),
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
            'Your vehicles and maintenance at a glance.',
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
          if (settings.showCosts)
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
          if (vehicles.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No vehicles yet. Add one in the Vehicles tab.',
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
          if (services.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No service records yet.'),
              ),
            ),
          for (final service in services.take(5))
            Card(
              child: ListTile(
                leading: const Icon(Icons.build_circle_outlined),
                title: Text(service['service_type'] as String),
                subtitle: Text(
                  '${service['make']} ${service['model']}'
                  ' - ${service['service_date']}',
                ),
                trailing: settings.showCosts
                    ? Text(
                        '\$${(service['cost'] as num).toStringAsFixed(2)}',
                      )
                    : null,
              ),
            ),
          const SizedBox(height: 16),
          const Text(
            'Pull down to refresh after adding or editing records.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
