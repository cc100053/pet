# Handoff: 房間選擇 frame casings (equippable room frames)

## Overview
Redesign of the room selection screen (`room_selection_view.dart`) so each room card is a **frame** the player can equip and swap. One card structure, four interchangeable skins (2 拍立得 polaroid + 2 收藏卡 collectible), plus a 換相框 picker sheet.

## About the Design Files
`Room Select Frames.dc.html` in this bundle is a **design reference built in HTML** — a prototype of intended look and behaviour, not production code. Recreate it in the existing Flutter app using its established widgets and patterns (`JuicyScaleButton`, `AppTheme`, `HomePolaroidMemoryFrame`, `showJuiceToast`, `GoogleFonts.mPlusRounded1c`). Do not port HTML/CSS.

Open the file in a browser. It contains four turns, newest first:
- **turn 4** — the four frame skins (`4a`–`4d`) — this is the spec to build
- **turn 3** — the skins in situ on 房間選擇 (`3a`) and the 換相框 sheet (`3b`)
- **turns 2 and 1** — earlier explorations, kept for context only. Do not build these.

## Fidelity
**High-fidelity.** Colours, borders, radii, sizes and copy are final and taken from the app's own tokens. Match them. The striped areas labelled `照片訊息` are placeholders for the real photo message image — not a texture to reproduce.

## The three invariants (most important part of this handoff)
Every skin obeys these; a new skin that breaks one is wrong:
1. **The photo message zone is untouchable.** Keep `HomePolaroidMemoryFrame`'s photo ratio (~1.72), its 2–2.5px black87 border, and let nothing paint over it — no rarity plate, no sheen, no unread badge, no gradient. The only exception is (2).
2. **The pet overlaps the photo's bottom-right corner only**, sprite roughly 60–66px, hanging ~8–10px past the photo's bottom and right edges, drop shadow `0 3px 4px rgba(0,0,0,.22)`. It reads as the pet standing in the room, not as a badge.
3. **No frame name or rarity text on the card.** The frame identifies itself visually. Names/prices appear only in the 換相框 sheet.

Unread count hangs off the outer rim's top-right corner (`top:-12px; right:-10px` equivalent), never inside the photo.

## Screens / Views

### 1. 房間選擇 (room selection) — see `3a`
- **Purpose**: pick a pet's home and enter it.
- **Layout**: warm cream vertical gradient `#FFFBF3 → #FFF3E2`, 18px horizontal padding. Header row: 42px circular user avatar (2.5px black87 border), title 房間選擇 22px w900, right-aligned 邀請碼 pill (white, 2.5px black87, r999, `0 3px 0` black87 hard shadow). Sub-line 選擇寵物的家並繼續。 13.5px w500 `#7A6F66`, 12px above / 18px below.
- **Grid**: 2 columns, gap 16px row / 14px column. Filled rooms first, then 空位 placeholders (196px tall, 3px dashed `rgba(0,0,0,.28)`, r20, `+` in a 42px r13 dashed square, label 空位 12px w900 `#9A9187`).
- **Card payload (identical in every skin)**: photo zone → pet sprite bottom-right → mat containing name (12.5px w900), `Lv n` (9.5px w900 `#FFB36B` = `AppTheme.secondaryColor`), hunger ring (26px circle, 2.5px border, value 10px w900 in ink `#2F2A23` — never white on the tint), then caption line (10.5px w500 `#7A6F66`, single line, ellipsis).
- **Bottom CTA**: 建立新房間, height 56, r22, `#5FBF9E`, 3px black87, white 16px w900, hard shadow `0 5px 0` black87.
- **Interactions**: tap card → enter room (juicy press: scale .96, keep any skin rotation). Long-press card → open 換相框. CTA press → translateY(5px), shadow to 0.

### 2. 換相框 sheet — see `3b`
- Scrim `rgba(47,42,35,.55)`. Sheet: `#FFFBF3 → #FFF7EA`, 3px black87 top border, r32 top corners, 16px/20px/34px padding, 52×5 grabber `rgba(0,0,0,.2)`.
- Header row: 換相框 18px w900, room name 12px w500 `#7A6F66`, then the **existing** currency pill from `home_game_status_bar.dart` — reuse `_CombinedCurrencyPill` as-is (diamond.png + candy.png at 16px, white .92 / 2px black87 / r999, 13px w800 numbers, `#EE6D85` 16px add button). Do not re-draw it.
- Live preview: the room's card at 190px wide, centred, wearing the currently highlighted skin.
- Swatch grid: 4 per row, gap 12. Each swatch is a 1:1 miniature of the skin's rim (r16, 3px black87, `0 4px 0` black87). States: **使用中** → 3px `#5FBF9E` outline offset 3px + 24px green ✓ badge bottom-right, label ink w900; **擁有** → label 擁有 10px w800 `#7A6F66`; **locked** → opacity .75 + candy icon 13px with price.
- Confirm 完成: height 52, **r16** (dialog/action radius per `memory-bank/ui-ux-guidelines.md`), `#5FBF9E`, 3px black87, `0 5px 0` shadow.
- Build this sheet on the app's existing equip/inventory panel (`home_room_inventory_panel.dart`, `home_furniture_inventory_overlay.dart`) rather than a new sheet: reuse its sheet chrome, grid and selected/owned/locked treatments; this design only specifies the swatch content.

## The four skins (turn 4)

Common: outer rim/mount → white or cream inner card → photo zone → mat.

