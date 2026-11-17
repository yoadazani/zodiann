import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart' show ZodiannBreakpoint;

import 'canvas/wheel_canvas.dart';
import 'geometry/wheel_proportions.dart';
import 'state/wheel_state.dart';

/// The zodiac wheel screen host (ZOD-WHL-001): the wheel canvas on the
/// screen's one provider.
///
/// It picks the desktop proportion table from the desktop breakpoint (1100
/// and up, MASTER §6) and the compact one below it (MASTER §7.2). It adds no
/// `ProviderScope`: it uses the app's root scope (ARCH-3). WHL-025 builds the
/// screen layout around it.
class WheelScreen extends ConsumerWidget {
  /// The wheel screen.
  const WheelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wheelStateProvider);
    final breakpoint = ZodiannBreakpoint.forWidth(
      MediaQuery.sizeOf(context).width,
    );
    return WheelCanvas(
      proportions: breakpoint == ZodiannBreakpoint.desktop
          ? WheelProportions.desktop
          : WheelProportions.compact,
      state: state,
    );
  }
}
