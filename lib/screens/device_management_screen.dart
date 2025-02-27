import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../providers/office_provider.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showDeviceDialog(),
          ),
        ],
      ),
      body: Consumer2<DeviceProvider, OfficeProvider>(
        builder: (context, deviceProvider, officeProvider, child) {
          if (deviceProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (deviceProvider.error != null) {
            return Center(child: Text(deviceProvider.error!));
          }

          if (deviceProvider.devices.isEmpty) {
            return const Center(child: Text('No devices found'));
          }

          return ListView.builder(
            itemCount: deviceProvider.devices.length,
            itemBuilder: (context, index) {
              final device = deviceProvider.devices[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(device['name']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Type: ${device['type']}'),
                      Text('Status: ${device['status']}'),
                      Text('Office: ${device['office_name'] ?? 'Not assigned'}'),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showDeviceDialog(device: device);
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(device);
                      }
                    },
                  ),
                ),
              );
            },
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
                  'office_id': _selectedOffice,
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