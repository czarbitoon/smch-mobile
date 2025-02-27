import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/office_provider.dart';

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

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filters', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: filterStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All'),
                      ),
                      ...statusOptions.map((status) {
                        return DropdownMenuItem<String?>(
                          value: status,
                          child: Text(status),
                        );
                      }),
                    ],
                    onChanged: onStatusChanged,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Consumer<OfficeProvider>(
                    builder: (context, officeProvider, child) {
                      return DropdownButtonFormField<String?>(
                        value: filterOffice,
                        decoration: const InputDecoration(
                          labelText: 'Office',
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All'),
                          ),
                          ...officeProvider.offices.map((office) {
                            return DropdownMenuItem<String?>(
                              value: office['id'].toString(),
                              child: Text(office['name']),
                            );
                          }),
                        ],
                        onChanged: onOfficeChanged,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(  // Changed to String?
              value: filterType,
              decoration: const InputDecoration(
                labelText: 'Type',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All'),
                ),
                ...deviceTypes.map((type) {
                  return DropdownMenuItem<String?>(
                    value: type,
                    child: Text(type),
                  );
                }),
              ],
              onChanged: onTypeChanged,
            ),
          ],
        ),
      ),
    );
  }
}