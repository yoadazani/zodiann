import 'dart:ui' show SemanticsRole;

import 'package:material_ui/material_ui.dart';

import '../theme/tokens/zodiann_dimensions.dart';
import '../theme/tokens/zodiann_states.dart';
import '../theme/zodiann_surfaces.dart';
import '../theme/zodiann_text_styles.dart';
import 'zodiann_pressable.dart';

/// One choice of a [ZodiannRadioList].
final class ZodiannRadioOption<T> {
  /// An option selecting [value], shown as [label] and an optional [badge].
  const ZodiannRadioOption({
    required this.value,
    required this.label,
    this.badge,
  });

  /// What [ZodiannRadioList.onChanged] receives.
  final T value;

  /// The visible and accessible name, localized by the caller. It wraps onto
  /// further lines rather than being cut.
  final String label;

  /// A trailing note ("Recommended", "Backup"), localized by the caller. A
  /// screen reader reads it after the label.
  final String? badge;
}

/// A single-selection list of radio rows (MASTER.md §10 "Others"; the
/// "Ephemeris source" block of the settings screen, settings.html `.radio`).
///
/// Each row is a round dot, a label and an optional trailing badge. Off: a
/// 1.5 px `line` ring. Selected: a 5 px `accent` ring around an 8 px hole.
/// The ring crossfades over 120 ms (MASTER §12), instantly under reduced
/// motion. Rows follow the reading direction: in Hebrew the dot is on the
/// right and the badge on the left.
///
/// A row is a `ZodiannPressable`: a 44 px minimum height (the rows touch, with
/// no gap: the 8 px between targets of MASTER §14 is waived for these dense
/// list rows, owner decision O1 of ZOD-UI-008), hover, press, a keyboard ring
/// and Enter / Space / tap. The list keeps no selection of its own: the parent
/// passes [value] and updates it from [onChanged].
///
/// Keyboard (NFR-X2, the radio-group pattern): exactly one row is in the Tab
/// order, the selected one (the first when nothing is selected). Arrow keys
/// **select** and focus: Down and Right the next row, Up and Left the
/// previous one (Left and Right swap in Hebrew), wrapping at the ends. With
/// nothing selected an arrow selects the first row (next) or the last
/// (previous). A parent that rejects the change leaves the tab stop on the
/// selected row.
///
/// Screen readers get a radio group; each row is a button that is checked or
/// not and belongs to a mutually exclusive group, with the badge as its hint.
///
/// [onChanged] null disables every row (42 % opacity, inert, not focusable).
class ZodiannRadioList<T> extends StatefulWidget {
  /// A list of [options] with [value] selected.
  ZodiannRadioList({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.autofocus = false,
  }) : assert(options.isNotEmpty, 'a radio list needs at least one option'),
       assert(
         options.map((o) => o.value).toSet().length == options.length,
         'option values must be unique',
       ),
       assert(
         options.every((o) => o.label.trim().isNotEmpty),
         'every option needs a label',
       ),
       assert(
         value == null || options.any((o) => o.value == value),
         'value must be one of the options',
       );

  /// The choices.
  final List<ZodiannRadioOption<T>> options;

  /// The selected choice, or null when nothing is selected.
  final T? value;

  /// Called with the chosen value; null disables the list. Not called for the
  /// row that is already selected.
  final ValueChanged<T>? onChanged;

  /// The group's accessible name, localized by the caller.
  final String semanticLabel;

  /// Whether the tab-stop row requests focus when first built.
  final bool autofocus;

  @override
  State<ZodiannRadioList<T>> createState() => _ZodiannRadioListState<T>();
}

class _ZodiannRadioListState<T> extends State<ZodiannRadioList<T>> {
  // One node per option, keyed by value; stale ones are disposed after the
  // frame, never while the old detector still holds them.
  final Map<T, FocusNode> _nodes = {};

  bool get _enabled => widget.onChanged != null;

  int get _selectedIndex =>
      widget.options.indexWhere((o) => o.value == widget.value);

  /// The one row in the Tab order: the selected one, else the first.
  int get _stopIndex {
    final selected = _selectedIndex;
    return selected < 0 ? 0 : selected;
  }

  FocusNode _nodeAt(int i) {
    final option = widget.options[i];
    final node = _nodes.putIfAbsent(option.value, FocusNode.new);
    node.debugLabel = 'radio-row-$i';
    return node;
  }

