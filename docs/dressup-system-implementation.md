# PicPet 寵物換裝系統實作計劃 (Pet Dress-Up System)

> **目標讀者**: 負責實作的 coding agent
> **版本**: v1.0
> **日期**: 2026-04-17
> **前置閱讀**: 實作前必須先讀完 `memory-bank/*.md`（不含 `archive/`）

---

## 1. 系統概述

### 1.1 功能目標
為 PicPet 的寵物新增多部位換裝功能。用戶可以為寵物穿戴/脫掉物件（帽子、圍巾、背包等），穿戴效果在主畫面即時顯示，並同步給同房間的其他用戶。

### 1.2 設計決策 — Widget 層掛載（非 PNG 序列圖）

**關鍵背景**：目前寵物動畫系統使用 **GIF 檔案**（`Image.asset` + `gaplessPlayback`），Flutter 的 GIF 播放不暴露當前幀索引。因此**不可能做到逐幀掛點追蹤**。

**方案**：保留 GIF 動畫系統不變，將穿戴物件作為獨立 Widget 層疊在寵物 GIF 之上。使用**正規化百分比坐標 (0.0~1.0)** 定義掛點位置，物件跟隨寵物 Widget 一起移動、翻轉、縮放。

**理由**：
- 不需要改動現有 GIF 動畫系統
- 寵物 idle/walk 動畫幅度極小（頭部 ±2-5px），Widget 層級掛載視覺上無感知差異
- 素材產出極少——每種寵物只需定義一組靜態掛點
- App bundle 幾乎不增長

---

## 2. 名詞定義

| 名詞 | 說明 |
|------|------|
| **Socket（掛點）** | 定義在寵物配置中的虛擬坐標點（正規化 0.0~1.0），標記寵物身體某部位的連接位置（如 `head`、`body`、`back`） |
| **Socket Override** | 在特定動畫狀態（如 `walk`）下對 Socket 坐標的覆寫。只有跟 idle 差異明顯的狀態才需定義 |
| **Anchor（錨點）** | 定義在物件上的虛擬坐標點（正規化 0.0~1.0，相對於物件自身尺寸），標記物件的重心或接合處 |
| **Equipment Item（穿戴物件）** | 已裁切至最小邊界的 PNG/WebP 圖片（如帽子、圍巾），含 socket_type 和 anchor 等中繼資料 |
| **z_order** | 渲染層級。`> 0` 渲染在寵物前面（帽子）；`< 0` 渲染在寵物後面（披風/背包）；`0` 與寵物同層 |

---

## 3. 渲染對齊公式

在渲染時，穿戴物件的左上角座標按以下公式計算：

```
petWidgetWidth  = _petAvatarSize.width   (目前是 100)
petWidgetHeight = _petAvatarSize.height  (目前是 100)

socketPixelX = socket.x * petWidgetWidth
socketPixelY = socket.y * petWidgetHeight

itemRenderWidth  = item.sizeRatio.w * petWidgetWidth
itemRenderHeight = item.sizeRatio.h * petWidgetHeight

anchorPixelX = anchor.x * itemRenderWidth
anchorPixelY = anchor.y * itemRenderHeight

itemLeft = socketPixelX - anchorPixelX
itemTop  = socketPixelY - anchorPixelY
```

翻轉處理（`_petFacingRight == false` 時）：
```
flippedSocketX = 1.0 - socket.x
// 物件圖片同時做水平翻轉 (Matrix4.diagonal3Values(-1, 1, 1))
```

---

## 4. 數據結構設計

### 4.1 寵物掛點配置（Dart 代碼，非 JSON）

**位置**: `lib/features/pet/pet_sockets.dart`（新檔案）

遵循現有 `PetCatalog` 的風格，使用 Dart 靜態配置，不使用外部 JSON：

