
import 'package:flutter/material.dart';
import 'database_helper.dart';

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

  factory Vehicle.fromMap(Map<String, Object?> map) {
    return Vehicle(
      id: map['id'] as int,
      make: map['make'] as String,
      model: map['model'] as String,
      year: map['year'] as int,
      mileage: map['mileage'] as int,
    );
  }
}

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  final DatabaseHelper db = DatabaseHelper.instance;

  List<Vehicle> vehicles = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadVehicles();
  }

  Future<void> loadVehicles() async {
    try {
      final rows = await db.getVehicles();

      if (!mounted) return;

      setState(() {
        vehicles = rows.map(Vehicle.fromMap).toList();
        isLoading = false;
        errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Could not load vehicles: $error';
      });
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

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
          bool saving = false;

          return StatefulBuilder(
            builder: (context, updateDialog) {
              return AlertDialog(
                title: Text(
                  isEditing ? 'Edit Vehicle' : 'Add Vehicle',
                ),
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
                              if (value == null ||
                                  value.trim().isEmpty) {
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
                              if (value == null ||
                                  value.trim().isEmpty) {
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
                            ),
                            validator: (value) {
                              final year = int.tryParse(
                                value?.trim() ?? '',
                              );

                              if (year == null ||
                                  year < 1886 ||
                                  year > DateTime.now().year + 1) {
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
                            ),
                            validator: (value) {
                              final mileage = int.tryParse(
                                value?.trim() ?? '',
                              );

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
                    onPressed: saving
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) {
                              return;
                            }

                            updateDialog(() {
                              saving = true;
                            });

                            try {
                              final make =
                                  makeController.text.trim();
                              final model =
                                  modelController.text.trim();
                              final year = int.parse(
                                yearController.text.trim(),
                              );
                              final mileage = int.parse(
                                mileageController.text.trim(),
                              );

                              if (isEditing) {
                                final changed = await db.updateVehicle(
                                  id: vehicle.id,
                                  make: make,
                                  model: model,
                                  year: year,
                                  mileage: mileage,
                                );

                                if (changed == 0) {
                                  throw StateError(
                                    'Vehicle was not found',
                                  );
                                }
                              } else {
                                await db.addVehicle(
                                  make: make,
                                  model: model,
                                  year: year,
                                  mileage: mileage,
                                );
                              }

                              if (!mounted) return;

                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }

                              await loadVehicles();

                              showMessage(
                                isEditing
                                    ? 'Vehicle updated'
                                    : 'Vehicle added',
                              );
                            } catch (error) {
                              showMessage(
                                'Could not save vehicle: $error',
                              );

                              if (dialogContext.mounted) {
                                updateDialog(() {
                                  saving = false;
                                });
                              }
                            }
                          },
                    child: Text(
                      saving
                          ? 'Saving...'
                          : isEditing
                              ? 'Save'
                              : 'Add',
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
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
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await db.deleteVehicle(vehicle.id);
      await loadVehicles();
      showMessage('Vehicle deleted');
    } catch (error) {
      showMessage('Could not delete vehicle: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () {
                            setState(() {
                              isLoading = true;
                            });
                            loadVehicles();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : vehicles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.directions_car,
                            size: 70,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          const Text('No vehicles added yet'),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: showVehicleForm,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Vehicle'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: loadVehicles,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: vehicles.length,
                        itemBuilder: (context, index) {
                          final vehicle = vehicles[index];

                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(
                                  Icons.directions_car,
                                ),
                              ),
                              title: Text(
                                '${vehicle.year} '
                                '${vehicle.make} '
                                '${vehicle.model}',
                              ),
                              subtitle: Text(
                                '${vehicle.mileage} miles',
                              ),
                              trailing: PopupMenuButton<String>(
                                tooltip: 'Vehicle options',
                                onSelected: (action) {
                                  if (action == 'edit') {
                                    showVehicleForm(
                                      vehicle: vehicle,
                                    );
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
                    ),
      floatingActionButton:
          !isLoading && errorMessage == null && vehicles.isNotEmpty
              ? FloatingActionButton(
                  onPressed: showVehicleForm,
                  tooltip: 'Add vehicle',
                  child: const Icon(Icons.add),
                )
              : null,
    );
  }
}
