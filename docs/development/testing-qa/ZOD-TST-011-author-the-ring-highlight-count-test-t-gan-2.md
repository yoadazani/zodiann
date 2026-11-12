# ZOD-TST-011 - Author the ring highlight-count test (T-GAN-2)

## Metadata

- **ID:** ZOD-TST-011
- **Category:** [Testing & QA](../README.md#testing-qa) (`testing-qa/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Verify the exact blue/yellow/gray counts per ring and the 9×9-square total, against Appendix B's ring table.

## Implementation Details

- Parameterize over rings 1–6 using Appendix B's literal table (cells-in-ring, blue, yellow, gray columns) so the test directly encodes the spec's own reference table rather than a hand-derived expectation.
- Explicitly assert the 9×9 (rings 1–4) total: 16 blue, 16 yellow, 16 gray.

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] Every row of Appendix B's table is individually asserted.
- [ ] The 9×9 total assertion exists as its own named test case.

## Dependencies

- [ZOD-GAN-002](../computation-engine/ZOD-GAN-002-implement-gann-highlight-classification-blue-yellow-gray.md) — Implement Gann highlight classification (blue/yellow/gray)

## Specification References

- T-GAN-2
- Appendix B

## Notes

- 2026-11-12 (product-owner decision): this task owns the dedicated T-GAN-2 verification of the classification implemented in [ZOD-GAN-002](../computation-engine/ZOD-GAN-002-implement-gann-highlight-classification-blue-yellow-gray.md), whose criterion was amended to point here. As with ZOD-TST-002:
  - expected counts come from Appendix B's literal table, never from production helpers;
  - add a mutation proof showing the suite fails if a classification rule or the priority order is altered.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Testing & QA" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
