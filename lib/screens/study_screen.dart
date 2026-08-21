import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/study_item.dart';
import '../services/database_service.dart';
import '../services/srs_service.dart';
import '../theme/app_colors.dart';

class StudyScreen extends StatefulWidget {
  final String level;
  final String studyType;

  const StudyScreen({super.key, required this.level, this.studyType = 'mix'});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  List<StudyItem> _items = [];
  Map<String, dynamic>? _details;

  bool _loading = true;
  bool _revealed = false;
  bool _saving = false;
  String? _error;

  int _index = 0;
  int _againCount = 0;
  int _hardCount = 0;
  int _goodCount = 0;
  int _easyCount = 0;
  int _learnedCount = 0;
  int _retryCount = 0;

  // Items rated "Otra vez" remain unresolved until they later receive
  // Difícil/Bien/Fácil or are marked Aprendida.
  final Set<String> _pendingAgain = <String>{};

  StudyItem? get _current {
    if (_index < 0 || _index >= _items.length) {
      return null;
    }

    return _items[_index];
  }

  String _itemKey(StudyItem item) => '${item.type}:${item.id}';

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final List<StudyItem> loaded;
      if (widget.level == 'BEGINNER') {
        loaded = await DatabaseService.getTodayBeginnerItems(limit: 20);
      } else if (widget.level == 'KANA') {
        loaded = await DatabaseService.getTodayKanaItems(
          script: widget.studyType,
          dueReviewLimit: 20,
          learningLimit: 2,
          newLimit: 8,
        );
      } else {
        loaded = await DatabaseService.getTodayStudyItems(
          level: widget.level,
          studyType: widget.studyType,
          dueReviewLimit: 20,
          learningLimit: 2,
          newLimit: 8,
        );
      }

      if (!mounted) return;

      setState(() {
        _items = loaded;
        _loading = false;
        _error = null;
      });

