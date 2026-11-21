/// core/l10n/app_localizations.dart
/// ==================================
/// Full bilingual localization system supporting Arabic (RTL) and English (LTR)
/// with instant dynamic switching, localized algorithm descriptions, and live
/// tactical move storytelling (`buildTacticalStory` & `buildBenchmarkTakeaway`).
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../ai_engine/ai_engine.dart';

/// Supported UI languages.
enum AppLanguage {
  /// Arabic (Right-to-Left, default — matching `krk_6_6.html`).
  ar('ar', TextDirection.rtl, 'AR'),

  /// English (Left-to-Right).
  en('en', TextDirection.ltr, 'EN');

  const AppLanguage(this.code, this.textDirection, this.shortCode);

  /// ISO 639-1 language code.
  final String code;

  /// Layout directionality flipped dynamically on toggle.
  final TextDirection textDirection;

  /// Compact badge label shown on the top-bar language toggle button.
  final String shortCode;

  /// Flutter [Locale] instance.
  Locale get locale => Locale(code);

  /// True when layout flows Right-to-Left.
  bool get isRtl => this == ar;

  /// Returns the opposite language.
  AppLanguage get toggled => this == ar ? en : ar;
}

/// Structured tactical commentary card rendered beside / beneath the board.
class TacticalStory {
  /// Creates an immutable [TacticalStory].
  const TacticalStory({
    required this.badge,
    required this.meta,
    required this.body,
    required this.bullets,
  });

  /// Highlighted move / phase badge (e.g., `"1. الرُخ: d1 ← d4"`).
  final String badge;

  /// Secondary phase tag (e.g., `"كش للملك الأسود!"`).
  final String meta;

  /// Narrative explanation of why the move happened.
  final String body;

  /// Concise quantitative facts shown beneath the narrative.
  final List<(String label, String value)> bullets;
}

/// Strongly typed bilingual string repository for the entire application.
class AppStrings {
  const AppStrings._(this.language);

  /// Returns the [AppStrings] bundle for [language].
  factory AppStrings.of(AppLanguage language) =>
      language == AppLanguage.ar ? ar : en;

  /// Pre-built Arabic bundle.
  static const AppStrings ar = AppStrings._(AppLanguage.ar);

  /// Pre-built English bundle.
  static const AppStrings en = AppStrings._(AppLanguage.en);

  /// Active language.
  final AppLanguage language;

  /// True when Arabic is active.
  bool get isAr => language == AppLanguage.ar;

  // -------------------------------------------------------------------------
  // Top App Bar & Navigation
  // -------------------------------------------------------------------------

  String get appTitle => isAr
      ? 'محلل نهاية الشطرنج AI 6×6'
      : '6×6 Chess Endgame AI Solver';

  String get appSubtitle => isAr
      ? 'استكشاف ومقارنة خوارزميات البحث في نهايات الشطرنج'
      : 'Interactive 6×6 Chess Endgame Search Visualizer';

  String get offlineReadyBadge => isAr ? 'جاهز محلياً' : 'Offline Ready';

  String get tabWorkspace => isAr ? 'الرقعة والحل' : 'Board & Solve';

  String get tabAnalysis => isAr ? 'التحليل والشرح' : 'Analysis';

  String get tabBenchmark => isAr ? 'المقارنة والأداء' : 'Benchmark';

  String get guideTooltip => isAr ? 'دليل الاستخدام' : 'User Guide';

  String get guideTitle => isAr
      ? 'دليل استخدام التطبيق'
      : 'How to Use This App';

  String get guideClose => isAr ? 'حسناً، إغلاق' : 'Got It';

