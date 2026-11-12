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

- [ ] The spiral position formulas are implemented and covered by GAN-001's own unit tests (cell 2 left of cell 1, clockwise order, Appendix B ring ends, round-trip over 9×9). Dedicated T-GAN-1 verification against explicit expected coordinates is tracked by [ZOD-TST-010](../testing-qa/ZOD-TST-010-author-the-gann-spiral-direction-test-suite-t-gan-1-t-gan-3.md).
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

- 2026-11-12 (product-owner decision, same resolution as ZOD-EPH-001 / ZOD-TST-002): the criterion "T-GAN-1 passes: cell 2 sits left of cell 1, spiral moves clockwise through the first several dozen cells" was amended. T-GAN-1 belongs to ZOD-TST-010, which depends on this task, so the original wording was a cycle. GAN-001 is covered by its own unit tests, and TST-010 provides the dedicated T-GAN-1 suite. The tasks stay separate, with the dependency running GAN-001 → TST-010.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Computation Engine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
