# PetTomo Codebase Refactoring Analysis

## Overview

This analysis identifies refactoring opportunities across the PetTomo codebase, focusing on oversized files, extractable components, and changes that would meaningfully improve long-term maintainability.

---

## 🔴 Critical: Giant Files

| File | Lines | Methods | Size |
|------|-------|---------|------|
| [home_view.dart](file:///Users/fatboy/pet/lib/features/home/home_view.dart) | **6,692** | **206** | 207 KB |
| [store_view.dart](file:///Users/fatboy/pet/lib/features/store/store_view.dart) | **2,572** | **55** | 80 KB |
| [chat_room_view.dart](file:///Users/fatboy/pet/lib/features/chat/chat_room_view.dart) | **1,788** | **62** | 56 KB |
| [memory_calendar_view.dart](file:///Users/fatboy/pet/lib/features/gallery/memory_calendar_view.dart) | **1,513** | **56** | 48 KB |
| [room_selection_view.dart](file:///Users/fatboy/pet/lib/features/home/room_selection_view.dart) | **1,185** | **32** | 40 KB |
| [home_game_status_bar.dart](file:///Users/fatboy/pet/lib/features/home/widgets/home_game_status_bar.dart) | **967** | **29** | 33 KB |

> [!CAUTION]
> `home_view.dart` at **6,692 lines** is an extreme outlier. It contains pet movement, room management, feed orchestration, unread messaging, debug tools, currency handling, departure flow, poop spawning, invite codes, and the entire `build()` tree in a single `_HomeViewState`. This is the #1 refactoring priority.

---

## 1. `home_view.dart` — Proposed Extraction Map

`_HomeViewState` has **206 methods** spanning at least **10 distinct responsibility domains**. Each should become its own file or service:

### 1A. Pet Movement Controller → `home_pet_movement.dart`
**~20 methods, ~350 lines**

Methods: `_startWanderTimer`, `_maybeTriggerWander`, `_startPetMove`, `_animatePetTo`, `_animatePetToAndWait`, `_handlePetFieldTap`, `_handlePetDragStart/Update/End/Cancel`, `_updateFacing`, `_petFieldSize`, `_currentPetNormalized`, `_positionFromNormalized`, `_normalizedFromTopLeft`, `_clampTopLeft`, `_clampNormalized`, `_durationForDistance`, `_durationForFoodApproach`, `_selectNextPetStationaryState`, `_sleepProbabilityForLocalHour`

> Extract to a `PetMovementController` mixin or standalone class that manages wander timers, move animations, drag gestures, and sleep/wake state selection.

### 1B. Pet State Service → `home_pet_state_service.dart`
**~15 methods, ~400 lines**

Methods: `_fetchPetState`, `_cachePetState`, `_applyPetStateUpdate`, `_refreshPetState`, `_subscribeToPetState`, `_applyPetAction`, `_tickPetState`, `_tickPetStateAndDispatchAlerts`, `_startPetTickTimer`, `_loadPetId`, `_loadPetInfo`, `_updatePetType`, `_precachePetAssets`, `_healthValue`

> Extract to a service/controller that owns the realtime pet-state subscription, tick timer, and state application logic.

### 1C. Feed Orchestration → `home_feed_orchestrator.dart`
**~12 methods, ~400 lines**

Methods: `_openFeedCamera`, `_handleOptimisticFeed`, `_handleFeedUploadCompleted`, `_handleFeedUploadFailed`, `_playFeedSequence`, `_pickFoodPlacement`, `_maybePromptFeedDoubleReward`, `_shouldOfferFeedDoubleReward`, `_showFeedDoubleRewardToast`, `_applyCoinRewardFeedback`, `_refreshLatestFeed`, `_refreshLatestRoomPhoto`, `_prependLatestFeedItem`

> Extract to a controller that handles the full feed lifecycle (camera → optimistic UI → upload → food animation → reward).

### 1D. Unread/Badge Manager → `home_unread_manager.dart`
**~12 methods, ~250 lines**

Methods: `_syncMessageSubscriptions`, `_roomUnreadCount`, `_roomHasUnread`, `_totalUnreadCount`, `_syncAppIconBadge`, `_syncAppIconBadgeWithRetry`, `_scheduleUnreadReconcile`, `_reconcileUnreadStateFromServer`, `_markRoomAsRead`, `_markRoomAsReadOnServer`, `_incrementRoomUnreadCount`, `_handleMessageInsert`, `_handleSystemMessageInsert`

> Extract to a standalone service—doesn't need UI context at all. Pure data + badge side-effects.

### 1E. Room Management → `home_room_manager.dart`
**~15 methods, ~500 lines**

Methods: `_fetchRooms`, `_applyLegacyRoomLocking`, `_isRoomLocked`, `_switchRoom`, `_enterRoomFromSelection`, `_createRoom`, `_applyPetSelection`, `_applyInitialPetName`, `_promptRoomCreationDetails`, `_joinRoomByCode`, `_confirmLeaveRoom`, `_leaveRoom`, `_fetchRoomPetSummaries`, `_fetchRoomLatestFeeds`, `_fetchRoomMemberCounts`, `_fetchRoomUnreadCounts`, `_memberCountForRoom`, `_legacyRoomSortTimestamp`

> Extract to a controller that handles multi-room lifecycle, switching, creation, joining, and leaving.

### 1F. Invite Code Flow → `home_invite_flow.dart`
**~5 methods, ~300 lines**

Methods: `_extractInviteCode`, `_showInviteCodeDialog`, `_showInviteCopiedPremiumPopup`, `_generateInviteCode`, `_showRoomLockedDialog`

> The invite premium popup alone is 150 lines of UI code. Extract to its own widget/flow file.

### 1G. Pet Departure Flow → `home_departure_flow.dart`
**~8 methods, ~200 lines**

Methods: `_handlePetDepartureState`, `_showPetDepartureFlow`, `_openStoreWithDepartures`, `_returnDepartedPet`, `_isRoomLikelyDeparted`, `_currentDepartedPetInfo`, `_departedPetsList`, `_departureHeroTag`

### 1H. Hunger Alerts → `home_hunger_alerts.dart`
**~5 methods, ~100 lines**

Methods: `_parseHungerAlertSystemBody`, `_showHungerAlertSnackBar`, `_dispatchNewHungerAlerts`, `_sendHungerAlertPush`, `_parseOptionalDate`

### 1I. Currency / Coins → `home_currency_controller.dart`
**~5 methods, ~150 lines**

Methods: `_loadCoins`, `_debugUpdateProfileBalances`, `_extractRewardAmount`, `_refreshProPlanStatus`, `_setDebugProPlan`

### 1J. Debug Tools → `home_debug_tools.dart`
**~5 methods, ~200 lines**

Methods: `_runFeedTest`, `_debugAdjustPetHunger`, `_debugAddPetExp`, `_debugSpawnPetPoop`, `_debugShowOverfedBubble`

### 1K. Overfed Bubble → part of feed orchestrator
Methods: `_handleOverfedState`, `_armOverfedBubbleForFeedEvent`

### 1L. `build()` method
The `build()` method itself (lines ~4600–6692) is roughly **2,000 lines**. It should be broken into composable widgets:
- Pet field area → `HomePetField` widget
- Background / room rendering → `HomeRoomBackground` widget
- Poop overlay → `HomPoopOverlay` widget
- Overfed bubble → `HomeOverfedBubble` widget
- Locked room overlay → `HomeLockedOverlay` widget
- Departure letter hero → `HomeDepartureHero` widget
- Ad banner slot → already exists as widget

---

## 2. `store_view.dart` — Proposed Extractions

### 2A. `StoreItem` model → `store_item.dart`
**~250 lines** — The `StoreItem` class (lines 2222–2468) with localization and pricing logic should be its own model file.

### 2B. IAP Purchase Logic → `store_iap_service.dart`
**~400 lines** — Methods: `_loadIap`, `_extractPackagesByProductId`, `_findPackageByProductId`, `_findStoreProductByProductId`, `_purchaseIapItem`, `_grantIapCoins`, `_grantIapDiamonds`, `_restorePurchases`

### 2C. Item Purchase Logic → `store_purchase_handler.dart`
**~400 lines** — Methods: `_purchaseItem`, `_purchaseDiamondItem`, `_purchaseBackgroundWithCoins`, `_purchaseBackgroundWithDiamonds`, `_ensureCurrencyPurchasable`, `_canAfford`, `_handleLetterPurchase`, `_consumePurchasedItem`

### 2D. UI Card Widgets → `widgets/store_item_card.dart`, `widgets/store_iap_card.dart`, `widgets/store_theme_card.dart`
**~600 lines** — `_buildStoreItemCard`, `_buildThemeItemCard`, `_buildIapCard`, `_buildIapActionButton`, `_buildIapButtonLabel`, `_openThemePreview` are all self-contained widget-building methods.

### 2E. Departed Pet Selector → `widgets/store_departed_pet_selector.dart`
**~100 lines** — `_selectDepartedPet`, `_confirmLetterPurchase`, `_showNoDepartedPetsDialog`

---

## 3. `chat_room_view.dart` — Proposed Extractions

### 3A. `ChatMessageList` → `chat_message_list.dart`
**~900 lines** — `ChatMessageList` + `ChatMessageListState` is an independent widget with its own state, caching, pagination, realtime subscription, block handling, and reporting. It should absolutely be its own file.

### 3B. Chat Widgets Already Inline → extract to `widgets/`
- `_ChatTopBar` (~100 lines)
- `_ChatMenuAvatar` (~30 lines)
- `_GlassPill` (~50 lines) — reusable, could go to `shared/ui/`
- `_DateSeparator` (~50 lines)
- `_ChatLoadingList` (~45 lines)

---

## 4. `memory_calendar_view.dart` — Proposed Extractions

### 4A. Calendar Widgets → `widgets/`
Multiple private widget classes are already well-separated internally but should be moved to files:
- `_CalendarHeader` → `calendar_header.dart`
- `_WeekdayStrip` → `calendar_weekday_strip.dart`
- `_MonthNavigator` → `calendar_month_navigator.dart`
- `_MonthCalendarCard` → `calendar_month_card.dart`
- `_MonthDayCell` → `calendar_day_cell.dart`
- `_DayBubble` → `calendar_day_bubble.dart`

### 4B. `MemoryFeed` model
The data model and data-fetching logic (`_loadMonth`, `_loadLatestFeed`, `_loadSenderProfiles`, `_loadBlockedUsers`) should be extracted to a calendar data service.

---

## 5. Cross-Cutting Service Concerns

### 5A. Profile Cache / Sender Resolution
`_ensureProfileSummary` in `home_view.dart` and `_ensureProfilesForMessages` / `_loadSenderProfiles` in chat + calendar all independently implement the same "fetch and cache user profiles" pattern.

> **Extract to:** `lib/services/profile/profile_cache_service.dart` — a shared, singleton profile cache that all features can query.

### 5B. Supabase Query Helpers
Multiple files independently construct Supabase queries with similar select/filter/order patterns for `messages`, `room_members`, `pets`, and `profiles`.

> **Extract to:** A thin repository pattern per table (e.g., `lib/services/room/room_repository.dart`, `lib/services/message/message_repository.dart`).

### 5C. Offline / Network Helpers
`_withNetworkTimeout`, `_showOfflineSnackBar`, `_ensureOnlineForWrite` in `home_view.dart` are general-purpose utilities.

> **Extract to:** `lib/shared/utils/network_helpers.dart`

### 5D. Repeated Currency Presentation
`_diamondColor`, candy SVG icon paths, and currency formatting logic are duplicated between `store_view.dart` and `home_game_status_bar.dart`.

> **Extract to:** `lib/shared/ui/currency_widgets.dart` — reusable `CandyIcon`, `DiamondIcon`, `CurrencyBuyButton`, `CurrencyBalanceChip`.

---

## 6. Architectural Improvements

### 6A. State Management: `setState` → Riverpod Providers
`_HomeViewState` holds **~50+ `setState` fields** (coins, diamonds, pet position, rooms list, unread counts, locked rooms, departure info, overfed timer, etc.). This makes the widget impossibly hard to reason about.

> **Migrate to Riverpod providers.** For example:
> - `roomsProvider` — list of rooms + lock status
> - `currentRoomProvider` — selected room state
> - `petStateProvider(roomId)` — per-room pet state
> - `unreadCountProvider(roomId)` — per-room unread
> - `currencyProvider` — candy/diamond balances
> 
> This eliminates the 6,692-line stateful widget and replaces it with composable, testable providers.

### 6B. `build()` Methods as Widget Trees
Several `build()` methods are hundreds of lines of inline widget trees (e.g., `_ChatRoomViewState.build` is 220 lines, `_StoreViewState._buildBody` is 125 lines). Break these into smaller `StatelessWidget` components.

### 6C. Model Classes in View Files
`StoreItem` (store_view.dart), `ChatMessage` (chat_message.dart — this one is already separate ✓), `FeedOptimisticMessage` / `FeedUploadResult` (feed_capture_view.dart), and `MemoryFeed` should all live in dedicated model files under `lib/models/`.

---

## 7. Maintainability Impact Summary

| Refactoring | Effort | Impact | Why |
|-------------|--------|--------|-----|
| Split `home_view.dart` | 🔴 High | 🟢 Highest | Eliminates a 6.7K-line god-object; enables isolated testing, faster code nav, and safe feature changes |
| Extract `ChatMessageList` | 🟡 Medium | 🟢 High | 900-line widget with its own state; extracting prevents accidental coupling with chat room UI |
| Split `store_view.dart` | 🟡 Medium | 🟢 High | Separates IAP logic, purchase handlers, and UI cards into testable units |
| Shared profile cache | 🟢 Low | 🟡 Medium | Eliminates 3× duplicated profile-fetching code; single source of truth |
| `StoreItem` → model file | 🟢 Low | 🟡 Medium | Clean separation of domain model from view; enables reuse in other features |
| Currency widgets → shared | 🟢 Low | 🟡 Medium | Consistent currency display across Home, Store, and future surfaces |
| Network helpers → shared | 🟢 Low | 🟡 Low | Small win; removes duplicated timeout/offline logic |
| Calendar widgets → files | 🟢 Low | 🟡 Low | Already well-separated internally; just needs file-level splits |
| Riverpod migration for Home | 🔴 High | 🟢 Highest | The real solution to the Home god-state problem; enables reactive, testable, composable state |

---

## Recommended Priority Order

1. **Split `home_view.dart`** — Start with mechanical extraction (controllers/services) before Riverpod migration
2. **Extract `ChatMessageList`** to its own file
3. **Extract `StoreItem` model** and split store purchase logic
4. **Create shared profile cache service**
5. **Extract shared currency widgets**
6. **Split calendar widgets** into individual files
7. **Migrate Home state to Riverpod providers** (can be done incrementally, one domain at a time)

---

## Execution Plan (Behavior-Preserving, PR-by-PR)

This plan intentionally avoids a big-bang rewrite. It ships in vertical slices with strict regression guardrails.

### PR Status Tracker

| PR | Scope | Status |
|----|-------|--------|
| PR 0 | Baseline safety net + invariants | ✅ Completed |
| PR 1 | Home unread manager extraction | ✅ Completed |
| PR 2 | Home invite flow extraction | ✅ Completed |
| PR 3 | Home pet movement controller extraction | ✅ Completed |
| PR 4 | Home feed orchestrator extraction | ✅ Completed |
| PR 5 | Home room manager extraction | ✅ Completed |
| PR 6 | Home build-tree decomposition | ✅ Completed |
| PR 7 | Shared profile cache service | ✅ Completed |
| PR 8 | Chat extraction (`ChatMessageList`) | ✅ Completed |
| PR 9 | Store extraction | ✅ Completed |
| PR 10 | Calendar modularization | ⬜ Pending |
| PR 11+ | Incremental Home Riverpod migration | ⬜ Pending |

### Refactor Invariants (Must Not Change)

Use this checklist as the baseline behavior contract during refactor PR reviews.

- Room switching behavior and selected-room persistence remain unchanged.
- Feed flow remains immediate and behavior-equivalent (send-start UX, optimistic rendering, server reconciliation).
- Unread indicators stay correct in all current surfaces (room cards, chat icon, app icon badge).
- Chat system message rendering remains localization-correct (hunger alerts, clean-poop, rename flows).
- Store legal links and purchase entry points stay reachable and functionally identical.
- Locked-room behavior and upgrade prompts remain unchanged.
- Pet movement/drag/wander timing and interaction feel remain unchanged unless explicitly targeted in a dedicated UX PR.

### Delivery Guardrails (apply to every PR)

- Preserve behavior unless explicitly noted.
- Keep diffs reviewable (target: small PRs, ideally <500 LOC touched where practical).
- Run and pass:
  - `flutter analyze`
  - `flutter test`
- Update `memory-bank/*.md` when behavior or architecture decisions change.

### PR 0 — Baseline Safety Net

**Goal:** lock current behavior before structural refactors.

- Add/strengthen tests for Home/Store/Chat critical flows.
- Add a short "refactor invariants" checklist (must-not-change behaviors).
- Keep this PR test-focused; no major code movement.

### PR 1 — Extract Home Unread Manager (low risk, high isolation)

**Create**
- `lib/features/home/controllers/home_unread_manager.dart`

**Update**
- `lib/features/home/home_view.dart`

**Move**
- unread/subscription/badge-related methods and wiring only.

**Exit criteria**
- Room unread counts and app icon badge behavior unchanged.
- `flutter analyze` and `flutter test` pass.

### PR 2 — Extract Home Invite Flow + Locked Room Dialogs

**Create**
- `lib/features/home/flows/home_invite_flow.dart`
- `lib/features/home/widgets/home_locked_overlay.dart` (if needed based on current build tree)

**Update**
- `lib/features/home/home_view.dart`

**Move**
- invite code parse/generate/dialog/premium popup/room locked dialog logic.

**Exit criteria**
- Invite/join/locked-room UX unchanged.
- `flutter analyze` and `flutter test` pass.

### PR 3 — Extract Home Pet Movement Controller (major early win)

**Create**
- `lib/features/home/controllers/home_pet_movement_controller.dart`

**Update**
- `lib/features/home/home_view.dart`

**Move**
- wander timers, drag handlers, movement animation helpers, position normalization/clamping, facing logic.

**Constraint**
- Keep state ownership in `_HomeViewState` for now to reduce migration risk.

**Exit criteria**
- Pet drag/wander/move behavior unchanged.
- `flutter analyze` and `flutter test` pass.

### PR 4 — Extract Home Feed Orchestrator

**Create**
- `lib/features/home/controllers/home_feed_orchestrator.dart`

**Update**
- `lib/features/home/home_view.dart`

**Move**
- camera/open-feed flow, optimistic feed lifecycle, upload success/failure handling, rewards feedback, latest feed/photo refresh.

### PR 5 — Extract Home Room Manager

**Create**
- `lib/features/home/controllers/home_room_manager.dart`

**Update**
- `lib/features/home/home_view.dart`

**Move**
- room fetch/switch/create/join/leave plus room summary loading.

### PR 6 — Decompose Home Build Tree

**Create**
- composable widgets under `lib/features/home/widgets/` for large UI sections (pet field, overlays, departure hero, room background).

**Update**
- `lib/features/home/home_view.dart`

**Move**
- only UI composition first; keep behavior logic untouched.

### PR 7 — Shared Profile Cache Service

**Create**
- `lib/services/profile/profile_cache_service.dart`

**Update**
- Home, Chat, Calendar profile resolution call sites.

**Move**
- duplicated sender/profile fetch-and-cache logic into one service.

### PR 8 — Chat Extraction

**Create**
- `lib/features/chat/chat_message_list.dart`
- chat subwidgets under `lib/features/chat/widgets/`

**Update**
- `lib/features/chat/chat_room_view.dart`

**Move**
- stateful message list stack (pagination, realtime, cache, block/report hooks).

### PR 9 — Store Extraction

**Create**
- `lib/features/store/models/store_item.dart`
- `lib/features/store/services/store_iap_service.dart`
- `lib/features/store/services/store_purchase_handler.dart`
- widget files under `lib/features/store/widgets/`

**Update**
- `lib/features/store/store_view.dart`

**Move**
- model, IAP logic, purchase handlers, and UI card builders.

### PR 10 — Calendar Modularization

**Create**
- calendar subwidgets under `lib/features/gallery/widgets/`
- `lib/features/gallery/services/memory_calendar_data_service.dart`

**Update**
- `lib/features/gallery/memory_calendar_view.dart`

**Move**
- view subwidgets and month/feed/profile loading logic into dedicated files/services.

### PR 11+ — Incremental Home Riverpod Migration

Migrate one domain at a time:
1. unread counts
2. rooms/current room
3. pet state
4. currency

Avoid full migration in one PR. Each step must pass the same regression gates.

### Suggested Cadence

- PR 1-6: ~1 PR/day is realistic.
- PR 7-10: can run partially in parallel if ownership is split.
- PR 11+: strictly incremental due higher behavioral risk.
