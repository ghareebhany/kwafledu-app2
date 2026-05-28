import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/user.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/error_widget.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/profile_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme        = Theme.of(context);
    final authState    = ref.watch(authProvider);
    final dashAsync    = ref.watch(dashboardProvider);
    final userId       = authState is AuthAuthenticated ? authState.user.id : 0;
    // profileProvider guards itself — safe to call even during transition
    final profileAsync = userId > 0
        ? ref.watch(profileProvider(userId))
        : const AsyncValue<User>.loading();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardProvider);
          if (userId > 0) ref.invalidate(profileProvider(userId));
        },
        child: CustomScrollView(
          slivers: [
            // ── SliverAppBar ────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 175,
              pinned: true,
              backgroundColor: AppTheme.brandRed,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFE52027),
                        Color(0xFFBF1219),
                        Color(0xFF8B0D12),
                      ],
                      stops: [0.0, 0.55, 1.0],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -30, right: -20,
                        child: Container(
                          width: 120, height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -20, left: -30,
                        child: Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.04),
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 52, height: 52,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(6),
                                child: const AppLogo(size: 40),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: profileAsync.when(
                                  loading: () => const SizedBox.shrink(),
                                  error: (_, __) => const SizedBox.shrink(),
                                  data: (user) => Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'مرحباً، ${user?.displayName ?? ''} 👋',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'استمر في التعلم اليوم',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.8),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.logout_rounded,
                                    color: Colors.white),
                                onPressed: () async {
                                  final ok = await _confirmLogout(context);
                                  if (ok == true) {
                                    ref.read(authProvider.notifier).logout();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Stats ───────────────────────────────────────────────────
            dashAsync.when(
              loading: () => const SliverToBoxAdapter(
                  child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()))),
              error: (e, _) => SliverToBoxAdapter(
                  child: AppErrorWidget(
                      message: e.toString().replaceAll('Exception: ', ''),
                      onRetry: () => ref.invalidate(dashboardProvider))),
              data: (stats) => SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text('إحصائياتك',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(children: [
                      Expanded(
                          child: _StatCard(
                              icon: Icons.book_outlined,
                              label: 'مسجّل فيها',
                              value: '${stats.enrolledCount}',
                              color: theme.colorScheme.primary)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _StatCard(
                              icon: Icons.play_circle_outline,
                              label: 'قيد التعلم',
                              value: '${stats.activeCount}',
                              color: Colors.orange)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _StatCard(
                              icon: Icons.check_circle_outline,
                              label: 'مكتملة',
                              value: '${stats.completedCount}',
                              color: Colors.green)),
                    ]),
                  ),

                  if (stats.inProgress.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Row(children: [
                        Text('استكمل تعلمك',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        TextButton(
                          onPressed: () => context.push('/my-courses'),
                          child: const Text('عرض الكل'),
                        ),
                      ]),
                    ),
                    ...stats.inProgress.map((c) => _InProgressCard(item: c)),
                    const SizedBox(height: 8),
                  ],

                  if (stats.enrolledCount == 0)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.school_outlined,
                              size: 72,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.2)),
                          const SizedBox(height: 16),
                          Text('لم تسجّل في أي دورة بعد',
                              style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5))),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () => context.go('/courses'),
                            icon: const Icon(Icons.explore_rounded),
                            label: const Text('تصفح الدورات'),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmLogout(BuildContext context) => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('تسجيل الخروج'),
          content: const Text('هل تريد تسجيل الخروج؟'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('خروج')),
          ],
        ),
      );
}

// ── بطاقة إحصاء ───────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 11,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6))),
      ]),
    );
  }
}

// ── بطاقة كورس قيد التقدم ────────────────────────────────────────────────────

class _InProgressCard extends StatelessWidget {
  final InProgressCourse item;
  const _InProgressCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => context.push('/course/${item.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(right: Radius.circular(16)),
            child: item.thumbnail.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: item.thumbnail,
                    width: 90, height: 90,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                        width: 90, height: 90,
                        color: theme.colorScheme.primaryContainer,
                        child: Icon(Icons.play_circle_outline,
                            color: theme.colorScheme.primary)),
                  )
                : Container(
                    width: 90, height: 90,
                    color: theme.colorScheme.primaryContainer,
                    child: Icon(Icons.play_circle_outline,
                        color: theme.colorScheme.primary)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: item.completedPercent / 100,
                      minHeight: 6,
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    Text(
                      '${item.completedLessons}/${item.totalLessons} درس',
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5)),
                    ),
                    const Spacer(),
                    Text(
                      '${item.completedPercent}%',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary),
                    ),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
        ]),
      ),
    );
  }
}
