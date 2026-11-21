/// features/explainer/widgets/algorithm_explainer_painter.dart
/// ===============================================================
/// Continuous looping `CustomPainter` visualizations showing *how* each search
/// algorithm explores the state space.
///
/// Supports all 7 [ExplainerAnimationType] presets out of the box (`bfs`,
/// `dfs`, `ucs`, `astar`, `greedy`, `idaStar`, `hillClimbing`) so newly added
/// algorithms automatically receive a tailored animation.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../ai_engine/ai_engine.dart';
import '../../../core/theme/theme.dart';

/// Compact 156px animated canvas visualizing [animationType].
class AlgorithmExplainerCanvas extends StatefulWidget {
  /// Creates an [AlgorithmExplainerCanvas].
  const AlgorithmExplainerCanvas({
    super.key,
    required this.animationType,
    required this.accent,
  });

  /// Preset driving the miniature graph / curve animation.
  final ExplainerAnimationType animationType;

  /// Category neon accent color.
  final Color accent;

  @override
  State<AlgorithmExplainerCanvas> createState() =>
      _AlgorithmExplainerCanvasState();
}

class _AlgorithmExplainerCanvasState extends State<AlgorithmExplainerCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        height: 156,
        decoration: BoxDecoration(
          color: AppColors.boardFrameBg,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: widget.accent.withValues(alpha: 0.28)),
        ),
        clipBehavior: Clip.antiAlias,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _ExplainerPainter(
                type: widget.animationType,
                progress: _controller.value,
                accent: widget.accent,
              ),
              child: const SizedBox.expand(),
            );
          },
        ),
      ),
    );
  }
}

class _ExplainerPainter extends CustomPainter {
  const _ExplainerPainter({
    required this.type,
    required this.progress,
    required this.accent,
  });

  final ExplainerAnimationType type;
  final double progress;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    // Subtle background micro-grid
    final gridPaint = Paint()
      ..color = AppColors.glassBorder.withValues(alpha: 0.35)
      ..strokeWidth = 0.7;
    const step = 22.0;
    for (var x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    switch (type) {
      case ExplainerAnimationType.bfsLevelWave:
        _paintBfs(canvas, size);
      case ExplainerAnimationType.dfsBranchBacktrack:
        _paintDfs(canvas, size);
      case ExplainerAnimationType.astarPriorityWave:
        _paintAStarOrGreedy(canvas, size, showG: true);
      case ExplainerAnimationType.greedyHeuristicWave:
        _paintAStarOrGreedy(canvas, size, showG: false);
      case ExplainerAnimationType.ucsCostWave:
        _paintUcs(canvas, size);
      case ExplainerAnimationType.idaThresholdRing:
        _paintIdaStar(canvas, size);
      case ExplainerAnimationType.hillClimbingCurve:
        _paintHillClimbing(canvas, size);
    }
  }

  /// Standard 7-node 3-level binary tree coordinates for BFS/DFS explainers.
  List<Offset> _treeNodes(Size size) {
    final w = size.width;
    final h = size.height - 28; // Leave room for FIFO/LIFO strip at bottom
    return <Offset>[
      Offset(w * 0.50, h * 0.16), // 0: Root A
      Offset(w * 0.28, h * 0.50), // 1: B
      Offset(w * 0.72, h * 0.50), // 2: C
      Offset(w * 0.15, h * 0.84), // 3: D
      Offset(w * 0.40, h * 0.84), // 4: E
      Offset(w * 0.60, h * 0.84), // 5: F
      Offset(w * 0.85, h * 0.84), // 6: G
    ];
  }

  static const List<(int, int)> _treeEdges = <(int, int)>[
    (0, 1),
    (0, 2),
    (1, 3),
    (1, 4),
    (2, 5),
    (2, 6),
  ];