      if (_items.isNotEmpty) {
        await _loadDetails();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadDetails() async {
    final item = _current;

    if (item == null) {
      return;
    }

    try {
      final result = await DatabaseService.getItemDetails(item);

      if (!mounted) return;

      setState(() {
        _details = result;
        _revealed = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });
    }
  }

  void _revealAnswer() {
    if (_revealed || _saving) return;

    HapticFeedback.lightImpact();
    setState(() => _revealed = true);
  }

  void _feedbackForRating(ReviewRating rating) {
    switch (rating) {
      case ReviewRating.again:
        HapticFeedback.mediumImpact();
        break;
      case ReviewRating.hard:
        HapticFeedback.selectionClick();
        break;
      case ReviewRating.good:
        HapticFeedback.lightImpact();
        break;
      case ReviewRating.easy:
        HapticFeedback.mediumImpact();
        break;
    }
  }

  Future<void> _rate(ReviewRating rating) async {
    final item = _current;

    if (item == null || _saving) {
      return;
    }

    _feedbackForRating(rating);

    setState(() {
      _saving = true;
    });

    try {
      await SrsService.review(item, rating);

      final itemKey = _itemKey(item);

      switch (rating) {
        case ReviewRating.again:
          _againCount += 1;
          _retryCount += 1;
          _pendingAgain.add(itemKey);

          // "Otra vez" nunca resuelve la tarjeta. Reaparece tras hasta
          // dos tarjetas distintas. Si vuelve a recibir "Otra vez", se
          // programa de nuevo y la sesión no puede terminar con ella pendiente.
          final retryIndex = (_index + 3).clamp(0, _items.length);
          _items.insert(retryIndex, item);
          break;
        case ReviewRating.hard:
          _hardCount += 1;
          _pendingAgain.remove(itemKey);
          break;
        case ReviewRating.good:
          _goodCount += 1;
          _pendingAgain.remove(itemKey);
          break;
        case ReviewRating.easy:
          _easyCount += 1;
          _pendingAgain.remove(itemKey);
          break;
      }

      _index += 1;

      if (!mounted) return;

      if (_current == null) {
        setState(() {
          _saving = false;
          _details = null;
        });
        return;
      }

      setState(() {
        _saving = false;
        _details = null;
        _revealed = false;
      });

      await _loadDetails();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _markLearned() async {
    final item = _current;
    if (item == null || _saving) return;

    HapticFeedback.mediumImpact();
    setState(() => _saving = true);

    try {
      await DatabaseService.setLearned(item, learned: true);
      _pendingAgain.remove(_itemKey(item));
      _learnedCount += 1;
      _index += 1;

      if (!mounted) return;

      if (_current == null) {
        setState(() {
          _saving = false;
          _details = null;
        });
        return;
      }

      setState(() {
        _saving = false;
        _details = null;
        _revealed = false;
      });
      await _loadDetails();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  String get _studyTypeLabel {
    switch (widget.studyType) {
      case 'vocab':
        return 'Vocabulary';
      case 'kanji':
        return 'Kanji';
      case 'grammar':
        return 'Grammar';
      case 'hiragana':
        return 'Hiragana';
      case 'katakana':
        return 'Katakana';
      case 'beginner':
        return 'Review';
      case 'mix':
      default:
        return 'Mix';
    }
  }

  String _questionFor(String type) {
    switch (type) {
      case 'kanji':
        return 'Do you remember its meaning and reading?';
      case 'grammar':
        return 'What does this grammar pattern express?';
      case 'kana':
        return 'Do you remember how to read this kana?';
      case 'beginner':
        return 'Do you remember what this expression means?';
      case 'vocab':
      default:
        return 'Do you know this word?';
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'kanji':
        return 'KANJI';
      case 'grammar':
        return 'GRAMMAR';
      case 'vocab':
        return 'VOCABULARY';
      case 'kana':
        return 'KANA';
      case 'beginner':
        return 'BEGINNER';
      default:
        return type.toUpperCase();
    }
  }

  bool get _canManageGrammar =>
      widget.studyType == 'grammar' &&
      widget.level != 'BEGINNER' &&
      widget.level != 'KANA';

  Future<void> _openGrammarManager() async {
    if (!_canManageGrammar) return;

    HapticFeedback.selectionClick();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.92,
          child: _GrammarManagerSheet(level: widget.level),
        );
      },
    );
  }

  Widget _buildGrammarManagerButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _openGrammarManager,
        icon: const Icon(Icons.manage_search_rounded),
        label: const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Browse and mark grammar',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _StudySessionSkeleton(
        level: widget.level,
        studyType: _studyTypeLabel,
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.level)),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.outline),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: .10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Something went wrong during this session.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _loading = true;
                        _error = null;
                      });
                      _loadSession();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.level)),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    color: AppColors.sageSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.sage,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Nothing due right now',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You are all caught up for now.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (_canManageGrammar) ...[
                  const SizedBox(height: 22),
                  _buildGrammarManagerButton(),
                ],
              ],
            ),
          ),
        ),
      );
    }

    if (_current == null) {
      return _buildSummary();
    }

    final item = _current!;
    final progress = (_index + 1) / _items.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(
          '${widget.level} · $_studyTypeLabel',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_index + 1}/${_items.length}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  color: AppColors.primaryStrong,
                  backgroundColor: AppColors.surfaceMuted,
                );
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                child: Column(
                  children: [
                    if (_canManageGrammar) ...[
                      _buildGrammarManagerButton(),
                      const SizedBox(height: 14),
                    ],
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        final slide = Tween<Offset>(
                          begin: const Offset(.025, .01),
                          end: Offset.zero,
                        ).animate(animation);

                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(position: slide, child: child),
                        );
                      },
                      child: _StudyFlashcard(
                        key: ValueKey(_itemKey(item)),
                        item: item,
                        details: _details,
                        revealed: _revealed,
                        typeLabel: _typeLabel(item.type),
                        question: _questionFor(item.type),
                        onReveal: _revealAnswer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 210),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return SizeTransition(
                  sizeFactor: animation,
                  alignment: AlignmentDirectional.topStart,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: _revealed
                  ? _RatingBar(
                      key: const ValueKey('rating-bar'),
                      disabled: _saving,
                      onRating: _rate,
                      onLearned: _markLearned,
                      showLearned: widget.level != 'BEGINNER',
                    )
                  : const SizedBox(key: ValueKey('rating-bar-hidden')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final total = _items.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Session complete',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.outline),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: .045),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: const BoxDecoration(
                    color: AppColors.sageSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: AppColors.sage,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '${widget.level} · $_studyTypeLabel complete',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$total cards completed this session',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SummaryChip(
                      label: 'Again',
                      value: _againCount,
                      icon: Icons.replay_rounded,
                      color: AppColors.error,
                    ),
                    _SummaryChip(
                      label: 'Hard',
                      value: _hardCount,
                      icon: Icons.psychology_alt_outlined,
                      color: AppColors.warning,
                    ),
                    _SummaryChip(
                      label: 'Good',
                      value: _goodCount,
                      icon: Icons.thumb_up_alt_outlined,
                      color: AppColors.blue,
                    ),
                    _SummaryChip(
                      label: 'Easy',
                      value: _easyCount,
                      icon: Icons.auto_awesome_rounded,
                      color: AppColors.sage,
                    ),
                    _SummaryChip(
                      label: 'Learned',
                      value: _learnedCount,
                      icon: Icons.check_circle_rounded,
                      color: AppColors.sage,
                    ),
                    if (_retryCount > 0)
                      _SummaryChip(
                        label: 'Retried',
                        value: _retryCount,
                        icon: Icons.refresh_rounded,
                        color: AppColors.gold,
                      ),
                  ],
                ),
                if (_canManageGrammar) ...[
                  const SizedBox(height: 24),
                  _buildGrammarManagerButton(),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text('Back'),
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

class _StudyFlashcard extends StatelessWidget {
  final StudyItem item;
  final Map<String, dynamic>? details;
  final bool revealed;
  final String typeLabel;
  final String question;
  final VoidCallback onReveal;

  const _StudyFlashcard({
    super.key,
    required this.item,
    required this.details,
    required this.revealed,
    required this.typeLabel,
    required this.question,
    required this.onReveal,
  });

  @override
  Widget build(BuildContext context) {
    final largeCharacter = item.type == 'kanji' || item.type == 'kana';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.outline),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: .045),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              typeLabel,
              style: const TextStyle(
                color: AppColors.primaryStrong,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
          ),
          const SizedBox(height: 26),
          Text(
            item.front,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: largeCharacter ? 72 : 38,
              height: 1.17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 230),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final slide = Tween<Offset>(
                begin: const Offset(0, .035),
                end: Offset.zero,
              ).animate(animation);

              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: slide, child: child),
              );
            },
            child: revealed
                ? _RevealedAnswer(
                    key: ValueKey('answer-${item.type}-${item.id}'),
                    item: item,
                    details: details,
                  )
                : Column(
                    key: ValueKey('question-${item.type}-${item.id}'),
                    children: [
                      Text(
                        question,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 28),
                      FilledButton.tonalIcon(
                        onPressed: onReveal,
                        icon: const Icon(Icons.visibility_rounded),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 3),
                          child: Text('Show answer'),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _RevealedAnswer extends StatelessWidget {
  final StudyItem item;
  final Map<String, dynamic>? details;

  const _RevealedAnswer({super.key, required this.item, required this.details});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 18),
        if (item.reading.isNotEmpty) ...[
          Text(
            item.reading,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.primaryStrong,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
        ],
        Text(
          item.meaning,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 20),
        _Details(item: item, details: details),
      ],
    );
  }
}

