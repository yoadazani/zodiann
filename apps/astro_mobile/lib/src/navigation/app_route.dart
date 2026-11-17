/// The app's screens, in the spec's Navigation table order (NAV-5).
///
/// The spec's route identifier is `#` plus the value's `name` (`#wheel`,
/// `#square`, …). It is an identifier only, not a web address: no URL
/// strategy is configured. [path] is the same identifier as a `go_router`
/// location, which must start with `/`. [wheel] is the default.
///
/// **App-level placeholder, not a public contract.** Feature packages must
/// never import the app layer. ZOD-NAV-001's top bar is route-independent
/// (the app shell maps routes to its copy), and so is ZOD-NAV-002's drawer
/// (it takes item data, not routes), so the decision on where a
/// feature-accessible route contract lives passes to the first feature-side
/// navigation (ZOD-DAT-005).
enum AppRoute {
  wheel,
  square,
  saved,
  settings,
  about;

  /// The `go_router` location: `/` plus [name].
  String get path => '/$name';

  /// The screen a router location resolves to: exact equality with [path],
  /// else the wheel. The shell and `activeRouteProvider` both resolve the
  /// matched route through this, so the top bar and the drawer agree.
  static AppRoute fromPath(String path) =>
      values.firstWhere((route) => route.path == path, orElse: () => wheel);

  /// The screen a link names, or null when it names none (ZOD-NAV-003).
  ///
  /// Accepts no scheme or the `zodiann` scheme (a scheme URI must have an
  /// authority, so `zodiann:square` and `zodiann:/square` name nothing). A
  /// host form (`zodiann://square`) needs a path of `''` or `/`; the path
  /// forms (`/square`, `zodiann:///square`) tolerate one trailing slash.
  /// Queries and fragments are ignored. Names are case-sensitive, except that
  /// `Uri` lowercases a scheme and a host, so `zodiann://Square` and
  /// `ZODIANN://square` resolve.
  ///
  /// Invariant: `fromUri(raw) ?? wheel` must equal the screen the router
  /// settles on after go_router normalises the link and the redirect runs,
  /// otherwise the active-route seed would differ from the first
  /// configuration.
  static AppRoute? fromUri(Uri uri) {
    var path = uri.path;
    if (uri.hasScheme) {
      if (uri.scheme != 'zodiann' || !uri.hasAuthority) return null;
      if (uri.host.isNotEmpty) {
        if (path.isNotEmpty && path != '/') return null;
        return _named(uri.host);
      }
    }
    if (path.length > 1 && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    return _named(path.startsWith('/') ? path.substring(1) : null);
  }

  static AppRoute? _named(String? name) {
    for (final route in values) {
      if (route.name == name) return route;
    }
    return null;
  }
}
