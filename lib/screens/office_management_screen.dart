import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/office_provider.dart';

class OfficeManagementScreen extends StatefulWidget {
  const OfficeManagementScreen({super.key});

  @override
  State<OfficeManagementScreen> createState() => _OfficeManagementScreenState();
}

class _OfficeManagementScreenState extends State<OfficeManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _managerController = TextEditingController();
  String? _selectedStatus;

  final List<String> _statusOptions = ['Active', 'Inactive', 'Under Maintenance'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<OfficeProvider>().loadOffices();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _managerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Office Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showOfficeDialog(),
          ),
        ],
      ),
      body: Consumer<OfficeProvider>(
        builder: (context, officeProvider, child) {
          if (officeProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (officeProvider.error != null) {
            return Center(child: Text(officeProvider.error!));
          }

          if (officeProvider.offices.isEmpty) {
            return const Center(child: Text('No offices found'));
          }

          return ListView.builder(
            itemCount: officeProvider.offices.length,
            itemBuilder: (context, index) {
              final office = officeProvider.offices[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(office['name']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Location: ${office["location"]}'),
                      Text('Manager: ${office["manager"]}'),
                      Text('Status: ${office["status"]}'),
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
                        _showOfficeDialog(office: office);
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(office);
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

  void _showOfficeDialog({Map<String, dynamic>? office}) {
    final isEditing = office != null;
    
    if (isEditing) {
      _nameController.text = office['name'];
      _locationController.text = office['location'];
      _managerController.text = office['manager'];
      _selectedStatus = office['status'];
    } else {
      _nameController.clear();
      _locationController.clear();
      _managerController.clear();
      _selectedStatus = _statusOptions.first;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Office' : 'Add Office'),
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
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter a location' : null,
                ),
                TextFormField(
                  controller: _managerController,
                  decoration: const InputDecoration(labelText: 'Manager'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter a manager name' : null,
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
                final officeData = {
                  'name': _nameController.text,
                  'location': _locationController.text,
                  'manager': _managerController.text,
                  'status': _selectedStatus,
                };

                final success = isEditing
                    ? await context
                        .read<OfficeProvider>()
                        .updateOffice(office!['id'], officeData)
                    : await context
                        .read<OfficeProvider>()
                        .createOffice(officeData);

                if (mounted) {
                  Navigator.pop(context);
                  if (!success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.read<OfficeProvider>().error ??
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

  void _showDeleteConfirmation(Map<String, dynamic> office) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Office'),
        content: Text('Are you sure you want to delete ${office['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final success = await context
                  .read<OfficeProvider>()
                  .deleteOffice(office['id']);
              if (mounted) {
                Navigator.pop(context);
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.read<OfficeProvider>().error ??
                          'Failed to delete office'),
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