```dart
import 'dart:ui';

/// A socket attachment point on a pet, using normalized coordinates (0.0–1.0).
class PetSocket {
  const PetSocket({required this.x, required this.y});
  final double x;
  final double y;

  PetSocket flippedX() => PetSocket(x: 1.0 - x, y: y);
}

/// Socket configuration for a single pet type.
class PetSocketConfig {
  const PetSocketConfig({
    required this.petId,
    required this.sockets,
    this.walkOverrides,
    this.sleepOverrides,
  });

  final String petId;

  /// Default sockets (used for idle/stay state).
  final Map<String, PetSocket> sockets;

  /// Optional per-animation-state overrides.
  /// Only define overrides when the socket position noticeably
  /// differs from idle.
  final Map<String, PetSocket>? walkOverrides;
  final Map<String, PetSocket>? sleepOverrides;

  /// Resolve socket for a given slot and animation state.
  PetSocket? resolve(String slotName, {bool walking = false, bool sleeping = false}) {
    if (walking && walkOverrides != null && walkOverrides!.containsKey(slotName)) {
      return walkOverrides![slotName];
    }
    if (sleeping && sleepOverrides != null && sleepOverrides!.containsKey(slotName)) {
      return sleepOverrides![slotName];
    }
    return sockets[slotName];
  }
}

class PetSocketCatalog {
  static const List<PetSocketConfig> configs = [
    PetSocketConfig(
      petId: 'ghost',
      sockets: {
        'head': PetSocket(x: 0.50, y: 0.18),
        'body': PetSocket(x: 0.50, y: 0.55),
        'back': PetSocket(x: 0.70, y: 0.40),
      },
      // Walk override example — adjust after checking GIF:
      // walkOverrides: {
      //   'head': PetSocket(x: 0.50, y: 0.15),
      // },
    ),
    PetSocketConfig(
      petId: 'cat',
      sockets: {
        'head': PetSocket(x: 0.50, y: 0.15),
        'body': PetSocket(x: 0.50, y: 0.50),
        'back': PetSocket(x: 0.72, y: 0.38),
      },
    ),
    PetSocketConfig(
      petId: 'fish',
      sockets: {
        'head': PetSocket(x: 0.50, y: 0.22),
        'body': PetSocket(x: 0.50, y: 0.52),
        'back': PetSocket(x: 0.68, y: 0.42),
      },
    ),
    PetSocketConfig(
      petId: 'tiger',
      sockets: {
        'head': PetSocket(x: 0.50, y: 0.14),
        'body': PetSocket(x: 0.50, y: 0.48),
        'back': PetSocket(x: 0.73, y: 0.36),
      },
    ),
  ];

  static PetSocketConfig? forPet(String petId) {
    for (final config in configs) {
      if (config.petId == petId) return config;
    }
    return null;
  }
}
```

> **注意**: 上面的數值是暫定值。實際坐標需要逐一打開每隻寵物的 GIF、
> 目測頭部/身體/背部的位置後微調。可以用 debug overlay 輔助標記（見 §10）。

### 4.2 穿戴物件配置（Dart 代碼）

**位置**: `lib/features/pet/equipment_catalog.dart`（新檔案）

```dart
/// Definition of an equipment item that can be worn by a pet.
class EquipmentDefinition {
  const EquipmentDefinition({
    required this.id,
    required this.socketType,
    required this.anchor,
    required this.sizeRatio,
    required this.assetPath,
    this.zOrder = 1,
    this.followsFlip = true,
  });

  /// Unique identifier matching DB `items.sku`.
  final String id;

  /// Which socket slot this item attaches to (head, body, back).
  final String socketType;

  /// Anchor point within the item (normalized 0.0–1.0 relative to item size).
  /// e.g. (0.5, 0.9) = bottom center of the item image.
  final EquipmentAnchor anchor;

  /// Item size relative to pet widget size.
  /// e.g. (0.4, 0.3) = item width is 40% of pet widget, height is 30%.
  final EquipmentSize sizeRatio;

  /// Asset path to the item's cropped PNG.
  final String assetPath;

  /// Render order relative to the pet:
  ///   > 0 → in front of pet (hat, glasses)
  ///   < 0 → behind pet (cape, backpack)
  ///   0   → same layer
  final int zOrder;

  /// Whether this item mirrors when the pet flips direction.
  /// Usually true; false for symmetrical items like halos.
  final bool followsFlip;
}

class EquipmentAnchor {
  const EquipmentAnchor({required this.x, required this.y});
  final double x;
  final double y;
}

class EquipmentSize {
  const EquipmentSize({required this.w, required this.h});
  final double w;
  final double h;
}

class EquipmentCatalog {
  /// All known equipment definitions.
  /// Add new items here as they become available.
  static const List<EquipmentDefinition> items = [
    // Example — first launch item:
    // EquipmentDefinition(
    //   id: 'equip_santa_hat',
    //   socketType: 'head',
    //   anchor: EquipmentAnchor(x: 0.5, y: 0.9),
    //   sizeRatio: EquipmentSize(w: 0.45, h: 0.35),
    //   assetPath: 'assets/equipment/hats/santa_hat.png',
    //   zOrder: 1,
    // ),
  ];

  static EquipmentDefinition? byId(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  static List<EquipmentDefinition> forSocket(String socketType) {
    return items.where((item) => item.socketType == socketType).toList();
  }
}
```

### 4.3 素材目錄結構

```
assets/
  equipment/
    hats/
      santa_hat.png        ← 已裁切至最小邊界的 PNG/WebP
      party_hat.png
    body/
      scarf.png
      bow_tie.png
    back/
      cape.png
      backpack.png
```

