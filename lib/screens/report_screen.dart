import 'package:flutter/material.dart';
import '../providers/report_provider.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ReportProvider _reportProvider = ReportProvider();
  int? _selectedDeviceId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _reportProvider.loadDeviceReports();
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Report')),
      body: _reportProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DropdownButtonFormField<int>(
                    value: _selectedDeviceId,
                    hint: const Text('Select Device'),
                    items: _reportProvider.devices.map((device) {
                      return DropdownMenuItem<int>(
                        value: device['id'],
                        child: Text(device['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDeviceId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  if (_reportProvider.error != null)
                    Text(
                      _reportProvider.error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                ],
              ),
            ),
    );
  }
}