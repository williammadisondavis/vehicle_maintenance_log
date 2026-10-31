
import 'package:flutter/material.dart';
import 'maintenance_planner.dart';
import 'vehicles_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vehicle Maintenance Log',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const AppNavigation(),
    );
  }
}

class AppNavigation extends StatefulWidget {
  const AppNavigation({super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  int selectedIndex = 0;

  final pages = const [
    HomeScreen(),
    VehiclesScreen(),
    ServicesScreen(),
    MaintenancePage(),
    SettingsScreen(),
  ];

  final titles = const [
    'Home',
    'Vehicles',
    'Service History',
    'Maintenance Planner',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[selectedIndex]),
        backgroundColor:
            Theme.of(context).colorScheme.primaryContainer,
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            label: 'Vehicles',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            label: 'Services',
          ),
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            label: 'Planner',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: ListTile(
        leading: Icon(Icons.directions_car),
        title: Text('Vehicle Maintenance Log'),
        subtitle: Text(
          'Track your vehicles and upcoming maintenance.',
        ),
      ),
    );
  }
}

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Service history will be added next.'),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Settings will be added here.'),
    );
  }
}

class MaintenancePage extends StatefulWidget {
  const MaintenancePage({super.key});

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  final mileageController =
      TextEditingController(text: '100000');
  final oilController =
      TextEditingController(text: '95400');
  final tireController =
      TextEditingController(text: '94000');
  final oilIntervalController =
      TextEditingController(text: '5000');
  final tireIntervalController =
      TextEditingController(text: '6000');

  List<MaintenanceResult> results = [];
  String? errorMessage;
  bool calculated = false;

  @override
  void dispose() {
    mileageController.dispose();
    oilController.dispose();
    tireController.dispose();
    oilIntervalController.dispose();
    tireIntervalController.dispose();
    super.dispose();
  }

  void calculate() {
    final mileage =
        int.tryParse(mileageController.text.trim());
    final oil = oilController.text.trim();
    final tires = tireController.text.trim();

    final oilMileage = int.tryParse(oil);
    final tireMileage = int.tryParse(tires);
    final oilInterval =
        int.tryParse(oilIntervalController.text.trim());
    final tireInterval =
        int.tryParse(tireIntervalController.text.trim());

    if (mileage == null ||
        oilInterval == null ||
        tireInterval == null ||
        (oil.isNotEmpty && oilMileage == null) ||
        (tires.isNotEmpty && tireMileage == null)) {
      setState(() {
        errorMessage = 'Please enter valid whole numbers.';
        calculated = false;
      });
      return;
    }

    try {
      final answer = calculateMaintenance(
        currentMileage: mileage,
        services: [
          ServiceHistory(
            name: 'Oil Change',
            lastMileage: oilMileage,
            interval: oilInterval,
          ),
          ServiceHistory(
            name: 'Tire Rotation',
            lastMileage: tireMileage,
            interval: tireInterval,
          ),
        ],
      );

      setState(() {
        results = answer;
        errorMessage = null;
        calculated = true;
      });
    } on ArgumentError catch (error) {
      setState(() {
        errorMessage = error.message.toString();
        calculated = false;
      });
    }
  }

  Widget numberField(
    String label,
    TextEditingController controller,
  ) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget serviceCard(
    String title,
    TextEditingController lastMileage,
    TextEditingController interval,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            numberField(
              'Last service mileage',
              lastMileage,
            ),
            const SizedBox(height: 12),
            numberField(
              'Service interval (miles)',
              interval,
            ),
          ],
        ),
      ),
    );
  }

  Widget resultCard(MaintenanceResult result) {
    final milesLeft = result.milesLeft;

    String details;

    if (milesLeft == null) {
      details = 'Add service history to calculate.';
    } else if (milesLeft < 0) {
      details = '${milesLeft.abs()} miles overdue';
    } else {
      details = '$milesLeft miles remaining';
    }

    return Card(
      child: ListTile(
        title: Text(result.name),
        subtitle: Text(
          '${result.status}\n'
          '$details\n'
          '${result.lastMileage == null ? "No service history" : "Last service: ${result.lastMileage} miles"}\n'
          '${result.nextMileage == null ? "Next service: unknown" : "Next service: ${result.nextMileage} miles"}',
        ),
        isThreeLine: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              Text(
                'Maintenance Planner',
                style:
                    Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your mileage to see what maintenance is due next.',
              ),
              const SizedBox(height: 8),
              const Text(
                'Sample mileage is filled in for testing. Nothing is saved yet.',
              ),
              const SizedBox(height: 20),
              numberField(
                'Current vehicle mileage',
                mileageController,
              ),
              const SizedBox(height: 16),
              serviceCard(
                'Oil Change',
                oilController,
                oilIntervalController,
              ),
              const SizedBox(height: 12),
              serviceCard(
                'Tire Rotation',
                tireController,
                tireIntervalController,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: calculate,
                child: const Text('Check Maintenance'),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              if (calculated) ...[
                const SizedBox(height: 24),
                Text(
                  'Maintenance Results',
                  style:
                      Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                for (final result in results)
                  resultCard(result),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