**素材規格**:
- 所有物件 PNG 已裁切至最小邊界（無多餘透明區域）
- 建議 WebP 格式，控制在 ~20KB 以下
- 必須在 `pubspec.yaml` 加入 `assets/equipment/` 目錄宣告
- 新增後用 `flutter build bundle` 驗證

---

## 5. 後端數據模型

### 5.1 Supabase 表：`pet_equipment`（新表）

存儲每隻寵物當前穿戴的裝備。一隻寵物每個 socket 只能裝備一件物件。

```sql
CREATE TABLE pet_equipment (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id     uuid NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  room_id    uuid NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  item_id    uuid NOT NULL REFERENCES items(id),
  slot       text NOT NULL,  -- 'head', 'body', 'back'
  equipped_at timestamptz NOT NULL DEFAULT now(),
  equipped_by uuid NOT NULL DEFAULT (select auth.uid()),

  -- One item per slot per pet
  UNIQUE (pet_id, slot)
);

-- Index for common queries
CREATE INDEX idx_pet_equipment_pet_id ON pet_equipment(pet_id);
CREATE INDEX idx_pet_equipment_room_id ON pet_equipment(room_id);

-- RLS: room members can read; only active room member can write
ALTER TABLE pet_equipment ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Room members can view pet equipment"
  ON pet_equipment FOR SELECT
  TO authenticated
  USING (
    exists (
      select 1 from room_members rm
      where rm.room_id = pet_equipment.room_id
        and rm.user_id = (select auth.uid())
        and rm.is_active
    )
  );

CREATE POLICY "Room members can manage pet equipment"
  ON pet_equipment FOR ALL
  TO authenticated
  USING (
    exists (
      select 1 from room_members rm
      where rm.room_id = pet_equipment.room_id
        and rm.user_id = (select auth.uid())
        and rm.is_active
    )
  )
  WITH CHECK (
    exists (
      select 1 from room_members rm
      where rm.room_id = pet_equipment.room_id
        and rm.user_id = (select auth.uid())
        and rm.is_active
    )
  );
```

### 5.2 `items` 表 — 新增 equipment 品類

在 `items` 表新增 equipment 類型物件。使用現有 `metadata` JSONB 欄位存放裝備專用中繼資料：

```sql
INSERT INTO items (sku, type, name, price_coins, price_diamonds, is_active, metadata) VALUES
(
  'equip_santa_hat',
  'cosmetic',
  'Santa Hat',
  100,  -- candy price
  NULL, -- no diamond price
  false, -- version-gated: use is_active = false
  jsonb_build_object(
    'category', 'equipment',
    'equipment_slot', 'head',
    'emoji', '🎅',
    'asset_path', 'assets/equipment/hats/santa_hat.png',
    'min_app_version', '1.2.0',
    'visibility_mode', 'version_gated'
  )
);
```

**metadata 必填欄位**（equipment 專用）：

| Key | Type | 說明 |
|-----|------|------|
| `category` | string | 固定 `"equipment"` |
| `equipment_slot` | string | `"head"` / `"body"` / `"back"` |
| `asset_path` | string | 本地無素材 path |
| `emoji` | string | 預覽 / fallback emoji |
| `min_app_version` | string | 最低支援版本（如 `"1.2.0"`） |
| `visibility_mode` | string | `"version_gated"` |

### 5.3 RPC 函數

#### `equip_pet_item(p_pet_id, p_room_id, p_item_id, p_slot)`

```sql
CREATE OR REPLACE FUNCTION equip_pet_item(
  p_pet_id uuid,
  p_room_id uuid,
  p_item_id uuid,
  p_slot text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  v_user_id uuid := (select auth.uid());
  v_item_sku text;
  v_existing_equipment_id uuid;
BEGIN
  -- Validate room membership
  IF NOT EXISTS (
    SELECT 1 FROM room_members rm
    WHERE rm.room_id = p_room_id
      AND rm.user_id = v_user_id
      AND rm.is_active
  ) THEN
    RAISE EXCEPTION 'Not an active room member';
  END IF;

  -- Validate pet belongs to room
  IF NOT EXISTS (
    SELECT 1 FROM pets WHERE id = p_pet_id
  ) THEN
    RAISE EXCEPTION 'Pet not found';
  END IF;

  -- Validate item exists and is equipment
  SELECT sku INTO v_item_sku FROM items
  WHERE id = p_item_id
    AND metadata->>'category' = 'equipment'
    AND metadata->>'equipment_slot' = p_slot;

  IF v_item_sku IS NULL THEN
    RAISE EXCEPTION 'Item not found or not valid for slot %', p_slot;
  END IF;

  -- Validate user owns this item (has it in inventory)
  IF NOT EXISTS (
    SELECT 1 FROM inventories
    WHERE user_id = v_user_id
      AND item_id = p_item_id
      AND quantity > 0
  ) THEN
    RAISE EXCEPTION 'Item not owned';
  END IF;

  -- Upsert: replace any existing equipment in this slot
  INSERT INTO pet_equipment (pet_id, room_id, item_id, slot, equipped_by)
  VALUES (p_pet_id, p_room_id, p_item_id, p_slot, v_user_id)
  ON CONFLICT (pet_id, slot) DO UPDATE
    SET item_id = EXCLUDED.item_id,
        equipped_by = EXCLUDED.equipped_by,
        equipped_at = now();

  RETURN jsonb_build_object('success', true, 'slot', p_slot, 'item_sku', v_item_sku);
END;
$$;
```

