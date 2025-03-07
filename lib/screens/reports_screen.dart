import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reports_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedReportType = 'All';
  final List<String> _reportTypes = ['All', 'Daily', 'Weekly', 'Monthly'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ReportsProvider>().loadReports();
    });
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
        onPressed: () async {
          try {
            await context.read<ReportsProvider>().generateReport();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Report generated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error generating report: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}