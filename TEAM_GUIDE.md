# دليل الفريق الهندسي — مشروع محلل نهايات الشطرنج AI 6×6

مرجع سريع ومباشر لفهم معمارية المشروع، ملفات الواجهة، المحرك الرياضي في `lib/ai_engine/`، وكيفية إضافة خوارزمية جديدة في خطوتين.

---

## القسم ١: ملفات التطبيق والواجهة (نظرة سريعة)

### نقطة التشغيل والجذر (`lib/`)
| الملف | الوظيفة |
|---|---|
| `lib/main.dart` | نقطة بداية التطبيق؛ تفعّل الخطوط الآمنة دون إنترنت وتُطلق `ChessAiSolverApp` داخل `ProviderScope`. |
| `lib/app.dart` | يبني `MaterialApp` مع ربط اللغة (`AR` RTL / `EN` LTR) والسمة الداكنة وشاشة `WorkspaceScreen`. |

### التصميم والترجمة والودجات المشتركة (`lib/core/`)
| المجلد | الملف | الوظيفة |
|---|---|---|
| `core/theme` | `app_colors.dart` | تعريف لوحة الألوان (Cyber-Slate والنيون الخافت) وألوان الفئات والتدرجات. |
| `core/theme` | `app_theme.dart` | بناء `ThemeData` وتنسيقات النصوص (`Cairo`، `Plus Jakarta Sans`، `JetBrains Mono`) دون اتصال. |
| `core/theme` | `glass_decorations.dart` | أشكال البطاقات الزجاجية، الشارات، إطار الرقعة، وبانرات الحالة. |
| `core/theme` | `theme.dart` | ملف تصدير موحّد (barrel) لمجلد `core/theme`. |
| `core/l10n` | `app_localizations.dart` | قاموس النصوص الكامل (`AppStrings`) باللغتين العربية والإنجليزية وباني القصص التكتيكية `buildTacticalStory`. |
| `core/widgets` | `ambient_background.dart` | خلفية اللوح الداكن مع الإضاءات الشعاعية الناعمة في الزوايا. |
| `core/widgets` | `glass_card.dart` | حاوية البطاقة الزجاجية `GlassCard` مع شارة الخطوة `StepBadge`. |
| `core/widgets` | `neon_button.dart` | أزرار التفاعل الموحّدة `NeonButton` بأربع درجات (Amber / Cyan / Violet / Ghost). |
| `core/widgets` | `animated_metric_chip.dart` | شرائح وبطاقات الأرقام التي تعدّ تصاعدياً بسلاسة (`AnimatedMetricChip` / `AnimatedMetricCard`). |
| `core/widgets` | `scanning_loader.dart` | أنيميشن الرادار ومؤقت التحميل `AiScanningOverlay` وشريط `ShimmerBar`. |
| `core/widgets` | `core_widgets.dart` | ملف تصدير موحّد لمجلد `core/widgets`. |

### إدارة الحالة (`lib/core/providers/`)
| الملف | الوظيفة |
|---|---|
| `app_settings_provider.dart` | يدير اللغة (`ar`/`en`)، إظهار الرؤية التكتيكية، سياسة الأسود `BlackPolicy`، وحد العقد `maxNodes`. |
| `board_setup_provider.dart` | يدير إعداد الرقعة التفاعلي (تبديل النهايات، النقر، السحب، الإضافة/الحذف في `CUSTOM`، التحقق اللحظي). |
| `solver_provider.dart` | يدير اختيار الخوارزمية ديناميكياً وتشغيلها عبر `AiEngineRunner.solveInBackground`. |
| `playback_provider.dart` | يدير التشغيل المرحلي للمسار (`first`/`prev`/`next`/`last`/`scrubTo`/`toggleAutoPlay`) والسرعة. |
| `benchmark_provider.dart` | يشغّل مقارنة كل الخوارزميات عبر `benchmarkAllInBackground` ويحمّل أي صف محلول للمعاينة. |
| `providers.dart` | ملف تصدير موحّد لكل المزوّدات (Riverpod Providers). |