#### `unequip_pet_item(p_pet_id, p_room_id, p_slot)`

```sql
CREATE OR REPLACE FUNCTION unequip_pet_item(
  p_pet_id uuid,
  p_room_id uuid,
  p_slot text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  v_user_id uuid := (select auth.uid());
  v_deleted int;
BEGIN
  -- Validate room membership
  IF NOT EXISTS (
    SELECT 1 FROM room_members rm
    WHERE rm.room_id = p_room_id
      AND rm.user_id = v_user_id
      AND rm.is_active
  ) THEN
    RAISE EXCEPTION 'Not an active room member';
  END IF;

  DELETE FROM pet_equipment
  WHERE pet_id = p_pet_id AND slot = p_slot;

  GET DIAGNOSTICS v_deleted = ROW_COUNT;

  RETURN jsonb_build_object('success', true, 'slot', p_slot, 'removed', v_deleted > 0);
END;
$$;
```

#### `get_pet_equipment(p_pet_id)`

```sql
CREATE OR REPLACE FUNCTION get_pet_equipment(p_pet_id uuid)
RETURNS TABLE (
  slot text,
  item_id uuid,
  item_sku text,
  equipped_at timestamptz,
  equipped_by uuid
)
LANGUAGE plpgsql
SECURITY INVOKER
STABLE
AS $$
BEGIN
  RETURN QUERY
    SELECT
      pe.slot,
      pe.item_id,
      i.sku AS item_sku,
      pe.equipped_at,
      pe.equipped_by
    FROM pet_equipment pe
    JOIN items i ON i.id = pe.item_id
    WHERE pe.pet_id = p_pet_id;
END;
$$;
```

### 5.4 Realtime 事件

訂閱 `pet_equipment` 表的 INSERT/UPDATE/DELETE，按 `room_id` 過濾，讓同房間用戶即時看到裝備變更：

```dart
// Subscribe pattern (follows existing room_item_inventory_revisions pattern)
final channel = Supabase.instance.client.channel('pet_equipment_$roomId');
channel.onPostgresChanges(
  event: PostgresChangeEvent.all,
  schema: 'public',
  table: 'pet_equipment',
  filter: PostgresChangeFilter(
    type: PostgresChangeFilterType.eq,
    column: 'room_id',
    value: roomId,
  ),
  callback: (_) => _refreshPetEquipment(),
);
channel.subscribe();
```

---

## 6. `ShopItem` 模型擴展

### 6.1 `shop_item.dart` 修改

在 `ShopItem` class 加入 equipment 相關 getter：

```dart
// 新增 getter
bool get isEquipment => category == 'equipment';
String? get equipmentSlot => _metadata['equipment_slot'] as String?;

// 修改 _buildPurchaseSuccessVisual 時需要處理 equipment 類型
```

### 6.2 `_loadStore()` 修改

Shop 載入時，equipment 類物件的已擁有數量查詢方式同其他 non-furniture 物件（讀 `inventories` 表），無需特殊處理。

### 6.3 Shop UI — 新增 Equipment 分類

在 `shop_view.dart` 加入 equipment section：

```dart
// 新 getter
List<ShopItem> get _equipmentItems =>
    _storeItems.where((item) => item.isEquipment).toList(growable: false);

// 在 build 中加入新 section（在 furniture 之後）
if (_equipmentItems.isNotEmpty) ...[
  SliverToBoxAdapter(
    child: KeyedSubtree(
      key: _equipmentSectionKey,
      child: _SectionHeader(title: l10n.shopSectionEquipment),
    ),
  ),
  // ... grid delegate same as furniture
],
```

同時在 `_ShopCategoryRow` 加入 Equipment 分類按鈕。

### 6.4 purchase_pet_equipment_with_coins / diamonds