  List<(String title, String body)> get guideSections => isAr
      ? const <(String, String)>[
          (
            '١. إعداد الرقعة وتشكيلة القطع',
            'اختر تشكيلة القطع البيضاء (KRK، KQK، KRRK، KRBK، أو مخصص)، ثم حرّك القطع بالنقر أو السحب والإفلات أو جرّب الأوضاع الجاهزة والوضع العشوائي القانوني.',
          ),
          (
            '٢. الرؤية التكتيكية (زر العين في الشريط العلوي)',
            'أظهر أو أخفِ نطاق سيطرة القطع البيضاء، ونقاط الهروب الآمنة باللون الكهرماني، وحلقة التهديد أو الكش مات باللون المرجاني.',
          ),
          (
            '٣. اختيار الخوارزمية والشرح المتحرك',
            'حدّد خوارزمية البحث وشاهد الرسم المتحرك الذي يوضح طريقة استكشافها، ثم اضغط "شغّل المحلل الذكي" للعثور على أقصر طريق للكش مات.',
          ),
          (
            '٤. التشغيل المرحلي والتحليل التكتيكي',
            'تنقّل بين نقلات الحل عبر أزرار التحكم (⏮ ◀ ▶ ⏭) واضبط السرعة (0.5× / 1× / 2×) مع متابعة الشرح التكتيكي وقيم g(n)/h(n)/f(n).',
          ),
          (
            '٥. مقارنة الخوارزميات (Benchmark)',
            'اضغط "قارن كل الخوارزميات" لاختبار جميع الخوارزميات على نفس الرقعة، واستعرض الفائزين والجدول والرسوم البيانية، وانقر أي صف محلول لعرضه على الرقعة.',
          ),
          (
            '٦. تبديل اللغة (AR | EN)',
            'بدّل فوراً بين العربية (من اليمين لليسار) والإنجليزية (من اليسار لليمين) من الزر الموجود في الشريط العلوي.',
          ),
        ]
      : const <(String, String)>[
          (
            '1. Endgame & Board Setup',
            'Pick White’s piece set (KRK, KQK, KRRK, KRBK, or Custom), move pieces via Tap-to-Place or Drag-and-Drop, or load Smart Presets and Random Legal positions.',
          ),
          (
            '2. Tactical Vision (Top Bar Eye Toggle)',
            'Toggle visual overlays showing White attack squares, pulsing amber escape dots for the Black King, and the coral check/checkmate ring.',
          ),
          (
            '3. Algorithm Selection & Live Explainer',
            'Select any search algorithm to watch its short animated search diagram, adjust the Black King strategy if desired, and tap Run AI Solver.',
          ),
          (
            '4. Move Playback & Step Analysis',
            'Step forward or backward through the checkmate path (⏮ ◀ ▶ ⏭), switch playback speed (0.5× / 1× / 2×), scrub the timeline, and read live move commentary.',
          ),
          (
            '5. Algorithm Comparison (Benchmark)',
            'Tap Compare All to run every algorithm on the same board, inspect Winner Cards and charts, and tap any solved row in the table to replay its solution.',
          ),
          (
            '6. Language Switcher (AR | EN)',
            'Instantly flip the entire interface between Arabic (RTL) and English (LTR) using the top-bar language toggle.',
          ),
        ];

  String get tacticalVisionToggle =>
      isAr ? 'الرؤية التكتيكية' : 'Tactical Vision';

  String get languageSwitchTooltip =>
      isAr ? 'التبديل إلى الإنجليزية' : 'Switch to Arabic';

  // -------------------------------------------------------------------------
  // Step 1: Board Setup & Endgame Piece Picker
  // -------------------------------------------------------------------------

  String get setupCardTitle => isAr
      ? 'إعداد الرقعة ونوع النهاية'
      : 'Board Setup & Endgame Mode';

  String get endgameModeLabel => isAr ? 'تشكيلة القطع:' : 'Endgame Set:';

  String get tapOrDragHint => isAr
      ? 'انقر على قطعة لاختيارها ثم انقر على أي مربع، أو اسحب القطعة وأفلتها مباشرة.'
      : 'Tap a piece pill then tap any square, or drag and drop pieces directly.';

  String get presetsLabel => isAr ? 'أوضاع جاهزة:' : 'Smart Presets:';

  List<String> presetNames(EndgameMode mode) {
    if (mode == EndgameMode.krk) {
      return isAr
          ? const <String>['افتراضي', 'مات في ٢', 'ضغط الحافة', 'تحدي']
          : const <String>['Default', 'Mate in 2', 'Edge Push', 'Challenge'];
    }
    return isAr
        ? const <String>['وضع قياسي', 'مات سريع']
        : const <String>['Standard', 'Quick Mate'];
  }

  String get randomLegalBtn => isAr ? 'وضع عشوائي قانوني' : 'Smart Random';

  String get resetBoardBtn => isAr ? 'إعادة ضبط' : 'Reset';

  String get customAttackersLabel =>
      isAr ? 'تخصيص القطع المهاجمة (بحد أقصى ٣):' : 'Custom Attackers (Max 3):';