### وحدات الميزات (`lib/features/`)
| المجلد | الملف | الوظيفة |
|---|---|---|
| `board_setup` | `chess_piece_svgs.dart` | رسومات SVG للقطع الخمس (`WK`, `WQ`, `WR`, `WB`, `BK`) مع التوهج داخل `ChessPieceToken`. |
| `board_setup` | `tactical_overlay_layer.dart` | `CustomPainter` يرسم مربعات السيطرة، نقاط هروب الأسود النابضة، وحلقة الكش/الكش مات. |
| `board_setup` | `move_arrow_overlay.dart` | `CustomPainter` يرسم سهم المسار المتقطع المتحرك مع موجة دائرية عند المربع الهدف. |
| `board_setup` | `chess_board_widget.dart` | الرقعة التفاعلية 6×6 (اتجاه LTR إجباري، انزلاق القطع بـ `AnimatedPositioned`، وسحب وإفلات). |
| `board_setup` | `board_setup_panel.dart` | لوحة الخطوة ١ لاختيار نوع النهاية، تخصيص القطع، الأوضاع الجاهزة، والوضع العشوائي. |
| `board_setup` | `board_setup.dart` | ملف تصدير موحّد لوحدة إعداد الرقعة. |
| `solver` | `algorithm_selector_panel.dart` | لوحة الخطوة ٢ لعرض الخوارزميات ديناميكياً من `AlgorithmRegistry.all` وتشغيل الحل والمقارنة. |
| `solver` | `solver.dart` | ملف تصدير موحّد لوحدة اختيار الخوارزمية. |
| `playback` | `playback_bar.dart` | شريط الخطوة ٣ للتحكم بالخطوات، شريط التمرير، السرعات، وشرائط النقلات المتتابعة. |
| `playback` | `playback_keyboard_scope.dart` | يربط اختصارات لوحة المفاتيح (`←`, `→`, `Space`, `Home`, `End`) بالتحكم في التشغيل. |
| `playback` | `playback.dart` | ملف تصدير موحّد لوحدة التشغيل المرحلي. |
| `explainer` | `algorithm_explainer_painter.dart` | `CustomPainter` يرسم حركة استكشاف كل خوارزمية (BFS, DFS, A*, UCS, Greedy, IDA*, Hill Climbing). |
| `explainer` | `algorithm_explainer_card.dart` | بطاقة تعرض الأنيميشن التعليمي مع بيانات البنية والتعقيد (`O(b^d)` وغيرها). |
| `explainer` | `explainer.dart` | ملف تصدير موحّد لوحدة الشرح المتحرك. |
| `telemetry` | `tactical_story_card.dart` | بطاقة تعرض التحليل التكتيكي المقروء للنقلة الحالية بناءً على `buildTacticalStory`. |
| `telemetry` | `heuristic_inspector_card.dart` | مفتش الدالة الاستدلالية (`g/h/f`، بُعد الحافة، شريط الاقتراب للمات) وبطاقات مقاييس التشغيل. |
| `telemetry` | `telemetry.dart` | ملف تصدير موحّد لوحدة القياس والتحليل. |
| `benchmark` | `benchmark_bar_chart.dart` | رسم بياني أفقي متحرك يقارن العقد والزمن وتكلفة المسار نسبياً بين الخوارزميات. |
| `benchmark` | `benchmark_dashboard.dart` | لوحة الخطوة ٤: بطاقات الفائزين، التحليل التلقائي، جدول المقارنة التفاعلي، والرسم البياني. |
| `benchmark` | `benchmark.dart` | ملف تصدير موحّد لوحدة المقارنة. |
| `workspace` | `top_app_bar.dart` | الشريط العلوي: شعار التطبيق، زر الرؤية التكتيكية، مبدّل `AR | EN`، وزر الدليل. |
| `workspace` | `guide_modal.dart` | نافذة منبثقة تشرح للمستخدم كيفية استخدام كل قسم في التطبيق باختصار. |
| `workspace` | `workspace_screen.dart` | الشاشة الرئيسية المتجاوبة (عمودان في الشاشات الكبيرة، و٣ تبويبات في الهواتف). |

---

## القسم ٢: شرح تفصيلي لمحرك الذكاء الاصطناعي (`lib/ai_engine/`)

هذا المجلد مكتوب بـ **Pure Dart** بالكامل (دون أي استيراد لـ Flutter) ليعمل بسلاسة داخل `Isolate.run`.

### كيف يتصل المحرك بالخوارزميات؟ (دورة حياة البحث)
```text
BoardState ──▶ MovesEngine.getSuccessors() ──▶ قائمة SuccessorTransition
                 (نقلة الأبيض + رد الأسود)         │
                                                    ▼
   SearchAlgorithm.reconstructPath() ◀── حلقة البحث (Queue / Stack / MinHeap)
```