  void _syncNodes() {
    final live = {for (final o in widget.options) o.value};
    final stale = [
      for (final key in _nodes.keys)
        if (!live.contains(key)) key,
    ];
    if (stale.isNotEmpty) {
      final nodes = [for (final key in stale) _nodes.remove(key)!];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final node in nodes) {
          node.dispose();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final node in _nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  int? _focusedIndex() {
    for (var i = 0; i < widget.options.length; i++) {
      if (_nodes[widget.options[i].value]?.hasPrimaryFocus ?? false) return i;
    }
    return null;
  }

  bool _arrowEnabled() => _enabled && _focusedIndex() != null;

  void _move({required bool forward}) {
    final onChanged = widget.onChanged;
    final from = _focusedIndex();
    if (onChanged == null || from == null) return;
    final count = widget.options.length;
    if (count < 2) return;
    final int to;
    if (widget.value == null) {
      to = forward ? 0 : count - 1;
    } else {
      to = (from + (forward ? 1 : -1) + count) % count;
    }
    final option = widget.options[to];
    final node = _nodeAt(to);
    // As the default traversal does: focus it and scroll it into view.
    FocusTraversalPolicy.defaultTraversalRequestFocusCallback(node);
    onChanged(option.value);
  }

  @override
  Widget build(BuildContext context) {
    _syncNodes();
    final theme = Theme.of(context);
    final s = theme.extension<ZodiannSurfaces>()!;
    final styles = theme.extension<ZodiannTextStyles>()!;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : ZodiannStates.selectionDuration;
    final stop = _stopIndex;
    final onChanged = widget.onChanged;

    final labelStyle = styles.body.copyWith(color: s.text);
    final badgeStyle = styles.body.copyWith(
      fontSize: ZodiannSize.radioBadgeText,
      color: s.text3,
    );

    Widget row(int i) {
      final option = widget.options[i];
      final selected = i == _selectedIndex;
      final badge = option.badge;
      return ZodiannPressable(
        // Keyed by value: an inserted or moved option must not hand its
        // neighbour's focus node, hover or dot state to another row.
        key: ObjectKey(option.value),
        onPressed: onChanged == null
            ? null
            : selected
            ? _noop
            : () => onChanged(option.value),
        semanticLabel: option.label,
        semanticHint: badge,
        checked: selected,
        inMutuallyExclusiveGroup: true,
        focusNode: _nodeAt(i),
        autofocus: widget.autofocus && i == stop,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: ZodiannSize.radioRowPadding,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                key: ValueKey('zodiann-radio-dot-$i'),
                duration: duration,
                curve: Curves.linear,
                width: ZodiannSize.radioDot,
                height: ZodiannSize.radioDot,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? s.accent : s.line,
                    width: selected
                        ? ZodiannSize.radioDotSelectedBorder
                        : ZodiannSize.radioDotBorder,
                  ),
                ),
              ),
              const SizedBox(width: ZodiannSpace.s3),
              Expanded(child: Text(option.label, style: labelStyle)),
              if (badge != null) ...[
                const SizedBox(width: ZodiannSpace.s3),
                Text(badge, style: badgeStyle),
              ],
            ],
          ),
        ),
      );
    }

    return Semantics(
      container: true,
      explicitChildNodes: true,
      role: SemanticsRole.radioGroup,
      label: widget.semanticLabel,
      child: Actions(
        actions: {
          DirectionalFocusIntent: _ArrowAction(
            enabled: _arrowEnabled,
            onMove: (forward) => _move(forward: forward),
            rtl: rtl,
          ),
        },
        // Tab visits one row only (the radio-group pattern). A traversal policy
        // rather than per-node flags: ZodiannPressable's focus detector sets
        // canRequestFocus on its node on every build.
        child: FocusTraversalGroup(
          policy: _RovingTabPolicy(stop: _nodeAt(stop)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [for (var i = 0; i < widget.options.length; i++) row(i)],
          ),
        ),
      ),
    );
  }
}

void _noop() {}

/// Tab order inside the list: the row that holds focus while one does (after
/// an arrow key a rejected change leaves focus off the stop, and one Tab or
/// Shift+Tab must still leave the group), otherwise the tab-stop row.
class _RovingTabPolicy extends ReadingOrderTraversalPolicy {
  _RovingTabPolicy({required this.stop});

  final FocusNode stop;

  @override
  Iterable<FocusNode> sortDescendants(
    Iterable<FocusNode> descendants,
    FocusNode currentNode,
  ) {
    final sorted = super.sortDescendants(descendants, currentNode).toList();
    final focused = sorted.where((n) => n.hasFocus).toList();
    if (focused.isNotEmpty) return focused;
    return sorted.where((n) => n == stop);
  }
}

/// The four arrow keys while a row has focus: Down and Right the next row, Up
/// and Left the previous one (Left and Right swap in Hebrew).
class _ArrowAction extends Action<DirectionalFocusIntent> {
  _ArrowAction({
    required this.enabled,
    required this.onMove,
    required this.rtl,
  });

  final bool Function() enabled;
  final void Function(bool forward) onMove;
  final bool rtl;

  @override
  bool isEnabled(DirectionalFocusIntent intent) => enabled();

  @override
  bool consumesKey(DirectionalFocusIntent intent) => true;

  @override
  Object? invoke(DirectionalFocusIntent intent) {
    final bool forward;
    switch (intent.direction) {
      case TraversalDirection.down:
        forward = true;
      case TraversalDirection.up:
        forward = false;
      case TraversalDirection.right:
        forward = !rtl;
      case TraversalDirection.left:
        forward = rtl;
    }
    onMove(forward);
    return null;
  }
}