複用現有的 `purchase_item_with_coins` RPC 即可（equipment 在 `items` 表中，購買後存入 `inventories`）。不需要新 purchase RPC。

---

## 7. 渲染實作

### 7.1 核心渲染 Widget（新檔案）

**位置**: `lib/features/home/widgets/pet_equipment_overlay.dart`

```dart
import 'package:flutter/material.dart';
import '../../pet/pet_sockets.dart';
import '../../pet/equipment_catalog.dart';

class PetEquipmentOverlay extends StatelessWidget {
  const PetEquipmentOverlay({
    super.key,
    required this.petId,
    required this.equippedItems,
    required this.petSize,
    required this.facingRight,
    required this.isWalking,
    required this.isSleeping,
  });

  final String petId;
  /// Map<slot, equipmentDefinitionId>
  final Map<String, String> equippedItems;
  final Size petSize;
  final bool facingRight;
  final bool isWalking;
  final bool isSleeping;

  @override
  Widget build(BuildContext context) {
    final socketConfig = PetSocketCatalog.forPet(petId);
    if (socketConfig == null || equippedItems.isEmpty) {
      return const SizedBox.shrink();
    }

    // Separate items by z-order for layering
    final behind = <Widget>[];
    final inFront = <Widget>[];

    for (final entry in equippedItems.entries) {
      final slot = entry.key;
      final itemId = entry.value;
      final equipDef = EquipmentCatalog.byId(itemId);
      if (equipDef == null) continue;

      var socket = socketConfig.resolve(
        slot,
        walking: isWalking,
        sleeping: isSleeping,
      );
      if (socket == null) continue;

      // Handle flip
      if (!facingRight) {
        socket = socket.flippedX();
      }

      final itemWidth = equipDef.sizeRatio.w * petSize.width;
      final itemHeight = equipDef.sizeRatio.h * petSize.height;

      final socketPx = Offset(
        socket.x * petSize.width,
        socket.y * petSize.height,
      );
      final anchorPx = Offset(
        equipDef.anchor.x * itemWidth,
        equipDef.anchor.y * itemHeight,
      );

      final left = socketPx.dx - anchorPx.dx;
      final top = socketPx.dy - anchorPx.dy;

      final widget = Positioned(
        left: left,
        top: top,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(
            (!facingRight && equipDef.followsFlip) ? -1.0 : 1.0,
            1.0,
            1.0,
          ),
          child: Image.asset(
            equipDef.assetPath,
            width: itemWidth,
            height: itemHeight,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      );

      if (equipDef.zOrder < 0) {
        behind.add(widget);
      } else {
        inFront.add(widget);
      }
    }

    // Return separate lists; caller stacks behind → pet → inFront
    // This widget returns front items; behind items via a separate getter
    // Or, use a single Stack and handle z-order internally:
    return SizedBox(
      width: petSize.width,
      height: petSize.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [...behind, ...inFront],
      ),
    );
  }
}
```

### 7.2 修改 `_buildPetAvatar()`

**位置**: `lib/features/home/home_view.dart` 行 ~5090

修改方式：將 `_buildPetAvatar()` 改為在寵物 GIF 前後插入裝備 Widget 層。

**修改前** (`_buildPetAvatar` 的回傳):
```dart
return SizedBox(
  width: _petAvatarSize.width,
  height: _petAvatarSize.height,
  child: Image.asset(asset, ...),
);
```

**修改後**:
```dart
return SizedBox(
  width: _petAvatarSize.width,
  height: _petAvatarSize.height,
  child: Stack(
    clipBehavior: Clip.none,
    children: [
      // Behind-pet equipment (z_order < 0)
      ..._buildEquipmentLayer(zOrderNegative: true),
      // Pet GIF
      Image.asset(asset, ...),
      // In-front-of-pet equipment (z_order >= 0)
      ..._buildEquipmentLayer(zOrderNegative: false),
    ],
  ),
);
```

### 7.3 修改 `_buildDraggablePet()`

**位置**: `lib/features/home/home_view.dart` 行 ~4512

寵物 Widget 已被 `Transform.scale` + `Transform` (flip) 包裹。由於 equipment overlay 是 `_buildPetAvatar()` 內部的 `Stack` children，所以它們會自動繼承翻轉和縮放，不需要在 `_buildDraggablePet` 做額外處理。

### 7.4 寵物狀態 bar 頭像（小頭像）

**位置**: `home_game_status_bar.dart` 行 ~4972

狀態列的小寵物頭像也需要顯示裝備。複用 `PetEquipmentOverlay`，傳入 `stayAsset` 的靜態 socket 配置即可。

---

## 8. 狀態管理

### 8.1 HomeView 新增狀態欄位

