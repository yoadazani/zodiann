# ZOD-GAN-001 - Implement the Gann spiral position formulas (k, j, i, θ)

## Metadata

- **ID:** ZOD-GAN-001
- **Category:** [Computation Engine](../README.md#computation-engine) (`computation-engine/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Implement the pure math at the heart of the Square of Nine: given a cell number `n`, derive its ring, index within ring, and angle.

## Implementation Details

- `k = ceil((sqrt(n) - 1) / 2)`, `j = n - (2k-1)^2 - 1`, `i = (j - (k-1)) mod 8k`, `θ = 45° · i / k`.
- `n = 1` is the center: ring 0, no angle.
- `i` is the number of steps clockwise from the axis where 2 sits.
- Also implement the inverse mapping, (x, y) relative to center: from `j`, compute `(k, j−k+1)` when `j < 2k`; `(3k−1−j, k)` when `j < 4k`; `(−k, 5k−1−j)` when `j < 6k`; else `(j−7k+1, −k)`; then flip both signs `(x, y) ← (−x, −y)` so 2 sits left of 1 and the spiral runs clockwise.
- Ring side length up to ring k: `2k+1`; last number in ring k: `(2k+1)²`.

## Design Reference

No direct design reference applies — pure computation; verified visually against `design-reference/zodiann/screens/02-square-of-nine_numbers_desktop_en_dark.png` only insofar as the resulting *values* must match what's rendered there once [ZOD-SQR-001](../gann-square/ZOD-SQR-001-build-the-mode-switcher-with-state-preservation.md) consumes this.

## Acceptance Criteria

- [ ] T-GAN-1 passes: cell 2 sits left of cell 1, spiral moves clockwise through the first several dozen cells.
- [ ] Ring 1 has last number 9, ring 4 has last number 81 (Appendix B).
- [ ] The (x, y) inverse mapping round-trips with the forward `n → (k, j, i)` mapping for every cell in a 9×9 square.

## Dependencies

- [ZOD-FND-001](../foundations-architecture/ZOD-FND-001-set-up-the-melos-monorepo-workspace.md) — Set up the Melos monorepo workspace

## Specification References

- "Gann spiral" (full formula block)
- SQ-8
- SQ-9
- Appendix B
- T-GAN-1

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Computation Engine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
