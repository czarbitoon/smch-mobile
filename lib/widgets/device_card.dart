import 'package:flutter/material.dart';

class DeviceCard extends StatelessWidget {
  final Map<String, dynamic> device;
  final Function() onEdit;
  final Function() onDelete;

  const DeviceCard({
    super.key,
    required this.device,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    device['name']?.toString() ?? 'Unnamed Device',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                _buildStatusChip(device['status']?.toString() ?? 'Unknown', theme),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.category, 'Type', device['type']?.toString() ?? 'Not specified', theme, isPlaceholder: device['type'] == null),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.business,
              'Office',
              device['office_name']?.toString() ?? 'Not assigned',
              theme,
              isPlaceholder: device['office_name'] == null,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, ThemeData theme) {
    Color chipColor;
    IconData iconData;

    switch (status) {
      case 'Available':
        chipColor = Colors.green;
        iconData = Icons.check_circle;
        break;
      case 'In Use':
        chipColor = Colors.blue;
        iconData = Icons.access_time;
        break;
      case 'Maintenance':
        chipColor = Colors.orange;
        iconData = Icons.build;
        break;
      case 'Retired':
        chipColor = Colors.grey;
        iconData = Icons.block;
        break;
      default:
        chipColor = Colors.grey;
        iconData = Icons.help;
    }

    return Chip(
      avatar: Icon(iconData, size: 18, color: chipColor),
      labelStyle: TextStyle(color: chipColor, fontWeight: FontWeight.bold),
      label: Text(status),
      backgroundColor: chipColor.withOpacity(0.1),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, ThemeData theme, {bool isPlaceholder = false}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isPlaceholder ? theme.textTheme.bodyMedium?.color?.withOpacity(0.6) : null,
            fontStyle: isPlaceholder ? FontStyle.italic : null,
          ),
        ),
      ],
    );
  }
}