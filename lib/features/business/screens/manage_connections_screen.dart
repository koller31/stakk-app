import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/business_connection_model.dart';
import '../providers/business_connection_provider.dart';
import 'add_business_connection_screen.dart';

/// Screen for managing saved business OAuth connections
class ManageConnectionsScreen extends StatelessWidget {
  const ManageConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.elevatedSurface,
        title: Text(
          'Business Connections',
          style: TextStyle(color: AppColors.primaryText),
        ),
        iconTheme: IconThemeData(color: AppColors.primaryText),
      ),
      body: Consumer<BusinessConnectionProvider>(
        builder: (context, provider, _) {
          if (provider.connections.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.connections.length,
            itemBuilder: (context, index) {
              final connection = provider.connections[index];
              return _buildConnectionCard(context, connection, provider);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addConnection(context),
        backgroundColor: AppColors.primaryAccent,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business, size: 64, color: AppColors.secondaryText),
          const SizedBox(height: 16),
          Text(
            'No Business Connections',
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect to your employer\'s badge system\nto add a digital business ID.',
            style: TextStyle(color: AppColors.secondaryText, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _addConnection(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Connection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(
    BuildContext context,
    BusinessConnectionModel connection,
    BusinessConnectionProvider provider,
  ) {
    final isExpired = connection.isTokenExpired;
    final statusColor = isExpired ? Colors.orange : Colors.green;
    final statusText = isExpired ? 'Token Expired' : 'Connected';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.elevatedSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.subtleBorder),
      ),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryAccent.withValues(alpha: 0.2),
              child: Text(
                connection.providerName.isNotEmpty
                    ? connection.providerName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: AppColors.primaryAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              connection.providerName,
              style: TextStyle(
                color: AppColors.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Last synced: ${_formatDate(connection.updatedAt)}',
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: AppColors.subtleBorder, height: 1),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => provider.refreshConnection(connection.id),
                  icon: Icon(Icons.refresh, size: 18, color: AppColors.primaryAccent),
                  label: Text(
                    'Refresh',
                    style: TextStyle(color: AppColors.primaryAccent),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: AppColors.subtleBorder,
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () =>
                      _confirmDisconnect(context, connection, provider),
                  icon: Icon(Icons.link_off, size: 18, color: AppColors.errorRed),
                  label: Text(
                    'Disconnect',
                    style: TextStyle(color: AppColors.errorRed),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDisconnect(
    BuildContext context,
    BusinessConnectionModel connection,
    BusinessConnectionProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevatedSurface,
        title: Text(
          'Disconnect ${connection.providerName}?',
          style: TextStyle(color: AppColors.primaryText),
        ),
        content: Text(
          'This will remove the connection and any associated badge data.',
          style: TextStyle(color: AppColors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.secondaryText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                Text('Disconnect', style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.removeConnection(connection.id);
    }
  }

  Future<void> _addConnection(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddBusinessConnectionScreen(),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}/${date.year}';
  }
}
