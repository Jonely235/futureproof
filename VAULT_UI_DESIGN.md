# Vault UI Redesign - Detailed Design Specifications

## Screen Architecture Overview

```
┌─────────────────────────────────────────┐
│         VaultBrowserScreen              │  ← Main entry point
│  (Clean, focused vault selection)       │
├─────────────────────────────────────────┤
│  • Adaptive list/grid view             │
│  • Tap to activate                      │
│  • "Create New Vault" button            │
│  • "Manage Vaults" button               │
└──────────────┬──────────────────────────┘
               │
       ┌───────┴───────┐
       ▼               ▼
┌──────────────┐  ┌─────────────────────┐
│   Create     │  │   VaultManagement   │
│   (Modal)    │  │   (Advanced Ops)    │
└──────────────┘  └─────────────────────┘
```

---

## Screen 1: VaultBrowserScreen

### Purpose
Simple, focused vault browsing and activation. No advanced features.

### Layout

```
┌────────────────────────────────────────────┐
│  ← Back        Vaults         ⋮ More      │  ← AppBar (minimal)
├────────────────────────────────────────────┤
│                                            │
│  ┌──────────────────────────────────────┐ │
│  │  👤  Personal Finances       ACTIVE  │ │  ← Active vault
│  │  💰  12 transactions    2 days ago   │ │     (gradient border)
│  └──────────────────────────────────────┘ │
│                                            │
│  ┌──────────────────────────────────────┐ │
│  │  💼  Business Finances               │ │
│  │  💰  8 transactions    1 week ago   │ │
│  └──────────────────────────────────────┘ │
│                                            │
│  ┌──────────────────────────────────────┐ │
│  │  📁  Custom Vault                   │ │
│  │  💰  0 transactions    Just now     │ │
│  └──────────────────────────────────────┘ │
│                                            │
│  ┌──────────────────────────────────────┐ │
│  │  👨‍👩‍👧‍👦  Family Budget                 │ │
│  │  💰  25 transactions   3 days ago   │ │
│  └──────────────────────────────────────┘ │
│                                            │
├────────────────────────────────────────────┤
│                                            │
│  ┌──────────────────────────────────────┐ │
│  │      + Create New Vault              │ │  ← Primary CTA
│  └──────────────────────────────────────┘ │  (fintechTeal, prominent)
│                                            │
│  [        Manage Vaults        ]          │  ← Secondary action
│  (outlined button, less prominent)          │
│                                            │
└────────────────────────────────────────────┘
```

### Features
- **Header**: Minimal, just back button and title
- **Vault List**: Adaptive layout
  - 1-3 vaults: Large hero cards
  - 4-6 vaults: List view
  - 7+ vaults: Grid view (2 cols mobile, 3 tablet)
- **Card Interaction**:
  - Tap to activate (switches active vault)
  - No long-press menus
  - No swipe actions
  - No drag handle
- **Create Button**: Large, prominent, bottom of screen
- **Manage Button**: Outlined, secondary, below create button

