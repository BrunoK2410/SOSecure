import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../auth/auth_view_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: user == null
              ? const Center(child: Text('No user information available'))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                user.fullName.isNotEmpty
                                    ? user.fullName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            user.fullName,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            user.email,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Card(
                      child: Column(
                        children: const [
                          ListTile(
                            leading: Icon(Icons.person_outline),
                            title: Text('Account information'),
                            subtitle: Text('Manage your personal details'),
                          ),
                          Divider(height: 1),
                          ListTile(
                            leading: Icon(Icons.security_outlined),
                            title: Text('Safety preferences'),
                            subtitle: Text('Configure alert behavior'),
                          ),
                          Divider(height: 1),
                          ListTile(
                            leading: Icon(Icons.palette_outlined),
                            title: Text('Appearance'),
                            subtitle: Text('Light / dark mode follows system'),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          await context.read<AuthViewModel>().logout();
                        },
                        child: const Text('Log Out'),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
