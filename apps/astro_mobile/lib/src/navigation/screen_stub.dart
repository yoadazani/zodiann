import 'package:material_ui/material_ui.dart';

import 'app_route.dart';

/// The blank screen a route shows until its real screen exists
/// (ZOD-FND-014; the screens replace it in ZOD-NAV-003 and their own tasks).
///
/// It must not read `ephemerisPortProvider`: no source is bound yet.
class ScreenStub extends StatelessWidget {
  const ScreenStub({super.key, required this.route});

  /// The route this stub stands in for.
  final AppRoute route;

  @override
  Widget build(BuildContext context) => const Scaffold();
}