---

### ١. `search_models.dart` — نماذج البيانات وهياكل البحث
- **`enum Actor` (`white`, `black`)**: يمثّل الطرف المنفّذ للنقلة؛ `opponent` تعيد الطرف المقابل.
- **`enum PieceType` (`wk`, `wq`, `wr`, `wb`, `bk`)**: يحدّد نوع القطعة ورمزها الجبري (`symbol`) وحركتها (`slidesOrthogonally`, `slidesDiagonally`, `isSlider`) واسمها بالعربية والإنجليزية.
- **`enum EndgameMode` (`krk`, `kqk`, `krrk`, `krbk`, `custom`)**: تشكيلات النهايات المدعومة وتحديد القطع البيضاء المطلوبة لكل نمط عبر `requiredPieces`.
- **`enum BlackPolicy` (`centerSeeking`, `evasive`)**: استراتيجية رد الملك الأسود الحتمية أثناء البحث.
- **`enum TacticalTag` & `enum SearchStatus`**: وسوم الشرح التكتيكي (`deliverCheckmate`, `cutOffRank`, ...) وحالة انتهاء البحث (`solved`, `failed`, `nodeCapReached`).
- **`class GridPos(int row, int col)`**: إحداثي مربع على الرقعة (`row=0` هو الصف `6` العلوي و`col=0` هو العمود `a`).
  - `squareIndex({int boardSize = 6}) -> int`: يحول الإحداثي إلى رقم خطي `0..35`.
  - `toAlgebraic({int boardSize = 6}) -> String`: يحوّل `(0,0)` إلى `'a6'` و`(5,5)` إلى `'f1'`.
  - `GridPos.fromAlgebraic(String coord, {int boardSize = 6}) -> GridPos`: يحوّل النص الجبري إلى `GridPos`.
  - `chebyshevDistanceTo(GridPos other) -> int`: مسافة خطوات الملك `max(|Δr|, |Δc|)`.
  - `manhattanDistanceTo(GridPos other) -> int`: المسافة العمودية/الأفقية `|Δr| + |Δc|`.
- **`class Piece(PieceType type, int row, int col)`**: يمثل قطعة غير قابلة للتعديل؛ `moveTo(int newRow, int newCol) -> Piece` تُرجع نسخة منقولة.
- **`class BoardState({required List<Piece> pieces, int boardSize = 6, ...})`**: حالة الرقعة الكاملة كعقدة في شجرة البحث. ترتّب القطع ترتيباً قياسياً (`_canonicalize`) وتبني `stateKey` و`hashCode` ثابتين حتى تتساوى الحالات المتطابقة (مثل تبديل الرخّين في `KRRK`).
  - `inBounds(int row, int col) -> bool`: يتحقق أن المربع داخل الرقعة.
  - `pieceAt(int row, int col) -> Piece?`: يعيد القطعة في المربع أو `null`.
  - `whiteKing` / `blackKing` / `whitePieces` / `whiteAttackers`: دوال مساعدة سريعة للوصول إلى القطع.
- **`class ChessMove`**: يصف نقلة نصف دور (`actor`, `piece`, `from`, `to`, `capturedPiece`) مع `toNotation(...) -> String` لتوليد مثل `Rf6#`.
- **`class SuccessorTransition`**: حافة انتقال كاملة في شجرة البحث (نقلة الأبيض `whiteMove` + الحالة الوسطية `midState` + رد الأسود `blackMove` + الحالة التالية `nextState` + التكلفة `stepCost` + الوسوم التكتيكية).
- **`class MoveStep` / `SearchTracePoint` / `SearchMetrics` / `SearchResult` / `PositionValidation`**: نماذج مخرجات الحل والقياس والتحقق من القانونية.
- **`class MinHeap<T>(int Function(T a, T b) _compare)`**: رتل أولوية ثنائي (`add(T value) -> void`, `removeFirst() -> T`) دون حزم خارجية، تعتمد عليه `A*`.

---

