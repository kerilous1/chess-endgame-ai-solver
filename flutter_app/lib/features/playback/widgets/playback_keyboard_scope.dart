/// features/playback/widgets/playback_keyboard_scope.dart
/// ======================================================
/// Wraps the workspace with desktop keyboard shortcuts (`←`, `→`, `Space`,
/// `Home`, `End`) to scrub through the solved checkmate sequence effortlessly.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';

/// Intercepts arrow and space keys when a solution path is loaded.
class PlaybackKeyboardScope extends ConsumerWidget {
  /// Creates a [PlaybackKeyboardScope].
  const PlaybackKeyboardScope({super.key, required this.child});

  /// Descendant subtree (typically the main workspace scaffold).
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSolution = ref.watch(
      playbackProvider.select((state) => state.hasSolution),
    );
    final notifier = ref.read(playbackProvider.notifier);

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        if (hasSolution) ...<ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.arrowLeft): notifier.prev,
          const SingleActivator(LogicalKeyboardKey.arrowRight): notifier.next,
          const SingleActivator(LogicalKeyboardKey.space):
              notifier.toggleAutoPlay,
          const SingleActivator(LogicalKeyboardKey.home): notifier.first,
          const SingleActivator(LogicalKeyboardKey.end): notifier.last,
        },
      },
      child: Focus(
        autofocus: true,
        child: child,
      ),
    );
  }
}
