import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../providers/office_provider.dart';
import '../widgets/device_filters.dart';
import '../widgets/device_card.dart';

class DeviceManagementScreen extends StatefulWidget {
  const DeviceManagementScreen({super.key});

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  String? _selectedOffice;
  String? _selectedStatus;

  final List<String> _statusOptions = ['Available', 'In Use', 'Maintenance', 'Retired'];

  String? _filterStatus = null;
  String? _filterOffice = null;
  String? _filterType = null;
  final Set<String> _deviceTypes = {};

  Future<void> _deleteDevice(int deviceId) async {
    try {
      if (deviceId <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid device ID')),
          );
        }
        return;
      }
  
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this device?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
  
      if (confirmed == true) {
        final success = await context.read<DeviceProvider>().deleteDevice(deviceId);
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Device deleted successfully')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.read<DeviceProvider>().error ?? 'Failed to delete device')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete device: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<DeviceProvider>().loadDevices();
      context.read<OfficeProvider>().loadOffices();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Management'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDeviceDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Device'),
      ),
      body: Consumer2<DeviceProvider, OfficeProvider>(
        builder: (context, deviceProvider, officeProvider, child) {
          if (deviceProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (deviceProvider.error != null) {
            return Center(child: Text(deviceProvider.error!));
          }

          return Column(
            children: [
              DeviceFilters(
                filterStatus: _filterStatus,
                filterOffice: _filterOffice,
                filterType: _filterType,
                statusOptions: _statusOptions,
                deviceTypes: _deviceTypes,
                onStatusChanged: (value) {
                  setState(() {
                    _filterStatus = value;
                  });
                  deviceProvider.applyFilters({
                    'status': value,
                    'office_id': _filterOffice,
                    'type': _filterType,
                  });
                },
                onOfficeChanged: (value) {
                  setState(() {
                    _filterOffice = value;
                  });
                  deviceProvider.applyFilters({
                    'status': _filterStatus,
                    'office_id': value,
                    'type': _filterType,
                  });
                },
                onTypeChanged: (value) {
                  setState(() {
                    _filterType = value;
                  });
                  deviceProvider.applyFilters({
                    'status': _filterStatus,
                    'office_id': _filterOffice,
                    'type': value,
                  });
                },
              ),
              if (deviceProvider.total > 0)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton(
                        onPressed: deviceProvider.currentPage > 1
                            ? () => deviceProvider.previousPage()
                            : null,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chevron_left, size: 20),
                            SizedBox(width: 4),
                            Text('Previous'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ...List.generate(
                        deviceProvider.lastPage,
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilledButton(
                            onPressed: index + 1 != deviceProvider.currentPage
                                ? () => deviceProvider.goToPage(index + 1)
                                : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: index + 1 == deviceProvider.currentPage
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.surfaceVariant,
                              foregroundColor: index + 1 == deviceProvider.currentPage
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              minimumSize: const Size(40, 40),
                            ),
                            child: Text('${index + 1}'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      FilledButton(
                        onPressed: deviceProvider.currentPage < deviceProvider.lastPage
                            ? () => deviceProvider.nextPage()
                            : null,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Next'),
                            SizedBox(width: 4),
                            Icon(Icons.chevron_right, size: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: deviceProvider.devices.isEmpty
                    ? const Center(child: Text('No devices found'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: deviceProvider.devices.length,
                        itemBuilder: (context, index) {
                          final device = deviceProvider.devices[index];
                          return DeviceCard(
                            device: device,
                            onEdit: () => _showDeviceDialog(device: device),
                            onDelete: () => _deleteDevice(device['id']),
                          );
                        },
                      ),
              ),
              if (deviceProvider.total > 0)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton(
                        onPressed: deviceProvider.currentPage > 1
                            ? () => deviceProvider.previousPage()
                            : null,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chevron_left, size: 20),
                            SizedBox(width: 4),
                            Text('Previous'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ...List.generate(
                        deviceProvider.lastPage,
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilledButton(
                            onPressed: index + 1 != deviceProvider.currentPage
                                ? () => deviceProvider.goToPage(index + 1)
                                : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: index + 1 == deviceProvider.currentPage
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.surfaceVariant,
                              foregroundColor: index + 1 == deviceProvider.currentPage
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              minimumSize: const Size(40, 40),
                            ),
                            child: Text('${index + 1}'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      FilledButton(
                        onPressed: deviceProvider.currentPage < deviceProvider.lastPage
                            ? () => deviceProvider.nextPage()
                            : null,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Next'),
                            SizedBox(width: 4),
                            Icon(Icons.chevron_right, size: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showDeviceDialog({Map<String, dynamic>? device}) {
    final isEditing = device != null;
    
    if (isEditing) {
      _nameController.text = device['name'];
      _typeController.text = device['type'];
      _selectedOffice = device['office_id']?.toString();
      _selectedStatus = device['status'];
    } else {
      _nameController.clear();
      _typeController.clear();
      _selectedOffice = null;
      _selectedStatus = _statusOptions.first;
    }
  
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Device' : 'Add Device'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter a name' : null,
                ),
                TextFormField(
                  controller: _typeController,
                  decoration: const InputDecoration(labelText: 'Type'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter a type' : null,
                ),
                Consumer<OfficeProvider>(
                  builder: (context, officeProvider, child) {
                    return DropdownButtonFormField<String>(
                      value: _selectedOffice,
                      decoration: const InputDecoration(labelText: 'Office'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('No Office'),
                        ),
                        ...officeProvider.offices.map((office) {
                          return DropdownMenuItem(
                            value: office['id'].toString(),
                            child: Text(office['name']),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedOffice = value;
                        });
                      },
                    );
                  },
                ),
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: _statusOptions.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select a status' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                final deviceData = {
                  'name': _nameController.text,
                  'type': _typeController.text,
                  'office_id': _selectedOffice != null ? int.parse(_selectedOffice!) : null,
                  'status': _selectedStatus,
                };
  
                final success = isEditing
                    ? await context
                        .read<DeviceProvider>()
                        .updateDevice(device!['id'], deviceData)
                    : await context
                        .read<DeviceProvider>()
                        .createDevice(deviceData);
  
                if (mounted) {
                  Navigator.pop(context);
                  if (!success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.read<DeviceProvider>().error ??
                            'Operation failed'),
                      ),
                    );
                  }
                }
              }
            },
            child: Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Device'),
        content: Text('Are you sure you want to delete ${device['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final success = await context
                  .read<DeviceProvider>()
                  .deleteDevice(device['id']);
              if (mounted) {
                Navigator.pop(context);
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.read<DeviceProvider>().error ??
                          'Failed to delete device'),
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}