import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reports_provider.dart';
import '../providers/device_provider.dart';
import '../providers/auth_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedStatus = 'All';
  String _selectedPriority = 'All';
  final List<String> _statusOptions = ['All', 'Pending', 'In Progress', 'Resolved', 'Closed'];
  final List<String> _priorityLevels = ['All', 'Low', 'Medium', 'High', 'Critical'];
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  bool get _isAdminOrStaff => context.read<AuthProvider>().isAdmin || context.read<AuthProvider>().isStaff;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ReportsProvider>().loadReports();
    });
  }

  @override
  void dispose() {
    _titleController?.dispose();
    _descriptionController?.dispose();
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

          final filteredReports = reportsProvider.reports.where((report) {
            if (_selectedStatus != 'All' && report['status']?.toString() != _selectedStatus) {
              return false;
            }
            if (_selectedPriority != 'All' && report['priority']?.toString() != _selectedPriority) {
              return false;
            }
            return true;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: _statusOptions.map((String status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedStatus = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                      items: _priorityLevels.map((String priority) {
                        return DropdownMenuItem<String>(
                          value: priority,
                          child: Text(priority),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedPriority = newValue;
                          });
                        }
                      },
                    ),
                  ],
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
                            Text('Generated: ${_formatDateTime(report['created_at'] ?? 'N/A')}'),
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
                                      Text('Status: ${details['status'] ?? 'N/A'}'),
                                      Text('Generated: ${_formatDateTime(details['created_at'] ?? 'N/A')}'),
                                      const SizedBox(height: 8),
                                      const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text(details['description'] ?? 'No description available'),
                                      const SizedBox(height: 8),
                                      if (details['device'] != null) ...[                                        
                                        const Text('Device:', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text('${details['device']['name'] ?? 'N/A'}')
                                      ],
                                      if (details['status'] != 'resolved' && (context.read<AuthProvider>().isAdmin || context.read<AuthProvider>().isStaff)) ...[                                        
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: () {
                                            final reportId = details['id'];
                                            if (reportId != null) {
                                              _showResolveDialog(context, int.parse(reportId.toString()));
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Invalid report ID'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          },
                                          child: const Text('Resolve Report')
                                        )
                                      ]
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

  Future<void> _showResolveDialog(BuildContext context, int reportId) async {
    final resolutionController = TextEditingController();
    bool isSubmitting = false;

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Resolve Report'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: resolutionController,
                decoration: const InputDecoration(
                  labelText: 'Resolution Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (resolutionController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please provide resolution notes'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setState(() => isSubmitting = true);

                      try {
                        final success = await context.read<ReportsProvider>().resolveReport(
                              reportId,
                              resolutionController.text.trim(),
                              isAdminOrStaff: context.read<AuthProvider>().isAdmin || context.read<AuthProvider>().isStaff,
                            );

                        if (!context.mounted) return;

                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Report resolved successfully'
                                  : 'Failed to resolve report',
                            ),
                            backgroundColor: success ? Colors.green : Colors.red,
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error resolving report: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } finally {
                        if (mounted) {
                          setState(() => isSubmitting = false);
                        }
                      }
                    },
              child: Text(isSubmitting ? 'Resolving...' : 'Resolve'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddReportDialog() async {
    final _formKey = GlobalKey<FormState>();
    final _descriptionController = TextEditingController();
    String _selectedPriority = 'Medium';
    int? _selectedDeviceId;
    bool _isSubmitting = false;
    bool _isLoadingDevices = true;
    List<Map<String, dynamic>> _devices = [];
    
    // Clean up the controller when the dialog is closed
    void dispose() {
      _descriptionController.dispose();
    }

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
                    DropdownButtonFormField<int>(
                      value: _selectedDeviceId,
                      decoration: const InputDecoration(
                        labelText: 'Device',
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
                      items: _priorityLevels.map((String priority) {
                        return DropdownMenuItem<String>(
                          value: priority,
                          child: Text(priority),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedPriority = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Describe the Issue',
                        hintText: 'Please provide details about the issue you\'re experiencing with this device',
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
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;

                        if (!mounted) return;
                        setState(() => _isSubmitting = true);

                        try {
                          final reportsProvider = Provider.of<ReportsProvider>(
                            context,
                            listen: false,
                          );

                          final selectedDevice = _devices.firstWhere(
                            (device) => device['id'] == _selectedDeviceId,
                            orElse: () => {'name': 'Device'},
                          );

                          final success = await reportsProvider.submitReport(
                            deviceId: _selectedDeviceId!,
                            title: 'Issue Report - ${selectedDevice['name']}',
                            description: _descriptionController.text,
                            priority: _selectedPriority,
                            status: 'Pending',
                          );

                          if (!mounted) return;

                          if (success) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Report submitted successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            if (mounted) {
                              setState(() => _isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(reportsProvider.error ?? 'Failed to submit report'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() => _isSubmitting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error submitting report: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
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

  String _formatDateTime(String dateTimeStr) {
    if (dateTimeStr == 'N/A') return dateTimeStr;
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }