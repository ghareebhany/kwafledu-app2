import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/error_widget.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState    = ref.watch(authProvider);
    final userId       = authState is AuthAuthenticated ? authState.user.id : 0;

    // Show loading while auth resolves
    if (authState is AuthInitial || authState is AuthLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (userId == 0) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final profileAsync = ref.watch(profileProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('ملفي الشخصي',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'تسجيل الخروج',
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
          message: e.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(profileProvider(userId)),
        ),
        data: (user) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // ── Avatar ──────────────────────────────────────────────
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    backgroundImage: user.avatarUrl.isNotEmpty
                        ? CachedNetworkImageProvider(user.avatarUrl)
                        : null,
                    child: user.avatarUrl.isEmpty
                        ? Icon(Icons.person,
                            size: 56, color: theme.colorScheme.primary)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                user.displayName.isNotEmpty ? user.displayName : 'المستخدم',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
              ),
              const SizedBox(height: 32),
              _InfoTile(
                icon: Icons.info_outline,
                label: 'نبذة عني',
                value: user.bio.isNotEmpty ? user.bio : 'لم تتم الإضافة بعد',
              ),
              if (user.website.isNotEmpty)
                _InfoTile(
                  icon: Icons.link,
                  label: 'الموقع',
                  value: user.website,
                ),
              if (user.phone.isNotEmpty)
                _InfoTile(
                  icon: Icons.phone_outlined,
                  label: 'الهاتف',
                  value: user.phone,
                ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () => _showEditSheet(
                    context, ref, userId, user.displayName, user.bio, user.phone),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('تعديل الملف الشخصي'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, int userId,
      String name, String bio, String phone) {
    final nameCtrl  = TextEditingController(text: name);
    final bioCtrl   = TextEditingController(text: bio);
    final phoneCtrl = TextEditingController(text: phone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('تعديل الملف الشخصي',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildTextField(nameCtrl, 'الاسم', Icons.person_outline),
            const SizedBox(height: 12),
            _buildTextField(bioCtrl, 'نبذة عني', Icons.info_outline,
                maxLines: 3),
            const SizedBox(height: 12),
            _buildTextField(phoneCtrl, 'الهاتف', Icons.phone_outlined,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 20),
            Consumer(builder: (_, ref, __) {
              final state = ref.watch(updateProfileProvider);
              return FilledButton(
                onPressed: state.isLoading
                    ? null
                    : () async {
                        await ref
                            .read(updateProfileProvider.notifier)
                            .update({
                          'display_name': nameCtrl.text.trim(),
                          'description': bioCtrl.text.trim(),
                          'phone': phoneCtrl.text.trim(),
                        });
                        final updated = ref.read(updateProfileProvider);
                        if (updated.success && ctx.mounted) {
                          Navigator.pop(ctx);
                          ref.invalidate(profileProvider(userId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم تحديث الملف بنجاح'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else if (updated.error != null && ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(updated.error!)),
                          );
                        }
                      },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: state.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('حفظ التغييرات'),
              );
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.5))),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 15)),
          ]),
        ],
      ),
    );
  }
}