### ٢. `moves_engine.dart` — قوانين الشطرنج 6×6 وتوليد النقلات
يحتوي على دوال عليا مختصرة تستدعي مثيلاتها الثابتة داخل `abstract final class MovesEngine`:
- **`getPieceAttackedSquares(BoardState state, Piece piece, {bool ignoreBlackKing = false}) -> Set<GridPos>`**: تحسب المربعات المهددة من قطعة بيضاء واحدة؛ تحمي القطع الصديقة وتوقف الأشعة خلفها، وعند `ignoreBlackKing: true` تمر عبر الملك الأسود (X-ray) لمنعه من التراجع على نفس خط الكش.
- **`getAttackedSquares(BoardState state, {bool ignoreBlackKing = false}) -> Set<GridPos>`**: تجمع كل المربعات المسيطر عليها من جميع القطع البيضاء.
- **`isCheck(BoardState state) -> bool`**: تتحقق هل الملك الأسود يقف على مربع ضمن `getAttackedSquares(state)`.
- **`isCheckmate(BoardState state) -> bool`**: تتحقق من `isCheck(state) && getBlackKingMoves(state).isEmpty`.
- **`isStalemate(BoardState state) -> bool`**: تتحقق من غياب الكش مع انعدام أي نقلة قانونية للأسود.
- **`hasSufficientMatingMaterial(BoardState state) -> bool`**: تتحقق من وجود وزير، أو رخ، أو فيلين على لونين متعاكسين لتفادي تعادل نقص القطع.
- **`validatePosition(BoardState state) -> PositionValidation` & `isLegalPosition(BoardState state) -> bool`**: تفحص الحدود، عدم التداخل، وجود ملك واحد لكل طرف، تباعد الملكين (`chebyshev > 1`)، عدم بدء الأسود في كش، وكفاية القطع.
- **`getBlackKingMoves(BoardState state) -> List<ChessMove>`**: تولّد النقلات القانونية للملك الأسود (باستخدام `ignoreBlackKing: true` + السماح بأكل القطع البيضاء غير المحمية).
- **`getWhiteMoves(BoardState state) -> List<ChessMove>`**: تولّد كل النقلات القانونية للقطع البيضاء مع منع تلامس الملكين وتوقف القطع المنزلقات عند أي عائق.
- **`applyMove(BoardState state, ChessMove move) -> BoardState`**: تُنتج حالة `BoardState` جديدة بعد تنفيذ النقلة وإزالة القطعة المأسورة إن وجدت وقلب الدور.
- **`chooseBlackKingMove(BoardState state, {BlackPolicy policy = BlackPolicy.centerSeeking}) -> ChessMove?`**: تختار رد الملك الأسود الحتمي: تأكل أي قطعة بيضاء غير محمية أولاً، وإلا تطبّق `centerSeeking` (أقرب للوسط) أو `evasive` (تعظيم منافذ الهروب).
- **`getSuccessors(BoardState state, {BlackPolicy blackPolicy, bool pruneDeadEnds = true}) -> List<SuccessorTransition>`**: العمود الفقري لخوارزميات البحث؛ تولّد كل نقلة بيضاء قانونية وتربطها مباشرةً بكش مات فوري أو برد الأسود الحتمي، وتُصفّي المآزق (Stalemate أو التضحية القاتلة بالمادة) وتوسّم النقلات بتصنيفات `TacticalTag`.
- **`presetPosition(EndgameMode mode, {int variant = 0}) -> BoardState`**: تُعيد أوضاعاً قياسية جاهزة وقانونية لكل نهاية.
- **`generateRandomLegalPosition(EndgameMode mode, {Random? rng, List<PieceType>? customAttackers}) -> BoardState`**: تولّد توزيعاً عشوائياً مضمون القانونية عبر أخذ عينات رفضية.

---

### ٣. `heuristics.dart` — الدالة الاستدلالية الافتراضية
- **`typedef HeuristicFn = double Function(BoardState state)`**: تعريف موحّد لتوقيع دالة التقدير.
- **`const String defaultHeuristicFormula`**: الصيغة الرياضية المعروضة في مفتش التقدير.
- **`edgeDistance(GridPos pos, int boardSize) -> int`**: تحسب أقصر مسافة بالمربعات بين موقع الملك الأسود وحواف الرقعة.
- **`endgameHeuristic(BoardState state) -> double`**: دالة تقدير مقبولة (Admissible) تضمن عدم المبالغة: تعيد `0.0` عند الكش مات، ولنهايات قطعة ثقيلة واحدة (`KRK`/`KQK`) تحسب `max(1, dEdge + 1, ceil((dKings - 1) / 2))`، وللنهايات متعددة القطع تعيد `1.0` كحد أدنى آمن.

