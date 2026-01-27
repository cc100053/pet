# Pet Level System

## Core Concept
The pet gains Experience Points (EXP) through interactions (specifically feeding) and levels up when enough EXP is accumulated. This creates a sense of progression and rewards regular engagement.

## Parameters

### Level Cap
- **Max Level**: 999

### Difficulty & Progression
- **Formula**: `XP_REQUIRED_FOR_NEXT_LEVEL = 50 * Current_Level`
    - Level 1 -> 2: Requires **50 XP**
    - Level 2 -> 3: Requires **100 XP**
    - Level 3 -> 4: Requires **150 XP**
    - ...
    - Level N -> N+1: Requires `50 * N` XP

### Rewards & Actions
- **Feed**: Grants **10 XP** (and 10 Coins).
- **Other Actions**: (To be determined if Clean/Touch also grant XP, currently defaulting to Feed).

### Cooldowns
- XP gain shares the **same cooldown** as Coin rewards.
- **Rule**: 1 Hour Cooldown per action type per room.
- If a user feeds the pet within the cooldown period:
    - No Coins granted.
    - No XP granted.

## UI/UX Requirements
### EXP Display
- **Location**: Top Left of the Pet View Screen (Home View).
- **Style**: **Circular Progress Bar**.
- **Placement**: The progress bar should circle *around* the Pet Icon/Avatar.
- **Visuals**:
    - The circle fills up as EXP is gained towards the next level.
    - When Level Up occurs, the bar resets (and potentially shows a visual celebration).
    - Current Level should be visible (likely near or on the icon).