  String get legendSlider => isAr ? 'نطاق سيطرة القطع' : 'Slider Control';

  String get legendKing => isAr ? 'نطاق الملك الأبيض' : 'White King Zone';

  String get legendEscape => isAr ? 'مربع هروب آمن' : 'Safe Escape';

  String get legendCheck => isAr ? 'تهديد / كش مات' : 'Check / Mate';

  String get statusLegalReady => isAr
      ? 'الوضع قانوني وجاهز للتشغيل — الأبيض يلعب أولاً.'
      : 'Position is legal and ready — White moves first.';

  String get statusCheckmateBanner => isAr
      ? 'كش مات! تم حصر الملك الأسود بالكامل.'
      : 'Checkmate! The Black King has zero legal escapes.';

  // -------------------------------------------------------------------------
  // Step 2: Algorithm Selector & Search Settings
  // -------------------------------------------------------------------------

  String get solverCardTitle => isAr
      ? 'اختيار خوارزمية البحث'
      : 'Search Algorithm & Strategy';

  String get allCategoriesLabel => isAr ? 'الكل' : 'All';

  String get blackPolicyLabel => isAr ? 'سياسة الملك الأسود:' : 'Black Policy:';

  String get nodeCapLabel => isAr ? 'حد العقد:' : 'Node Cap:';

  String get runSolverCta => isAr ? 'شغّل المحلل الذكي' : 'Run AI Solver';

  String get compareAllCta => isAr ? 'قارن كل الخوارزميات' : 'Compare All';

  String get scanningTitle => isAr
      ? 'جارٍ البحث عن أفضل حل...'
      : 'Searching for the best solution...';

  String get scanningSubtitle => isAr
      ? 'تحليل النقلات الممكنة حتى الكش مات'
      : 'Evaluating legal moves toward checkmate';

  String get benchmarkScanningTitle => isAr
      ? 'جارٍ مقارنة الخوارزميات...'
      : 'Comparing algorithms...';

  String get benchmarkScanningSubtitle => isAr
      ? 'قياس النقلات والعقد والزمن على نفس الرقعة'
      : 'Measuring moves, nodes, and speed on this position';

  String get notImplementedBadge => isAr ? 'قريباً' : 'Coming Soon';

  String get nodeCapErrorMsg => isAr
      ? 'تم بلوغ الحد الأقصى للعقد المفتوحة قبل إيجاد الكش مات. جرّب خوارزمية موجّهة مثل A* أو ارفع حد العقد.'
      : 'Node expansion cap reached before finding checkmate. Try A* or raise the node cap.';

  String get noSolutionErrorMsg => isAr
      ? 'انتهى البحث ضمن حد العمق/العقد بدون الوصول إلى كش مات.'
      : 'Search finished within depth/node bounds without finding checkmate.';

  // -------------------------------------------------------------------------
  // Step 3: Playback Bar
  // -------------------------------------------------------------------------

  String get playbackCardTitle =>
      isAr ? 'التشغيل المرحلي للمسار' : 'Step-by-Step Playback';

  String get initialPositionLabel => isAr ? 'الوضع الابتدائي' : 'Initial Position';

  String stepOfLabel(int current, int total) =>
      isAr ? 'اللقطة $current من $total' : 'Frame $current of $total';

  String get whiteTurnLabel => isAr ? 'دور الأبيض' : 'White Move';

  String get blackReplyLabel => isAr ? 'رد الأسود' : 'Black Reply';

  String get checkmateTag => isAr ? 'كش مات #' : 'Checkmate #';

  String get checkTag => isAr ? 'كش +' : 'Check +';

  String get speedLabel => isAr ? 'السرعة:' : 'Speed:';

  String get shortcutsHint => isAr
      ? 'اختصارات لوحة المفاتيح: ← السابق | → التالي | مسافة تشغيل/إيقاف'
      : 'Shortcuts: ← Prev | → Next | Space Play/Pause';

  // -------------------------------------------------------------------------
  // Telemetry, Heuristic Inspector & Algorithm Explainer
  // -------------------------------------------------------------------------

  String get telemetryCardTitle => isAr
      ? 'مقاييس الأداء ومفتش التقدير'
      : 'Telemetry & Heuristic Inspector';

  String get storyCardTitle =>
      isAr ? 'التحليل التكتيكي للنقلة' : 'Tactical Move Commentary';

