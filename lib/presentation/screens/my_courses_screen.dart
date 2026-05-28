import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/error_widget.dart';
import '../providers/dashboard_provider.dart';

class MyCoursesScreen extends ConsumerStatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  ConsumerState<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends ConsumerState<MyCoursesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  static const _tabs = [
    (label: 'الكل',      status: 'all'),
    (label: 'قيد التعلم', status: 'active'),
    (label: 'المكتملة',   status: 'completed'),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دوراتي',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: _tabs
            .map((t) => _CoursesList(status: t.status))
            .toList(),
      ),
    );
  }
}

// ── قائمة الكورسات حسب الـ status ────────────────────────────────────────────

class _CoursesList extends ConsumerStatefulWidget {
  final String status;
  const _CoursesList({required this.status});

  @override
  ConsumerState<_CoursesList> createState() => _CoursesListState();
}

class _CoursesListState extends ConsumerState<_CoursesList> {
  int _page = 1;

  @override
  Widget build(BuildContext context) {
    final filter   = MyCoursesFilter(status: widget.status, page: _page);
    final async    = ref.watch(myCourseItemsProvider(filter));
    final theme    = Theme.of(context);

    return async.when(
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppErrorWidget(
        message: e.toString().replaceAll('Exception: ', ''),
        onRetry: () => ref.invalidate(myCourseItemsProvider(filter)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.menu_book_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                Text(
                  widget.status == 'completed'
                      ? 'لم تكمل أي دورة بعد'
                      : widget.status == 'active'
                          ? 'لا توجد دورات قيد التعلم'
                          : 'لم تسجّل في أي دورة بعد',
                  style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
                if (widget.status == 'all') ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.go('/courses'),
                    icon: const Icon(Icons.explore_rounded),
                    label: const Text('تصفح الدورات'),
                  ),
                ],
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(myCourseItemsProvider(filter)),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _MyCourseCard(item: items[i]),
          ),
        );
      },
    );
  }
}

// ── بطاقة الكورس ─────────────────────────────────────────────────────────────

class _MyCourseCard extends StatelessWidget {
  final MyCourseItem item;
  const _MyCourseCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final course  = item.course;

    return GestureDetector(
      onTap: () => context.push('/course/${course.id}'),
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail + completed badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: course.thumbnail.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: course.thumbnail,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                              height: 150,
                              color: theme.colorScheme.primaryContainer),
                        )
                      : Container(
                          height: 150,
                          color: theme.colorScheme.primaryContainer,
                          child: Icon(Icons.play_circle_outline,
                              size: 56, color: theme.colorScheme.primary)),
                ),
                if (item.isCourseCompleted)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.check_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text('مكتملة',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ]),
                    ),
                  ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.person_outline,
                        size: 14,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                    const SizedBox(width: 4),
                    Text(course.instructorName,
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6))),
                  ]),
                  const SizedBox(height: 12),

                  // Progress
                  if (!item.isCourseCompleted) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: item.completedPercent / 100,
                        minHeight: 7,
                        backgroundColor:
                            theme.colorScheme.primary.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(children: [
                      Text(
                        '${item.completedLessons}/${course.totalLessons} درس',
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5)),
                      ),
                      const Spacer(),
                      Text(
                        '${item.completedPercent}%',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                            fontSize: 13),
                      ),
                    ]),
                    const SizedBox(height: 12),
                  ],

                  // زر الاستكمال / المراجعة
                  SizedBox(
                    width: double.infinity,
                    child: item.isCourseCompleted
                        ? OutlinedButton.icon(
                            onPressed: () =>
                                context.push('/course/${course.id}'),
                            icon: const Icon(Icons.replay_rounded, size: 18),
                            label: const Text('مراجعة الدورة'),
                          )
                        : FilledButton.icon(
                            onPressed: () =>
                                context.push('/lessons/${course.id}'),
                            icon: const Icon(Icons.play_arrow_rounded, size: 18),
                            label: const Text('استكمل التعلم'),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