class _StudySessionSkeleton extends StatelessWidget {
  final String level;
  final String studyType;

  const _StudySessionSkeleton({required this.level, required this.studyType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          '$level · $studyType',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const _SkeletonBlock(width: double.infinity, height: 6, radius: 0),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: const Column(
                    children: [
                      _SkeletonBlock(width: 92, height: 26, radius: 99),
                      SizedBox(height: 28),
                      _SkeletonBlock(width: 190, height: 56, radius: 14),
                      SizedBox(height: 26),
                      _SkeletonBlock(width: 240, height: 13, radius: 8),
                      SizedBox(height: 12),
                      _SkeletonBlock(width: 190, height: 13, radius: 8),
                      SizedBox(height: 30),
                      _SkeletonBlock(width: 180, height: 52, radius: 18),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrammarManagerSkeleton extends StatelessWidget {
  const _GrammarManagerSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return Container(
          height: 104,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.outline),
          ),
          child: const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SkeletonBlock(width: 130, height: 15, radius: 8),
                    SizedBox(height: 8),
                    _SkeletonBlock(width: 210, height: 11, radius: 7),
                    SizedBox(height: 11),
                    _SkeletonBlock(width: 96, height: 22, radius: 99),
                  ],
                ),
              ),
              SizedBox(width: 12),
              _SkeletonBlock(width: 34, height: 34, radius: 17),
            ],
          ),
        );
      },
    );
  }
}