  String get admissibleBadge => isAr ? 'تقدير مقبول h(n)' : 'Admissible h(n)';

  String get heuristicNoteTitle => isAr
      ? 'كيف تُحسب دالة التقدير h(n)؟'
      : 'How Does Heuristic h(n) Work?';

  String get heuristicNoteBody => isAr
      ? 'تقيس الدالة الحد الأدنى لعدد النقلات المتبقية حتى الكش مات استناداً إلى بُعد الملك الأسود عن الحافة والمسافة بين الملكين، دون مبالغة أبداً للحفاظ على ضمان أقصر مسار في خوارزمية A*.'
      : 'Measures a strict lower bound on remaining White turns to checkmate using Black King edge distance and King separation, guaranteeing shortest-path optimality in A*.';

  String get explainerCardTitle =>
      isAr ? 'كيف تعمل الخوارزمية؟' : 'How This Algorithm Works';

  String get metricTimeMs => isAr ? 'الزمن' : 'Time';

  String get metricExpanded => isAr ? 'العقد المفتوحة' : 'Expanded';

  String get metricGenerated => isAr ? 'العقد المولّدة' : 'Generated';

  String get metricMemory => isAr ? 'ذروة الذاكرة' : 'Peak Frontier';

  String get metricCost => isAr ? 'تكلفة الحل' : 'Path Cost';

  String get closenessLabel =>
      isAr ? 'الاقتراب من الكش مات' : 'Checkmate Progress';

  String get edgeDistanceLabel => isAr ? 'بُعد الحافة' : 'Edge Dist';

  String get kingGapLabel => isAr ? 'فجوة الملكين' : 'King Gap';

  String get escapesLabel => isAr ? 'منافذ الهروب' : 'Escapes';

  String get dataStructureLabel => isAr ? 'بنية البيانات' : 'Data Structure';

  String get formulaLabel => isAr ? 'معادلة التقييم' : 'Formula';

  String get timeComplexityLabel => isAr ? 'تعقيد الزمن' : 'Time';

  String get spaceComplexityLabel => isAr ? 'تعقيد الذاكرة' : 'Space';

  String get completeLabel => isAr ? 'الاكتمال' : 'Complete';

  String get optimalLabel => isAr ? 'الأمثلية' : 'Optimal';

  String get yesLabel => isAr ? 'نعم ✓' : 'Yes ✓';

  String get noLabel => isAr ? 'لا ✗' : 'No ✗';

  String get movesUnit => isAr ? 'نقلة' : 'moves';

  String get msUnit => isAr ? 'ms' : 'ms';

  // -------------------------------------------------------------------------
  // Benchmark Dashboard
  // -------------------------------------------------------------------------

  String get benchmarkTitle => isAr
      ? 'لوحة مقارنة الخوارزميات الحيّة'
      : 'Live Algorithm Benchmark';

  String get benchmarkSubtitle => isAr
      ? 'تشغيل جميع الخوارزميات المتاحة على نفس الوضعية ومقارنة أدائها'
      : 'Runs every available algorithm on the current position and compares results';

  String get benchmarkEmptyPrompt => isAr
      ? 'اضغط "قارن كل الخوارزميات" لعرض البطاقات الفائزة والجدول والرسوم البيانية التفاعلية.'
      : 'Tap "Compare All" to generate winner cards, comparison table, and animated charts.';

  String get winnerShortest => isAr ? 'أقصر مسار (الأمثل)' : 'Shortest Path';

  String get winnerFastest => isAr ? 'أسرع تنفيذ' : 'Fastest Execution';

  String get winnerFewestNodes => isAr ? 'أقل عقد مفتوحة' : 'Fewest Nodes';

  String get colAlgorithm => isAr ? 'الخوارزمية' : 'Algorithm';

  String get colCategory => isAr ? 'الفئة' : 'Category';

  String get colStatus => isAr ? 'الحالة' : 'Status';

  String get colMoves => isAr ? 'النقلات' : 'Moves';

  String get colExpanded => isAr ? 'العقد' : 'Expanded';

  String get colMemory => isAr ? 'الذاكرة' : 'Frontier';

  String get colTime => isAr ? 'الزمن (ms)' : 'Time (ms)';

  String get colAction => isAr ? 'معاينة' : 'Load';

