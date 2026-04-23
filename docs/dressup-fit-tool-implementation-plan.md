# Dress-Up Fit Tool Implementation Plan

> Audience: coding agent taking over the next session
> Date: 2026-04-23
> Scope: Admin/debug-only visual tool for tuning pet equipment placement
> Related plan: `docs/dressup-system-implementation.md`
> Required pre-read before implementation: active `memory-bank/*.md` and current files named below

## 1. Goal

Build an admin-only visual fitting tool so a manager can tune each equipment
item against each pet without editing coordinates by hand.

The tool should let the manager:
- Select a pet, equipment item, animation state, and optional facing direction.
- See the pet GIF, socket markers, equipment image, anchor marker, and alignment
  guides in one preview.
- Adjust socket position, item anchor, item size, and optional per-pet fit
  offsets through sliders/steppers.
- Copy a Dart config snippet that can be pasted into `pet_sockets.dart` or
  `equipment_catalog.dart`.
- Avoid writing any production data in Phase 1.

This is primarily an internal production workflow tool. It should be safe,
repeatable, and fast enough to fit many item/pet combinations.

## 2. Current State

Dress-up MVP is already wired:
- Pet sockets: `lib/features/pet/pet_sockets.dart`
- Equipment catalog: `lib/features/pet/equipment_catalog.dart`
- Overlay renderer: `lib/features/home/widgets/pet_equipment_overlay.dart`
- Home debug drawer socket toggle: `lib/features/home/home_view.dart`
- Equipment inventory UI: `lib/features/home/widgets/home_room_inventory_panel.dart`
- Shop item metadata integration: `lib/features/shop/models/shop_item.dart`
- Live backend migration: `supabase/migrations/20260422150216_add_pet_equipment.sql`

Important current design decision:
- Equipment is rendered as widget overlays on top of existing pet GIFs.
- Flutter GIF playback does not expose frame indices, so this tool should tune
  stable normalized coordinates, not per-frame animation anchors.

Current data model:
- `PetSocketCatalog`: pet-level body points such as `head`, `body`, `back`.
- `EquipmentDefinition`: item-level `anchor`, `sizeRatio`, `assetPath`,
  `zOrder`.
- `PetEquipmentOverlay`: computes `position = socket - anchor`.

## 3. Recommended Approach

Implement a **local admin/debug fitting page** first. Do not build a remote
dashboard or Supabase-backed editor in the next session.

Reasoning:
- Source-of-truth should remain code-reviewed Dart config for now.
- No backwards-compatibility risk from remote config/cache behavior.
- The manager needs visual fitting and copyable output more than live mutation.
- It can be shipped only behind existing admin/debug access.

Phase 1 output should be a tool that generates config snippets, not one that
saves to the database.

## 4. Product Workflow

Recommended manager flow:

1. Open Home drawer as admin.
2. Open `Dress-up Fit Tool`.
3. Choose pet:
   - `ghost`
   - `cat`
   - `fish`
   - `tiger`
4. Choose equipment item:
   - initially `equip_straw_hat`
   - future catalog items should appear automatically from `EquipmentCatalog.items`
5. Choose slot:
   - default to the equipment item's `slot`
   - allow previewing another slot only as a debug option if useful
6. Choose state:
   - `idle`
   - `walk`
   - `sleep`
7. Choose facing:
   - right
   - left
8. Adjust values:
   - socket `x`, `y`
   - anchor `x`, `y`
   - item width ratio `w`
   - item height ratio `h`
   - per-pet offset `dx`, `dy`
   - per-pet scale
9. Copy generated Dart snippet.
10. Paste snippet into config files and run tests.

## 5. UI Specification

Create a full-screen page instead of a bottom sheet. The fitting surface needs
space and precise controls.

Suggested route:
- File: `lib/features/home/debug/dress_up_fit_tool_page.dart`
- Opened from the existing admin drawer in `HomeView`.

Layout:
- Header:
  - Title: `Dress-up Fit Tool`
  - Close/back button
  - Short warning: `Preview only. Copy generated config into code.`
- Left/top preview area:
  - Pet GIF at a fixed square size, e.g. `220x220`
  - Equipment overlay
  - Socket marker
  - Equipment anchor marker
  - Center crosshair/grid
  - Optional bounding boxes for pet and item
- Right/bottom controls:
  - Pet dropdown
  - Equipment dropdown
  - State segmented control
  - Facing segmented control
  - Layer toggle: front/behind visual check
  - Numeric controls/sliders
  - Reset buttons
  - Copy buttons

Mobile-friendly layout:
- Use a `LayoutBuilder`.
- Wide screens: preview left, controls right.
- Compact screens: preview top, controls scroll below.

Interaction requirements:
- Use `JuicyScaleButton` for clickable controls.
- Sliders can be native Flutter sliders, but step buttons should use
  `JuicyScaleButton`.
- All updates should be immediate local state updates.
- No async work in build.
- No Supabase write in Phase 1.

## 6. Preview Details

The preview should render using the same math as production. Avoid duplicating
alignment formulas in a way that can drift.

