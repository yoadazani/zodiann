# ZOD-NAV-002 Side navigation drawer: design

Task: `docs/development/navigation/ZOD-NAV-002-implement-the-side-navigation-drawer.md`. Spec: NAV-2, NAV-3, NAV-7. Design: MASTER §5 "Drawer", §12 "Motion", `DESIGN_DECISIONS.md` D17, `_source/kit.css:149-174`, `_source/kit.js:255-267`, `screens/00-navigation-drawer_desktop_{en,he}_dark.png`, `responsive/mobile/navigation-drawer_mobile_{en,he}_dark.png`.

## Intent

The hamburger opens a drawer from the start side. It shows the logo and wordmark, two groups of five screens (each with an icon, a name and a description, the active one marked), and a footer. It closes four ways: backdrop tap, close button, swipe aside, Android back. It is never permanent, at any width.

## Goals

- The drawer matches the references pixel for pixel in en and he, and in both themes (a light reference is rendered from `kit.css`, see below).
- Open 240 ms `easeOutCubic`, close 180 ms, the scrim fading in step; instant under reduced motion (MASTER §12).
- The active item carries the accessibility "selected" state (NAV-3).
- A route-independent `shared_ui` widget, like `ZodiannTopBar`. No route contract has to live in a feature package.

## Non-goals

- **Item taps do nothing in this task (product-owner decision A, 2026-11-17).** The item reports a tap, and the app passes a no-op. ZOD-NAV-003 wires navigation and closing.
- Focus moving to the active item on open, focus returning to the hamburger, and the hamburger's expanded / collapsed state: ZOD-NAV-004.
- Verifying the width rule and "never docked" across breakpoints: ZOD-NAV-005 (this task still implements `min(320, 86 %)`).
- The real app version (no version source exists yet).

## Approaches

Product-owner decision (2026-11-17): **option 2**.

1. **`Scaffold.drawer`.** Back, scrim tap and swipe come built in. Its settle time is fixed at about 246 ms both ways and it ignores reduced motion, so it misses MASTER §12. Rejected.
2. **A custom modal route (chosen).** `ZodiannDrawer` is the panel. A small `PopupRoute` supplies the 240 / 180 ms timing, the scrim and the reduced-motion fallback. Back, backdrop tap and the close button all pop the route. It is a real route, so NAV-004's focus work follows naturally.
3. **An in-shell `Stack` overlay with no route.** Back needs a manual `PopScope`, and the route stack and focus become fragile. Rejected.

## Design

**`shared_ui`**
- `ZodiannDrawer`: header (76 high, 1 px `line-soft` rule; logo `ZodiannLogo(size: ZodiannSize.logoDrawer)`, wordmark 20/600 −0.01 em, a `ZodiannIconButton` with `ZodiannIcons.x` at the end), groups, footer (version and the "stays on this device" line, `text-3`, 12). Width `min(320, 0.86 × screen width)`, `surface` fill, `ZodiannElevation.floating` plus `floatingOutline`. Logical (directional) layout throughout, so it mirrors in Hebrew.
- `ZodiannDrawerGroup(label, items)` and `ZodiannDrawerItem(icon, name, description, selected, onTap)`: route-independent data. An item is a `ZodiannPressable` (hover, press, focus ring, 44 px target) with semantics `selected`. The active item has the `accent-soft` fill, the full-strength icon and name, and a 3 px `accent` bar on the start edge.
- `showZodiannDrawer(context, builder)`: the `PopupRoute`, pushed on the root navigator so it covers the top bar. 240 ms in with `easeOutCubic`, 180 ms out, reduced motion → zero. The scrim is `scrim` and is excluded from semantics (the close button is the accessible way to dismiss). Swipe-aside is a horizontal drag toward the start edge that follows the finger and settles by velocity or the halfway point; RTL is mirrored. It has no edge-drag-to-open.
- The panel covers the status-bar and bottom insets with its background, and keeps its content inside the side and bottom safe areas.

**App (`apps/astro_mobile`)**
- `AppShell` enables the hamburger: `onMenuPressed` calls `showZodiannDrawer`. It maps `AppRoute.values` (table order) to the two groups; `selected` is the active route. Item taps are a no-op, marked for NAV-003.
- Copy (en and he): names and descriptions from `kit.js` (the screen titles already exist), the group labels "Analysis" / "Library and app", and the footer text. One string is new, because `kit.js` gives the drawer's close button no label: **"Close menu"** / **"סגירת תפריט"**, mirroring `openMenu`. The version line is `Version {version}` with the app passing `1.0.0`, a constant until a version source exists.

**Light-theme reference.** `kit.css` and `kit.js` render the drawer with `?theme=light&drawer=1`. The task's "both themes" criterion has no reference PNG, so the plan adds a Chrome-rendered light reference (en and he, desktop and mobile) in the same way as the earlier tasks' references, and compares against it.

## Tests (outline for the plan)

Widget: width at several screen widths; header geometry; the four close paths; swipe in LTR and RTL; reduced motion; the selected semantics; mirrored layout; `ZodiannLogo` variant follows the app theme. Reference PNGs in both languages and both themes. App: hamburger opens the drawer, the active item follows the route, back closes it without changing the route, items are inert. Mutation proofs as in earlier tasks.

## Open items / my calls

- The close-button label is new copy outside `kit.js` (needs approval).
- The close curve is `easeOutCubic` too, as MASTER names only one curve.
- The light reference is derived from `kit.css`, not a designer-supplied image.

## Approval (product owner, 2026-11-17)

The design is approved, with these clarifications:

1. **Close-button label.** "Close menu" / "סגירת תפריט" is an intentional, documented exception to NAV-001's "`kit.js`-only copy" rule. The labels stay localized (ARB) and consistent with `openMenu`.
2. **Light-theme references.** Generate them (en and he, desktop and mobile) with Chrome from `kit.css`. They are labelled as **generated visual references, not designer-provided assets**. `kit.css` and the design specification stay authoritative; the images never override or redefine them.
3. **Curve and version.** `easeOutCubic` for both open (240 ms) and close (180 ms); instant under reduced motion. `1.0.0` is a **temporary app-provided** value. **Version ownership stays outside `shared_ui`:** the drawer receives the version (or the finished line) from the caller and hardcodes nothing. The temporary fallback is documented so an authoritative version source can replace it later.
