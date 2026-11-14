/// The app's screens, in the spec's Navigation table order (NAV-5).
///
/// The spec's route identifier is `#` plus the value's `name` (`#wheel`,
/// `#square`, …). It is an identifier only, not a web address: no URL
/// strategy is configured. [path] is the same identifier as a `go_router`
/// location, which must start with `/`. [wheel] is the default.
///
/// **App-level placeholder, not a public contract.** Feature packages must
/// never import the app layer. The first task that needs a route from a
/// feature package (for example ZOD-DAT-005, or ZOD-NAV-001/002 if built in
/// `shared_ui`) decides where the feature-accessible route contract lives.
enum AppRoute {
  wheel,
  square,
  saved,
  settings,
  about;

  /// The `go_router` location: `/` plus [name].
  String get path => '/$name';
}
