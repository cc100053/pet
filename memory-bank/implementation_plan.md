# UI/UX Refinement Implementation Plan

## Goal
Refine the application's UI/UX to achieve a "premium", "dynamic", and "polished" look without altering core functionality. The focus is on visual aesthetics: consistency, glassmorphism impacts, softer layouts, and better typography.

## Design System Update
- **Theme**: Move from basic `Colors.teal` seed to a custom `AppTheme` with defined color palettes (Primary, Secondary, Surface, Background).
- **Typography**: Ensure consistent use of text styles (Headings, Body, Captions) with a modern font if possible (using Google Fonts or default high-quality system fonts).
- **Shapes**: Unified border radius (e.g., `24.0` for large containers, `16.0` for cards).

## Component Breakdown

### 1. Global Theme & App Structure (`lib/app/app.dart`, `lib/shared/theme/`)
- [NEW] Create `lib/shared/theme/app_theme.dart` to house the design system constants.
- [MODIFY] `lib/app/app.dart` to use the new theme.

### 2. Left-Side Options List (Drawer) (`lib/features/home/home_view.dart`)
- **Current**: Standard `Drawer` with `ListTile`.
- **New**:
  - Custom container with rounded top-right/bottom-right corners.
  - User profile section with a large avatar and "premium" background.
  - Room list as clear, separated cards rather than a flat list.
  - New "Add Room" button styling.
  - Apply glassmorphism or a subtle gradient background.

### 3. Chat Interface (`lib/features/chat/`)
- **Chat Bubbles**:
  - "Me": Gradient background, rounded corners (with "tail" effect or just bubbles).
  - "Others": Clean white/light grey, subtle shadow.
  - Typography: Clearer contrast.
- **Input Area**:
  - Change from standard bottom bar to a "Floating Island" or "Glass Bar" design.
  - Style the "Camera" button to be grander (as it's the core interaction).
- **Background**: Add a subtle wallpaper or gradient behind the chat.

### 4. Store & Related Features (`lib/features/store/store_view.dart`)
- **Cards**: Replace basic Card widgets with "Premium Cards" (elevation, gradient stroke/border, badging).
- **Layout**: distinct sections for "Consumables" vs "Cosmetics".
- **Purchase Button**: Sticky or prominent "Buy" buttons with haptic feedback visual cues (scale on press).

### 5. Image Selection & Dialogs
- **Dialogs**: Global clean-up of `showDialog` to use a custom styled dialog (rounded, blur backdrop).
- **Image Preview**: enhance the "Feeding" preview modal.

## Execution Steps
1.  **Setup Theme**: Create `app_theme.dart` and apply it.
2.  **Refactor Drawer**: Update `HomeView` drawer.
3.  **Refactor Chat**: Update `ChatRoomView` and message bubbles.
4.  **Refactor Store**: Update `StoreView`.
5.  **Polishing**: Review input fields and dialogs.

## Verification
- **Visual Check**: Run the app (mental check of code changes since I cannot run it) to ensure no widget overflow or broken constraints.
- **Code Consistency**: Ensure all new widgets use the constants from `AppTheme`.