在 `_HomeViewState` 加入：

```dart
// Equipment state
Map<String, String> _equippedItems = {};  // slot → equipment_definition_id (sku)
bool _equipmentLoading = false;
String? _equipmentError;
RealtimeChannel? _petEquipmentChannel;
```

### 8.2 裝備載入

在 `_loadPetState` / `_refreshPetState` 之後呼叫：

```dart
Future<void> _loadPetEquipment() async {
  final petId = _petId;
  if (petId == null) return;

  setState(() {
    _equipmentLoading = true;
    _equipmentError = null;
  });

  try {
    final rows = await Supabase.instance.client.rpc(
      'get_pet_equipment',
      params: {'p_pet_id': petId},
    );
    final equipped = <String, String>{};
    for (final row in rows as List) {
      final slot = row['slot'] as String?;
      final sku = row['item_sku'] as String?;
      if (slot != null && sku != null) {
        equipped[slot] = sku;
      }
    }
    if (!mounted) return;
    setState(() {
      _equippedItems = equipped;
    });
  } catch (error) {
    if (!mounted) return;
    setState(() {
      _equipmentError = error.toString();
    });
  } finally {
    if (mounted) {
      setState(() {
        _equipmentLoading = false;
      });
    }
  }
}
```

### 8.3 Realtime 訂閱

在 `_subscribePetState` 旁加入 equipment realtime 訂閱（見 §5.4）。
在 `dispose()` 中清理 channel。遵循現有 `removeChannel(...)` 模式。

### 8.4 裝備/卸下操作

```dart
Future<void> _equipItem(String itemId, String slot) async {
  final petId = _petId;
  final roomId = _roomId;
  if (petId == null || roomId == null) return;

  try {
    await Supabase.instance.client.rpc(
      'equip_pet_item',
      params: {
        'p_pet_id': petId,
        'p_room_id': roomId,
        'p_item_id': itemId,
        'p_slot': slot,
      },
    );
    await _loadPetEquipment();
  } catch (error) {
    if (!mounted) return;
    // Show error toast
  }
}

Future<void> _unequipItem(String slot) async {
  final petId = _petId;
  final roomId = _roomId;
  if (petId == null || roomId == null) return;

  try {
    await Supabase.instance.client.rpc(
      'unequip_pet_item',
      params: {
        'p_pet_id': petId,
        'p_room_id': roomId,
        'p_slot': slot,
      },
    );
    await _loadPetEquipment();
  } catch (error) {
    if (!mounted) return;
    // Show error toast
  }
}
```

---

## 9. 換裝 UI — 穿戴介面

### 9.1 入口

在 `HomeGameStatusBar` 或 `HomeBottomNavBar` 加一個「🎩 裝扮」按鈕。
點擊後開啟一個 bottom sheet 或 overlay（類似 furniture inventory panel）。

### 9.2 換裝面板 Widget

**位置**: `lib/features/home/widgets/pet_equipment_panel.dart`（新檔案）

面板結構：
```
┌───────────────────────────────┐
│  [寵物預覽 + 當前裝備]          │  ← 用 PetEquipmentOverlay 即時預覽
│                               │
├───────────────────────────────┤
│  [HEAD] [BODY] [BACK]         │  ← slot tab bar
├───────────────────────────────┤
│  ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐   │  ← 該 slot 可穿戴的物件 grid
│  │🎩│ │🧢│ │🎓│ │👒│ │🪖│   │     已穿戴的顯示勾號
│  └──┘ └──┘ └──┘ └──┘ └──┘   │     點擊 = 穿上 or 脫下
│                               │
│  [❌ 卸下] [✅ 穿上]            │  ← 操作按鈕
└───────────────────────────────┘
```

### 9.3 交互邏輯

- 用戶點擊 slot tab → 顯示該 slot 已擁有的物件
- 點擊物件 → 即時預覽（只改 local state，不呼叫 RPC）
- 點「穿上」→ 呼叫 `equip_pet_item` RPC，成功後更新狀態
- 點「卸下」→ 呼叫 `unequip_pet_item` RPC
- 已穿戴的物件顯示高亮邊框 + 勾號

---

## 10. 版本相容性

### 10.1 Version Gating 策略

遵循現有 repo 慣例：

1. Equipment 類型物件在 `items` 表用 `is_active = false` + `metadata.visibility_mode = 'version_gated'` + `metadata.min_app_version = '1.2.0'`
2. `get_visible_shop_items(p_app_version)` 已經支援 version-gated 物件，無需修改
3. `pet_equipment` 表的 `item_id` 對老版本 App 不可見——老版本 App 不會查詢 `pet_equipment` 表，因此不受影響
4. 老版本 App 看到的寵物就是原本的 GIF，不帶任何裝備（graceful degradation）

