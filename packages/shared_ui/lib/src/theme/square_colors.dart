import 'package:material_ui/material_ui.dart';

/// The MASTER.md §2.2 "Square of Nine (Appendix D)" colour tokens, one field per token (ARCH-7).
///
/// Values live only in `tokens/` (ZOD-UI-001 fills MASTER's exact values).
/// [tokens] lists them under their exact MASTER names, in MASTER order.
final class SquareColors extends ThemeExtension<SquareColors> {
  const SquareColors({
    required this.axisFill,
    required this.axisInk,
    required this.axis,
    required this.diagFill,
    required this.diagInk,
    required this.diag,
    required this.eighthFill,
    required this.eighthInk,
    required this.cellFill,
    required this.cellInk,
    required this.cellLine,
    required this.center,
    required this.today,
    required this.selOuter,
    required this.selInner,
  });

  /// `axis-fill`.
  final Color axisFill;

  /// `axis-ink`.
  final Color axisInk;

  /// `axis`.
  final Color axis;

  /// `diag-fill`.
  final Color diagFill;

  /// `diag-ink`.
  final Color diagInk;

  /// `diag`.
  final Color diag;

  /// `eighth-fill`.
  final Color eighthFill;

  /// `eighth-ink`.
  final Color eighthInk;

  /// `cell-fill`.
  final Color cellFill;

  /// `cell-ink`.
  final Color cellInk;

  /// `cell-line`.
  final Color cellLine;

  /// `center`.
  final Color center;

  /// `today`.
  final Color today;

  /// `sel-outer`.
  final Color selOuter;

  /// `sel-inner`.
  final Color selInner;

  /// Every colour token under its MASTER name, in MASTER order.
  Map<String, Color> get tokens => {
    'axis-fill': axisFill,
    'axis-ink': axisInk,
    'axis': axis,
    'diag-fill': diagFill,
    'diag-ink': diagInk,
    'diag': diag,
    'eighth-fill': eighthFill,
    'eighth-ink': eighthInk,
    'cell-fill': cellFill,
    'cell-ink': cellInk,
    'cell-line': cellLine,
    'center': center,
    'today': today,
    'sel-outer': selOuter,
    'sel-inner': selInner,
  };

  @override
  SquareColors copyWith({
    Color? axisFill,
    Color? axisInk,
    Color? axis,
    Color? diagFill,
    Color? diagInk,
    Color? diag,
    Color? eighthFill,
    Color? eighthInk,
    Color? cellFill,
    Color? cellInk,
    Color? cellLine,
    Color? center,
    Color? today,
    Color? selOuter,
    Color? selInner,
  }) => SquareColors(
    axisFill: axisFill ?? this.axisFill,
    axisInk: axisInk ?? this.axisInk,
    axis: axis ?? this.axis,
    diagFill: diagFill ?? this.diagFill,
    diagInk: diagInk ?? this.diagInk,
    diag: diag ?? this.diag,
    eighthFill: eighthFill ?? this.eighthFill,
    eighthInk: eighthInk ?? this.eighthInk,
    cellFill: cellFill ?? this.cellFill,
    cellInk: cellInk ?? this.cellInk,
    cellLine: cellLine ?? this.cellLine,
    center: center ?? this.center,
    today: today ?? this.today,
    selOuter: selOuter ?? this.selOuter,
    selInner: selInner ?? this.selInner,
  );

  @override
  SquareColors lerp(covariant SquareColors? other, double t) {
    if (other == null) return this;
    return SquareColors(
      axisFill: Color.lerp(axisFill, other.axisFill, t)!,
      axisInk: Color.lerp(axisInk, other.axisInk, t)!,
      axis: Color.lerp(axis, other.axis, t)!,
      diagFill: Color.lerp(diagFill, other.diagFill, t)!,
      diagInk: Color.lerp(diagInk, other.diagInk, t)!,
      diag: Color.lerp(diag, other.diag, t)!,
      eighthFill: Color.lerp(eighthFill, other.eighthFill, t)!,
      eighthInk: Color.lerp(eighthInk, other.eighthInk, t)!,
      cellFill: Color.lerp(cellFill, other.cellFill, t)!,
      cellInk: Color.lerp(cellInk, other.cellInk, t)!,
      cellLine: Color.lerp(cellLine, other.cellLine, t)!,
      center: Color.lerp(center, other.center, t)!,
      today: Color.lerp(today, other.today, t)!,
      selOuter: Color.lerp(selOuter, other.selOuter, t)!,
      selInner: Color.lerp(selInner, other.selInner, t)!,
    );
  }
}
