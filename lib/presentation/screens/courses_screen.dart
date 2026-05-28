import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/error_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../domain/entities/course.dart';
import '../providers/auth_provider.dart';
import '../providers/courses_provider.dart';
import '../widgets/course_card.dart';

// ── Filter State ──────────────────────────────────────────────────────────────

class _FilterState {
  final String search;
  final String instructor;
  final String sortBy; // 'newest' | 'popular' | 'rating'

  const _FilterState({
    this.search     = '',
    this.instructor = '',
    this.sortBy     = 'newest',
  });

  _FilterState copyWith({String? search, String? instructor, String? sortBy}) =>
      _FilterState(
        search:     search     ?? this.search,
        instructor: instructor ?? this.instructor,
        sortBy:     sortBy     ?? this.sortBy,
      );

  bool get hasActiveFilter =>
      search.isNotEmpty || instructor.isNotEmpty || sortBy != 'newest';
}

// ── Screen ────────────────────────────────────────────────────────────────────

class CoursesScreen extends ConsumerStatefulWidget {
  const CoursesScreen({super.key});

  @override
  ConsumerState<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends ConsumerState<CoursesScreen> {
  final _scrollCtrl  = ScrollController();
  final _searchCtrl  = TextEditingController();
  var _filter        = const _FilterState();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // FIX: تأخير الطلب حتى تكتمل المصادقة واستعادة الـ nonce
      // courses endpoint يتطلب token+nonce في هذا الخادم
      _fetchWhenReady();
    });
  }

  Future<void> _fetchWhenReady() async {
    // انتظر حتى يخرج authProvider من AuthInitial (بحد أقصى 5 ثوان)
    for (var i = 0; i < 50; i++) {
      final s = ref.read(authProvider);
      if (s is! AuthInitial) break;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (!mounted) return;
    ref.read(coursesProvider.notifier).fetchCourses();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(coursesProvider.notifier).loadMore();
    }
  }

  // ── Filter courses locally ────────────────────────────────────────────────

  List<Course> _applyFilter(List<Course> courses) {
    var result = courses;

    if (_filter.search.isNotEmpty) {
      final q = _filter.search.toLowerCase();
      result = result.where((c) =>
          c.title.toLowerCase().contains(q) ||
          c.instructorName.toLowerCase().contains(q)).toList();
    }

    if (_filter.instructor.isNotEmpty) {
      result = result
          .where((c) => c.instructorName == _filter.instructor)
          .toList();
    }

    switch (_filter.sortBy) {
      case 'popular':
        result = [...result]
          ..sort((a, b) => b.totalEnrolled.compareTo(a.totalEnrolled));
        break;
      case 'rating':
        result = [...result]..sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }

    return result;
  }

  // ── Unique instructor list ────────────────────────────────────────────────

  List<String> _getInstructors(List<Course> courses) {
    final names = courses.map((c) => c.instructorName).toSet().toList();
    names.sort();
    return names;
  }

  @override
  Widget build(BuildContext context) {
    final state  = ref.watch(coursesProvider);
    final theme  = Theme.of(context);
    final filtered = _applyFilter(state.courses);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(coursesProvider.notifier).fetchCourses(refresh: true),
        child: CustomScrollView(
          controller: _scrollCtrl,
          slivers: [
            // ── AppBar with search ────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              floating: true,
              snap: true,
              backgroundColor: AppTheme.brandRed,
              foregroundColor: Colors.white,
              expandedHeight: 0,
              title: const Text('الدورات التعليمية',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              centerTitle: true,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  color: AppTheme.brandRed,
                  padding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) =>
                            setState(() => _filter = _filter.copyWith(search: v)),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'ابحث عن دورة أو معلم...',
                          hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 14),
                          prefixIcon: Icon(Icons.search_rounded,
                              color: Colors.white.withValues(alpha: 0.8)),
                          suffixIcon: _filter.search.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.close_rounded,
                                      color:
                                          Colors.white.withValues(alpha: 0.8)),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _filter =
                                        _filter.copyWith(search: ''));
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.15),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Filter button
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.tune_rounded,
                              color: Colors.white),
                          onPressed: () =>
                              _showFilterSheet(context, state.courses),
                        ),
                        if (_filter.hasActiveFilter)
                          Positioned(
                            top: 6, right: 6,
                            child: Container(
                              width: 8, height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.brandGold,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ]),
                ),
              ),
            ),

            // ── Filter chips row ──────────────────────────────────────────
            if (_filter.hasActiveFilter)
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(children: [
                    if (_filter.search.isNotEmpty)
                      _FilterChip(
                        label: 'بحث: ${_filter.search}',
                        onDelete: () {
                          _searchCtrl.clear();
                          setState(
                              () => _filter = _filter.copyWith(search: ''));
                        },
                      ),
                    if (_filter.instructor.isNotEmpty)
                      _FilterChip(
                        label: _filter.instructor,
                        icon: Icons.person_outline,
                        onDelete: () => setState(
                            () => _filter = _filter.copyWith(instructor: '')),
                      ),
                    if (_filter.sortBy != 'newest')
                      _FilterChip(
                        label: _sortLabel(_filter.sortBy),
                        icon: Icons.sort_rounded,
                        onDelete: () => setState(
                            () => _filter = _filter.copyWith(sortBy: 'newest')),
                      ),
                    TextButton(
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _filter = const _FilterState());
                      },
                      child: const Text('مسح الكل'),
                    ),
                  ]),
                ),
              ),

            // ── Content ───────────────────────────────────────────────────
            if (state.isLoading && state.courses.isEmpty)
              const SliverToBoxAdapter(
                  child: Padding(
                      padding: EdgeInsets.only(top: 32),
                      child: AppLoadingWidget(itemCount: 4)))
            else if (state.error != null && state.courses.isEmpty)
              SliverToBoxAdapter(
                  child: AppErrorWidget(
                      message: state.error!,
                      onRetry: () => ref
                          .read(coursesProvider.notifier)
                          .fetchCourses(refresh: true)))
            else if (filtered.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded,
                          size: 64,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      Text(
                        _filter.hasActiveFilter
                            ? 'لا توجد نتائج للفلتر الحالي'
                            : 'لا توجد دورات متاحة حالياً',
                        style: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // Count
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: Row(children: [
                    Text(
                      '${filtered.length} دورة',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55)),
                    ),
                    if (state.total > filtered.length) ...[
                      Text(' من ${state.total}',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4))),
                    ],
                  ]),
                ),
              ),

              // Grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => CourseCard(
                      course: filtered[i],
                      onTap: () => context.push('/course/${filtered[i].id}'),
                    ),
                    childCount: filtered.length,
                  ),
                ),
              ),

              // Load more
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: state.isLoadingMore
                      ? const Center(child: CircularProgressIndicator())
                      : state.hasMore
                          ? const SizedBox.shrink()
                          : Center(
                              child: Text(
                                'تم عرض جميع الدورات',
                                style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.4)),
                              ),
                            ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _sortLabel(String s) {
    switch (s) {
      case 'popular': return 'الأكثر تسجيلاً';
      case 'rating':  return 'الأعلى تقييماً';
      default:        return 'الأحدث';
    }
  }

  // ── Filter Bottom Sheet ───────────────────────────────────────────────────

  void _showFilterSheet(BuildContext context, List<Course> courses) {
    final instructors = _getInstructors(courses);
    var tempFilter    = _filter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, ctrl) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(children: [
                    Text('فلترة النتائج',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setModal(() => tempFilter = const _FilterState());
                      },
                      child: const Text('إعادة ضبط'),
                    ),
                  ]),
                ),
                const Divider(height: 1),

                Expanded(
                  child: ListView(
                    controller: ctrl,
                    padding: const EdgeInsets.all(20),
                    children: [
                      // ── Sort ───────────────────────────────────────────
                      Text('ترتيب حسب',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, children: [
                        for (final s in [
                          ('newest',  'الأحدث',          Icons.new_releases_rounded),
                          ('popular', 'الأكثر تسجيلاً',  Icons.people_rounded),
                          ('rating',  'الأعلى تقييماً',  Icons.star_rounded),
                        ])
                          ChoiceChip(
                            avatar: Icon(s.$3, size: 16),
                            label: Text(s.$2),
                            selected: tempFilter.sortBy == s.$1,
                            onSelected: (_) =>
                                setModal(() => tempFilter =
                                    tempFilter.copyWith(sortBy: s.$1)),
                          ),
                      ]),

                      const SizedBox(height: 24),

                      // ── Instructor ─────────────────────────────────────
                      if (instructors.isNotEmpty) ...[
                        Row(children: [
                          Text('المعلم',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          if (tempFilter.instructor.isNotEmpty)
                            TextButton(
                              onPressed: () => setModal(() =>
                                  tempFilter = tempFilter.copyWith(instructor: '')),
                              child: const Text('الكل'),
                            ),
                        ]),
                        const SizedBox(height: 8),
                        ...instructors.map((name) => RadioListTile<String>(
                              title: Text(name, style: const TextStyle(fontSize: 14)),
                              value: name,
                              groupValue: tempFilter.instructor,
                              onChanged: (v) => setModal(() =>
                                  tempFilter = tempFilter.copyWith(instructor: v ?? '')),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            )),
                      ],

                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // Apply button
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          setState(() => _filter = tempFilter);
                          Navigator.pop(ctx);
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('تطبيق الفلتر',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Filter Chip Widget ────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onDelete;

  const _FilterChip({required this.label, this.icon, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        avatar: icon != null
            ? Icon(icon, size: 14, color: theme.colorScheme.primary)
            : null,
        label: Text(label,
            style: TextStyle(
                fontSize: 12, color: theme.colorScheme.primary)),
        backgroundColor:
            theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        deleteIcon: Icon(Icons.close_rounded,
            size: 14, color: theme.colorScheme.primary),
        onDeleted: onDelete,
        side: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.3)),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
