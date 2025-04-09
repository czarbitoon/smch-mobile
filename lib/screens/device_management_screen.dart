import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../providers/office_provider.dart';
import '../widgets/device_filters.dart';
import '../widgets/device_card.dart';
import '../widgets/common/state_widgets.dart';
import 'device_report_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';

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

  final List<String> _statusOptions = ['active', 'inactive', 'maintenance'];

  String? _filterStatus;
  String? _filterOffice;
  String? _filterType;
  Set<String> _deviceTypes = {};

  File? _imageFile;
  final _imagePicker = ImagePicker();

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
      context.read<DeviceProvider>().loadDeviceTypes();
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
    final deviceProvider = context.watch<DeviceProvider>();
    _deviceTypes = deviceProvider.deviceTypes.map((type) => type['name'].toString()).toSet();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Management'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              deviceProvider.loadDevices();
              deviceProvider.loadDeviceTypes();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDeviceDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Device'),
        tooltip: 'Add New Device',
      ),
      body: Consumer2<DeviceProvider, OfficeProvider>(
        builder: (context, deviceProvider, officeProvider, child) {
          if (deviceProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading devices...'),
                ],
              ),
            );
          }

          if (deviceProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    deviceProvider.error!,
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      deviceProvider.loadDevices();
                      deviceProvider.loadDeviceTypes();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: deviceProvider.total > 0 ? 80 : 0,
                child: DeviceFilters(
                  filterStatus: _filterStatus,
                  filterOffice: _filterOffice,
                  filterType: _filterType,
                  statusOptions: _statusOptions,
                  deviceTypes: _deviceTypes,
                  onStatusChanged: (value) {
                    setState(() => _filterStatus = value);
                    deviceProvider.applyFilters({
                      'status': value,
                      'office_id': _filterOffice,
                      'type': _filterType,
                    });
                  },
                  onOfficeChanged: (value) {
                    setState(() => _filterOffice = value);
                    deviceProvider.applyFilters({
                      'status': _filterStatus,
                      'office_id': value,
                      'type': _filterType,
                    });
                  },
                  onTypeChanged: (value) {
                    setState(() => _filterType = value);
                    deviceProvider.applyFilters({
                      'status': _filterStatus,
                      'office_id': _filterOffice,
                      'type': value,
                    });
                  },
                ),
              ),
              Expanded(
                child: deviceProvider.devices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.devices_other,
                              size: 64,
                              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No devices found',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your filters or add a new device',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: deviceProvider.devices.length,
                        itemBuilder: (context, index) {
                          final device = deviceProvider.devices[index];
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: DeviceCard(
                              key: ValueKey(device['id']),
                              device: device,
                              onEdit: () => _showDeviceDialog(device: device),
                              onDelete: () => _deleteDevice(device['id']),
                            ),
                          );
                        },
                      ),
              ),
              if (deviceProvider.total > 0)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 80,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
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
                        FilledButton.icon(
                          onPressed: deviceProvider.currentPage > 1
                              ? () => deviceProvider.previousPage()
                              : null,
                          icon: const Icon(Icons.chevron_left),
                          label: const Text('Previous'),
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
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.surfaceVariant,
                                foregroundColor: index + 1 == deviceProvider.currentPage
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurfaceVariant,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                minimumSize: const Size(40, 40),
                              ),
                              child: Text('${index + 1}'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        FilledButton.icon(
                          onPressed: deviceProvider.currentPage < deviceProvider.lastPage
                              ? () => deviceProvider.nextPage()
                              : null,
                          icon: const Icon(Icons.chevron_right),
                          label: const Text('Next'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showDeviceDialog({Map<String, dynamic>? device}) async {
    final isEditing = device != null;
    _nameController.text = device?['name'] ?? '';
    _typeController.text = device?['type'] ?? '';
    _selectedOffice = device?['office_id']?.toString();
    _selectedStatus = device?['status'];
    _imageFile = null;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Edit Device' : 'Add Device'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_imageFile != null || device?['image_url'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _imageFile != null
                          ? Image.file(
                              _imageFile!,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              device!['image_url'],
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Device Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _typeController,
                  decoration: const InputDecoration(
                    labelText: 'Device Type',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedOffice,
                  decoration: const InputDecoration(
                    labelText: 'Office',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('No Office'),
                    ),
                    ...context.read<OfficeProvider>().offices.map((office) {
                      return DropdownMenuItem(
                        value: office['id'].toString(),
                        child: Text(office['name']),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedOffice = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (_nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a device name')),
                  );
                  return;
                }

                final deviceData = {
                  'name': _nameController.text,
                  'type': _typeController.text,
                  'office_id': _selectedOffice != null ? int.parse(_selectedOffice!) : null,
                  'status': _selectedStatus,
                };

                Navigator.pop(context, {
                  ...deviceData,
                  'image_file': _imageFile,
                });
              },
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final deviceProvider = context.read<DeviceProvider>();
      final success = isEditing
          ? await deviceProvider.updateDevice(device!['id'], result)
          : await deviceProvider.createDevice(result);

      if (success && result['image_file'] != null) {
        await deviceProvider.uploadDeviceImage(
          isEditing ? device['id'] : deviceProvider.devices.last['id'],
          result['image_file'].path,
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
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

class DeviceFilters extends StatelessWidget {
  final String? filterStatus;
  final String? filterOffice;
  final String? filterType;
  final List<String> statusOptions;
  final Set<String> deviceTypes;
  final Function(String?) onStatusChanged;
  final Function(String?) onOfficeChanged;
  final Function(String?) onTypeChanged;

  const DeviceFilters({
    super.key,
    required this.filterStatus,
    required this.filterOffice,
    required this.filterType,
    required this.statusOptions,
    required this.deviceTypes,
    required this.onStatusChanged,
    required this.onOfficeChanged,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: filterStatus,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Statuses'),
                    ),
                    ...statusOptions.map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        )),
                  ],
                  onChanged: onStatusChanged,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: filterOffice,
                  decoration: InputDecoration(
                    labelText: 'Office',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Offices'),
                    ),
                    ...context.watch<OfficeProvider>().offices.map((office) => DropdownMenuItem(
                          value: office['id'].toString(),
                          child: Text(office['name']),
                        )),
                  ],
                  onChanged: onOfficeChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: filterType,
                  decoration: InputDecoration(
                    labelText: 'Device Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Types'),
                    ),
                    ...deviceTypes.map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        )),
                  ],
                  onChanged: onTypeChanged,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    // Show advanced filters dialog
                    showDialog(
                      context: context,
                      builder: (context) => AdvancedFiltersDialog(
                        onApply: (filters) {
                          // Apply advanced filters
                          context.read<DeviceProvider>().applyFilters({
                            ...filters,
                            'status': filterStatus,
                            'office_id': filterOffice,
                            'type': filterType,
                          });
                        },
                      ),
                    );
                  },
                  icon: const Icon(Icons.tune),
                  label: const Text('Advanced Filters'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AdvancedFiltersDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onApply;

  const AdvancedFiltersDialog({
    super.key,
    required this.onApply,
  });

  @override
  State<AdvancedFiltersDialog> createState() => _AdvancedFiltersDialogState();
}

class _AdvancedFiltersDialogState extends State<AdvancedFiltersDialog> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _sortBy;
  String? _sortOrder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: const Text('Advanced Filters'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Date Range'),
            subtitle: Text(
              _startDate != null && _endDate != null
                  ? '${DateFormat('MMM d, y').format(_startDate!)} - ${DateFormat('MMM d, y').format(_endDate!)}'
                  : 'Select date range',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final DateTimeRange? range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: _startDate != null && _endDate != null
                    ? DateTimeRange(start: _startDate!, end: _endDate!)
                    : null,
              );
              if (range != null) {
                setState(() {
                  _startDate = range.start;
                  _endDate = range.end;
                });
              }
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Sort By'),
            subtitle: Text(_sortBy ?? 'Select field'),
            trailing: const Icon(Icons.sort),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => SimpleDialog(
                  title: const Text('Sort By'),
                  children: [
                    RadioListTile(
                      title: const Text('Name'),
                      value: 'name',
                      groupValue: _sortBy,
                      onChanged: (value) {
                        setState(() => _sortBy = value);
                        Navigator.pop(context);
                      },
                    ),
                    RadioListTile(
                      title: const Text('Status'),
                      value: 'status',
                      groupValue: _sortBy,
                      onChanged: (value) {
                        setState(() => _sortBy = value);
                        Navigator.pop(context);
                      },
                    ),
                    RadioListTile(
                      title: const Text('Last Updated'),
                      value: 'updated_at',
                      groupValue: _sortBy,
                      onChanged: (value) {
                        setState(() => _sortBy = value);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          if (_sortBy != null) ...[
            const Divider(),
            ListTile(
              title: const Text('Sort Order'),
              subtitle: Text(_sortOrder ?? 'Select order'),
              trailing: const Icon(Icons.swap_vert),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => SimpleDialog(
                    title: const Text('Sort Order'),
                    children: [
                      RadioListTile(
                        title: const Text('Ascending'),
                        value: 'asc',
                        groupValue: _sortOrder,
                        onChanged: (value) {
                          setState(() => _sortOrder = value);
                          Navigator.pop(context);
                        },
                      ),
                      RadioListTile(
                        title: const Text('Descending'),
                        value: 'desc',
                        groupValue: _sortOrder,
                        onChanged: (value) {
                          setState(() => _sortOrder = value);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _startDate = null;
              _endDate = null;
              _sortBy = null;
              _sortOrder = null;
            });
          },
          child: const Text('Reset'),
        ),
        FilledButton(
          onPressed: () {
            final filters = {
              if (_startDate != null) 'start_date': _startDate!.toIso8601String(),
              if (_endDate != null) 'end_date': _endDate!.toIso8601String(),
              if (_sortBy != null) 'sort_by': _sortBy,
              if (_sortOrder != null) 'sort_order': _sortOrder,
            };
            widget.onApply(filters);
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}