Recommended implementation:
- Extract a small pure helper from `PetEquipmentOverlay`:
  - file: `lib/features/home/widgets/pet_equipment_layout.dart`
  - function: `resolveEquipmentPlacement(...)`
- Reuse this helper in both:
  - `PetEquipmentOverlay`
  - `DressUpFitToolPage`

Suggested helper shape:

```dart
class EquipmentPlacement {
  const EquipmentPlacement({
    required this.itemSize,
    required this.socketOffset,
    required this.anchorOffset,
    required this.topLeft,
  });

  final Size itemSize;
  final Offset socketOffset;
  final Offset anchorOffset;
  final Offset topLeft;
}

EquipmentPlacement resolveEquipmentPlacement({
  required Size petSize,
  required PetSocket socket,
  required EquipmentAnchor anchor,
  required EquipmentSize sizeRatio,
  Offset normalizedOffset = Offset.zero,
  double scale = 1,
});
```

The tool can pass local draft values into this helper and display:
- socket marker at `socketOffset`
- anchor marker at `topLeft + anchorOffset`
- equipment image at `topLeft`
- item bounding rectangle at `topLeft & itemSize`

## 7. Data Model Additions

Phase 1 can be local-only, but structure the code so future per-pet overrides
are clean.

Recommended additions to `equipment_catalog.dart`:

```dart
class EquipmentFitOverride {
  const EquipmentFitOverride({
    this.offset = Offset.zero,
    this.scale = 1,
  });

  final Offset offset; // normalized against pet size
  final double scale;
}
```

Extend `EquipmentDefinition`:

```dart
final Map<String, EquipmentFitOverride> petOverrides;
```

Use case:
- If all hats are wrong on a pet, tune `PetSocketCatalog`.
- If one item is wrong on every pet, tune `EquipmentDefinition.anchor` or
  `sizeRatio`.
- If one item is only wrong on one pet, tune `petOverrides[petId]`.

Do not add rotation in the first implementation unless there is a real visual
need. Rotation complicates hit testing, generated snippets, and tests.

## 8. Draft State Model

Inside the fitting page, keep one mutable draft object in widget state.

Suggested shape:

```dart
class DressUpFitDraft {
  const DressUpFitDraft({
    required this.petId,
    required this.equipmentSku,
    required this.slot,
    required this.state,
    required this.facingRight,
    required this.socket,
    required this.anchor,
    required this.sizeRatio,
    required this.overrideOffset,
    required this.overrideScale,
  });

  final String petId;
  final String equipmentSku;
  final String slot;
  final DressUpFitAnimationState state;
  final bool facingRight;
  final PetSocket socket;
  final EquipmentAnchor anchor;
  final EquipmentSize sizeRatio;
  final Offset overrideOffset;
  final double overrideScale;
}
```

Use `copyWith` to keep updates predictable.

State reset behavior:
- Changing pet resets socket to the catalog value for that pet/slot/state.
- Changing equipment resets anchor/size to that equipment definition.
- Changing state resolves the matching socket override if present.
- `Reset socket` restores socket from `PetSocketCatalog`.
- `Reset item` restores anchor/size from `EquipmentCatalog`.
- `Reset override` restores offset `0,0` and scale `1`.

## 9. Generated Output

The page should generate three snippets:

### 9.1 Pet Socket Snippet

Use when a body socket is globally wrong for that pet.

```dart
PetEquipmentSlot.head: PetSocket(x: 0.50, y: 0.23),
```

If state is `walk`:

```dart
walkOverrides: {
  PetEquipmentSlot.head: PetSocket(x: 0.50, y: 0.24),
},
```

If state is `sleep`:

```dart
sleepOverrides: {
  PetEquipmentSlot.head: PetSocket(x: 0.50, y: 0.28),
},
```

### 9.2 Equipment Definition Snippet

Use when item-level anchor or size is wrong globally.

```dart
anchor: EquipmentAnchor(x: 0.52, y: 0.78),
sizeRatio: EquipmentSize(w: 0.66, h: 0.34),
```

### 9.3 Per-Pet Override Snippet

Use when this item only needs tuning on one pet.

```dart
petOverrides: {
  'fish': EquipmentFitOverride(
    offset: Offset(-0.03, 0.02),
    scale: 0.85,
  ),
},
```

Copy behavior:
- Use `Clipboard.setData`.
- Show non-blocking success via `showJuiceSnackbar`.
- Include enough context in the displayed text so the manager knows which file
  to edit.

## 10. Admin Access And Entry Point

Add a debug drawer entry under the existing Pet debug section:

```dart
ListTile(
  title: Text(l10n.drawerDebugDressUpFitTool),
  onTap: () {
    Navigator.pop(context);
    Navigator.of(context).push(...DressUpFitToolPage...);
  },
)
```

Access control:
- Only render this item when `_isDebugAdmin` is true.
- Do not expose it to normal users.
- The page itself should still be harmless if reached directly because it makes
  no backend writes.