  String get statusSolved => isAr ? 'محلولة' : 'Solved';

  String get statusNodeCap => isAr ? 'بلغ الحد' : 'Node Cap';

  String get statusFailed => isAr ? 'فشل' : 'Failed';

  String get loadTraceTooltip =>
      isAr ? 'استعراض هذا الحل على الرقعة' : 'Inspect this solution on board';

  // -------------------------------------------------------------------------
  // Dynamic Enum Translators
  // -------------------------------------------------------------------------

  String pieceName(PieceType type) => isAr ? type.nameAr : type.nameEn;

  String endgameName(EndgameMode mode) => isAr ? mode.labelAr : mode.labelEn;

  String categoryName(AlgorithmCategory cat) =>
      isAr ? cat.labelAr : cat.labelEn;

  String algorithmName(SearchAlgorithm algo) =>
      isAr ? algo.nameAr : algo.nameEn;

  String algorithmDesc(SearchAlgorithm algo) =>
      isAr ? algo.shortDescAr : algo.shortDescEn;

  String algorithmDataStructure(SearchAlgorithm algo) =>
      isAr ? algo.dataStructureAr : algo.dataStructureEn;

  String blackPolicyName(BlackPolicy policy) => switch (policy) {
        BlackPolicy.centerSeeking =>
          isAr ? 'التمسك بالوسط (كلاسيكي)' : 'Center-Seeking (Classic)',
        BlackPolicy.evasive =>
          isAr ? 'مراوغة ذكية (توسيع الهروب)' : 'Smart Evasive (Max Escapes)',
      };

  // -------------------------------------------------------------------------
  // Tactical Move Storytelling (Evolved from `krk_6_6.html` -> Multi-Endgame)
  // -------------------------------------------------------------------------

