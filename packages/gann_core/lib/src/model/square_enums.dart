/// The Square of Nine's three modes (SQ-1): numbers, dates, and date and time
/// in hour steps. Serialized as the value's `name`.
enum SquareMode { numbers, dates, datetime }

/// Where the spiral's number 2 sits relative to the center. The spec's fixed
/// choice is [left] (SQ-8); other values exist for the planned setting.
enum SpiralStart { left, right, up, down }

/// Spiral direction. The spec's fixed choice is clockwise, [cw] (SQ-8).
enum SpiralRotation { cw, ccw }
