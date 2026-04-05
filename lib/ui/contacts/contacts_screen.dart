import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../data/models/emergency_contact.dart';
import '../shared/app_text_field.dart';
import 'contacts_view_model.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ContactsViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Contacts')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddContactDialog(context),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: viewModel.hasContacts
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${viewModel.contactsCount} trusted contacts',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'These contacts will be notified during an emergency.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.swipe_left_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Swipe left to delete or tap to edit a contact.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.separated(
                        itemCount: viewModel.contacts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final contact = viewModel.contacts[index];

                          return Dismissible(
                            key: ValueKey(contact.id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) async {
                              return await _showDeleteConfirmationDialog(
                                context,
                                contact,
                              );
                            },
                            onDismissed: (_) {
                              context.read<ContactsViewModel>().deleteContact(
                                contact.id,
                              );

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${contact.name} was deleted'),
                                ),
                              );
                            },
                            background: Container(
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            child: Card(
                              child: InkWell(
                                onTap: () => _showEditContactDialog(context, contact),
                                borderRadius: BorderRadius.circular(12),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                                    child: const Icon(Icons.person, color: AppColors.primary),
                                  ),
                                  title: Row(
                                    children: [
                                      Text(contact.name),
                                      if (contact.uid != null) ...[
                                        const SizedBox(width: 6),
                                        const Icon(Icons.verified, size: 14, color: AppColors.success),
                                      ],
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(contact.phoneNumber),
                                      Text(
                                        contact.relationship,
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                )
              : _EmptyContactsState(
                  onAddPressed: () => _showAddContactDialog(context),
                ),
        ),
      ),
    );
  }

  void _showAddContactDialog(BuildContext context) {
    _showContactFormDialog(
      context,
      title: 'Add Emergency Contact',
      description: 'Add a trusted person who should be notified in an emergency.',
      buttonText: 'Add Contact',
      icon: Icons.person_add_alt_1_rounded,
      iconColor: AppColors.primary,
      onSubmit: ({
        required String name,
        required String phoneNumber,
        required String relationship,
        String? uid,
        String? linkedUserEmail,
      }) {
        context.read<ContactsViewModel>().addContact(
          name: name,
          phoneNumber: phoneNumber,
          relationship: relationship,
          uid: uid,
          linkedUserEmail: linkedUserEmail,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact added successfully')),
        );
      },
    );
  }

  void _showEditContactDialog(BuildContext context, EmergencyContact contact) {
    _showContactFormDialog(
      context,
      title: 'Edit Contact',
      description: 'Update the contact information below.',
      buttonText: 'Save Changes',
      icon: Icons.edit_rounded,
      iconColor: AppColors.primary,
      initialName: contact.name,
      initialPhoneNumber: contact.phoneNumber,
      initialRelationship: contact.relationship,
      initialUid: contact.uid,
      initialLinkedEmail: contact.linkedUserEmail,
      onSubmit: ({
        required String name,
        required String phoneNumber,
        required String relationship,
        String? uid,
        String? linkedUserEmail,
      }) {
        context.read<ContactsViewModel>().updateContact(
          id: contact.id,
          name: name,
          phoneNumber: phoneNumber,
          relationship: relationship,
          uid: uid,
          linkedUserEmail: linkedUserEmail,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact updated successfully')),
        );
      },
    );
  }

  void _showContactFormDialog(
    BuildContext context, {
    required String title,
    required String description,
    required String buttonText,
    required IconData icon,
    required Color iconColor,
    required void Function({
      required String name,
      required String phoneNumber,
      required String relationship,
      String? uid,
      String? linkedUserEmail,
    }) onSubmit,
    String initialName = '',
    String initialPhoneNumber = '',
    String initialRelationship = '',
    String? initialUid,
    String? initialLinkedEmail,
  }) {
    final nameController = TextEditingController(text: initialName);
    final phoneController = TextEditingController(text: initialPhoneNumber);
    final relationshipController = TextEditingController(text: initialRelationship);
    final emailController = TextEditingController(text: initialLinkedEmail ?? '');

    String? nameError;
    String? phoneError;
    String? relationshipError;
    String? linkedUid = initialUid;
    String? linkedName;
    bool isSearching = false;
    bool _hasFetchedLegacyData = false;

    bool isValidPhone(String phone) {
      final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      return RegExp(r'^\+?[0-9]{8,15}$').hasMatch(cleaned);
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (!_hasFetchedLegacyData && initialUid != null && emailController.text.isEmpty) {
              _hasFetchedLegacyData = true;
              Future.microtask(() async {
                try {
                  final user = await context.read<ContactsViewModel>().findUserById(initialUid);
                  if (user != null) {
                    setState(() {
                      emailController.text = user.email;
                      linkedName = user.fullName;
                    });
                  }
                } catch (_) {}
              });
            }
            Future<void> searchUser() async {
              final email = emailController.text.trim();
              if (email.isEmpty) return;

              setState(() {
                isSearching = true;
                linkedUid = null;
                linkedName = null;
              });

              try {
                final user = await context.read<ContactsViewModel>().findUserByEmail(email);
                setState(() {
                  if (user != null) {
                    linkedUid = user.id;
                    linkedName = user.fullName;
                    if (nameController.text.isEmpty) {
                      nameController.text = user.fullName;
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No SOSecure user found with this email')),
                    );
                  }
                });
              } finally {
                setState(() => isSearching = false);
              }
            }

            void validateAndSubmit() {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              final relationship = relationshipController.text.trim();

              setState(() {
                nameError = name.isEmpty ? 'Name is required' : null;
                phoneError = phone.isEmpty
                    ? 'Phone number is required'
                    : (!isValidPhone(phone) ? 'Enter a valid phone number' : null);
                relationshipError = relationship.isEmpty ? 'Relationship is required' : null;
              });

              if (nameError != null || phoneError != null || relationshipError != null) return;

              onSubmit(
                name: name,
                phoneNumber: phone,
                relationship: relationship,
                uid: linkedUid,
                linkedUserEmail: linkedUid != null ? emailController.text.trim() : null,
              );

              Navigator.of(dialogContext).pop();
            }

            final colorScheme = Theme.of(context).colorScheme;

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 30, color: iconColor),
                      ),
                      const SizedBox(height: 16),
                      Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(description, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 24),
                      
                      AppTextField(
                        label: 'Full name',
                        controller: nameController,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(Icons.person_outline),
                        errorText: nameError,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: 'Phone number (for SMS)',
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(Icons.phone_outlined),
                        errorText: phoneError,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: 'Relationship',
                        controller: relationshipController,
                        textInputAction: TextInputAction.done,
                        prefixIcon: const Icon(Icons.favorite_border),
                        errorText: relationshipError,
                      ),
                      const SizedBox(height: 24),
                      
                      // LINKING SECTION
                      Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          initiallyExpanded: initialUid != null,
                          tilePadding: EdgeInsets.zero,
                          title: Text(
                            'Connect to their SOSecure app',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colorScheme.primary),
                          ),
                          subtitle: Text(
                            'Optional: If they use SOSecure, they\'ll get instant push notifications instead of just SMS.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(top: 8, bottom: 8),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: colorScheme.outlineVariant),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: AppTextField(
                                          label: 'User email',
                                          controller: emailController,
                                          prefixIcon: const Icon(Icons.email_outlined),
                                          hintText: 'user@example.com',
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton.filledTonal(
                                        onPressed: isSearching ? null : searchUser,
                                        icon: isSearching 
                                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                          : const Icon(Icons.search),
                                      ),
                                    ],
                                  ),
                                  if (linkedUid != null) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.verified, size: 16, color: AppColors.success),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Linked: ${linkedName ?? 'Account Found'}',
                                              style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => setState(() => linkedUid = null),
                                            child: const Icon(Icons.close, size: 16, color: AppColors.success),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else if (emailController.text.isNotEmpty && !isSearching) ...[
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: TextButton.icon(
                                        onPressed: () {
                                          context.read<ContactsViewModel>().inviteContact(
                                            phoneController.text.trim(),
                                          );
                                        },
                                        icon: const Icon(Icons.sms_outlined, size: 16),
                                        label: const Text('Send app invite via SMS'),
                                        style: TextButton.styleFrom(
                                          backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.4),
                                          foregroundColor: colorScheme.primary,
                                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: validateAndSubmit,
                          child: Text(buttonText),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.onSurfaceVariant,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool?> _showDeleteConfirmationDialog(
    BuildContext context,
    EmergencyContact contact,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colorScheme = Theme.of(context).colorScheme;

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    size: 30,
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Delete Contact',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to remove ${contact.name} from your emergency contacts?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Text('Delete'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.onSurfaceVariant,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyContactsState extends StatelessWidget {
  final VoidCallback onAddPressed;

  const _EmptyContactsState({required this.onAddPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.contact_phone_outlined,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No emergency contacts yet',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Add trusted people who should be notified in an emergency. You can add family members, friends, or anyone you rely on.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colorScheme.outline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Add at least one contact',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add),
              label: const Text('Add Contact'),
            ),
          ],
        ),
      ),
    );
  }
}
