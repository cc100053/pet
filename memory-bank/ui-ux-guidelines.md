# UI/UX Design Guidelines: Juice UI System

This document defines the high-fidelity game-style UI system for PicPet. AI agents MUST strictly adhere to these specifications to ensure visual and interactive consistency.

---

## 1. Interaction Principles (The "Juicy" Feel)

### 1.1 Responsive Actions
- **Instant Feedback Rule**: `onTap` callbacks MUST trigger business logic (navigation, state changes, etc.) **synchronously and immediately** upon finger release.
- **Concurrent Animation**: Do NOT await animations (squish/pop/bouncy effects) before executing code logic. Let the animation play in the background.

### 1.2 Bouncy Buttons (`JuicyScaleButton`)
- **Usage**: Mandatory for ALL clickable elements.
- **Haptics**:
    - Tap Down: `HapticFeedback.lightImpact()`
    - Tap Up/Release: `HapticFeedback.mediumImpact()`

---

## 2. Visual Specifications

### 2.1 Styling Constants
- **Borders**: Solid black (`Colors.black`).
    - Primary (Cards/Main Buttons): `width: 2.0` to `3.0`.
    - Secondary: `width: 1.0` to `1.5`.
- **Corner Radius**:
    - Large Cards/Toasts: `BorderRadius.circular(32)`.
    - Dialogs/Action Buttons: `BorderRadius.circular(16)`.
- **Backgrounds**: Soft cream gradients.
    - Start: `Colors.white`
    - End: `Color(0xFFFFF7EA)`
- **Shadows (Depth)**: Use `BoxShadow` for a modern 3D floating effect.
    - **Do NOT** use solid colored blocks for button bottoms.
    - **Specs**: `color: Colors.black.withValues(alpha: 0.15)`, `offset: Offset(0, 4)`, `blurRadius: 4`.

### 2.2 Typography
- **Font Family**: Primary: `GoogleFonts.mPlusRounded1c`.
- **Weights**:
    - Headings/Action Labels: `FontWeight.w900` (Black).
    - Body/Hints: `FontWeight.w700` (Bold) or `w800`.

---

## 3. Feedback & Dialog Systems

### 3.1 Blocking UI (`showJuiceToast`)
Used for critical errors, warnings, confirmations, and inputs. Requires user action or explicit dismissal.
- **Positions**:
    - `JuicePosition.center`: For complex inputs (using `body`), IAP previews, and critical "Yes/No" confirmations.
    - `JuicePosition.bottom`: Standard alerts and warnings.
- **Animations**:
    - Entry: Bouncy scale/slide with `Curves.easeOutBack`.
    - Exit: Symmetrical fade and slide/scale with `reverseCurve: Curves.easeInBack`.

### 3.2 Non-Blocking UI (`showJuiceSnackbar`)
Used for positive reinforcement (Success, Copied).
- **Implementation**: Built using `Overlay`.
- **Behavior**:
    - Does NOT dim the background.
    - Does NOT block user interaction with elements behind it.
    - Auto-dismisses after 2.5 seconds.

---

## 4. Implementation Patterns

### 4.1 Input Validation in Dialogs
When using `showJuiceToast` for input (e.g., Invite Codes):
1.  Wrap the `body` in a `StatefulBuilder`.
2.  Perform validation inside the `onPressed` or `onSubmitted` handler within the dialog.
3.  Update an internal `errorText` and call `setState` provided by the builder.
4.  **Only** call `Navigator.pop(context, value)` if validation passes.

---

## 5. Color Palette (Tone Mapping)
- **Info**: `AppTheme.primaryColor` (Blue-ish)
- **Success**: `AppTheme.successColor` (Green-ish)
- **Warning**: `AppTheme.secondaryColor` (Orange-ish)
- **Danger**: `AppTheme.errorColor` (Red-ish)
