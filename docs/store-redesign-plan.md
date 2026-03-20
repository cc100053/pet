# Store UI Redesign Specification (AI-Agent Optimized)

## 1. Objective
Refactor the existing `StoreView` and related widgets to match the provided visual reference. The goal is a "Kawaii" (cute) aesthetic with soft pastel gradients, rounded components, and a 2-column grid layout. 

**CRITICAL:** No backend logic, API calls, or IAP flows should be modified. Only the presentation layer (UI/UX) is within scope. Map existing data models (`StoreItem`) to the new UI components.

## 2. Visual Identity & Design Tokens

### 2.1 Color Palette & Gradients
*   **Main Background**: A multi-stop linear gradient:
    *   Top: `#E0F7FF` (Light Blue)
    *   Middle: `#F3E5F5` (Soft Lavender)
    *   Bottom: `#FFF3E0` (Soft Peach/Pink)
*   **Primary Action (Buy)**: Linear gradient `#FFB74D` to `#FFA726` (Gold/Orange).
*   **Pro/Premium Banner**: Linear gradient `#90CAF9` to `#CE93D8` with a white border.
*   **Currency Icons**:
    *   Diamonds: `#4C7DFF` (Existing)
    *   Candy/Coins: `#FF8A65` (Warm Orange)
*   **Card Background**: White with high opacity (0.9+) or slight transparency for glassmorphism effect.

### 2.2 Shapes & Effects
*   **Border Radius**: 
    *   Main Cards: `28.0` to `32.0`
    *   Action Buttons: `24.0` (Pill-shaped)
    *   Currency Chips: `16.0`
*   **Shadows**: 
    *   Soft Elevation: `BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))`

## 3. Component Specifications

### 3.1 Top Navigation Bar (Custom AppBar)
*   **Background**: Transparent.
*   **Leading**: Custom "Back" arrow with soft styling.
*   **Actions**: 
    *   `CurrencyChip`: A capsule shape displaying icon and balance.
    *   Layout: `[DiamondChip, SizedBox(width: 8), CandyChip]`.

### 3.2 Premium Featured Banner (PageView)
*   **Structure**: A horizontal `PageView` showing `StoreItem` where `iapType == 'subscription'`.
*   **Content**:
    *   **Left**: Illustrative character or item emoji (Scale up).
    *   **Right**: 
        *   "Pro" Badge (Gold background, white text).
        *   Title (Large, bold, dark grey).
        *   Description (Small, dark grey).
        *   Price Button: Wide orange/yellow gradient button with price text.

### 3.3 Category Navigation Row
*   **Layout**: `Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly)`.
*   **Item**: `Column(IconBox, TextLabel)`.
*   **IconBox**: Soft colored square with rounded corners (`16.0`). Icons for Furniture, Themes, Special Packs, Consumables.

### 3.4 Store Item Grid (The Main List)
*   **Layout**: `SliverGrid` with `SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2)`.
*   **Card Design (`StoreGridItemCard`)**:
    *   **Header**: Item Name (Bold, centered).
    *   **Body**: 
        *   Container with soft gradient background.
        *   Large Emoji or Image Asset in center.
    *   **Footer**:
        *   `Row(CurrencyIcon, PriceText, Spacer, BuyButton)`.
        *   `BuyButton`: Small capsule button labeled "購入" (or l10n equivalent).

## 4. Implementation Strategy

### Phase 1: Layout Foundation
*   Convert `StoreView` body to `CustomScrollView`.
*   Implement `StoreBackgroundWrapper` using `BoxDecoration` with the specified multi-stop gradient.
*   Setup `SliverAppBar` with transparent background and custom currency chips.

### Phase 2: Refactoring Widgets
*   **`StoreFeaturedBanner`**: Implement the `PageView` using existing `_subscriptionItems`.
*   **`StoreCategoryRow`**: Implement the static navigation row. Use `_jumpToSection` logic for scrolling.
*   **`StoreGridItemCard`**: Create a new widget that replaces the list-style cards. It must handle both Currency (Coin/Diamond) and IAP (Price String) items.

### Phase 3: Wiring & Cleanup
*   Map `_furnitureItems`, `_themeItems`, and `_premiumUtilityItems` into the `SliverGrid`.
*   Ensure `RefreshIndicator` wraps the `CustomScrollView`.
*   Maintain `AdMobBannerSlot` and `StoreLegalLinksRow` at the bottom.

## 5. Mapping Existing Logic
*   **Price**: Use `item.priceCoins`, `item.priceDiamonds`, or `item.localizedIapPrice()`.
*   **Actions**:
    *   Coin Purchase: `_purchaseItem(item)`
    *   Diamond Purchase: `_purchaseDiamondItem(item)`
    *   IAP Purchase: `_purchaseIapItem(item)`
*   **Ownership**: Use `_isItemOwned(item)` to show "Owned" state instead of the price button.

## 6. Technical Constraints
*   **UI Framework**: Flutter (existing project standards).
*   **Styling**: Use `AppTheme` colors where possible, but allow overrides for the specific Store palette.
*   **Performance**: Ensure the background gradient doesn't cause lag during scrolling (use `RepaintBoundary` if needed).
