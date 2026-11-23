import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../icons/zodiann_icon.dart';
import '../icons/zodiann_icon_data.dart';
import '../icons/zodiann_icons.g.dart';
import '../theme/tokens/zodiann_dimensions.dart';
import '../theme/tokens/zodiann_states.dart';
import '../theme/zodiann_surfaces.dart';
import '../theme/zodiann_text_styles.dart';

/// The text, date and number input (MASTER.md §10 "Inputs"; kit.css `.field`
/// and `.input`): a label above a 40 px field on `bg-raised` with a `line`
/// border, an optional leading icon in `text-3`, and four treatments.
///
/// - **Focus** (mouse or keyboard): `accent` border plus a 3 px `accent-soft`
///   halo painted outside the box, so the layout does not change.
/// - **Error:** [errorText] switches on a `danger` border, a 3 px `danger-soft`
///   halo and a message row under the field (16 px alert icon, 12 px `danger`
///   text) that says how to fix the value (NFR-R2). Colour is never the only
///   signal (NFR-X4). A blank [errorText] asserts; a disabled field ignores it.
/// - **Disabled:** the input box at 45 % opacity, not focusable, not editable;
///   the label keeps full strength.
///
/// The widget parses and validates nothing: the caller decides when a value is
/// invalid and passes the message. Any string is accepted without throwing.
///
/// A tap on the label, or in the gap beneath it, focuses the field (as an HTML
/// `label`). [ltr] is for dates and numbers (L-7): the value is laid out left
/// to right and starts at the physical left even in a Hebrew layout.
class ZodiannTextField extends StatefulWidget {
  /// A field with its visible, localized [label].
  // Not const: the blank-message assert needs `trim()`; labels are localized at
  // run time, so a field is never a constant anyway.
  ZodiannTextField({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.leadingIcon,
    this.hintText,
    this.errorText,
    this.enabled = true,
    this.ltr = false,
    this.inputWidth,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
  }) : assert(
         errorText == null || errorText.trim().isNotEmpty,
         'errorText must not be blank: an error always explains itself',
       );

  /// The label above the field, always visible.
  final String label;

  /// The text being edited; null means the field owns one.
  final TextEditingController? controller;

  /// The field's focus node; null means the field owns one.
  final FocusNode? focusNode;

  /// An optional 16 px icon in `text-3` before the value.
  final ZodiannIconData? leadingIcon;

  /// The placeholder shown in `text-3` while the field is empty.
  final String? hintText;

  /// Non-null turns on the error state and shows this message.
  final String? errorText;

  /// False dims the input to 45 % and makes it inert.
  final bool enabled;

  /// Lay the value out left to right, start-aligned (L-7: dates and numbers).
  final bool ltr;

  /// A fixed width for the input box alone, at the start edge; the label and
  /// the error message keep the field's full width (the component sheet's
  /// 120 px Cells field, kit.css `width: 120px` on `.input`). Null fills.
  final double? inputWidth;

  /// The soft keyboard to show.
  final TextInputType? keyboardType;

  /// The keyboard's action key.
  final TextInputAction? textInputAction;

  /// Formatters applied to every edit.
  final List<TextInputFormatter>? inputFormatters;

  /// Called with the new text after every edit.
  final ValueChanged<String>? onChanged;

  /// Called with the text when the action key is pressed.
  final ValueChanged<String>? onSubmitted;

  /// Focus the field when first built.
  final bool autofocus;

  /// Identifies the drawn 40 px input box in tests.
  @visibleForTesting
  static const Key inputBoxKey = ValueKey<String>('zodiann-text-field-box');

  @override
  State<ZodiannTextField> createState() => _ZodiannTextFieldState();
}