  TacticalStory buildTacticalStory({
    required BoardState currentBoard,
    MoveStep? activeStep,
    BoardState? previousBoard,
  }) {
    final n = currentBoard.boardSize;
    final bk = currentBoard.blackKingOrNull;
    final wk = currentBoard.whiteKingOrNull;

    if (bk == null || wk == null) {
      return TacticalStory(
        badge: initialPositionLabel,
        meta: isAr ? 'تعديل الرقعة' : 'Editing Board',
        body: isAr
            ? 'ضع الملك الأبيض والملك الأسود على الرقعة للبدء.'
            : 'Place both the White King and Black King on the board to begin.',
        bullets: const <(String, String)>[],
      );
    }

    final edgeDist = edgeDistance(bk.pos, n);
    final kDist = wk.pos.chebyshevDistanceTo(bk.pos);
    final escapes = MovesEngine.getBlackKingMoves(currentBoard).length;
    final center = (n - 1) / 2.0;
    final centerDist = math.sqrt(
      (bk.row - center) * (bk.row - center) +
          (bk.col - center) * (bk.col - center),
    );

    if (activeStep == null) {
      final validation = MovesEngine.validatePosition(currentBoard);
      if (!validation.isValid) {
        return TacticalStory(
          badge: isAr ? 'وضع غير قانوني' : 'Illegal Position',
          meta: validation.errorCodes.first,
          body: (isAr ? validation.messagesAr : validation.messagesEn).first,
          bullets: const <(String, String)>[],
        );
      }

      final edgeHint = edgeDist == 0
          ? (isAr
              ? 'الملك الأسود محصور بالفعل على الحافة، مما يسهّل تنفيذ كش مات سريع.'
              : 'The Black King is already pinned on an edge, enabling a quick mate.')
          : (isAr
              ? 'الملك الأسود يبعد $edgeDist مربعات عن أقرب حافة، والهدف دفعه تدريجياً نحو الحافة.'
              : 'The Black King is $edgeDist squares from the edge; White aims to herd it back.');

      final attackersStr = currentBoard.whiteAttackers
          .map((p) => '${pieceName(p.type)} (${p.pos.toAlgebraic()})')
          .join(isAr ? ' و ' : ' + ');

      return TacticalStory(
        badge: initialPositionLabel,
        meta: isAr ? 'الأبيض يلعب أولاً' : 'White Moves First',
        body: isAr
            ? 'تبدأ المواجهة بالملك الأبيض في ${wk.pos.toAlgebraic()} مع $attackersStr ضد الملك الأسود في ${bk.pos.toAlgebraic()}. $edgeHint'
            : 'White starts with King at ${wk.pos.toAlgebraic()} and $attackersStr against Black King at ${bk.pos.toAlgebraic()}. $edgeHint',
        bullets: <(String, String)>[
          (escapesLabel, '$escapes'),
          (isAr ? 'بُعد المركز' : 'Center Dist', centerDist.toStringAsFixed(2)),
          (isAr ? 'المسافة بين الملكين' : 'King Distance', '$kDist'),
        ],
      );
    }

    final fromAlg = activeStep.from.toAlgebraic(boardSize: n);
    final toAlg = activeStep.to.toAlgebraic(boardSize: n);
    final pieceLabel = pieceName(activeStep.piece);
    final moveNumber = (activeStep.g).round();

    if (activeStep.actor == Actor.white) {
      if (activeStep.isCheckmate) {
        return TacticalStory(
          badge: isAr
              ? '🏆 كش مات! $pieceLabel $fromAlg ← $toAlg'
              : '🏆 Checkmate! $pieceLabel $fromAlg → $toAlg',
          meta: isAr ? 'حسم في $moveNumber نقلات' : 'Mate in $moveNumber moves',
          body: isAr
              ? 'يتحرك $pieceLabel من $fromAlg إلى $toAlg موجّهاً ضربة الكش مات النهائية! الملك الأسود في ${bk.pos.toAlgebraic()} محاصر تماماً ولا يملك أي مربع آمن للهروب.'
              : '$pieceLabel moves from $fromAlg to $toAlg to deliver checkmate! The Black King on ${bk.pos.toAlgebraic()} has zero legal escape squares.',
          bullets: <(String, String)>[
            (escapesLabel, '0'),
            (isAr ? 'الحالة' : 'Status', checkmateTag),
          ],
        );
      }

      final body = switch (activeStep.tacticalTag) {
        TacticalTag.deliverCheck => isAr
            ? 'ينطلق $pieceLabel من $fromAlg إلى $toAlg موجّهاً كشاً مباشراً للملك الأسود في ${bk.pos.toAlgebraic()} لإجباره على التراجع.'
            : '$pieceLabel strikes from $fromAlg to $toAlg, giving direct check to force the Black King back.',
        TacticalTag.cutOffRank => isAr
            ? 'يقطع $pieceLabel الصف عند $toAlg ليُغلق طريق عودة الملك الأسود نحو وسط الرقعة ويُقلّص الصندوق.'
            : '$pieceLabel cuts off the rank at $toAlg, shrinking the box and blocking retreat toward the center.',
        TacticalTag.cutOffFile => isAr
            ? 'يقطع $pieceLabel العمود عند $toAlg ليُضيّق الخناق على الملك الأسود ويحصره في مساحة أصغر.'
            : '$pieceLabel cuts off the file at $toAlg, trapping the Black King in a smaller zone.',
        TacticalTag.advanceKing => isAr
            ? 'يتقدم الملك الأبيض إلى $toAlg لتقليص المسافة بين الملكين وسد منافذ فرار الملك الأسود.'
            : 'The White King steps forward to $toAlg, closing distance to guard escape squares.',
        TacticalTag.restrictEscape => isAr
            ? 'يتحرك $pieceLabel إلى $toAlg مقلّصاً مربعات هروب الملك الأسود المتاحة إلى $escapes فقط.'
            : '$pieceLabel moves to $toAlg, restricting the Black King to just $escapes safe square(s).',
        _ => isAr
            ? 'يعيد $pieceLabel التموضع في $toAlg كنقلة تكتيكية تمهيدية للحفاظ على السيطرة وإجبار الأسود على التراجع.'
            : '$pieceLabel repositions to $toAlg as a waiting/coordinating move to tighten the mating net.',
      };

      return TacticalStory(
        badge: isAr
            ? '$moveNumber. $pieceLabel: $fromAlg ← $toAlg'
            : '$moveNumber. $pieceLabel: $fromAlg → $toAlg',
        meta: activeStep.isCheck
            ? checkTag
            : (isAr ? 'تضييق تكتيكي' : 'Tactical Squeeze'),
        body: body,
        bullets: <(String, String)>[
          (escapesLabel, '$escapes'),
          (isAr ? 'المسافة بين الملكين' : 'King Distance', '$kDist'),
          ('h(n)', activeStep.h.toStringAsFixed(1)),
        ],
      );
    }

    // Black King reply
    final prevEscapes = previousBoard == null
        ? escapes
        : MovesEngine.getBlackKingMoves(previousBoard).length;
    final blackBody = switch (activeStep.tacticalTag) {
      TacticalTag.captureUndefended => isAr
          ? 'يلتقط الملك الأسود قطعة غير محمية في $toAlg للدفاع عن نفسه.'
          : 'The Black King captures an undefended piece on $toAlg.',
      TacticalTag.evadeCheck => isAr
          ? 'يهرب الملك الأسود من الكش من $fromAlg إلى $toAlg من بين $prevEscapes ${prevEscapes == 1 ? "خيار متاح" : "خيارات متاحة"}.'
          : 'The Black King evades check from $fromAlg to $toAlg out of $prevEscapes legal option(s).',
      TacticalTag.retreatToEdge => isAr
          ? 'يضطر الملك الأسود للانسحاب نحو الحافة إلى $toAlg (بُعد الحافة = $edgeDist).'
          : 'The Black King is forced toward the edge onto $toAlg (edge dist = $edgeDist).',
      _ => isAr
          ? 'يتحرك الملك الأسود إلى $toAlg محاولاً التمسك بأقرب مربع آمن لمركز الرقعة (مسافة المركز = ${centerDist.toStringAsFixed(2)}).'
          : 'The Black King steps to $toAlg, staying as close to the center as safely possible (dist = ${centerDist.toStringAsFixed(2)}).',
    };

    return TacticalStory(
      badge: isAr
          ? '$moveNumber... $pieceLabel: $fromAlg ← $toAlg'
          : '$moveNumber... $pieceLabel: $fromAlg → $toAlg',
      meta: blackReplyLabel,
      body: blackBody,
      bullets: <(String, String)>[
        (isAr ? 'بُعد المركز' : 'Center Dist', centerDist.toStringAsFixed(2)),
        (edgeDistanceLabel, '$edgeDist'),
      ],
    );
  }

