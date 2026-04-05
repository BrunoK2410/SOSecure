import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../auth/auth_view_model.dart';
import '../contacts/contacts_view_model.dart';
import '../history/history_view_model.dart';
import '../shared/sos_button.dart';
import '../map/map_view_model.dart';
import 'home_view_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _formatDate(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day.$month.$year at $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    final contactsViewModel = context.watch<ContactsViewModel>();
    final historyViewModel = context.watch<HistoryViewModel>();
    final mapViewModel = context.watch<MapViewModel>();
    final authViewModel = context.watch<AuthViewModel>();
    final currentUser = authViewModel.currentUser;
    final firstName = currentUser?.fullName.split(' ').first ?? 'User';

    if (viewModel.lastMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(viewModel.lastMessage!)));
        viewModel.clearMessage();
      });
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SOSecure', style: Theme.of(context).textTheme.titleLarge),
            Text(
              'Stay prepared, stay safe',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => context.push('/profile'),
              child: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, $firstName',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Your safety, one tap away.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _StatusChip(
                    icon: Icons.location_on,
                    label: (mapViewModel.isLocationPermissionGranted &&
                            mapViewModel.isLocationServiceEnabled)
                        ? 'Location active'
                        : 'Location inactive',
                    color: (mapViewModel.isLocationPermissionGranted &&
                            mapViewModel.isLocationServiceEnabled)
                        ? AppColors.success
                        : AppColors.danger,
                    onTap: () => context.go('/map'),
                  ),
                  const SizedBox(width: 12),
                  _StatusChip(
                    icon: Icons.contacts,
                    label: '${contactsViewModel.contactsCount} contact(s)',
                    color: AppColors.primary,
                    onTap: () => context.go('/contacts'),
                  ),
                ],
              ),
              const SizedBox(height: 44),

              Center(
                child: SosButton(
                  size: 260,
                  onCompleted: () async {
                    await context.read<HomeViewModel>().triggerSos();
                  },
                ),
              ),

              const SizedBox(height: 20),

              Center(
                child: Text(
                  viewModel.isSendingAlert
                      ? 'Sending SOS alert...'
                      : 'Press and hold to trigger alert',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: viewModel.isSendingAlert 
                    ? null 
                    : () => viewModel.broadcastSms(),
                  icon: const Icon(Icons.sms_outlined),
                  label: const Text('Broadcast SOS via SMS'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.history, color: AppColors.primary),
                  title: const Text('Last alert'),
                  subtitle: Text(
                    historyViewModel.hasEvents
                        ? '${_formatDate(historyViewModel.events.first.timestamp)} - ${historyViewModel.events.first.status}'
                        : 'No recent alerts',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.push('/history'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.outline),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
      ),
    );
  }
}