class _ZodiannTextFieldState extends State<ZodiannTextField>
    implements TextSelectionGestureDetectorBuilderDelegate {
  final GlobalKey<EditableTextState> _editableKey =
      GlobalKey<EditableTextState>();
  late final TextSelectionGestureDetectorBuilder _gestures =
      TextSelectionGestureDetectorBuilder(delegate: this);

  TextEditingController? _ownedController;
  FocusNode? _ownedNode;

  TextEditingController get _controller =>
      widget.controller ?? (_ownedController ??= TextEditingController());
  FocusNode get _focusNode => widget.focusNode ?? (_ownedNode ??= FocusNode());

  @override
  GlobalKey<EditableTextState> get editableTextKey => _editableKey;
  @override
  bool get forcePressEnabled => false;
  @override
  bool get selectionEnabled => widget.enabled;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(ZodiannTextField old) {
    super.didUpdateWidget(old);
    if (old.enabled && !widget.enabled && _focusNode.hasFocus) {
      _focusNode.unfocus();
    }
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _ownedNode)!.removeListener(_onFocus);
      if (old.focusNode != null && widget.focusNode == null) {
        // Moving from a supplied node to an owned one: nothing to dispose.
      } else if (old.focusNode == null && widget.focusNode != null) {
        _ownedNode?.dispose();
        _ownedNode = null;
      }
      _focusNode.addListener(_onFocus);
    }
    if (old.controller == null && widget.controller != null) {
      _ownedController?.dispose();
      _ownedController = null;
    }
  }

  @override
  void dispose() {
    (widget.focusNode ?? _ownedNode)?.removeListener(_onFocus);
    _ownedNode?.dispose();
    _ownedController?.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (mounted) setState(() {});
  }

  void _focusField() {
    if (!widget.enabled) return;
    _editableKey.currentState?.requestKeyboard();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.extension<ZodiannSurfaces>()!;
    final t = theme.extension<ZodiannTextStyles>()!;
    final enabled = widget.enabled;
    final error = enabled ? widget.errorText : null;
    final focused = enabled && _focusNode.hasFocus;

    final Color borderColor = error != null
        ? s.danger
        : focused
        ? s.accent
        : s.line;
    final Color? haloColor = error != null
        ? s.dangerSoft
        : focused
        ? s.accentSoft
        : null;

    final valueStyle = t.body.copyWith(color: s.text);
    final textDirection = widget.ltr ? TextDirection.ltr : null;

    Widget editable = EditableText(
      key: _editableKey,
      controller: _controller,
      focusNode: _focusNode,
      style: valueStyle,
      cursorColor: s.accent,
      backgroundCursorColor: s.line,
      selectionColor: s.accentLine,
      selectionControls: _selectionControls(theme.platform),
      contextMenuBuilder: (context, state) =>
          AdaptiveTextSelectionToolbar.editableText(editableTextState: state),
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      inputFormatters: [_wellFormedText, ...?widget.inputFormatters],
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      autofocus: enabled && widget.autofocus,
      readOnly: !enabled,
      autocorrect: false,
      enableSuggestions: false,
      maxLines: 1,
      textDirection: textDirection,
      textAlign: TextAlign.start,
      scrollPadding: const EdgeInsets.all(ZodiannSpace.s5),
      rendererIgnoresPointer: true,
    );
    editable = _gestures.buildGestureDetector(
      behavior: HitTestBehavior.translucent,
      child: editable,
    );
    if (widget.hintText != null) {
      final hint = Positioned.fill(
        child: IgnorePointer(
          child: ExcludeSemantics(
            child: Align(
              alignment: widget.ltr
                  ? Alignment.centerLeft
                  : AlignmentDirectional.centerStart,
              child: Text(
                widget.hintText!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: textDirection,
                style: valueStyle.copyWith(color: s.text3),
              ),
            ),
          ),
        ),
      );
      editable = Stack(
        children: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) =>
                value.text.isEmpty ? hint : const SizedBox.shrink(),
          ),
          editable,
        ],
      );
    }
    editable = ExcludeFocus(
      excluding: !enabled,
      child: IgnorePointer(ignoring: !enabled, child: editable),
    );

    Widget input = DecoratedBox(
      key: ZodiannTextField.inputBoxKey,
      decoration: BoxDecoration(
        color: s.bgRaised,
        borderRadius: ZodiannRadius.control,
        border: Border.all(color: borderColor, width: ZodiannSize.hairline),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: ZodiannSize.control),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: ZodiannSpace.s3),
            child: Row(
              children: [
                if (widget.leadingIcon != null) ...[
                  ExcludeSemantics(
                    child: ZodiannIcon(
                      widget.leadingIcon!,
                      size: ZodiannSize.iconSmall,
                      color: s.text3,
                    ),
                  ),
                  const SizedBox(width: ZodiannSpace.s2),
                ],
                Expanded(child: editable),
              ],
            ),
          ),
        ),
      ),
    );
    if (!enabled) {
      input = Opacity(
        opacity: ZodiannStates.fieldDisabledOpacity,
        child: input,
      );
    }
    input = MouseRegion(
      cursor: enabled ? SystemMouseCursors.text : SystemMouseCursors.basic,
      child: input,
    );
    if (haloColor != null) {
      input = CustomPaint(
        painter: ZodiannFieldHaloPainter(
          color: haloColor,
          width: ZodiannSize.fieldHalo,
          radius: ZodiannRadius.control.topLeft.x,
        ),
        child: input,
      );
    }
    if (widget.inputWidth != null) {
      input = Align(
        alignment: AlignmentDirectional.centerStart,
        child: SizedBox(width: widget.inputWidth, child: input),
      );
    }

    final hintParts = [?widget.hintText, ?error];
    final labelStyle = t.label.copyWith(color: s.text2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        MergeSemantics(
          child: Semantics(
            container: true,
            label: widget.label,
            hint: hintParts.isEmpty ? null : hintParts.join('. '),
            enabled: enabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _focusField,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      bottom: ZodiannSize.fieldGap,
                    ),
                    child: ExcludeSemantics(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(widget.label, style: labelStyle),
                      ),
                    ),
                  ),
                ),
                input,
              ],
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: ZodiannSize.fieldGap),
            child: Semantics(
              liveRegion: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: ZodiannIcon(
                      ZodiannIcons.alert,
                      size: ZodiannSize.iconSmall,
                      color: s.danger,
                    ),
                  ),
                  const SizedBox(width: ZodiannSize.fieldGap),
                  Expanded(
                    child: Text(
                      error,
                      style: t.label.copyWith(
                        color: s.danger,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  TextSelectionControls _selectionControls(TargetPlatform platform) =>
      switch (platform) {
        TargetPlatform.android ||
        TargetPlatform.fuchsia => materialTextSelectionControls,
        _ => desktopTextSelectionControls,
      };
}

/// Removes unpaired UTF-16 surrogates from every edit. The engine's text
/// layout throws on ill-formed text, and pasted text can contain a lone
/// surrogate; an input must never crash on what is typed or pasted (NFR-R2).
const TextInputFormatter _wellFormedText = _WellFormedTextFormatter();

final class _WellFormedTextFormatter extends TextInputFormatter {
  const _WellFormedTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (_isWellFormed(text)) return newValue;
    final kept = StringBuffer();
    var removedBeforeBase = 0;
    var removedBeforeExtent = 0;
    final units = text.codeUnits;
    for (var i = 0; i < units.length; i++) {
      final u = units[i];
      final isHigh = u >= 0xD800 && u <= 0xDBFF;
      final isLow = u >= 0xDC00 && u <= 0xDFFF;
      final pairedHigh = isHigh && i + 1 < units.length && _isLow(units[i + 1]);
      final pairedLow = isLow && i > 0 && _isHigh(units[i - 1]);
      if ((isHigh && !pairedHigh) || (isLow && !pairedLow)) {
        if (i < newValue.selection.baseOffset) removedBeforeBase++;
        if (i < newValue.selection.extentOffset) removedBeforeExtent++;
      } else {
        kept.writeCharCode(u);
      }
    }
    final clean = kept.toString();
    final selection = newValue.selection.isValid
        ? TextSelection(
            baseOffset: (newValue.selection.baseOffset - removedBeforeBase)
                .clamp(0, clean.length),
            extentOffset:
                (newValue.selection.extentOffset - removedBeforeExtent).clamp(
                  0,
                  clean.length,
                ),
          )
        : newValue.selection;
    return TextEditingValue(text: clean, selection: selection);
  }

  static bool _isHigh(int u) => u >= 0xD800 && u <= 0xDBFF;
  static bool _isLow(int u) => u >= 0xDC00 && u <= 0xDFFF;

  static bool _isWellFormed(String text) {
    final units = text.codeUnits;
    for (var i = 0; i < units.length; i++) {
      final u = units[i];
      if (_isHigh(u)) {
        if (i + 1 >= units.length || !_isLow(units[i + 1])) return false;
        i++;
      } else if (_isLow(u)) {
        return false;
      }
    }
    return true;
  }
}

/// Paints the focus and error halo: a ring [width] wide just **outside** the
/// field's box (kit.css `box-shadow: 0 0 0 3px`), so it takes no layout and
/// cannot cover the border. [radius] is the box's corner radius.
final class ZodiannFieldHaloPainter extends CustomPainter {
  /// A halo of [color], [width] px wide, around a box with corner [radius].
  const ZodiannFieldHaloPainter({
    required this.color,
    required this.width,
    required this.radius,
  });

  /// The halo colour (`accent-soft` or `danger-soft`).
  final Color color;

  /// The ring width.
  final double width;

  /// The box's corner radius; the ring's outer radius is this plus [width].
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final inner = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final outer = RRect.fromRectAndRadius(
      (Offset.zero & size).inflate(width),
      Radius.circular(radius + width),
    );
    final ring = Path.combine(
      PathOperation.difference,
      Path()..addRRect(outer),
      Path()..addRRect(inner),
    );
    canvas.drawPath(ring, Paint()..color = color);
  }

  @override
  bool shouldRepaint(ZodiannFieldHaloPainter old) =>
      old.color != color || old.width != width || old.radius != radius;
}
