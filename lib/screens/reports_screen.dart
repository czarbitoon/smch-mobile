import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/report_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      final reportProvider = context.read<ReportProvider>();
      reportProvider.loadDeviceReports();
      reportProvider.loadOfficeReports();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Device Reports'),
            Tab(text: 'Office Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DeviceReportsTab(),
          OfficeReportsTab(),
        ],
      ),
    );
  }
}

class DeviceReportsTab extends StatelessWidget {
  const DeviceReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, reportProvider, child) {
        if (reportProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (reportProvider.error != null) {
          return Center(child: Text(reportProvider.error!));
        }

        if (reportProvider.deviceReports.isEmpty) {
          return const Center(child: Text('No device reports found'));
        }

        return ListView.builder(
          itemCount: reportProvider.deviceReports.length,
          itemBuilder: (context, index) {
            final report = reportProvider.deviceReports[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(report['device_name']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status: ${report["status"]}'),
                    Text('Last Updated: ${report["updated_at"]}'),
                    Text('Description: ${report["description"]}'),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class OfficeReportsTab extends StatelessWidget {
  const OfficeReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, reportProvider, child) {
        if (reportProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (reportProvider.error != null) {
          return Center(child: Text(reportProvider.error!));
        }

        if (reportProvider.officeReports.isEmpty) {
          return const Center(child: Text('No office reports found'));
        }

        return ListView.builder(
          itemCount: reportProvider.officeReports.length,
          itemBuilder: (context, index) {
            final report = reportProvider.officeReports[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(report['office_name']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Activity: ${report["activity"]}'),
                    Text('Date: ${report["date"]}'),
                    Text('Details: ${report["details"]}'),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}