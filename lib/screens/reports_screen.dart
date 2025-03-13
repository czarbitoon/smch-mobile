import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reports_provider.dart';
import '../providers/device_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedReportType = 'All';
  final List<String> _reportTypes = ['All', 'Daily', 'Weekly', 'Monthly'];
  final List<String> _priorityLevels = ['Low', 'Medium', 'High', 'Critical'];
  final List<String> _statusOptions = ['Pending', 'In Progress', 'Resolved', 'Closed'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ReportsProvider>().loadReports();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: Consumer<ReportsProvider>(
        builder: (context, reportsProvider, child) {
          if (reportsProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (reportsProvider.error != null) {
            return Center(
              child: Text(
                'Error: ${reportsProvider.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final filteredReports = _selectedReportType == 'All'
              ? reportsProvider.reports
              : reportsProvider.reports
                  .where((report) =>
                      report['type']?.toString().toLowerCase() ==
                      _selectedReportType.toLowerCase())
                  .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: DropdownButtonFormField<String>(
                  value: _selectedReportType,
                  decoration: const InputDecoration(
                    labelText: 'Report Type',
                    border: OutlineInputBorder(),
                  ),
                  items: _reportTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedReportType = newValue;
                      });
                    }
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredReports.length,
                  padding: const EdgeInsets.all(16.0),
                  itemBuilder: (context, index) {
                    final report = filteredReports[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      child: ListTile(
                        title: Text('Report #${report['id']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Type: ${report['type'] ?? 'N/A'}'),
                            Text('Generated: ${report['created_at'] ?? 'N/A'}'),
                            Text('Status: ${report['status'] ?? 'N/A'}'),
                          ],
                        ),
                        onTap: () async {
                          try {
                            final details = await reportsProvider
                                .getReportDetails(report['id']);
                            if (!mounted) return;
                            
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Report #${report['id']} Details'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Type: ${details['type'] ?? 'N/A'}'),
                                      Text('Status: ${details['status'] ?? 'N/A'}'),
                                      Text('Generated: ${details['created_at'] ?? 'N/A'}'),
                                      const SizedBox(height: 8),
                                      const Text('Summary:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text(details['summary'] ?? 'No summary available'),
                                      const SizedBox(height: 8),
                                      const Text('Devices:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ...(details['devices'] as List<dynamic>? ?? [])
                                          .map((device) => Padding(
                                                padding: const EdgeInsets.only(left: 8.0),
                                                child: Text('- ${device['name']} (${device['status']})'),
                                              ))
                                          .toList(),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error loading report details: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddReportDialog();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddReportDialog() async {
    final _formKey = GlobalKey<FormState>();
    final _descriptionController = TextEditingController();
    String _selectedPriority = 'Medium';
    String _selectedStatus = 'Pending';
    int? _selectedDeviceId;
    bool _isSubmitting = false;
    bool _isLoadingDevices = true;
    List<Map<String, dynamic>> _devices = [];

    final List<String> _priorityLevels = ['Low', 'Medium', 'High', 'Critical'];
    final List<String> _statusOptions = ['Pending', 'In Progress', 'Resolved', 'Closed'];

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Load devices when dialog is shown
          if (_isLoadingDevices) {
            _isLoadingDevices = false;
            Future.microtask(() async {
              final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
              await deviceProvider.loadDevices();
              setState(() {
                _devices = deviceProvider.devices;
              });
            });
          }

          return AlertDialog(
            title: const Text('Add New Report'),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Device selection dropdown
                    DropdownButtonFormField<int>(
                      value: _selectedDeviceId,
                      decoration: const InputDecoration(
                        labelText: 'Select Device',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select a device'),
                      items: _devices.map((device) {
                        return DropdownMenuItem<int>(
                          value: device['id'],
                          child: Text(device['name'] ?? 'Unknown Device'),
                        );
                      }).toList(),
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a device';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() => _selectedDeviceId = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                      items: _priorityLevels.map((priority) {
                        return DropdownMenuItem(
                          value: priority,
                          child: Text(priority),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedPriority = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: _statusOptions.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedStatus = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter report description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;

                        setState(() => _isSubmitting = true);

                        try {
                          final reportsProvider = context.read<ReportsProvider>();
                          final success = await reportsProvider.submitReport(
                            description: _descriptionController.text,
                            priority: _selectedPriority,
                            status: _selectedStatus,
                            deviceId: _selectedDeviceId,
                          );

                          if (success) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Report submitted successfully')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(reportsProvider.error ?? 'Failed to submit report')),
                            );
                          }
                        } finally {
                          setState(() => _isSubmitting = false);
                        }
                      },
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit'),
              ),
            ],
          );
        },
      ),
    );
  }
}