### Colors & Styling
- Background: `offWhite` (#FAFAFA)
- Active vault border: `fintechTeal` (#00BFA5) with gradient
- Active vault badge: `fintechTeal` gradient background
- Create button: `fintechTeal` background, white text
- Manage button: Outlined, `fintechTeal` border

### Transitions
- Opening: Fade in + slide up (300ms)
- Card tap: Scale down (0.97) + haptic feedback
- Active vault: Subtle pulse animation on badge

---

## Screen 2: VaultManagementScreen

### Purpose
Advanced vault operations: search, filter, sort, reorder, edit, delete.

### Layout

```
┌────────────────────────────────────────────┐
│  ← Back    Manage Vaults    [Search 🔍]   │  ← AppBar with search
├────────────────────────────────────────────┤
│  Filter: [All] [Personal] [Business]...    │  ← Filter chips
│  Sort: Name ▾  View: ☷  ☰                │  ← Sort + view toggle
├────────────────────────────────────────────┤
│                                            │
│  ┌──────────────────────────────────────┐ │
│  │ ⋮⋮  👤  Personal Finances    ✏️ 🗑️ │ │  ← Drag handle + actions
│  │     💰  12 transactions    2 days ago│ │     (visible icons)
│  └──────────────────────────────────────┘ │
│  ← Swipe left to delete →                 │
│                                            │
│  ┌──────────────────────────────────────┐ │
│  │ ⋮⋮  💼  Business Finances    ✏️ 🗑️ │ │
│  │     💰  8 transactions    1 week ago │ │
│  └──────────────────────────────────────┘ │
│  ← Swipe left to delete →                 │
│                                            │
│  ┌──────────────────────────────────────┐ │
│  │ ⋮⋮  📁  Custom Vault         ✏️ 🗑️ │ │
│  │     💰  0 transactions    Just now  │ │
│  └──────────────────────────────────────┘ │
│  ← Swipe left to delete →                 │
│                                            │
└────────────────────────────────────────────┘
```

### Features
- **Header**: Back button + title + search button
- **Search Bar** (when search tapped):
  - Expands below header
  - 300ms debounce
  - Real-time filtering
- **Filter Chips**:
  - Horizontal scrolling
  - All, Personal, Business, Family, Custom
  - Active chip: `fintechTeal` background
- **Sort Dropdown**:
  - Name (A-Z, Z-A)
  - Created (newest, oldest)
  - Modified (recent, least recent)
  - Transactions (most, least)
  - Custom order
- **View Toggle**:
  - List icon / Grid icon
  - Remembers last selection
- **Vault Cards**:
  - Drag handle on left (⋮⋮)
  - Edit icon (✏️)
  - Delete icon (🗑️)
  - Swipe left to delete
  - Long-press for drag mode
- **Empty State**:
  - "No vaults found"
  - Clear filters button

### Interactions
- **Drag to reorder**: Long press or drag handle
- **Swipe to delete**: Swipe left, confirm delete
- **Edit vault**: Tap edit icon → VaultEditScreen
- **Search**: Tap search icon → search bar expands
- **Filter**: Tap chip → filters vaults

### Haptic Feedback
- Long press start: Light impact
- Drag start: Medium impact
- Delete confirmed: Heavy impact
- Filter tapped: Light impact

---

## Screen 3: VaultCreationScreen (REDESIGNED)

### Purpose
Create new vault with improved visual design and progressive disclosure.

### Presentation
- Modal bottom sheet (draggable)
- Height: 80% of screen (scrollable if needed)
- Animation: Slide up + fade (300ms)

### Layout

```
┌────────────────────────────────────────────┐
│  ═══════════════════════════════════════   │  ← Drag handle
│  Create New Vault                  ✕       │  ← Close button
├────────────────────────────────────────────┤
│                                            │
│  ┌────────────────────────────────────┐   │
│  │  👤  Personal Finances    ACTIVE   │   │  ← Live preview card
│  │  💰  0 transactions    Just now    │   │     (updates as you type)
│  └────────────────────────────────────┘   │
│                                            │
│  ▼ Basic Information (expanded)           │  ← Collapsible section
│  ┌──────────────────────────────────────┐ │
│  │  Vault Name                          │ │
│  │  ┌────────────────────────────────┐ │ │
│  │  │ My Personal Finances           │ │ │
│  │  └────────────────────────────────┘ │ │
│  │                                      │ │
│  │  Vault Type                         │ │
│  │  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐  │ │
│  │  │ 👤  │ │ 💼  │ │ 👨‍👩‍👧‍👦 │ │ 📁  │  │ │  ← Card selector
│  │  │Pers.│ │Bus. │ │Fam. │ │Cus.│  │ │     (with icons)
│  │  └─────┘ └─────┘ └─────┘ └─────┘  │ │
│  └──────────────────────────────────────┘ │
│                                            │
│  ▶ Appearance (collapsed)                 │  ← Collapsible sections
│  ▶ Settings (collapsed)                   │
│                                            │
├────────────────────────────────────────────┤
│  [ Cancel ]           [ Create Vault → ]   │  ← Action buttons
└────────────────────────────────────────────┘
```

### Expanded Section: "Appearance"

```
┌────────────────────────────────────────────┐
│  ▼ Appearance                              │
│  ┌──────────────────────────────────────┐ │
│  │  Accent Color                         │ │
│  │  ┌──┐ ├──┐ ├──┐ ├──┐ ├──┐ ├──┐ ├──┐ │ │  ← Color picker
│  │  │  │ │  │ │  │ │  │ │  │ │  │ │ │     (8 colors)
│  │  └──┘ └──┘ └──┘ └──┘ └──┘ └──┘ └──┘ │ │
│  └──────────────────────────────────────┘ │
│  ┌──────────────────────────────────────┐ │
│  │  Icon                                 │ │
│  │  ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ...│ │  ← Icon picker
│  │  │📁│ │💰│ │💎│ │🚀│ │⭐│ │🔥│ │  │ │     (16 icons)
│  │  └──┘ └──┘ └──┘ └──┘ └──┘ └──┘ └──┘ │ │
│  └──────────────────────────────────────┘ │
└────────────────────────────────────────────┘
```

### Expanded Section: "Settings"

```
┌────────────────────────────────────────────┐
│  ▼ Settings                                │
│  ┌──────────────────────────────────────┐ │
│  │  Monthly Income (Optional)            │ │
│  │  ┌────────────────────────────────┐ │ │
│  │  │ $ 5000.00                      │ │ │
│  │  └────────────────────────────────┘ │ │
│  └──────────────────────────────────────┘ │
│  ┌──────────────────────────────────────┐ │
│  │  Savings Goal (Optional)             │ │
│  │  ┌────────────────────────────────┐ │ │
│  │  │ $ 1000.00                      │ │ │
│  │  └────────────────────────────────┘ │ │
│  └──────────────────────────────────────┘ │
└────────────────────────────────────────────┘
```

### Features
- **Live Preview Card**:
  - Shows vault card as it will appear
  - Updates in real-time as user types
  - Selected type icon, color shown
  - Name updates as user types
- **Vault Type Selector**:
  - Cards (not radio buttons)
  - Large emoji icons
  - Type name below icon
  - Selected card: `fintechTeal` border
  - 4 cards in horizontal row
- **Collapsible Sections**:
  - "Basic Information": Expanded by default
  - "Appearance": Collapsed (color, icon pickers)
  - "Settings": Collapsed (income, savings)
  - Chevron rotates when expanded
- **Color Picker**:
  - 8 circles (reuse from VaultEditScreen)
  - Selected color: white checkmark
  - Changes preview card border color
- **Icon Picker**:
  - 16 emoji icons in grid
  - Selected icon: `fintechTeal` border
  - Changes preview card icon
- **Form Validation**:
  - Name required (min 2 chars)
  - Type required
  - Optional fields: Income, savings, color, icon

### Colors & Styling
- Modal background: White with top shadow
- Selected type card: `fintechTeal` border (2px)
- Create button: `fintechTeal` background
- Cancel button: Outlined, gray border
- Section header: Collapsed = gray chevron right, Expanded = fintechTeal chevron down

### Transitions
- Opening: Slide up + fade (300ms easeOut)
- Section expand: Height animation + chevron rotate (300ms)
- Type selection: Scale down (0.95) + color fade (150ms)
- Color/icon selection: Scale up (1.1) + bounce back (200ms)

---

## Navigation Flow

```
                    App Launch
                         ↓
            ┌───────────────────────┐
            │  VaultBrowserScreen   │  ← Entry point
            │  (Clean list view)     │
            └───────────┬───────────┘
                        │
        ┌───────────────┼───────────────┐
        │               │               │
   Create Vault   Manage Vaults   Tap Vault
        │               │               │
        ↓               ↓               ↓
  ┌──────────┐  ┌──────────────┐  Switch active
  │ Creation │  │ManagementScr │  vault, return
  │  Modal   │  │              │  to home screen
  └─────┬────┘  └──────┬───────┘
        │              │
        │         Edit │
        │         Vault │
        │              ↓
        │    ┌──────────────┐
        │    │VaultEditScreen│
        │    └───────────────┘
        │
        ↓
   New vault created
        │
        ↓
   Return to browser
```

---

## Component Reuse

### Existing Components (Reuse As-Is)
- `VaultCardWidget` - Excellent design, use in browser
- `VaultGridView` - Responsive grid, use in management
- `VaultTypeFilter` - Filter chips, use in management
- `VaultSearchBar` - Search with debounce, use in management
- Color picker - From VaultEditScreen
- Icon picker - From VaultEditScreen

### New Components to Create
- `VaultBrowserScreen` - New simplified list view
- `VaultManagementScreen` - New advanced management view
- Redesigned `VaultCreationScreen` - Keep filename, improve content

### Components to Modify
- Navigation routing to point to VaultBrowserScreen instead of VaultListScreen

---

## Design Specifications

### Spacing
- Card padding: 16px
- Card margin: 16px horizontal, 8px vertical
- Section spacing: 24px
- Button padding: 16px horizontal, 12px vertical

### Border Radius
- Cards: 16px
- Buttons: 12px
- Modal: 20px (top corners)
- Type selector cards: 12px

### Typography
- Screen titles: Playfair Display, 24px, w600
- Section headers: Space Grotesk, 14px, w600, gray700
- Card titles: Space Grotesk, 17px, w700, black
- Card subtitles: Space Grotesk, 13px, w500, gray700
- Card details: Space Grotesk, 12px, gray700

### Colors
- Primary: `fintechTeal` (#00BFA5)
- Background: `offWhite` (#FAFAFA)
- Card background: White
- Active vault border: `fintechTeal` gradient
- Selected state: `fintechTeal` with 0.1 opacity background
- Text: black, gray700, gray500

### Icons
- Create: `Icons.add`
- Manage: `Icons.settings` or `Icons.tune`
- Edit: `Icons.edit`
- Delete: `Icons.delete`
- Search: `Icons.search`
- Sort: `Icons.sort`
- Grid view: `Icons.grid_view`
- List view: `Icons.view_list`
- Drag handle: `Icons.drag_handle` or `Icons.drag_indicator`
- Expand: `Icons.expand_more`
- Collapse: `Icons.chevron_right`

### Animations
- Standard duration: 300ms
- Curve: easeInOut
- Stagger: 50ms increments (list items)
- Haptic:
  - Light impact: Button taps
  - Medium impact: Long press, selection
  - Heavy impact: Destructive actions

---

## Success Metrics

### Usability Goals
- New vault creation: < 30 seconds (from entry to creation)
- Vault activation: 1 tap (current: 1 tap ✓)
- Find vault in management: < 5 seconds (with search/filter)
- Learn to use: No tutorial needed (intuitive)

### Performance Goals
- Screen transitions: < 300ms
- List rendering: 60fps with 100+ vaults
- Search response: < 100ms (after debounce)
- Filter response: Instant

### UX Goals
- Cognitive load: Reduced (separate screens)
- Visual hierarchy: Clear (primary vs secondary actions)
- Discoverability: Improved (obvious button purposes)
- Consistency: Matches design system throughout

---

## Implementation Priority

### Phase 1: Quick Wins (2-3 hours)
1. Create VaultBrowserScreen (simplified list)
2. Update navigation to use browser screen
3. Add create/manage buttons to browser

### Phase 2: Management Screen (2-3 hours)
1. Create VaultManagementScreen
2. Add search, filter, sort functionality
3. Implement drag-to-reorder
4. Add swipe-to-delete

### Phase 3: Improved Creation (2-3 hours)
1. Redesign VaultCreationScreen with modal
2. Add live preview card
3. Implement card-based type selector
4. Add collapsible sections
5. Add color/icon pickers

### Phase 4: Polish (1-2 hours)
1. Test all flows
2. Add animations
3. Haptic feedback
4. Edge cases (empty states, etc.)

**Total Estimate: 7-11 hours**