  void _paintBfs(Canvas canvas, Size size) {
    final nodes = _treeNodes(size);
    const labels = <String>['A', 'B', 'C', 'D', 'E', 'F', 'G'];
    final phase = progress * 4.0; // 0..1 level0, 1..2 level1, 2..3 level2, 3..4 hold
    final activeLevel = phase.floor().clamp(0, 3);

    // Sweeping level wave line
    final waveY = (size.height - 28) * (0.12 + (phase.clamp(0, 3) / 3) * 0.78);
    canvas.drawLine(
      Offset(12, waveY),
      Offset(size.width - 12, waveY),
      Paint()
        ..color = accent.withValues(alpha: 0.35)
        ..strokeWidth = 1.6,
    );

    for (final (u, v) in _treeEdges) {
      final childLevel = v <= 2 ? 1 : 2;
      final lit = activeLevel >= childLevel;
      canvas.drawLine(
        nodes[u],
        nodes[v],
        Paint()
          ..color = lit ? accent.withValues(alpha: 0.75) : AppColors.glassBorderHover
          ..strokeWidth = lit ? 2.0 : 1.2,
      );
    }

    for (var i = 0; i < nodes.length; i++) {
      final level = i == 0 ? 0 : (i <= 2 ? 1 : 2);
      final visited = activeLevel >= level;
      final isGoal = i == 5 && activeLevel >= 2;
      _drawNode(
        canvas,
        nodes[i],
        label: labels[i],
        color: isGoal ? AppColors.amber : (visited ? accent : AppColors.textDim),
        filled: visited,
        glow: activeLevel == level || isGoal,
      );
    }

    // Bottom FIFO Queue strip
    final queueItems = switch (activeLevel) {
      0 => const <String>['A'],
      1 => const <String>['B', 'C'],
      _ => const <String>['D', 'E', 'F', 'G'],
    };
    _drawStructureStrip(
      canvas,
      size,
      prefix: 'FIFO:',
      items: queueItems,
      color: accent,
    );
  }

  void _paintDfs(Canvas canvas, Size size) {
    final nodes = _treeNodes(size);
    const labels = <String>['A', 'B', 'C', 'D', 'E', 'F', 'G'];

    // Sequence: 0(A)->1(B)->3(D dead-end coral)->backtrack 1(B)->4(E goal!)
    final stage = (progress * 5.0).floor().clamp(0, 4);
    final activeNode = switch (stage) {
      0 => 0,
      1 => 1,
      2 => 3,
      3 => 1,
      _ => 4,
    };
    final visitedSet = switch (stage) {
      0 => const <int>{0},
      1 => const <int>{0, 1},
      2 => const <int>{0, 1, 3},
      3 => const <int>{0, 1, 3},
      _ => const <int>{0, 1, 3, 4},
    };
    final activePathEdges = switch (stage) {
      1 => const <(int, int)>{(0, 1)},
      2 => const <(int, int)>{(0, 1), (1, 3)},
      3 => const <(int, int)>{(0, 1)},
      4 => const <(int, int)>{(0, 1), (1, 4)},
      _ => const <(int, int)>{},
    };

    for (final (u, v) in _treeEdges) {
      final onPath = activePathEdges.contains((u, v));
      final isDead = stage == 2 && u == 1 && v == 3;
      canvas.drawLine(
        nodes[u],
        nodes[v],
        Paint()
          ..color = isDead
              ? AppColors.coral
              : (onPath ? accent : AppColors.glassBorderHover)
          ..strokeWidth = onPath ? 2.4 : 1.1,
      );
    }

    for (var i = 0; i < nodes.length; i++) {
      final isDeadEnd = i == 3 && stage >= 2;
      final isGoal = i == 4 && stage == 4;
      final color = isDeadEnd
          ? AppColors.coral
          : (isGoal
              ? AppColors.amber
              : (visitedSet.contains(i) ? accent : AppColors.textDim));
      _drawNode(
        canvas,
        nodes[i],
        label: isDeadEnd ? '✕' : (isGoal ? '#' : labels[i]),
        color: color,
        filled: visitedSet.contains(i),
        glow: activeNode == i,
      );
    }

    final stackItems = switch (stage) {
      0 => const <String>['A'],
      1 => const <String>['A', 'B'],
      2 => const <String>['A', 'B', 'D'],
      3 => const <String>['A', 'B'],
      _ => const <String>['A', 'B', 'E'],
    };
    _drawStructureStrip(
      canvas,
      size,
      prefix: 'LIFO:',
      items: stackItems,
      color: stage == 2 ? AppColors.coral : accent,
    );
  }