### 10.2 同房間舊版本用戶

- 舊版本不會訂閱 `pet_equipment` realtime
- 舊版本的寵物渲染不包含 equipment overlay
- **結果**：舊版本用戶看到寵物沒穿裝備，新版本用戶看到穿了裝備。這是可接受的行為。

---

## 11. 效能優化

| 項目 | 做法 |
|------|------|
| Equipment 圖片預載 | 在 `_precachePetAssets` 中加入已穿戴物件的 `precacheImage` |
| 避免不必要重建 | 用 `RepaintBoundary` 包裹 pet + equipment `Stack` |
| 圖片大小控制 | 物件 PNG/WebP 控制在 20KB 以下 |
| Equipment overlay rebuid | 只在 `_equippedItems`、`_petIsMoving`、`_petFacingRight` 變化時重建 |
| GIF 不受影響 | Equipment overlay 是 `Stack` children，不影響 GIF 的播放性能 |

---

## 12. Debug / 開發輔助工具

### 12.1 Socket Debug Overlay

加一個 debug-only 的 overlay 顯示寵物身上的 socket 位置（紅色小圓點），方便美術調整坐標：

```dart
// In debug drawer section:
SwitchListTile(
  title: Text('Show Socket Debug'),
  value: _showSocketDebug,
  onChanged: (v) => setState(() => _showSocketDebug = v),
),
```

在 `_buildPetAvatar` 中根據 `_showSocketDebug` 加入彩色圓點 Widget。

### 12.2 Debug 快捷穿戴

在 debug drawer 加入「Quick Equip Test Item」按鈕，可以跳過購買直接穿戴預設物件，方便測試渲染效果。

---

## 13. 本地化 (i18n)

在 `lib/l10n/app_en.arb`、`app_ja.arb`、`app_zh.arb` 加入：

```json
{
  "shopSectionEquipment": "Pet Outfit",
  "equipmentSlotHead": "Head",
  "equipmentSlotBody": "Body",
  "equipmentSlotBack": "Back",
  "equipmentEquipCta": "Equip",
  "equipmentUnequipCta": "Remove",
  "equipmentNoneOwned": "You don't own any items for this slot yet.",
  "equipmentDressingTitle": "Dress Up",
  "equipmentEquipSuccess": "Equipped {itemName}!",
  "equipmentUnequipSuccess": "Removed equipment from {slot}."
}
```

在 `shop_item_localization.dart` 加入 equipment 物件的 SKU → localized name 映射。

---

## 14. 測試計劃

### 14.1 Widget Tests

| 測試 | 驗證內容 |
|------|----------|
| `pet_equipment_overlay_test.dart` | Equipment overlay 在 head/body/back 各 slot 正確定位 |
| `pet_equipment_overlay_flip_test.dart` | 翻轉時 socket.x 正確鏡像、物件圖片正確翻轉 |
| `pet_equipment_overlay_zorder_test.dart` | zOrder < 0 的物件在 GIF 後面、>= 0 的在前面 |
| `pet_equipment_overlay_empty_test.dart` | equippedItems 為空時不渲染多餘 Widget |
| `pet_socket_config_test.dart` | PetSocketCatalog.forPet 回傳正確配置；resolve 在 walk/sleep override 正確 |
| `equipment_catalog_test.dart` | EquipmentCatalog.byId / forSocket 正確查找 |

### 14.2 Integration / Manual

| 測試 | 方法 |
|------|------|
| 穿戴流程 E2E | 在 debug 模式手動操作：購買 → 穿上 → 寵物顯示物件 → 走路時物件跟隨 → 卸下 |
| 翻轉驗證 | 拖曳寵物左右移動，確認物件跟隨翻轉 |
| 房間同步 | 另一台裝置登入同房間，確認 realtime 更新 |
| 老版本相容 | 用 1.1.x 版本進入同房間，確認不 crash、只看到原始寵物 |

### 14.3 驗收指令

```bash
flutter analyze
flutter test
flutter build bundle  # 驗證 assets 正確引用
```

---

## 15. 實作順序（Checklist）

按以下順序實作，每階段完成後執行 `flutter analyze` + `flutter test`：

### Phase 1：數據層（可以不碰 UI 先完成）
- [ ] 新建 `lib/features/pet/pet_sockets.dart` — PetSocketCatalog
- [ ] 新建 `lib/features/pet/equipment_catalog.dart` — EquipmentCatalog
- [ ] 寫 Supabase migration：`pet_equipment` 表 + RLS + 索引
- [ ] 寫 Supabase migration：RPC 函數 `equip_pet_item` / `unequip_pet_item` / `get_pet_equipment`
- [ ] 在 `items` 表插入至少一個測試裝備物件
- [ ] `ShopItem` model 加入 `isEquipment` / `equipmentSlot` getter

