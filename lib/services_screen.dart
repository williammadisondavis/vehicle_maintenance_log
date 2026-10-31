
import 'package:flutter/material.dart';
import 'database_helper.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final db = DatabaseHelper.instance;

  List<Map<String, Object?>> services = [];
  List<Map<String, Object?>> vehicles = [];

  bool loading = true;
  String? errorMessage;

  final serviceTypes = const [
    'Oil Change',
    'Tire Rotation',
    'Brake Inspection',
    'Battery Replacement',
    'Air Filter',
    'Transmission Service',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final vehicleRows = await db.getVehicles();
      final serviceRows = await db.getServices();

      if (!mounted) return;

      setState(() {
        vehicles = vehicleRows;
        services = serviceRows;
        loading = false;
        errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = 'Could not load service history: $error';
      });
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> openServiceForm({
    Map<String, Object?>? service,
  }) async {
    await loadData();
    if (!mounted || errorMessage != null) return;

    if (vehicles.isEmpty) {
      showMessage('Add a vehicle before recording a service.');
      return;
    }

    final editing = service != null;
    final formKey = GlobalKey<FormState>();

    int selectedVehicle = editing
        ? service['vehicle_id'] as int
        : vehicles.first['id'] as int;

    String selectedType = editing
        ? service['service_type'] as String
        : 'Oil Change';

    DateTime selectedDate = editing
        ? DateTime.parse(service['service_date'] as String)
        : DateTime.now();

    final mileageController = TextEditingController(
      text: editing ? service['mileage'].toString() : '',
    );

    final costController = TextEditingController(
      text: editing ? service['cost'].toString() : '0',
    );

    final notesController = TextEditingController(
      text: editing ? service['notes'] as String : '',
    );

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          bool saving = false;

          return StatefulBuilder(
            builder: (context, updateDialog) {
              return AlertDialog(
                title: Text(
                  editing ? 'Edit Service' : 'Add Service',
                ),
                content: SizedBox(
                  width: 420,
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButtonFormField<int>(
                            initialValue: selectedVehicle,
                            decoration: const InputDecoration(
                              labelText: 'Vehicle',
                            ),
                            items: vehicles.map((vehicle) {
                              final id = vehicle['id'] as int;

                              return DropdownMenuItem(
                                value: id,
                                child: Text(
                                  '${vehicle['year']} '
                                  '${vehicle['make']} '
                                  '${vehicle['model']}',
                                ),
                              );
                            }).toList(),
                            onChanged: saving
                                ? null
                                : (value) {
                                    if (value != null) {
                                      updateDialog(() {
                                        selectedVehicle = value;
                                      });
                                    }
                                  },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: selectedType,
                            decoration: const InputDecoration(
                              labelText: 'Service Type',
                            ),
                            items: serviceTypes.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              );
                            }).toList(),
                            onChanged: saving
                                ? null
                                : (value) {
                                    if (value != null) {
                                      updateDialog(() {
                                        selectedType = value;
                                      });
                                    }
                                  },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: mileageController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Mileage at Service',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              final number = int.tryParse(
                                value?.trim() ?? '',
                              );

                              if (number == null || number < 0) {
                                return 'Enter valid mileage';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: costController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                            decoration: const InputDecoration(
                              labelText: 'Cost',
                              prefixText: '\$',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              final number = double.tryParse(
                                value?.trim() ?? '',
                              );

                              if (number == null ||
                                  !number.isFinite ||
                                  number < 0) {
                                return 'Enter valid cost';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: saving
                                ? null
                                : () async {
                                    final picked = await showDatePicker(
                                      context: dialogContext,
                                      initialDate: selectedDate,
                                      firstDate: DateTime(1950),
                                      lastDate: DateTime.now(),
                                    );

                                    if (picked != null &&
                                        dialogContext.mounted) {
                                      updateDialog(() {
                                        selectedDate = picked;
                                      });
                                    }
                                  },
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              'Date: ${selectedDate.year}-'
                              '${selectedDate.month.toString().padLeft(2, '0')}-'
                              '${selectedDate.day.toString().padLeft(2, '0')}',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: notesController,
                            maxLines: 2,
                            maxLength: 250,
                            decoration: const InputDecoration(
                              labelText: 'Notes (optional)',
                              border: OutlineInputBorder(),
                            ),
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

                            final date =
                                '${selectedDate.year}-'
                                '${selectedDate.month.toString().padLeft(2, '0')}-'
                                '${selectedDate.day.toString().padLeft(2, '0')}';

                            try {
                              if (editing) {
                                await db.updateService(
                                  id: service['id'] as int,
                                  vehicleId: selectedVehicle,
                                  serviceType: selectedType,
                                  mileage: int.parse(
                                    mileageController.text.trim(),
                                  ),
                                  cost: double.parse(
                                    costController.text.trim(),
                                  ),
                                  serviceDate: date,
                                  notes: notesController.text.trim(),
                                );
                              } else {
                                await db.addService(
                                  vehicleId: selectedVehicle,
                                  serviceType: selectedType,
                                  mileage: int.parse(
                                    mileageController.text.trim(),
                                  ),
                                  cost: double.parse(
                                    costController.text.trim(),
                                  ),
                                  serviceDate: date,
                                  notes: notesController.text.trim(),
                                );
                              }

                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }

                              await loadData();

                              showMessage(
                                editing
                                    ? 'Service updated'
                                    : 'Service added',
                              );
                            } catch (error) {
                              showMessage(
                                'Could not save service: $error',
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
                          : editing
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
      mileageController.dispose();
      costController.dispose();
      notesController.dispose();
    }
  }

  Future<void> deleteService(
    Map<String, Object?> service,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Service?'),
          content: Text(
            'Delete this ${service['service_type']} record?',
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
      await db.deleteService(service['id'] as int);
      await loadData();
      showMessage('Service deleted');
    } catch (error) {
      showMessage('Could not delete service: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                      ),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            loading = true;
                          });
                          loadData();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : services.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.build_outlined,
                            size: 60,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          const Text('No service records yet'),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () => openServiceForm(),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Service'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: services.length,
                        itemBuilder: (context, index) {
                          final service = services[index];

                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.build),
                              ),
                              title: Text(
                                service['service_type'] as String,
                              ),
                              subtitle: Text(
                                '${service['year']} '
                                '${service['make']} '
                                '${service['model']}\n'
                                '${service['service_date']} • '
                                '${service['mileage']} miles\n'
                                '\$${(service['cost'] as num).toStringAsFixed(2)}'
                                '${(service['notes'] as String).isEmpty ? '' : '\n${service['notes']}'}',
                              ),
                              isThreeLine: true,
                              trailing: PopupMenuButton<String>(
                                tooltip: 'Service options',
                                onSelected: (action) {
                                  if (action == 'edit') {
                                    openServiceForm(service: service);
                                  } else {
                                    deleteService(service);
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
          !loading && errorMessage == null && services.isNotEmpty
              ? FloatingActionButton(
                  onPressed: () => openServiceForm(),
                  tooltip: 'Add service',
                  child: const Icon(Icons.add),
                )
              : null,
    );
  }
}