  void _paintAStarOrGreedy(
    Canvas canvas,
    Size size, {
    required bool showG,
  }) {
    final w = size.width;
    final h = size.height - 28;
    final pts = <Offset>[
      Offset(w * 0.14, h * 0.50), // 0: Start
      Offset(w * 0.42, h * 0.24), // 1: Low-cost upper
      Offset(w * 0.42, h * 0.78), // 2: High-cost lower
      Offset(w * 0.68, h * 0.30), // 3: Near goal
      Offset(w * 0.88, h * 0.52), // 4: Checkmate Goal
    ];
    final tags = showG
        ? const <String>['f=3', 'f=3', 'f=6', 'f=3', '#']
        : const <String>['h=3', 'h=2', 'h=5', 'h=1', 'h=0'];
    const edges = <(int, int)>[
      (0, 1),
      (0, 2),
      (1, 3),
      (2, 3),
      (3, 4),
    ];

    final step = (progress * 4.0).floor().clamp(0, 3);
    final litNodes = switch (step) {
      0 => const <int>{0},
      1 => const <int>{0, 1},
      2 => const <int>{0, 1, 3},
      _ => const <int>{0, 1, 3, 4},
    };
    final bestEdges = switch (step) {
      1 => const <(int, int)>{(0, 1)},
      2 => const <(int, int)>{(0, 1), (1, 3)},
      3 => const <(int, int)>{(0, 1), (1, 3), (3, 4)},
      _ => const <(int, int)>{},
    };

    for (final (u, v) in edges) {
      final chosen = bestEdges.contains((u, v));
      canvas.drawLine(
        pts[u],
        pts[v],
        Paint()
          ..color = chosen ? accent : AppColors.glassBorderHover
          ..strokeWidth = chosen ? 2.5 : 1.1,
      );
    }

    for (var i = 0; i < pts.length; i++) {
      final isGoal = i == 4 && step == 3;
      final isActive = litNodes.contains(i);
      final color = isGoal
          ? AppColors.amber
          : (i == 2
              ? AppColors.textDim
              : (isActive ? accent : AppColors.textMuted));
      _drawNode(
        canvas,
        pts[i],
        label: tags[i],
        radius: 13.5,
        color: color,
        filled: isActive,
        glow: isGoal || (i == step),
      );
    }

    _drawStructureStrip(
      canvas,
      size,
      prefix: showG ? 'Heap(g+h):' : 'Heap(h):',
      items: showG
          ? const <String>['f=3', 'f=6']
          : const <String>['h=1', 'h=5'],
      color: accent,
    );
  }

