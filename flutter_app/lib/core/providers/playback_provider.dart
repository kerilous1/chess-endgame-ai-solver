/// core/providers/playback_provider.dart
/// =======================================
/// Riverpod controller managing step-by-step solution playback:
/// - Transport actions: `first`, `prev`, `next`, `last`, `scrubTo`
/// - Timed `autoPlay` with speed selection (`0.5×`, `1×`, `2×`)
/// - Derived `displayedBoard` and `previousBoard` snapshots for gliding pieces
///   and tactical commentary
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ai_engine/ai_engine.dart';

/// Playback speed presets matching `krk_6_6.html` (`0.5×`, `1×`, `2×`).
enum PlaybackSpeed {
  slow(0.5, Duration(milliseconds: 1600), '0.5×'),
  normal(1.0, Duration(milliseconds: 850), '1×'),
  fast(2.0, Duration(milliseconds: 420), '2×');

  const PlaybackSpeed(this.multiplier, this.stepDuration, this.label);

  /// Speed multiplier.
  final double multiplier;

  /// Interval between automatic frame advances.
  final Duration stepDuration;

  /// Compact UI pill label.
  final String label;
}

/// Immutable playback state consumed by the board, scrubber, and telemetry.
class PlaybackState {
  /// Creates a [PlaybackState].
  const PlaybackState({
    required this.initialBoard,
    this.steps = const <MoveStep>[],
    this.currentFrameIndex = 0,
    this.isPlaying = false,
    this.speed = PlaybackSpeed.normal,
  });

  /// Starting board before frame 1.
  final BoardState initialBoard;

  /// Reconstructed solution frames (`0 .. steps.length - 1`).
  final List<MoveStep> steps;

  /// Active frame cursor (`0` = initial board; `1..steps.length` = `steps[i-1]`).
  final int currentFrameIndex;

  /// True while auto-play timer is ticking.
  final bool isPlaying;

  /// Selected playback speed.
  final PlaybackSpeed speed;

  /// True when a solved path is currently loaded.
  bool get hasSolution => steps.isNotEmpty;

  /// Maximum valid [currentFrameIndex].
  int get totalFrames => steps.length;

  /// True when viewing frame `0` (initial position).
  bool get isAtStart => currentFrameIndex <= 0;

  /// True when viewing the final checkmate frame.
  bool get isAtEnd => currentFrameIndex >= steps.length;

  /// Active [MoveStep] at [currentFrameIndex], or `null` at frame `0`.
  MoveStep? get activeStep =>
      (currentFrameIndex > 0 && currentFrameIndex <= steps.length)
          ? steps[currentFrameIndex - 1]
          : null;

  /// Board position currently displayed on the 6×6 grid.
  BoardState get displayedBoard => activeStep?.snapshot ?? initialBoard;

  /// Board position immediately prior to [activeStep] (for delta storytelling).
  BoardState? get previousBoard {
    if (currentFrameIndex <= 0) return null;
    if (currentFrameIndex == 1) return initialBoard;
    return steps[currentFrameIndex - 2].snapshot;
  }

  /// Returns an updated copy of [PlaybackState].
  PlaybackState copyWith({
    BoardState? initialBoard,
    List<MoveStep>? steps,
    int? currentFrameIndex,
    bool? isPlaying,
    PlaybackSpeed? speed,
  }) {
    return PlaybackState(
      initialBoard: initialBoard ?? this.initialBoard,
      steps: steps ?? this.steps,
      currentFrameIndex: currentFrameIndex ?? this.currentFrameIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      speed: speed ?? this.speed,
    );
  }
}

/// Controls solution navigation and auto-play timing.
class PlaybackNotifier extends Notifier<PlaybackState> {
  Timer? _timer;

  @override
  PlaybackState build() {
    ref.onDispose(_stopTimer);
    return PlaybackState(
      initialBoard: MovesEngine.presetPosition(EndgameMode.krk, variant: 0),
    );
  }

  /// Loads a newly computed checkmate [path] starting from [startBoard].
  void loadSolution(BoardState startBoard, List<MoveStep> path) {
    _stopTimer();
    state = PlaybackState(
      initialBoard: startBoard,
      steps: List<MoveStep>.unmodifiable(path),
      currentFrameIndex: 0,
      isPlaying: false,
      speed: state.speed,
    );
  }

  /// Clears any loaded solution path and stops playback.
  void reset() {
    _stopTimer();
    state = PlaybackState(
      initialBoard: MovesEngine.presetPosition(EndgameMode.krk, variant: 0),
      speed: state.speed,
    );
  }

  /// Jumps to frame `0` (initial position).
  void first() {
    pause();
    if (!state.hasSolution) return;
    state = state.copyWith(currentFrameIndex: 0);
  }

  /// Steps one frame backward.
  void prev() {
    pause();
    if (!state.hasSolution || state.isAtStart) return;
    state = state.copyWith(currentFrameIndex: state.currentFrameIndex - 1);
  }

  /// Steps one frame forward.
  void next() {
    pause();
    _advanceOneStep();
  }

  /// Jumps directly to the final checkmate frame.
  void last() {
    pause();
    if (!state.hasSolution) return;
    state = state.copyWith(currentFrameIndex: state.totalFrames);
  }

  /// Scrubs directly to [frameIndex] (`0 .. totalFrames`).
  void scrubTo(int frameIndex) {
    pause();
    if (!state.hasSolution) return;
    final clamped = frameIndex.clamp(0, state.totalFrames);
    state = state.copyWith(currentFrameIndex: clamped);
  }

  /// Starts or pauses automatic step-by-step playback.
  void toggleAutoPlay() {
    if (!state.hasSolution) return;
    if (state.isPlaying) {
      pause();
      return;
    }

    // Restart from frame 0 if the user presses Play while already at checkmate.
    if (state.isAtEnd) {
      state = state.copyWith(currentFrameIndex: 0);
    }

    state = state.copyWith(isPlaying: true);
    _startTimer();
  }

  /// Stops auto-play without altering the current frame.
  void pause() {
    _stopTimer();
    if (state.isPlaying) {
      state = state.copyWith(isPlaying: false);
    }
  }

  /// Changes playback speed and refreshes the active timer if currently playing.
  void setSpeed(PlaybackSpeed speed) {
    final wasPlaying = state.isPlaying;
    state = state.copyWith(speed: speed);
    if (wasPlaying) {
      _startTimer();
    }
  }

  void _startTimer() {
    _stopTimer();
    _timer = Timer.periodic(state.speed.stepDuration, (_) {
      if (!state.hasSolution || state.isAtEnd) {
        pause();
        return;
      }
      _advanceOneStep();
      if (state.isAtEnd) {
        pause();
      }
    });
  }

  void _advanceOneStep() {
    if (!state.hasSolution || state.isAtEnd) return;
    state = state.copyWith(currentFrameIndex: state.currentFrameIndex + 1);
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Global playback controller provider.
final playbackProvider =
    NotifierProvider<PlaybackNotifier, PlaybackState>(PlaybackNotifier.new);
