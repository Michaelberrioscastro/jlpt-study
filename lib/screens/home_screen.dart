import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/database_service.dart';
import '../theme/app_colors.dart';
import 'practice/practice_home_screen.dart';
import 'kana_screen.dart';
import 'level_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;
  int _previousTab = 0;
  String _activeLevel = 'N5';

  final _studyNavigatorKey = GlobalKey<NavigatorState>();
  final _practiceNavigatorKey = GlobalKey<NavigatorState>();
  final _kanaNavigatorKey = GlobalKey<NavigatorState>();

  GlobalKey<NavigatorState>? _navigatorKeyFor(int index) {
    return switch (index) {
      1 => _studyNavigatorKey,
      2 => _practiceNavigatorKey,
      3 => _kanaNavigatorKey,
      _ => null,
    };
  }

  void _selectTab(int index) {
    if (_currentTab == index) {
      HapticFeedback.selectionClick();

      final navigator = _navigatorKeyFor(index)?.currentState;
      if (navigator != null && navigator.canPop()) {
        navigator.popUntil((route) => route.isFirst);
      }
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.selectionClick();

    setState(() {
      _previousTab = _currentTab;
      _currentTab = index;
    });
  }

  void _handleBack(bool didPop, Object? result) {
    if (didPop) return;

    final navigator = _navigatorKeyFor(_currentTab)?.currentState;

    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return;
    }

    if (_currentTab != 0) {
      FocusManager.instance.primaryFocus?.unfocus();

      setState(() {
        _previousTab = _currentTab;
        _currentTab = 0;
      });
    }
  }

  Widget _buildStudyNavigator() {
    return Navigator(
      key: _studyNavigatorKey,
      onGenerateRoute: (_) {
        return MaterialPageRoute<void>(
          builder: (_) => _StudyHub(
            initialLevel: _activeLevel,
            onLevelChanged: (level) {
              if (!mounted || _activeLevel == level) return;
              setState(() => _activeLevel = level);
            },
          ),
        );
      },
    );
  }

  Widget _buildPracticeNavigator() {
    return Navigator(
      key: _practiceNavigatorKey,
      onGenerateRoute: (_) {
        return MaterialPageRoute<void>(
          builder: (_) => const PracticeHomeScreen(),
        );
      },
    );
  }

  Widget _buildKanaNavigator() {
    return Navigator(
      key: _kanaNavigatorKey,
      onGenerateRoute: (_) {
        return MaterialPageRoute<void>(builder: (_) => const KanaScreen());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _OverviewHome(
        activeLevel: _activeLevel,
        onStudyTap: () => _selectTab(1),
        onPracticeTap: () => _selectTab(2),
        onKanaTap: () => _selectTab(3),
      ),
      _buildStudyNavigator(),
      _buildPracticeNavigator(),
      _buildKanaNavigator(),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.primaryStrong,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: PopScope<Object?>(
        canPop: _currentTab == 0,
        onPopInvokedWithResult: _handleBack,
        child: Scaffold(
          extendBody: false,
          body: Stack(
            children: [
              for (var index = 0; index < pages.length; index++)
                _AnimatedTabPage(
                  key: ValueKey('main-tab-$index'),
                  index: index,
                  selectedIndex: _currentTab,
                  previousIndex: _previousTab,
                  child: pages[index],
                ),
            ],
          ),
          bottomNavigationBar: _PremiumNavigationBar(
            selectedIndex: _currentTab,
            onSelected: _selectTab,
          ),
        ),
      ),
    );
  }
}

class _AnimatedTabPage extends StatelessWidget {
  final int index;
  final int selectedIndex;
  final int previousIndex;
  final Widget child;

  const _AnimatedTabPage({
    super.key,
    required this.index,
    required this.selectedIndex,
    required this.previousIndex,
    required this.child,
  });

  static const _duration = Duration(milliseconds: 230);
  static const _curve = Cubic(0.16, 1.0, 0.3, 1.0);