---

### ٤. `base_algorithm.dart` — العقد القياسي للخوارزميات ومُسجّل القياس
- **`enum AlgorithmCategory`**: تصنيفات البحث (`uninformed`, `informed`, `memoryBounded`, `localSearch`).
- **`enum ExplainerAnimationType`**: أنماط الأنيميشن السبعة المتاحة في بطاقة الشرح (`bfsLevelWave`, `dfsBranchBacktrack`, `ucsCostWave`, `astarPriorityWave`, `greedyHeuristicWave`, `idaThresholdRing`, `hillClimbingCurve`).
- **`class SearchTelemetry`**: مسجّل الأداء أثناء البحث:
  - `updateMaxFrontier(int frontierSize) -> void`: يحدّث ذروة الذاكرة (Frontier).
  - `recordExpansion(BoardState state, {required int frontierSize, double g, double h, double? f}) -> void`: يزيد عداد العقد المفتوحة ويسجل عينة متوازنة في `trace` (بحد أقصى 60 نقطة).
  - `recordGeneration([int count = 1]) -> void`: يزيد عداد العقد المولّدة.
  - `buildMetrics({required int solutionCost, required int solutionPlies}) -> SearchMetrics`: يوقف الساعة ويُخرج كائن المقاييس النهائي.
- **`abstract class SearchAlgorithm`**: الفئة الأم لكل خوارزمية؛ تحتوي خصائص البيانات الوصفية (`id`, `nameEn`, `nameAr`, `category`, `dataStructureEn/Ar`, `formula`, `timeComplexity`, `spaceComplexity`, `isComplete`, `isOptimal`, `shortDescEn/Ar`, `explainerAnimationType`, `isImplemented`) والدوال الجاهزة:
  - `solve(BoardState start, {int maxNodes = 50000, int maxDepth = 40, BlackPolicy blackPolicy = BlackPolicy.centerSeeking}) -> SearchResult`: الدالة الوحيدة المطلوب تنفيذها في كل خوارزمية.
  - `validateStart(BoardState start, SearchTelemetry telemetry) -> SearchResult?`: تتحقق من قانونية نقطة البداية قبل بدء الحلقة.
  - `reconstructPath({required BoardState goalState, required Map<BoardState, (BoardState, SuccessorTransition)> cameFrom, HeuristicFn heuristicFn = endgameHeuristic}) -> List<MoveStep>`: تتبع خريطة الآباء للخلف وتبني مسار الخطوات.
  - `buildStepsFromTransitions(List<SuccessorTransition> transitions, {required HeuristicFn heuristicFn}) -> List<MoveStep>`: تفك كل انتقال إلى خطوة أبيض ثم خطوة أسود مع حساب `g/h/f` والوسوم ومربعات السيطرة.
  - `buildSolvedResult(...)` / `buildFailedResult(...)` / `buildNodeCapResult(...)`: تُغلّف النتيجة في `SearchResult` موحّد.

---

### ٥. الخوارزميات الجاهزة (`lib/ai_engine/algorithms/`)
- **`bfs_algorithm.dart` → `class BfsAlgorithm`**: تنفذ `solve(...)` باستخدام طابور `Queue<(BoardState, int)>` ومجموعة `visited` مع فحص مبكر للكش مات (`O(b^d)`، كاملة ومثلى).
- **`dfs_algorithm.dart` → `class DfsAlgorithm`**: تنفذ `solve(...)` باستخدام مكدس `List<(BoardState, int)>` وحد عمق آمن (`depthCap`) ومجموعة `visited` لمنع الدورات (`O(b · m)` ذاكرة).
- **`astar_algorithm.dart` → `class AStarAlgorithm`**: تنفذ `solve(...)` باستخدام رتل الأولوية `MinHeap<_AStarNode>` المرتب حسب `f = g + h` مع كسر التعادل بـ `h` الأصغر وتحديث `bestG` وفحص الهدف عند السحب من الرتل لضمان الأمثلية.

---