### Phase 2：渲染層
- [ ] 新建 `lib/features/home/widgets/pet_equipment_overlay.dart`
- [ ] 修改 `_buildPetAvatar()` — 加入 equipment Stack 層
- [ ] 在 `_HomeViewState` 加入 equipment 狀態欄位
- [ ] 實作 `_loadPetEquipment()`（在 pet state 載入後呼叫）
- [ ] 實作 realtime 訂閱 `pet_equipment` 表
- [ ] 準備至少一個測試物件 PNG，加入 `assets/equipment/` 和 `pubspec.yaml`
- [ ] 渲染驗證：debug 模式下直接設定 `_equippedItems` 確認顯示

### Phase 3：穿戴 UI
- [ ] 新建 `lib/features/home/widgets/pet_equipment_panel.dart`
- [ ] 在 Home 加入裝扮按鈕入口
- [ ] 實作 `_equipItem()` / `_unequipItem()`
- [ ] 接通 equipment panel 到 equip/unequip RPC

### Phase 4：商城整合
- [ ] Shop `_loadStore` 中處理 equipment 已擁有數量（已自動由 `inventories` 查詢覆蓋）
- [ ] Shop UI 加入 Equipment section
- [ ] 加入 l10n 字串
- [ ] 本地化物件名稱

### Phase 5：Polish
- [ ] Socket debug overlay
- [ ] 物件預覽動畫（穿上時 scale bounce）
- [ ] `precacheImage` 優化
- [ ] `RepaintBoundary` 優化
- [ ] 版本相容性測試
- [ ] 完整 widget test
- [ ] 更新 `memory-bank/` 文件

---

## 16. 需要注意的 Repo 慣例

| 慣例 | 本功能的對應做法 |
|------|------------------|
| Version-gated items use `is_active = false` | Equipment items 同樣 |
| New features need `min_app_version` | 整個換裝系統 gate 在 `1.2.0` |
| RPC params prefix `p_` | 已遵循 |
| RPC use `SECURITY INVOKER` | 已遵循 |
| Realtime cleanup in `dispose()` | 用 `removeChannel(...)` |
| Additive RPCs preferred | 新增 RPC，不修改現有 |
| Widget tests required | §14.1 |
| `flutter analyze` + `flutter test` after changes | §14.3 |
| Update `memory-bank/` if behavior changes | Phase 5 checklist |
| Use `.codex/skills/shared-item-rollout/SKILL.md` | 裝備物件上架時需遵循 |

---

## 17. 檔案清單總覽

### 新建檔案
| 路徑 | 用途 |
|------|------|
| `lib/features/pet/pet_sockets.dart` | 寵物掛點配置 |
| `lib/features/pet/equipment_catalog.dart` | 穿戴物件定義 |
| `lib/features/home/widgets/pet_equipment_overlay.dart` | 渲染覆蓋層 Widget |
| `lib/features/home/widgets/pet_equipment_panel.dart` | 換裝 UI 面板 |
| `assets/equipment/hats/` | 帽子素材目錄 |
| `assets/equipment/body/` | 身體裝備素材目錄 |
| `assets/equipment/back/` | 背部裝備素材目錄 |
| `supabase/migrations/YYYYMMDDHHMMSS_add_pet_equipment.sql` | DB migration |
| `test/pet_equipment_overlay_test.dart` | Widget 測試 |
| `test/pet_socket_config_test.dart` | Socket 配置測試 |

### 修改檔案
| 路徑 | 修改內容 |
|------|----------|
| `lib/features/home/home_view.dart` | 加入 equipment 狀態、修改 `_buildPetAvatar`、realtime 訂閱 |
| `lib/features/shop/models/shop_item.dart` | 加入 `isEquipment` / `equipmentSlot` getter |
| `lib/features/shop/shop_view.dart` | 加入 Equipment shop section |
| `lib/features/shop/shop_item_localization.dart` | 加入 equipment SKU 本地化 |
| `lib/l10n/app_en.arb` | 加入換裝相關字串 |
| `lib/l10n/app_ja.arb` | 加入換裝相關字串 |
| `lib/l10n/app_zh.arb` | 加入換裝相關字串 |
| `pubspec.yaml` | 加入 `assets/equipment/` 目錄 |
| `memory-bank/architecture.md` | 紀錄換裝系統架構 |
| `memory-bank/progress.md` | 紀錄實作進度 |
| `memory-bank/database-schema.md` | 紀錄 `pet_equipment` 表 |
