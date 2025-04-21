import 'package:flutter/material.dart';
import '../utils/api_diagnostics.dart';
import '../config/app_config.dart';
import '../config/network_config.dart';

class ApiDiagnosticsScreen extends StatefulWidget {
  const ApiDiagnosticsScreen({super.key});

  @override
  State<ApiDiagnosticsScreen> createState() => _ApiDiagnosticsScreenState();
}

class _ApiDiagnosticsScreenState extends State<ApiDiagnosticsScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _diagnosticResults;
  String? _selectedApiUrl;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await ApiDiagnostics.runDiagnostics();
      setState(() {
        _diagnosticResults = results;
        _isLoading = false;
      });

      // Find the first working URL from the test results
      final workingUrls = results['connection_tests']
          .where((test) => test['success'] == true)
          .toList();

      if (workingUrls.isNotEmpty) {
        _selectedApiUrl = workingUrls.first['url'];
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _diagnosticResults = {
          'error': e.toString(),
        };
      });
    }
  }

  Future<void> _applySelectedApiUrl() async {
    if (_selectedApiUrl == null) return;

    // Here you would typically update a persistent configuration
    // For now, we'll just show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('API URL updated to: $_selectedApiUrl'),
        backgroundColor: Colors.green,
      ),
    );

    // In a real implementation, you would save this to persistent storage
    // and update the app configuration
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Connection Diagnostics'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildDiagnosticsContent(),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: _runDiagnostics,
              child: const Text('Run Diagnostics Again'),
            ),
            ElevatedButton(
              onPressed: _selectedApiUrl != null ? _applySelectedApiUrl : null,
              child: const Text('Apply Selected URL'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticsContent() {
    if (_diagnosticResults == null) {
      return const Center(child: Text('No diagnostic results available'));
    }

    if (_diagnosticResults!.containsKey('error')) {
      return Center(
        child: Text(
          'Error running diagnostics: ${_diagnosticResults!['error']}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            'Current Configuration',
            [
              'API URL: ${AppConfig.apiUrl}',
              'Network Config URL: ${NetworkConfig.getApiUrl()}',
              'Platform: ${_diagnosticResults!['platform']['type']}',
            ],
          ),
          const SizedBox(height: 16),
          _buildConnectionTestsSection(),
          const SizedBox(height: 16),
          _buildRecommendationSection(),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<String> items) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(item),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionTestsSection() {
    final connectionTests = _diagnosticResults!['connection_tests'] as List;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connection Tests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...connectionTests.map((test) => _buildConnectionTestItem(test)),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionTestItem(Map<String, dynamic> test) {
    final bool success = test['success'] ?? false;
    final String url = test['url'] ?? 'Unknown URL';
    final String description = test['description'] ?? '';
    final int? statusCode = test['status_code'];
    final String? error = test['error'];
    final int responseTime = test['response_time_ms'] ?? 0;

    return RadioListTile<String>(
      title: Text(description),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(url),
          if (statusCode != null) Text('Status: $statusCode'),
          if (error != null) Text('Error: $error', style: const TextStyle(color: Colors.red)),
          if (responseTime > 0) Text('Response time: ${responseTime}ms'),
        ],
      ),
      value: url,
      groupValue: _selectedApiUrl,
      onChanged: success ? (value) {
        setState(() {
          _selectedApiUrl = value;
        });
      } : null,
      activeColor: Colors.green,
      selected: url == _selectedApiUrl,
      secondary: Icon(
        success ? Icons.check_circle : Icons.error,
        color: success ? Colors.green : Colors.red,
      ),
    );
  }

  Widget _buildRecommendationSection() {
    final recommendation = _diagnosticResults!['recommendation'] as String? ?? 'No recommendation available';

    return Card(
      elevation: 2,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recommendation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Text(recommendation),
          ],
        ),
      ),
    );
  }
}