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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HomeViewModel>().loadSafetyPrefs();
    });
  }

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

    if (viewModel.lastMessage != null && !viewModel.silentSos) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final message = viewModel.lastMessage;
        if (message == null) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        viewModel.clearMessage();
      });
    }

    final String statusText;
    if (viewModel.isConfirmingSos) {
      statusText = viewModel.silentSos
          ? ''
          : 'Sending in ${viewModel.confirmCountdownSeconds}s — tap Cancel';
    } else if (viewModel.isSendingAlert) {
      statusText = viewModel.silentSos ? '' : 'Sending SOS alert...';
    } else if (viewModel.hasActiveAlert) {
      statusText = viewModel.silentSos
          ? ''
          : 'SOS is active — contacts notified';
    } else if (viewModel.confirmBeforeSend) {
      statusText = 'Press and hold to start 3s confirmation';
    } else {
      statusText = 'Press and hold to trigger alert';
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
              onTap: () async {
                final homeVm = context.read<HomeViewModel>();
                await context.push('/profile');
                if (!mounted) return;
                homeVm.loadSafetyPrefs();
              },
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
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SosButton(
                      size: 260,
                      silentMode: viewModel.silentSos,
                      enabled: !viewModel.isSendingAlert &&
                          !viewModel.isConfirmingSos,
                      onCompleted: () {
                        context.read<HomeViewModel>().onSosHoldCompleted();
                      },
                    ),
                    if (viewModel.isConfirmingSos && !viewModel.silentSos)
                      IgnorePointer(
                        child: Text(
                          '${viewModel.confirmCountdownSeconds}',
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Center(
                child: Text(
                  statusText,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (viewModel.isConfirmingSos) ...[
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: viewModel.cancelConfirmCountdown,
                    child: Text(
                      viewModel.silentSos ? 'Cancel' : 'Cancel SOS',
                    ),
                  ),
                ),
              ],
              if (viewModel.hasActiveAlert && !viewModel.isConfirmingSos) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: viewModel.isResolvingAlert
                        ? null
                        : () => viewModel.resolveActiveAlert(),
                    icon: viewModel.isResolvingAlert
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: const Text("I'm Safe (Resolve Alert)"),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: viewModel.isSendingAlert || viewModel.isConfirmingSos
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
