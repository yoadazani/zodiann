import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/tokens/zodiann_dimensions.dart';
import '../theme/zodiann_surfaces.dart';
import '../theme/zodiann_text_styles.dart';
import 'zodiann_pressable.dart';

/// How many decimal places [x] is written with (`0.25` is 2, `3.0` is 0).
int _decimals(double x) {
  final s = x.toString();
  if (s.contains('e') || s.contains('E')) return 10;
  final dot = s.indexOf('.');
  if (dot < 0) return 0;
  final frac = s.substring(dot + 1);
  return frac == '0' ? 0 : frac.length;
}

/// The value one [step] from [value] in [direction] (+1 or -1), or null when
/// that button has nowhere to go.
///
/// A [value] outside `[min, max]` counts as the nearest bound, so a stale
/// value never lets a button step past a bound. The sum is rounded to the
/// decimals of [step] and [value] first, so 0.1 steps do not drift.
@visibleForTesting
double? orbStepperNext({
  required double value,
  required double step,
  required double min,
  required double max,
  required int direction,
}) {
  final v = value.clamp(min, max);
  if (direction > 0 ? v >= max : v <= min) return null;
  final places = math.max(_decimals(step), _decimals(v));
  final raw = double.parse((v + direction * step).toStringAsFixed(places));
  return raw.clamp(min, max);
}

/// The orb stepper (MASTER.md §10 "Others"; kit.css `.stepper`): a 36 high
/// box with a 1 px `line` border, radius 8 and a `bg-raised` fill, holding
/// `− value +`: two 34 wide buttons (18 px glyphs in `text-2`) around the
/// value (at least 52 wide, centred, weight 500, tabular figures).
///
/// The control knows nothing about orbs: the caller supplies the bounds
/// ([min], [max], the aspect-orb limits are ZOD-ASP-002's), the [step] and
/// the formatted, localized [valueLabel] (for example "±8°"). A bound makes
/// its own button inert (42 % opacity, not focusable); [onChanged] receives
/// the next value, and is never called at a bound or by a rebuild.
///
/// Layout is 44 high with the 36 box centred, and each button is a 44 × 44
/// slot placed against its outer end (`ZodiannPressable.slotAlignment`), so
/// the glyphs sit where the kit draws them and the slots overlap only the
/// inert value area. The buttons' focus rings surround the 34 × 34 button
/// areas and paint over the border and the value; the control never clips.
///
/// The row follows the reading direction (the minus button is on the start
/// side: on the right in Hebrew); the value stays left to right (L-7).
/// The group is one semantics node with [semanticLabel] and the value, with
/// the two buttons beneath it and increase / decrease actions.
class ZodiannOrbStepper extends StatelessWidget {
  /// A stepper showing [valueLabel] for [value].
  ZodiannOrbStepper({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.valueLabel,
    required this.decrementLabel,
    required this.incrementLabel,
    this.step = 1,
    this.semanticLabel,
    this.valueLabelFor,
  }) : assert(min < max, 'min must be below max'),
       assert(value >= min && value <= max, 'value must be within min..max'),
       assert(step > 0, 'step must be positive'),
       assert(valueLabel.trim().isNotEmpty, 'valueLabel must not be blank'),
       assert(
         decrementLabel.trim().isNotEmpty && incrementLabel.trim().isNotEmpty,
         'the button labels must not be blank',
       );

  /// The current value.
  final double value;

  /// The least value (the minus button is inert there).
  final double min;

  /// The greatest value (the plus button is inert there).
  final double max;

  /// The size of one step (default 1).
  final double step;

  /// Called with the next value; null disables both buttons.
  final ValueChanged<double>? onChanged;

  /// The value as text, localized and formatted by the caller ("±8°").
  final String valueLabel;

  /// The accessible name of the − button.
  final String decrementLabel;

  /// The accessible name of the + button.
  final String incrementLabel;

  /// The accessible name of the whole control (for example the aspect).
  final String? semanticLabel;

  /// The label of any value, for example `(v) => '±${v.round()}°'`. Flutter
  /// requires the next and previous value as text to announce an increase or
  /// decrease action, so the group offers those actions to a screen reader
  /// only when this is given (the two buttons always work).
  final String Function(double value)? valueLabelFor;

  /// The minus and plus glyphs (not user copy: the kit's `−` and `+`).
  static const String _minus = '−';
  static const String _plus = '+';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.extension<ZodiannSurfaces>()!;
    final styles = theme.extension<ZodiannTextStyles>()!;
    final callback = onChanged;

    double? next(int direction) => orbStepperNext(
      value: value,
      step: step,
      min: min,
      max: max,
      direction: direction,
    );
    final down = callback == null ? null : next(-1);
    final up = callback == null ? null : next(1);

    Widget button({
      required Key areaKey,
      required String label,
      required String glyph,
      required double? target,
      required AlignmentGeometry alignment,
    }) => ZodiannPressable(
      onPressed: target == null ? null : () => callback!(target),
      semanticLabel: label,
      slotAlignment: alignment,
      child: SizedBox(
        key: areaKey,
        width: ZodiannSize.stepperButtonWidth,
        height: ZodiannSize.stepper - 2 * ZodiannSize.hairline,
        child: Center(
          child: Text(
            glyph,
            style: styles.body.copyWith(
              fontSize: ZodiannSize.stepperGlyph,
              color: s.text2,
            ),
          ),
        ),
      ),
    );

    const inset = (ZodiannSize.minTouchTarget - ZodiannSize.stepper) / 2;
    const buttonArea = SizedBox(width: ZodiannSize.stepperButtonWidth);

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      value: valueLabel,
      onIncrease: up == null || valueLabelFor == null
          ? null
          : () => callback!(up),
      increasedValue: up == null ? null : valueLabelFor?.call(up),
      onDecrease: down == null || valueLabelFor == null
          ? null
          : () => callback!(down),
      decreasedValue: down == null ? null : valueLabelFor?.call(down),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: inset),
            child: DecoratedBox(
              key: const ValueKey('zodiann-stepper-box'),
              decoration: BoxDecoration(
                color: s.bgRaised,
                borderRadius: ZodiannRadius.control,
                border: Border.all(color: s.line, width: ZodiannSize.hairline),
              ),
              child: Padding(
                padding: const EdgeInsets.all(ZodiannSize.hairline),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: ZodiannSize.stepper - 2 * ZodiannSize.hairline,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      buttonArea,
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: ZodiannSize.stepperValueMinWidth,
                        ),
                        child: Center(
                          heightFactor: 1,
                          // Numbers read left to right in both languages.
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: ExcludeSemantics(
                              child: Text(
                                valueLabel,
                                key: const ValueKey('zodiann-stepper-value'),
                                maxLines: 1,
                                softWrap: false,
                                textAlign: TextAlign.center,
                                style: styles.body.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: s.text,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      buttonArea,
                    ],
                  ),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            start: ZodiannSize.hairline,
            top: 0,
            bottom: 0,
            child: button(
              areaKey: const ValueKey('zodiann-stepper-minus-area'),
              label: decrementLabel,
              glyph: _minus,
              target: down,
              alignment: AlignmentDirectional.centerStart,
            ),
          ),
          PositionedDirectional(
            end: ZodiannSize.hairline,
            top: 0,
            bottom: 0,
            child: button(
              areaKey: const ValueKey('zodiann-stepper-plus-area'),
              label: incrementLabel,
              glyph: _plus,
              target: up,
              alignment: AlignmentDirectional.centerEnd,
            ),
          ),
        ],
      ),
    );
  }
}