  @override
  Widget build(BuildContext context) {
    final active = index == selectedIndex;

    final targetOffset = active
        ? Offset.zero
        : index < selectedIndex
        ? const Offset(-0.018, 0)
        : const Offset(0.018, 0);

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !active,
        child: ExcludeSemantics(
          excluding: !active,
          child: AnimatedOpacity(
            opacity: active ? 1 : 0,
            duration: _duration,
            curve: active ? _curve : Curves.easeOutCubic,
            child: AnimatedSlide(
              offset: targetOffset,
              duration: _duration,
              curve: _curve,
              child: AnimatedScale(
                scale: active ? 1 : 0.994,
                duration: _duration,
                curve: _curve,
                alignment: Alignment.center,
                child: TickerMode(
                  enabled: active,
                  child: RepaintBoundary(child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _PremiumNavigationBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryStrong,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.brandGold.withValues(alpha: .28)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryStrong.withValues(alpha: .18),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onSelected,
            height: 70,
            backgroundColor: AppColors.primaryStrong,
            indicatorColor: AppColors.brandGold.withValues(alpha: .22),
            elevation: 0,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.school_outlined),
                selectedIcon: Icon(Icons.school_rounded),
                label: 'Study',
              ),
              NavigationDestination(
                icon: Icon(Icons.fact_check_outlined),
                selectedIcon: Icon(Icons.fact_check_rounded),
                label: 'Practice',
              ),
              NavigationDestination(
                icon: Icon(Icons.translate_outlined),
                selectedIcon: Icon(Icons.translate_rounded),
                label: 'Kana',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewHome extends StatefulWidget {
  final String activeLevel;
  final VoidCallback onStudyTap;
  final VoidCallback onPracticeTap;
  final VoidCallback onKanaTap;

  const _OverviewHome({
    required this.activeLevel,
    required this.onStudyTap,
    required this.onPracticeTap,
    required this.onKanaTap,
  });

  @override
  State<_OverviewHome> createState() => _OverviewHomeState();
}

class _OverviewHomeState extends State<_OverviewHome> {
  Map<String, int>? _counts;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _OverviewHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeLevel != widget.activeLevel) {
      _load();
    }
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      final counts = await DatabaseService.getStudyCounts(widget.activeLevel);
      if (!mounted) return;

      setState(() {
        _counts = counts;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _counts?['total'] ?? 0;
    final learned = _counts?['learned'] ?? 0;
    final due = _counts?['due'] ?? 0;
    final progress = total == 0 ? 0.0 : learned / total;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 112),
          children: [
            _OverviewHero(level: widget.activeLevel, due: due),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(
                    eyebrow: 'CONTINUE',
                    title: 'Today\'s study',
                    trailing: _MiniBadge(
                      icon: Icons.auto_graph_rounded,
                      label: widget.activeLevel,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ContinueCard(
                    level: widget.activeLevel,
                    progress: progress,
                    learned: learned,
                    total: total,
                    due: due,
                    loading: _loading,
                    onTap: widget.onStudyTap,
                  ),
                  const SizedBox(height: 28),
                  const _SectionTitle(
                    eyebrow: 'QUICK ACCESS',
                    title: 'What would you like to do?',
                  ),
                  const SizedBox(height: 12),
                  _HomeActionCard(
                    icon: Icons.school_rounded,
                    title: 'Study with SRS',
                    subtitle: 'Vocabulary, Kanji, Grammar, and Mix by level.',
                    accent: AppColors.primary,
                    accentSoft: AppColors.primarySoft,
                    onTap: widget.onStudyTap,
                  ),
                  const SizedBox(height: 10),
                  _HomeActionCard(
                    icon: Icons.fact_check_rounded,
                    title: 'JLPT Practice',
                    subtitle:
                        'Vocabulary, Grammar, and Reading with level-based tests.',
                    accent: AppColors.sage,
                    accentSoft: AppColors.sageSoft,
                    onTap: widget.onPracticeTap,
                  ),
                  const SizedBox(height: 10),
                  _HomeActionCard(
                    icon: Icons.translate_rounded,
                    title: 'Kana',
                    subtitle:
                        'Review Hiragana and Katakana while keeping your progress.',
                    accent: AppColors.gold,
                    accentSoft: AppColors.goldSoft,
                    onTap: widget.onKanaTap,
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

class _OverviewHero extends StatelessWidget {
  final String level;
  final int due;

  const _OverviewHero({required this.level, required this.due});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryContainer, AppColors.surface],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primaryStrong,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryStrong.withValues(alpha: .18),
                        blurRadius: 16,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: const Text(
                    'あ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'JLPT Study',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your Japanese study space',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                _HeaderPill(
                  icon: due > 0
                      ? Icons.notifications_active_outlined
                      : Icons.check_circle_outline_rounded,
                  label: due > 0 ? '$due' : '✓',
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'おかえりなさい',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              due > 0
                  ? 'You have $due reviews due in $level.'
                  : 'Your $level path is up to date. Choose how you\'d like to continue.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final String level;
  final double progress;
  final int learned;
  final int total;
  final int due;
  final bool loading;
  final VoidCallback onTap;

  const _ContinueCard({
    required this.level,
    required this.progress,
    required this.learned,
    required this.total,
    required this.due,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.outline),
          ),
          child: loading
              ? const _ContinueCardSkeleton()
              : Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: Text(
                            level,
                            style: const TextStyle(
                              color: AppColors.primaryStrong,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Continue $level',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$learned of $total learned · $due reviews',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.primaryStrong,
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 520),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(99),
                          color: AppColors.primaryStrong,
                          backgroundColor: AppColors.surfaceMuted,
                        );
                      },
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ContinueCardSkeleton extends StatelessWidget {
  const _ContinueCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 100,
      child: Column(
        children: [
          Row(
            children: [
              _SkeletonPulse(width: 54, height: 54, borderRadius: 17),
              SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonPulse(width: 132, height: 15, borderRadius: 8),
                    SizedBox(height: 9),
                    _SkeletonPulse(width: 205, height: 11, borderRadius: 7),
                  ],
                ),
              ),
              SizedBox(width: 18),
            ],
          ),
          Spacer(),
          _SkeletonPulse(width: double.infinity, height: 8, borderRadius: 99),
        ],
      ),
    );
  }
}

class _StudyCardSkeleton extends StatelessWidget {
  const _StudyCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 265,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.outline),
      ),
      child: const Column(
        children: [
          Row(
            children: [
              _SkeletonPulse(width: 64, height: 64, borderRadius: 20),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonPulse(width: 128, height: 17, borderRadius: 8),
                    SizedBox(height: 10),
                    _SkeletonPulse(width: 220, height: 11, borderRadius: 7),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 22),
          Row(
            children: [
              _SkeletonPulse(width: 135, height: 11, borderRadius: 7),
              Spacer(),
              _SkeletonPulse(width: 42, height: 11, borderRadius: 7),
            ],
          ),
          SizedBox(height: 9),
          _SkeletonPulse(width: double.infinity, height: 9, borderRadius: 99),
          SizedBox(height: 20),
          _SkeletonPulse(width: double.infinity, height: 58, borderRadius: 18),
          SizedBox(height: 18),
          _SkeletonPulse(width: double.infinity, height: 54, borderRadius: 18),
        ],
      ),
    );
  }
}

class _SkeletonPulse extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _SkeletonPulse({
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  State<_SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<_SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final color = Color.lerp(
          AppColors.surfaceMuted,
          AppColors.surfaceSoft,
          _animation.value,
        );

        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

class _HomeActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final Color accentSoft;
  final VoidCallback onTap;

  const _HomeActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.accentSoft,
    required this.onTap,
  });

  @override
  State<_HomeActionCard> createState() => _HomeActionCardState();
}

class _HomeActionCardState extends State<_HomeActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? .988 : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (value) => setState(() => _pressed = value),
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.outline),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: widget.accentSoft,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(widget.icon, color: widget.accent),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StudyHub extends StatefulWidget {
  final String initialLevel;
  final ValueChanged<String> onLevelChanged;

  const _StudyHub({required this.initialLevel, required this.onLevelChanged});

  @override
  State<_StudyHub> createState() => _StudyHubState();
}

class _StudyHubState extends State<_StudyHub> {
  static const List<String> _levels = ['N5', 'N4', 'N3', 'N2', 'N1'];

  late String _selectedLevel;
  Map<String, int>? _counts;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedLevel = widget.initialLevel;
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await DatabaseService.getStudyCounts(_selectedLevel);
      if (!mounted) return;

      setState(() {
        _counts = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _selectLevel(String level) async {
    if (_selectedLevel == level) return;

    setState(() => _selectedLevel = level);
    widget.onLevelChanged(level);
    await _loadCounts();
  }

  Future<void> _openLevel() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LevelScreen(level: _selectedLevel)),
    );

    if (!mounted) return;
    await _loadCounts();
  }

  @override
  Widget build(BuildContext context) {
    final total = _counts?['total'] ?? 0;
    final learned = _counts?['learned'] ?? 0;
    final learning = _counts?['learning'] ?? 0;
    final due = _counts?['due'] ?? 0;
    final newItems = _counts?['new'] ?? 0;
    final progress = total == 0 ? 0.0 : learned / total;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadCounts,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 112),
          children: [
            _HeroHeader(selectedLevel: _selectedLevel, overallDue: due),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(
                    eyebrow: 'JLPT PATH',
                    title: 'Your level',
                    trailing: _MiniBadge(
                      icon: Icons.auto_graph_rounded,
                      label: _selectedLevel,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _LevelRail(
                    levels: _levels,
                    selectedLevel: _selectedLevel,
                    onSelected: _selectLevel,
                  ),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final slide = Tween<Offset>(
                        begin: const Offset(.025, 0),
                        end: Offset.zero,
                      ).animate(animation);

                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(position: slide, child: child),
                      );
                    },
                    child: _buildLevelArea(
                      key: ValueKey(
                        '$_selectedLevel-$_loading-${_error != null}-$learned-$learning-$due-$newItems',
                      ),
                      progress: progress,
                      total: total,
                      learned: learned,
                      learning: learning,
                      due: due,
                      newItems: newItems,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const _FooterTip(
                    text:
                        'Your progress percentage only increases when you mark an item as Learned.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelArea({
    required Key key,
    required double progress,
    required int total,
    required int learned,
    required int learning,
    required int due,
    required int newItems,
  }) {
    if (_loading) {
      return _StudyCardSkeleton(key: key);
    }

    if (_error != null) {
      return _ErrorPanel(key: key, error: _error!, onRetry: _loadCounts);
    }

    return _PrimaryStudyCard(
      key: key,
      symbol: _selectedLevel,
      title: '$_selectedLevel profile',
      subtitle: 'Vocabulary · Kanji · Grammar · Mix',
      progress: progress,
      learned: learned,
      total: total,
      learning: learning,
      due: due,
      newItems: newItems,
      accent: AppColors.primary,
      accentSoft: AppColors.primarySoft,
      buttonLabel: 'Enter $_selectedLevel',
      onTap: total == 0 ? null : _openLevel,
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final String selectedLevel;
  final int overallDue;

  const _HeroHeader({required this.selectedLevel, required this.overallDue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryContainer, AppColors.surface],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primaryStrong,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    '学',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Study',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'SRS by JLPT level',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                _HeaderPill(
                  icon: overallDue > 0
                      ? Icons.notifications_active_outlined
                      : Icons.check_circle_outline_rounded,
                  label: overallDue > 0 ? '$overallDue' : '✓',
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              '今日は何を勉強する？',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Continue your $selectedLevel path or switch levels anytime.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: AppColors.primaryStrong),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primaryStrong,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String eyebrow;
  final String title;
  final Widget? trailing;

  const _SectionTitle({
    required this.eyebrow,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelRail extends StatelessWidget {
  final List<String> levels;
  final String selectedLevel;
  final ValueChanged<String> onSelected;

  const _LevelRail({
    required this.levels,
    required this.selectedLevel,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: levels.map((level) {
          final selected = selectedLevel == level;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: level == levels.last ? 0 : 5),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onSelected(level),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primaryStrong
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: selected
                        ? const [
                            BoxShadow(
                              color: Color(0x24102536),
                              blurRadius: 12,
                              offset: Offset(0, 5),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    level,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PrimaryStudyCard extends StatefulWidget {
  final String symbol;
  final String title;
  final String subtitle;
  final double progress;
  final int learned;
  final int total;
  final int learning;
  final int due;
  final int newItems;
  final Color accent;
  final Color accentSoft;
  final String buttonLabel;
  final VoidCallback? onTap;

  const _PrimaryStudyCard({
    super.key,
    required this.symbol,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.learned,
    required this.total,
    required this.learning,
    required this.due,
    required this.newItems,
    required this.accent,
    required this.accentSoft,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  State<_PrimaryStudyCard> createState() => _PrimaryStudyCardState();
}

class _PrimaryStudyCardState extends State<_PrimaryStudyCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.986 : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.outline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _pressed ? 0.025 : 0.045),
              blurRadius: _pressed ? 8 : 22,
              offset: Offset(0, _pressed ? 3 : 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: _setPressed,
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: widget.accentSoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.symbol,
                          style: TextStyle(
                            color: widget.accent,
                            fontSize: widget.symbol.length <= 2 ? 27 : 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              widget.subtitle,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  _AnimatedProgress(
                    progress: widget.progress,
                    accent: widget.accent,
                    learned: widget.learned,
                    total: widget.total,
                  ),

                  const SizedBox(height: 20),
                  _StatStrip(
                    learned: widget.learned,
                    learning: widget.learning,
                    due: widget.due,
                    newItems: widget.newItems,
                    accent: widget.accent,
                  ),

                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: widget.onTap,
                      style: FilledButton.styleFrom(
                        backgroundColor: widget.accent,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      label: Text(widget.buttonLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedProgress extends StatelessWidget {
  final double progress;
  final Color accent;
  final int learned;
  final int total;

  const _AnimatedProgress({
    required this.progress,
    required this.accent,
    required this.learned,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              '$learned / $total learned',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text(
              '${(progress * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                color: accent,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress),
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 9,
                color: accent,
                backgroundColor: AppColors.surfaceMuted,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _StatStrip extends StatelessWidget {
  final int learned;
  final int learning;
  final int due;
  final int newItems;
  final Color accent;

  const _StatStrip({
    required this.learned,
    required this.learning,
    required this.due,
    required this.newItems,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TinyStat(
              icon: Icons.check_rounded,
              label: 'Learned',
              value: learned,
              accent: accent,
            ),
          ),
          Expanded(
            child: _TinyStat(
              icon: Icons.school_outlined,
              label: 'Learning',
              value: learning,
              accent: accent,
            ),
          ),
          Expanded(
            child: _TinyStat(
              icon: Icons.schedule_rounded,
              label: 'Reviews',
              value: due,
              accent: accent,
            ),
          ),
          Expanded(
            child: _TinyStat(
              icon: Icons.auto_awesome_outlined,
              label: 'New',
              value: newItems,
              accent: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color accent;

  const _TinyStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: accent),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9.5),
        ),
      ],
    );
  }
}

class _FooterTip extends StatelessWidget {
  final String text;

  const _FooterTip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: AppColors.blue,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorPanel({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 38,
          ),
          const SizedBox(height: 12),
          Text(
            'Couldn\'t load your progress.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
