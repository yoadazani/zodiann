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
}