  /// Generates an analytical comparison summary for the Benchmark Dashboard.
  String buildBenchmarkTakeaway(BenchmarkSuiteResult suite) {
    final solved = suite.results.where((r) => r.isSolved).toList(growable: false);
    if (solved.isEmpty) {
      return isAr
          ? 'لم تنجح أي خوارزمية في إتمام الحل ضمن حد العقد الحالي. جرّب رفع حد العقد أو اختيار وضع أسهل.'
          : 'No algorithm solved this position within the current node cap. Try raising the node budget.';
    }

    final fastest = suite.winners.fastestId != null
        ? AlgorithmRegistry.tryById(suite.winners.fastestId!)
        : null;
    final fewest = suite.winners.fewestNodesId != null
        ? AlgorithmRegistry.tryById(suite.winners.fewestNodesId!)
        : null;
    final shortest = suite.winners.shortestPathId != null
        ? AlgorithmRegistry.tryById(suite.winners.shortestPathId!)
        : null;

    final maxNodesExpanded = solved
        .map((r) => r.metrics.expandedNodes)
        .reduce(math.max);
    final minNodesExpanded = solved
        .map((r) => r.metrics.expandedNodes)
        .reduce(math.min);
    final ratioText = minNodesExpanded > 0
        ? (maxNodesExpanded / minNodesExpanded).toStringAsFixed(1)
        : '1.0';

    if (isAr) {
      return 'نجحت ${solved.length} من أصل ${suite.results.length} خوارزميات. '
          'حقّقت ${fewest?.nameAr ?? "-"} أقل استكشاف بـ $minNodesExpanded عقدة '
          '(تقليص بمقدار $ratioText× مقارنةً بـ $maxNodesExpanded عقدة)، '
          'بينما قدّمت ${shortest?.nameAr ?? "-"} أقصر مسار و${fastest?.nameAr ?? "-"} أسرع زمن تنفيذ.';
    }

    return '${solved.length} of ${suite.results.length} algorithms reached checkmate. '
        '${fewest?.nameEn ?? "-"} expanded the fewest nodes ($minNodesExpanded — '
        '${ratioText}x leaner than $maxNodesExpanded), while '
        '${shortest?.nameEn ?? "-"} found the shortest mate and '
        '${fastest?.nameEn ?? "-"} finished fastest.';
  }
}