Localization:
- Add only minimal strings if needed.
- English/Japanese/Chinese ARB files are active.
- Run `flutter gen-l10n` after ARB edits.
- Existing `ko` and `zh_TW` untranslated warnings are known; do not fix them
  unless requested.

## 11. Implementation Phases

### Phase 1: Pure Layout Helper

Files:
- Add `lib/features/home/widgets/pet_equipment_layout.dart`
- Update `pet_equipment_overlay.dart` to call the helper.

Tests:
- Add `test/features/home/widgets/pet_equipment_layout_test.dart`
- Cover:
  - top-left formula
  - normalized offset
  - scale
  - anchor calculation

Acceptance:
- Existing overlay tests still pass.
- No behavior change in Home.

### Phase 2: Fit Tool Page

Files:
- Add `lib/features/home/debug/dress_up_fit_tool_page.dart`

Implement:
- Pet/equipment/state/facing selectors.
- Preview with markers and bounding boxes.
- Sliders/steppers for socket, anchor, size, override offset, override scale.
- Reset buttons.
- Generated snippet display.
- Copy buttons.

Acceptance:
- Manager can fit `equip_straw_hat` on `ghost`, `cat`, `fish`, and `tiger`
  without editing code during preview.
- Tool works in compact and wide layouts.

### Phase 3: Admin Drawer Entry

Files:
- Update `lib/features/home/home_view.dart`
- Update ARB files and generated `app_localizations*` files.

Acceptance:
- Entry appears only for debug admin.
- Tapping entry opens the fit tool.

### Phase 4: Per-Pet Override Support

Files:
- Update `lib/features/pet/equipment_catalog.dart`
- Update `pet_equipment_layout.dart`
- Update `pet_equipment_overlay.dart`
- Update tests.

Implement:
- `EquipmentFitOverride`
- `petOverrides` on `EquipmentDefinition`
- Overlay applies override by current `petId`.

Acceptance:
- Production overlay and fit tool use identical override math.
- Existing straw hat still renders identically when no override is set.

### Phase 5: Polish And Documentation

Files:
- Update this doc with actual decisions if they differ.
- Update active `memory-bank/*.md` only if behavior or current architecture
  changes.
- Update `tasks/todo.md` review section.

Acceptance:
- Handoff docs remain current and compact.

## 12. Test Plan

Required focused tests:
- `pet_equipment_layout_test.dart`
  - formula correctness
  - offset/scale math
- `pet_equipment_overlay_test.dart`
  - still renders z-order and markers correctly after helper extraction
  - applies per-pet override if Phase 4 is implemented
- `dress_up_fit_tool_page_test.dart`
  - shows selectors
  - changing slider updates generated snippet
  - reset restores catalog value
  - copy button calls clipboard path or shows expected copied UI
- Existing:
  - `home_room_inventory_panel_test.dart`
  - `equipment_catalog_test.dart`
  - `pet_socket_config_test.dart`

Required commands:

```sh
dart format lib test
flutter gen-l10n # only if ARB files change
flutter analyze
flutter test
```

Optional asset verification if adding new equipment folders:

```sh
flutter build bundle
```

## 13. Non-Goals For Next Session

Do not implement these in the next session unless explicitly requested:
- Supabase-backed remote fit editor.
- Uploading equipment images from the admin tool.
- Per-frame animation socket editing.
- Rotation/skew controls.
- Public user-facing dress-up editor changes beyond what already exists.
- App Store metadata/release-note updates.

## 14. Future Phase: Real Admin Dashboard

Only consider a remote admin dashboard after the local tool proves the workflow.

Possible backend model:

```sql
equipment_fit_overrides (
  id uuid primary key,
  equipment_sku text not null,
  pet_id text not null,
  slot text not null,
  offset_x double precision not null default 0,
  offset_y double precision not null default 0,
  scale double precision not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  updated_by uuid
)
```

Risks:
- Old-client compatibility and caching behavior.
- Review/audit/rollback requirements.
- Remote config load failures causing visual drift.
- More surface area for RLS/admin-only authorization bugs.

Recommendation:
- Keep Phase 1 code-driven.
- Only move to remote saves once there are many assets and multiple non-coding
  operators tuning them regularly.

## 15. Handoff Checklist For Next Agent

Before editing:
- Read all active `memory-bank/*.md`.
- Inspect:
  - `lib/features/pet/pet_sockets.dart`
  - `lib/features/pet/equipment_catalog.dart`
  - `lib/features/home/widgets/pet_equipment_overlay.dart`
  - `lib/features/home/home_view.dart`
  - `test/features/home/widgets/pet_equipment_overlay_test.dart`
- Confirm current git status and avoid reverting user changes.

During implementation:
- Keep changes local/admin-only.
- Extract shared math before building UI.
- Reuse Juice UI interactions.
- Keep generated snippets deterministic and easy to paste.

Before finishing:
- Run focused tests first.
- Run `flutter analyze`.
- Run `flutter test`.
- Update `tasks/todo.md` review notes.
- Update memory bank only if behavior/current architecture changed.

