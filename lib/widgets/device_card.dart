import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../providers/device_report_provider.dart';

class DeviceCard extends StatefulWidget {
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
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;
  Timer? _hoverTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _hoverTimer?.cancel();
    super.dispose();
  }

  void _handleHover(bool isHovered) {
    _hoverTimer?.cancel();
    _hoverTimer = Timer(const Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() => _isHovered = isHovered);
        if (isHovered) {
          _controller.forward();
        } else {
          _controller.reverse();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reportProvider = context.watch<DeviceReportProvider>();
    final TextEditingController descriptionController = TextEditingController();

    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Card(
            elevation: _isHovered ? 4 : 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.device['image_url'] != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl: widget.device['image_url'],
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 150,
                            color: theme.colorScheme.surfaceVariant,
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 150,
                            color: theme.colorScheme.surfaceVariant,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error, color: theme.colorScheme.error),
                                const SizedBox(height: 8),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(color: theme.colorScheme.error),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: _buildStatusChip(widget.device['status']?.toString() ?? 'Unknown', theme),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.device['name']?.toString() ?? 'Unnamed Device',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.devices, 'Type', widget.device['type']?.toString() ?? 'Unknown', theme, isPlaceholder: widget.device['type'] == null),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.business,
                        'Office',
                        widget.device['office_name']?.toString() ?? 'No office assigned',
                        theme,
                        isPlaceholder: widget.device['office_name'] == null,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: widget.onEdit,
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _showReportDialog(context, reportProvider, descriptionController),
                        icon: const Icon(Icons.report_problem),
                        label: const Text('Report'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: widget.onDelete,
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context, DeviceReportProvider reportProvider, TextEditingController descriptionController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Device'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Issue Description',
                hintText: 'Describe the issue...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            if (reportProvider.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  reportProvider.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: reportProvider.isLoading
                ? null
                : () async {
                    final success = await reportProvider.submitReport(
                      deviceId: widget.device['id'],
                      title: 'Device Issue Report',
                      description: descriptionController.text,
                      priority: 'Medium',
                      status: 'Pending',
                    );
                    if (success == true) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Report submitted successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
            child: reportProvider.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, ThemeData theme) {
    Color chipColor;
    IconData iconData;

    switch (status.toLowerCase()) {
      case 'available':
        chipColor = Colors.green;
        iconData = Icons.check_circle;
        break;
      case 'in use':
        chipColor = Colors.blue;
        iconData = Icons.access_time;
        break;
      case 'maintenance':
        chipColor = Colors.orange;
        iconData = Icons.build;
        break;
      case 'retired':
        chipColor = Colors.grey;
        iconData = Icons.block;
        break;
      default:
        chipColor = Colors.grey;
        iconData = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 16, color: chipColor),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: chipColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, ThemeData theme, {bool isPlaceholder = false}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
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
          ),
        ),
      ],
    );
  }
}