class _SkeletonBlock extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const _SkeletonBlock({
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  State<_SkeletonBlock> createState() => _SkeletonBlockState();
}

class _SkeletonBlockState extends State<_SkeletonBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    )..repeat(reverse: true);

    _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final color = Color.lerp(
          AppColors.surfaceMuted,
          AppColors.surfaceSoft,
          _pulse.value,
        );

        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}

class _RotatingSyncIcon extends StatefulWidget {
  final double size;

  const _RotatingSyncIcon({this.size = 22});

  @override
  State<_RotatingSyncIcon> createState() => _RotatingSyncIconState();
}

class _RotatingSyncIconState extends State<_RotatingSyncIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(
        Icons.sync_rounded,
        color: AppColors.primaryStrong,
        size: widget.size,
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: .20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            '$label $value',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _GrammarManagerSheet extends StatefulWidget {
  final String level;

  const _GrammarManagerSheet({required this.level});

  @override
  State<_GrammarManagerSheet> createState() => _GrammarManagerSheetState();
}

class _GrammarManagerSheetState extends State<_GrammarManagerSheet> {
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _savingIds = <int>{};

  List<StudyItem> _items = [];
  String _query = '';
  String _filter = 'all';
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final items = await DatabaseService.getGrammarItems(widget.level);
      if (!mounted) return;

      setState(() {
        _items = items;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _toggleLearned(StudyItem item) async {
    if (_savingIds.contains(item.id)) return;

    HapticFeedback.selectionClick();
    setState(() => _savingIds.add(item.id));

    try {
      await DatabaseService.setLearned(item, learned: !item.learned);
      final refreshed = await DatabaseService.getGrammarItems(widget.level);

      if (!mounted) return;

      setState(() {
        _items = refreshed;
        _savingIds.remove(item.id);
      });
      HapticFeedback.lightImpact();
    } catch (e) {
      if (!mounted) return;

      setState(() => _savingIds.remove(item.id));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Couldn\'t update grammar: $e')));
    }
  }

  List<StudyItem> get _visibleItems {
    final normalizedQuery = _query.trim().toLowerCase();

    return _items.where((item) {
      if (_filter == 'learned' && !item.learned) return false;
      if (_filter == 'pending' && item.learned) return false;

      if (normalizedQuery.isEmpty) return true;

      return item.front.toLowerCase().contains(normalizedQuery) ||
          item.meaning.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  String _srsLabel(String state) {
    switch (state) {
      case 'learning':
        return 'Learning';
      case 'review':
        return 'Review';
      case 'mature':
        return 'Mature';
      case 'new':
      default:
        return 'New';
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _visibleItems;
    final learnedCount = _items.where((item) => item.learned).length;
    final pendingCount = _items.length - learnedCount;

    return Material(
      color: AppColors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_rounded),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.level} Grammar',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '$learnedCount of ${_items.length} marked as learned',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search by pattern or meaning',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  filled: true,
                  fillColor: AppColors.surfaceSoft,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text('All ${_items.length}'),
                      selected: _filter == 'all',
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        setState(() => _filter = 'all');
                      },
                    ),
                    ChoiceChip(
                      label: Text('Pending $pendingCount'),
                      selected: _filter == 'pending',
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        setState(() => _filter = 'pending');
                      },
                    ),
                    ChoiceChip(
                      label: Text('Learned $learnedCount'),
                      selected: _filter == 'learned',
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        setState(() => _filter = 'learned');
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Marking an item as learned does not change its SRS history.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const _GrammarManagerSkeleton()
                  : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 42),
                            const SizedBox(height: 10),
                            const Text(
                              'Couldn\'t load grammar.',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.tonal(
                              onPressed: () {
                                setState(() {
                                  _loading = true;
                                  _error = null;
                                });
                                _load();
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : visibleItems.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Text(
                          _query.trim().isEmpty
                              ? 'There are no grammar points in this filter.'
                              : 'No grammar found for “${_query.trim()}”.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                      itemCount: visibleItems.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = visibleItems[index];
                        final saving = _savingIds.contains(item.id);

                        return Container(
                          padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
                          decoration: BoxDecoration(
                            color: item.learned
                                ? AppColors.sageSoft.withValues(alpha: .55)
                                : AppColors.surfaceSoft,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: item.learned
                                  ? AppColors.sage.withValues(alpha: .30)
                                  : AppColors.outline,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.front,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    if (item.meaning.trim().isNotEmpty) ...[
                                      const SizedBox(height: 5),
                                      Text(
                                        item.meaning,
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 9),
                                    Wrap(
                                      spacing: 7,
                                      runSpacing: 6,
                                      children: [
                                        _GrammarStatusChip(
                                          learned: item.learned,
                                        ),
                                        _SrsStatusChip(
                                          label: _srsLabel(item.state),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: item.learned
                                    ? 'Mark as pending'
                                    : 'Mark as learned',
                                onPressed: saving
                                    ? null
                                    : () => _toggleLearned(item),
                                icon: saving
                                    ? const _RotatingSyncIcon()
                                    : Icon(
                                        item.learned
                                            ? Icons.check_circle_rounded
                                            : Icons
                                                  .radio_button_unchecked_rounded,
                                      ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrammarStatusChip extends StatelessWidget {
  final bool learned;

  const _GrammarStatusChip({required this.learned});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: learned ? AppColors.sageSoft : AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            learned
                ? Icons.check_circle_outline_rounded
                : Icons.circle_outlined,
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            learned ? 'Learned' : 'Pending',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _SrsStatusChip extends StatelessWidget {
  final String label;

  const _SrsStatusChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        'SRS: $label',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  final StudyItem item;
  final Map<String, dynamic>? details;

  const _Details({required this.item, required this.details});

  @override
  Widget build(BuildContext context) {
    if (details == null) {
      return const SizedBox.shrink();
    }

    final children = <Widget>[];

    void addInfo(String label, dynamic value) {
      final text = value?.toString().trim() ?? '';

      if (text.isEmpty) {
        return;
      }

      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 84,
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (item.type == 'vocab') {
      addInfo('Type', details!['grammar_type']);
      addInfo('Also', details!['additional_definitions']);
    } else if (item.type == 'kanji') {
      addInfo('On', details!['onyomi']);
      addInfo('Kun', details!['kunyomi']);
      addInfo('Radical', details!['radical']);
      addInfo('Strokes', details!['strokes']);
    } else if (item.type == 'grammar') {
      addInfo('Pattern', details!['structure']);
    } else if (item.type == 'kana') {
      final script = details!['script']?.toString();
      addInfo(
        'Script',
        script == 'hiragana'
            ? 'Hiragana'
            : script == 'katakana'
            ? 'Katakana'
            : script,
      );
      addInfo('Group', details!['category']);
    }

    final examples = details!['examples'] as List? ?? const [];

    if (examples.isNotEmpty) {
      final first = Map<String, dynamic>.from(examples.first as Map);

      final japanese = (first['japanese'] ?? first['word'] ?? '')
          .toString()
          .trim();

      final english = (first['english'] ?? first['meaning'] ?? '')
          .toString()
          .trim();

      if (japanese.isNotEmpty || english.isNotEmpty) {
        children.add(const SizedBox(height: 18));
        children.add(
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Example',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        );

        if (japanese.isNotEmpty) {
          children.add(
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  japanese,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }

        if (english.isNotEmpty) {
          children.add(
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  english,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
            ),
          );
        }
      }
    }

    return Column(children: children);
  }
}

class _RatingBar extends StatelessWidget {
  final bool disabled;
  final ValueChanged<ReviewRating> onRating;
  final VoidCallback onLearned;
  final bool showLearned;

  const _RatingBar({
    super.key,
    required this.disabled,
    required this.onRating,
    required this.onLearned,
    this.showLearned = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 0,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.outline)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: disabled
                      ? const Padding(
                          key: ValueKey('saving-row'),
                          padding: EdgeInsets.only(bottom: 9),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _RotatingSyncIcon(size: 17),
                              SizedBox(width: 7),
                              Text(
                                'Saving answer…',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox(key: ValueKey('saving-row-hidden')),
                ),
                Row(
                  children: [
                    _RatingButton(
                      label: 'Again',
                      icon: Icons.replay_rounded,
                      color: AppColors.error,
                      disabled: disabled,
                      onTap: () => onRating(ReviewRating.again),
                    ),
                    _RatingButton(
                      label: 'Hard',
                      icon: Icons.psychology_alt_outlined,
                      color: AppColors.warning,
                      disabled: disabled,
                      onTap: () => onRating(ReviewRating.hard),
                    ),
                    _RatingButton(
                      label: 'Good',
                      icon: Icons.thumb_up_alt_outlined,
                      color: AppColors.blue,
                      disabled: disabled,
                      onTap: () => onRating(ReviewRating.good),
                    ),
                    _RatingButton(
                      label: 'Easy',
                      icon: Icons.auto_awesome_rounded,
                      color: AppColors.sage,
                      disabled: disabled,
                      onTap: () => onRating(ReviewRating.easy),
                    ),
                  ],
                ),
                if (showLearned) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: disabled ? null : onLearned,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.sage,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 11),
                        child: Text(
                          'Mark as learned',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RatingButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool disabled;
  final VoidCallback onTap;

  const _RatingButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.disabled,
    required this.onTap,
  });

  @override
  State<_RatingButton> createState() => _RatingButtonState();
}

class _RatingButtonState extends State<_RatingButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: AnimatedScale(
          scale: _pressed ? .96 : 1,
          duration: const Duration(milliseconds: 90),
          child: Material(
            color: widget.disabled
                ? AppColors.surfaceMuted
                : widget.color.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: widget.disabled ? null : widget.onTap,
              onHighlightChanged: widget.disabled
                  ? null
                  : (value) => setState(() => _pressed = value),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 11,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.icon,
                      size: 18,
                      color: widget.disabled
                          ? AppColors.textMuted
                          : widget.color,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: widget.disabled
                            ? AppColors.textMuted
                            : widget.color,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
