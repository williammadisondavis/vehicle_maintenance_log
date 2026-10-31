
import 'package:flutter/material.dart';

class Vehicle {
  final int id;
  final String make;
  final String model;
  final int year;
  final int mileage;

  const Vehicle({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.mileage,
  });
}

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  final List<Vehicle> vehicles = [];
  int nextId = 1;

  Future<void> showVehicleForm({Vehicle? vehicle}) async {
    final makeController = TextEditingController(
      text: vehicle?.make ?? '',
    );
    final modelController = TextEditingController(
      text: vehicle?.model ?? '',
    );
    final yearController = TextEditingController(
      text: vehicle?.year.toString() ?? '',
    );
    final mileageController = TextEditingController(
      text: vehicle?.mileage.toString() ?? '',
    );

    final formKey = GlobalKey<FormState>();
    final isEditing = vehicle != null;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(isEditing ? 'Edit Vehicle' : 'Add Vehicle'),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: makeController,
                        decoration: const InputDecoration(
                          labelText: 'Make',
                          hintText: 'Toyota',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter a make';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: modelController,
                        decoration: const InputDecoration(
                          labelText: 'Model',
                          hintText: 'Camry',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter a model';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: yearController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Year',
                          hintText: '2020',
                        ),
                        validator: (value) {
                          final year = int.tryParse(value ?? '');
                          final maximum = DateTime.now().year + 1;

                          if (year == null ||
                              year < 1886 ||
                              year > maximum) {
                            return 'Enter a valid year';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: mileageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Current Mileage',
                          hintText: '50000',
                        ),
                        validator: (value) {
                          final mileage = int.tryParse(value ?? '');
                          if (mileage == null || mileage < 0) {
                            return 'Enter valid mileage';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;

                  final updatedVehicle = Vehicle(
                    id: vehicle?.id ?? nextId++,
                    make: makeController.text.trim(),
                    model: modelController.text.trim(),
                    year: int.parse(yearController.text.trim()),
                    mileage: int.parse(
                      mileageController.text.trim(),
                    ),
                  );

                  setState(() {
                    if (isEditing) {
                      final index = vehicles.indexWhere(
                        (item) => item.id == vehicle.id,
                      );
                      if (index != -1) {
                        vehicles[index] = updatedVehicle;
                      }
                    } else {
                      vehicles.add(updatedVehicle);
                    }
                  });

                  Navigator.pop(dialogContext);
                },
                child: Text(isEditing ? 'Save' : 'Add'),
              ),
            ],
          );
        },
      );
    } finally {
      // Wait until the dialog's exit animation finishes.
      await Future<void>.delayed(
        const Duration(milliseconds: 300),
      );
      makeController.dispose();
      modelController.dispose();
      yearController.dispose();
      mileageController.dispose();
    }
  }

  Future<void> deleteVehicle(Vehicle vehicle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Vehicle?'),
          content: Text(
            'Remove ${vehicle.year} ${vehicle.make} '
            '${vehicle.model}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      setState(() {
        vehicles.removeWhere((item) => item.id == vehicle.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: vehicles.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.directions_car,
                    size: 70,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  const Text('No vehicles added yet'),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap the button below to add your first vehicle.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => showVehicleForm(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Vehicle'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];

                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.directions_car),
                    ),
                    title: Text(
                      '${vehicle.year} ${vehicle.make} ${vehicle.model}',
                    ),
                    subtitle: Text(
                      '${vehicle.mileage} miles',
                    ),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Vehicle options',
                      onSelected: (action) {
                        if (action == 'edit') {
                          showVehicleForm(vehicle: vehicle);
                        } else if (action == 'delete') {
                          deleteVehicle(vehicle);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: vehicles.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => showVehicleForm(),
              tooltip: 'Add vehicle',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