### ٦. `algorithm_registry.dart` — السجل الديناميكي للخوارزميات
- **`abstract final class AlgorithmRegistry`**:
  - `registeredAlgorithms`: القائمة المركزية التي تحتوي مثيلات الخوارزميات المفعّلة (`BfsAlgorithm`, `DfsAlgorithm`, `AStarAlgorithm`).
  - `all -> List<SearchAlgorithm>`: تعيد القائمة كاملة وتقرأ منها جميع شاشات الواجهة والمقارنة.
  - `byId(String id) -> SearchAlgorithm` & `tryById(String id) -> SearchAlgorithm?`: للبحث عن خوارزمية عبر معرّفها.
  - `byCategory(AlgorithmCategory category) -> List<SearchAlgorithm>`: لترشيح الخوارزميات حسب الفئة.
  - `activeCategories -> List<AlgorithmCategory>`: تعيد الفئات غير الفارغة فقط.

---

### ٧. `isolate_runner.dart` & `ai_engine.dart` — التنفيذ المتوازي والتصدير
- **`class BenchmarkWinners`** & **`class BenchmarkSuiteResult`**: تغلّف نتائج المقارنة والفائزين الثلاثة (`shortestPathId`, `fastestId`, `fewestNodesId`).
- **`abstract final class AiEngineRunner`**:
  - `solveInBackground(...) -> Future<SearchResult>`: تستدعي `_solveSync` داخل `Isolate.run` (مع بديل microtask على الويب).
  - `benchmarkAllInBackground(...) -> Future<BenchmarkSuiteResult>`: تستدعي `_benchmarkSync` لتشغيل جميع خوارزميات `AlgorithmRegistry.all` وحساب الفائزين داخل Isolate واحد.
- **`ai_engine.dart`**: ملف barrel يصدّر كل ما سبق بـ `import` واحد.

---

## القسم ٣: وصفة من خطوتين لإضافة خوارزمية بحث جديدة

لا تحتاج لتعديل أي ملف في الواجهة أو الشاشات عند إضافة خوارزمية جديدة (مثل Greedy BFS أو UCS أو IDA* أو Hill Climbing):

1. **أنشئ ملفاً جديداً داخل `lib/ai_engine/algorithms/`** (مثلاً `greedy_algorithm.dart`) يرث من `SearchAlgorithm` وينفذ `solve(...)`:
   ```dart
   import '../base_algorithm.dart';
   import '../heuristics.dart';
   import '../moves_engine.dart';
   import '../search_models.dart';

   class GreedyAlgorithm extends SearchAlgorithm {
     const GreedyAlgorithm();

     @override String get id => 'greedy';
     @override String get nameEn => 'Greedy Best-First Search';
     @override String get nameAr => 'البحث الجشع لأفضل أولوية';
     @override AlgorithmCategory get category => AlgorithmCategory.informed;
     @override String get dataStructureEn => 'Min-Heap (h only)';
     @override String get dataStructureAr => 'رتل أولوية حسب h(n)';
     @override String get formula => 'f(n) = h(n)';
     @override String get timeComplexity => 'O(b^m)';
     @override String get spaceComplexity => 'O(b^m)';
     @override bool get isComplete => false;
     @override bool get isOptimal => false;
     @override String get shortDescEn => 'Expands the node with lowest h(n) first.';
     @override String get shortDescAr => 'يفتح العقدة ذات أقل تقدير h(n) مباشرة.';
     @override ExplainerAnimationType get explainerAnimationType =>
         ExplainerAnimationType.greedyHeuristicWave;

     @override
     SearchResult solve(
       BoardState start, {
       int maxNodes = 50000,
       int maxDepth = 40,
       BlackPolicy blackPolicy = BlackPolicy.centerSeeking,
     }) {
       final telemetry = SearchTelemetry();
       final invalid = validateStart(start, telemetry);
       if (invalid != null) return invalid;

       // استخدم MovesEngine.getSuccessors(...) و reconstructPath(...) هنا
       return buildFailedResult(telemetry, message: 'Not implemented yet');
     }
   }
   ```

2. **أضف سطراً واحداً في `lib/ai_engine/algorithm_registry.dart`**:
   ```dart
   import 'algorithms/greedy_algorithm.dart';

   static const List<SearchAlgorithm> registeredAlgorithms = <SearchAlgorithm>[
     BfsAlgorithm(),
     DfsAlgorithm(),
     AStarAlgorithm(),
     GreedyAlgorithm(), // <-- أضف هذا السطر فقط!
   ];
   ```
   ستظهر الخوارزمية الجديدة فوراً في مرشحات الفئات، القائمة، بطاقة الشرح المتحرك، ولوحة Benchmark!
