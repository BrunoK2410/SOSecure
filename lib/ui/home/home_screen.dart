import 'package:provider/provider.dart';
import 'home_view_model.dart';
import '../shared/sos_button.dart';
import '../../app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();

    if (viewModel.lastMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(viewModel.lastMessage!)));
        viewModel.clearMessage();
      });
    }
    return Scaffold(
      appBar: AppBar(title: const Text('SOSecure')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back',
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
                    label: viewModel.isLocationActive
                        ? 'Location active'
                        : 'Location inactive',
                    color: viewModel.isLocationActive
                        ? AppColors.success
                        : AppColors.danger,
                  ),
                  const SizedBox(width: 12),
                  _StatusChip(
                    icon: Icons.contacts,
                    label: '${viewModel.contactsCount} contacts',
                    color: AppColors.primary,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              Center(
                child: SosButton(
                  onCompleted: () async {
                    await context.read<HomeViewModel>().triggerSos();
                  },
                ),
              ),

              const SizedBox(height: 16),

              Center(
                child: Text(
                  viewModel.isSendingAlert
                      ? 'Sending SOS alert...'
                      : 'Press and hold to trigger alert',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),

              const SizedBox(height: 32),

              _ActionCard(
                icon: Icons.contact_phone,
                title: 'Emergency Contacts',
                subtitle: 'Add and manage trusted contacts',
                onTap: () => context.push('/contacts'),
              ),
              const SizedBox(height: 16),
              _ActionCard(
                icon: Icons.map,
                title: 'My Location',
                subtitle: 'View your current location on the map',
                onTap: () => context.push('/contacts'),
              ),
              const SizedBox(height: 16),
              _ActionCard(
                icon: Icons.history,
                title: 'Alert History',
                subtitle: 'Review previous SOS events',
                onTap: () => context.push('/map'),
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

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      ),
    );
  }
}