### 4a 拍立得 · 經典 (`4a`)
- Card: `#fff`, 3px black87, r14, padding 8/8/0, shadow `0 8px 14px rgba(0,0,0,.10)` + `0 5px 0` black87, rotate −1°.
- Washi tape: 60×18 `rgba(95,191,158,.5)`, 2px `rgba(0,0,0,.45)`, r3, rotate −3°, centred, 9px above the card.
- Photo: 2px black87, r6. Mat padding `12px 4px 16px` (deep bottom = polaroid).

### 4b 拍立得 · 軟木板 (`4b`)
- Board background (the screen behind the card, optional): kraft stripes `#DFCBA6/#D8C29A` at 135°.
- Card: `#F1E4CC`, 3px black87, r10, shadow `0 10px 16px rgba(0,0,0,.18)` + `0 5px 0` black87, rotate +1.2°.
- Pushpin: 18px circle `radial-gradient(circle at 34% 30%, #FFF0F0, #E24B4B 60%, #A32A2A)`, 2.5px black87, shadow `0 3px 4px rgba(0,0,0,.3)`, centred, 11px above the card.
- Photo sunk in a white bevel: 5px `#fff` border + 2px black87 outline, r4. Lv colour warms to `#C9803A`; hunger ring `#E08A8A` on `#FFF7EA`.

### 4c 收藏卡 · 金葉 (`4c`)
- Mount: 6px padding, `linear-gradient(150deg,#FFF0C9,#F0B75E 38%,#C98A32 62%,#FFE9B8)`, 3px black87, r18, shadow `0 8px 14px rgba(0,0,0,.14)` + `0 5px 0`.
- Sheen: `linear-gradient(112deg, transparent 36%, rgba(255,255,255,.6) 47%, transparent 58%)` filling the mount, r15, **painted UNDER the inner card** (inner card z above it) so it only lights the rim. Never over the photo.
- Corner ornaments: four 12×12 L-shapes, 3px `rgba(0,0,0,.5)`, 6px outer radius, inset 4px.
- Inner card `#FFFBF3`, 2.5px black87, r12. Lv colour `#C08A2E`.

### 4d 收藏卡 · 夜光 (`4d`)
- Mount: `linear-gradient(150deg,#8FE3C8,#5FBF9E 32%,#6E63C8 78%,#B9AEF2)`, 3px black87, r18, glow `0 0 18px rgba(126,214,183,.45)` + `0 5px 0` black87.
- Inner card `#231F1B`; photo placeholder stripes `#4A4239/#565046`; name `#FFF7EA`, caption `#B9AF9E`, hunger value `#FFF7EA` on a `#FF9A9E` ring, Lv stays `#FFB36B`.
- Pet sprite shadow deepens to `0 3px 6px rgba(0,0,0,.5)`.

## Suggested implementation shape (Flutter)
- `enum RoomFrameStyle { polaroidClassic, corkboard, goldLeaf, nightGlow }` persisted per room (per member, if frames are personal) — new column on `rooms` (or `room_members`) + migration, following the `room_backgrounds` / furniture inventory precedent.
- `class RoomFrameSkin` holding the visual values above: mount decoration, innerCardColor, photoBorder, matPadding, rotation, ornament builder, tape/pin builder, text colours. One `const` instance per enum value in a `room_frame_skins.dart` catalogue.
- One `RoomFrameCard` widget = `HomePolaroidMemoryFrame` generalised to take a `RoomFrameSkin` (it already owns the photo-zone maths, avatar and caption bands). Wrap in `JuicyScaleButton`, `lightImpact` on press / `mediumImpact` on release, fire navigation immediately.
- Unread badge and pet sprite as `Positioned` children in a `Stack(clipBehavior: Clip.none)` around the card — badge on the mount, sprite anchored to the photo's bottom-right.
- Ownership/equip state alongside the existing store items (`items` table, `store_purchase` RPC) so locked skins price in candy.

## Design tokens (all already in `AppTheme`)
| Token | Value |
| --- | --- |
| primary / 使用中 / CTA | `#5FBF9E` |
| secondary / Lv | `#FFB36B` |
| background | `#FFFBF3`, gradient to `#FFF3E2` / `#FFF7EA` |
| ink / textPrimary | `#2F2A23` |
| muted / textSecondary | `#7A6F66` |
| error / unread | `#FF4D4D` |
| add button | `#EE6D85` |
| card border | `Colors.black87`, 2–3px |
| radii | cards 20–22, inner card 12–15, photo 6–10, actions 16, pills 999 |
| hard shadow | `0 4–6px 0 Colors.black87` |
| soft shadow | `0 8–10px 14–18px rgba(0,0,0,.10–.14)` |
| type | `GoogleFonts.mPlusRounded1c`; 22 w900 title, 12.5–13 w900 name, 10.5–11 w500 caption, 9.5–10 w900 numerals |

## Assets
From the repo, copied into this bundle's `assets/` at their original paths — use the originals in the app, not these copies:
- `assets/pet_sequences/{tiger,chicken,cat,fish,ghost}/…-01.png` — idle frames used as stand-ins for the live pet sequence.
- `assets/shop/icon/candy.png`, `assets/shop/icon/diamond.png` — currency icons.
- Room photos are placeholders; the real source is the room's latest photo message.

## Files
- `Room Select Frames.dc.html` — the design (turn 4 = skins, turn 3 = screen + sheet).
- `ios-frame.jsx` — device bezel used by the prototype only; ignore.
- Repo files this was grounded in: `lib/features/home/room_selection_view.dart`, `lib/features/home/widgets/home_polaroid_memory_frame.dart`, `lib/features/home/widgets/home_game_status_bar.dart`, `lib/features/home/widgets/home_room_inventory_panel.dart`, `lib/shared/theme/app_theme.dart`, `lib/shared/ui/app_dialog.dart`, `memory-bank/ui-ux-guidelines.md`.