  void _paintUcs(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.24, (size.height - 26) * 0.52);
    final maxR = size.width * 0.66;
    for (var ring = 1; ring <= 3; ring++) {
      final r = maxR * (ring / 3.0) * (0.4 + 0.6 * progress);
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = accent.withValues(alpha: (1.0 - ring * 0.22).clamp(0.15, 0.8)),
      );
    }
    _drawNode(canvas, center, label: 'g=0', radius: 13, color: accent, filled: true, glow: true);
    _drawNode(
      canvas,
      Offset(size.width * 0.82, (size.height - 26) * 0.52),
      label: '#',
      radius: 13,
      color: AppColors.amber,
      filled: progress > 0.72,
      glow: progress > 0.72,
    );
    _drawStructureStrip(
      canvas,
      size,
      prefix: 'Heap(g):',
      items: const <String>['g=1', 'g=2', 'g=3'],
      color: accent,
    );
  }

  void _paintIdaStar(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.50, (size.height - 28) * 0.48);
    final stage = (progress * 3.0).floor().clamp(0, 2);
    final radius = (size.height - 28) * (0.28 + stage * 0.22);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = accent.withValues(alpha: 0.78),
    );
    _drawNode(canvas, center, label: 'f≤${stage + 2}', radius: 15, color: accent, filled: true, glow: true);
    _drawNode(
      canvas,
      Offset(size.width * 0.80, (size.height - 28) * 0.32),
      label: '>',
      radius: 11,
      color: stage < 2 ? AppColors.coral : AppColors.amber,
      filled: true,
      glow: stage == 2,
    );
    _drawStructureStrip(
      canvas,
      size,
      prefix: 'Threshold:',
      items: <String>['T=${stage + 2}', 'O(b·d)'],
      color: accent,
    );
  }

  void _paintHillClimbing(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height - 28;
    final curve = Path();
    double heightAt(double t) {
      // Smooth landscape with a local peak at t=0.28 and global peak at t=0.78
      final local = math.exp(-math.pow((t - 0.28) / 0.11, 2)) * 0.46;
      final global = math.exp(-math.pow((t - 0.78) / 0.14, 2)) * 0.78;
      return h * (0.86 - local - global);
    }

    for (var i = 0; i <= 60; i++) {
      final t = i / 60.0;
      final x = 16 + t * (w - 32);
      final y = heightAt(t);
      if (i == 0) {
        curve.moveTo(x, y);
      } else {
        curve.lineTo(x, y);
      }
    }
    canvas.drawPath(
      curve,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = AppColors.sky.withValues(alpha: 0.75),
    );

    // Global peak star marker
    final globalPt = Offset(16 + 0.78 * (w - 32), heightAt(0.78));
    _drawNode(canvas, globalPt, label: '★', radius: 10, color: AppColors.cyan, filled: true, glow: progress > 0.75);

    // Moving dot: climbs local hill (0..0.4), restarts (0.4..0.55), climbs global (0.55..1.0)
    final dotT = progress < 0.42
        ? 0.08 + (progress / 0.42) * 0.20
        : (progress < 0.56 ? 0.56 : 0.56 + ((progress - 0.56) / 0.44) * 0.22);
    final dotPos = Offset(16 + dotT * (w - 32), heightAt(dotT));
    _drawNode(canvas, dotPos, label: '', radius: 7, color: accent, filled: true, glow: true);

    _drawStructureStrip(
      canvas,
      size,
      prefix: 'Local:',
      items: progress < 0.56
          ? const <String>['Climb', 'Local Opt']
          : const <String>['Restart', 'Global ★'],
      color: accent,
    );
  }

  void _drawNode(
    Canvas canvas,
    Offset center, {
    required String label,
    required Color color,
    bool filled = false,
    bool glow = false,
    double radius = 12,
  }) {
    if (glow) {
      canvas.drawCircle(
        center,
        radius * 1.45,
        Paint()..color = color.withValues(alpha: 0.26),
      );
    }
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = filled ? color.withValues(alpha: 0.24) : AppColors.bgElevated,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = glow ? 2.2 : 1.5
        ..color = color,
    );
    if (label.isNotEmpty) {
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: radius * 0.78,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
    }
  }

  void _drawStructureStrip(
    Canvas canvas,
    Size size, {
    required String prefix,
    required List<String> items,
    required Color color,
  }) {
    final y = size.height - 15;
    final prefixPainter = TextPainter(
      text: TextSpan(
        text: prefix,
        style: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    prefixPainter.paint(canvas, Offset(12, y - prefixPainter.height / 2));

    var x = 18 + prefixPainter.width;
    for (final item in items) {
      final itemPainter = TextPainter(
        text: TextSpan(
          text: item,
          style: const TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final boxW = itemPainter.width + 12;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y - 9, boxW, 18),
        const Radius.circular(5),
      );
      canvas.drawRRect(rect, Paint()..color = color.withValues(alpha: 0.16));
      canvas.drawRRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = color.withValues(alpha: 0.45),
      );
      itemPainter.paint(canvas, Offset(x + 6, y - itemPainter.height / 2));
      x += boxW + 6;
    }
  }

  @override
  bool shouldRepaint(covariant _ExplainerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.type != type ||
        oldDelegate.accent != accent;
  }
}
