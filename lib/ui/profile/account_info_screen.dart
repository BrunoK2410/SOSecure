import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../auth/auth_view_model.dart';

class AccountInfoScreen extends StatelessWidget {
  const AccountInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Account Information')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: user == null
              ? const Center(child: Text('No user data available'))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoSection(
                      title: 'Public Profile',
                      items: [
                        _InfoItem(
                          label: 'Full Name',
                          value: user.fullName,
                          icon: Icons.person_outline,
                        ),
                        _InfoItem(
                          label: 'Email Address',
                          value: user.email,
                          icon: Icons.email_outlined,
                          isLast: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _InfoSection(
                      title: 'Account Security',
                      items: [
                        _InfoItem(
                          label: 'User ID',
                          value: user.id,
                          icon: Icons.fingerprint,
                          isLast: true,
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<_InfoItem> items;

  const _InfoSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Card(
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isLast;

  const _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
          title: Text(label, style: Theme.of(context).textTheme.bodySmall),
          subtitle: Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 56),
      ],
    );
  }
}
