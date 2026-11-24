# ZOD-IOS-006 - Decide and implement native iOS selection handles, and verify text input on iOS

## Metadata

- **ID:** ZOD-IOS-006
- **Category:** iOS (`ios/tasks/`)
- **Parent task:** [ZOD-UI-005](../../shared-ui-design-system/ZOD-UI-005-implement-the-input-field-component.md) (iOS selection handles and device checks)
- **Phase:** Phase 1
- **Priority:** Medium
- **Status:** Not Started (an owner decision is open; the device checks are blocked on macOS)
- **Scope:** MVP

## Description

`ZodiannTextField` draws Material's round selection handles on iOS, because Cupertino's native handles need `cupertino_ui` as a direct dependency of `shared_ui` (it is only transitive through `material_ui`). Whether that dependency is allowed is an open owner decision. This task records the decision, implements it, and runs the iOS-only text-input checks.

## Implementation Details

Moved from ZOD-UI-005 ("Not covered" and the open owner decision):

- **Owner decision (open):** may `shared_ui` depend directly on `cupertino_ui` so the field can use `cupertinoTextSelectionHandleControls`?
  - If yes: use Cupertino-native handles on iOS (test-first where a widget test can show the handle controls in use) and update the licensing inventory for the new direct dependency.
  - If no: record that iOS keeps Material's round handles, with the reason, and close the item.
- Device checks on iOS that no device was authorized for: touch typing, the selection toolbar in English and Hebrew, and the soft-keyboard types.

## Design Reference

`design-reference/zodiann/components/components_{dark,light}.png` (input field). The handle shape is not part of the design reference.

## Acceptance Criteria

- [ ] The owner has decided whether iOS uses Cupertino-native or Material round selection handles, and the decision is recorded in `docs/PROGRESS.md` Technical Decisions. *(Open owner item of ZOD-UI-005.)*
- [ ] On iOS, touch typing, the selection toolbar (English and Hebrew) and the soft-keyboard types work in `ZodiannTextField`. *(ZOD-UI-005 "Not covered", iOS device check.)*

## Dependencies

- [ZOD-UI-005](../../shared-ui-design-system/ZOD-UI-005-implement-the-input-field-component.md) — Android and host half (Done)
- [ZOD-IOS-002](ZOD-IOS-002-verify-the-app-shell-build-and-runtime-on-ios.md) — needs a working iOS build (for the device checks, not for the decision)

## Specification References

- MASTER.md §10 (Inputs)

## Notes

- The decision can be taken on Windows; the implementation's device check cannot.
- ZOD-UI-005's other "Not covered" items (the Body select, validation messages, the Android device check and the screen-reader announcement of the error) are not iOS-specific and stay with it or with their owners.

---

*Part of the [Zodiann development task breakdown](../../TASKS.md). iOS-specific tasks live in `docs/development/ios/tasks/`; see [`../../README.md`](../../README.md) and the iOS section of [`../../TASKS.md`](../../TASKS.md).*
