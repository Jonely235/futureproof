# FutureProof Improvement Tasks

> **Created**: 2026-01-10
> **Status**: Active Development
> **Focus**: Bug Fixes & UI Improvements

---

## 🎯 Current Issues (Priority)

### 🔴 CRITICAL BUGS

#### Bug #1: Settings Save Button Not Working
**Status**: 🔴 Open
**Priority**: CRITICAL
**Location**: `lib/screens/settings_screen.dart`

**Problem**:
- Users cannot save their settings (monthly income, savings goal, category budgets)
- Save button appears non-functional
- Settings are not persisted to SharedPreferences

**Impact**:
- Users cannot set their income or savings goals
- Budgets cannot be configured
- App cannot calculate accurate financial status

**Root Cause**:
Likely issues:
- Missing `SharedPreferences` save logic
- Save button not connected to save function
- No feedback on save success/failure

**Fix Required**:
1. Add save logic to persist settings to SharedPreferences
2. Show success/error message when saving
3. Validate inputs before saving
4. Refresh providers after save to update calculations

**Estimated Time**: 30-60 minutes

---

#### Bug #2: Transactions Not Auto-Refreshing After Adding
**Status**: 🔴 Open
**Priority**: CRITICAL
**Location**: `lib/screens/add_expense_screen.dart`, `lib/providers/transaction_provider.dart`

**Problem**:
- After adding a new expense, the transaction list doesn't update
- User must manually refresh or restart app to see new transaction
- Affects both Home screen and Transaction History screen

**Impact**:
- Users think the app isn't working
- Can't see if transaction was actually added
- Poor user experience

**Root Cause**:
TransactionProvider not notifying listeners after add, or screens not watching provider correctly

**Fix Required**:
1. Ensure `TransactionProvider.addTransaction()` calls `notifyListeners()`
2. Screens should use `context.watch<TransactionProvider>()`
3. Show loading indicator during add
4. Navigate back after successful add with refresh

**Estimated Time**: 30-45 minutes

---

### 🟨 UI IMPROVEMENTS

#### Issue #3: UI is Ugly - Design Overhaul Needed
**Status**: 🟨 Open
**Priority**: HIGH
**Location**: All screens

**Problems**:
- Outdated Material Design 2 look
- Inconsistent styling across screens
- Poor color scheme
- Cramped layouts
- No visual hierarchy
- Boring/standard widgets

**Required Improvements**:

**1. Overall Design System:**
- [ ] Implement modern Material Design 3 (Material You)
- [ ] Create consistent color scheme (warm, friendly colors)
- [ ] Better typography (clear font hierarchy)
- [ ] Proper spacing and padding
- [ ] Rounded corners, cards, shadows
- [ ] Smooth animations and transitions

**2. Home Screen (`lib/screens/home_screen.dart`):**
- [ ] Better hero section with gradient background
- [ ] Animated "Are We Okay?" button
- [ ] Show recent transactions preview
- [ ] Quick stats cards (income, expenses, savings rate)
- [ ] Better financial status dialog with charts
- [ ] Bottom navigation bar improvement

**3. Add Expense Screen (`lib/screens/add_expense_screen.dart`):**
- [ ] Better category picker with icons and colors
- [ ] Amount input with currency formatting
- [ ] Date/time picker that's easy to use
- [ ] Note input with character counter
- [ ] Clear submit/cancel buttons
- [ ] Form validation with helpful error messages
- [ ] Success animation after adding

**4. Transaction History (`lib/screens/transaction_history_screen.dart`):**
- [ ] Card-based transaction list
- [ ] Group by date with headers
- [ ] Swipe to delete with undo
- [ ] Filter by category
- [ ] Search functionality
- [ ] Pull to refresh
- [ ] Empty state illustration

**5. Analytics Screen (`lib/screens/analytics_dashboard_screen.dart`):**
- [ ] Better charts with proper colors
- [ ] Interactive graphs
- [ ] Summary cards at top
- [ ] Insights section with icons
- [ ] Budget progress bars

**6. Settings Screen (`lib/screens/settings_screen.dart`):**
- [ ] Grouped settings sections
- [ ] Better input fields
- [ ] Clear save button with loading state
- [ ] Success/error feedback
- [ ] Info icons explaining each setting

**Color Palette Proposal:**
```dart
// Primary: Friendly Blue
primary: Color(0xFF4A90E2)
primaryDark: Color(0xFF357ABD)

// Secondary: Warm Orange (for actions)
secondary: Color(0xFFFF9800)

// Success: Green
success: Color(0xFF4CAF50)

// Warning: Orange
warning: Color(0xFFFF9800)

// Error: Red
error: Color(0xFFF44336)

// Background: Off-white
background: Color(0xFFF5F5F5)
surface: Color(0xFFFFFFFF)

// Text
textPrimary: Color(0xFF212121)
textSecondary: Color(0xFF757575)
```

**Estimated Time**: 4-6 hours

---

## 📋 All Tasks Summary

### Phase 1: Critical Bug Fixes (1-2 hours)
- [ ] **Task 1.1**: Fix Settings Save Button (30-60 min)
  - Implement SharedPreferences save logic
  - Add validation and error handling
  - Show user feedback (snackbar/toast)

- [ ] **Task 1.2**: Fix Transaction Auto-Refresh (30-45 min)
  - Fix TransactionProvider notifyListeners
  - Update screens to watch provider
  - Add loading indicators
  - Test add → view flow

### Phase 2: UI/UX Redesign (4-6 hours)
- [ ] **Task 2.1**: Design System & Color Scheme (30 min)
  - Define app theme with Material 3
  - Create color palette
  - Set up typography
  - Add consistent spacing/padding

- [ ] **Task 2.2**: Redesign Home Screen (60 min)
  - New hero section with gradient
  - Animated financial status button
  - Quick stats cards
  - Recent transactions preview
  - Better bottom navigation

- [ ] **Task 2.3**: Redesign Add Expense Screen (45 min)
  - Modern form layout
  - Category picker with icons
  - Better amount input
  - Improved date picker
  - Validation and feedback
  - Success animation

- [ ] **Task 2.4**: Redesign Transaction History (60 min)
  - Card-based list
  - Date grouping
  - Swipe actions (delete/undo)
  - Pull to refresh
  - Empty state
  - Search/filter

- [ ] **Task 2.5**: Redesign Analytics Dashboard (60 min)
  - Better charts
  - Summary cards
  - Interactive graphs
  - Insights with icons
  - Budget progress bars

- [ ] **Task 2.6**: Redesign Settings Screen (45 min)
  - Grouped sections
  - Better inputs
  - Clear save button
  - User feedback
  - Explanatory tooltips

- [ ] **Task 2.7**: Add Animations & Transitions (30 min)
  - Page transitions
  - Button animations
  - Loading spinners
  - Success animations
  - Smooth list scrolling

### Phase 3: Polish & Testing (1-2 hours)
- [ ] **Task 3.1**: Test all user flows
  - Add expense → view in history
  - Change settings → verify save
  - Check financial status
  - Test analytics display

- [ ] **Task 3.2**: Fix any remaining bugs
  - Address issues found during testing
  - Edge cases
  - Error handling

- [ ] **Task 3.3**: Performance optimization
  - Reduce build size
  - Improve app startup time
  - Smooth animations (60 FPS)

- [ ] **Task 3.4**: Final testing on device
  - Test on actual iPhone
  - Verify all features work
  - Check for crashes

---

## 🎯 Success Criteria

### Must Have (MVP):
- ✅ Settings save and persist
- ✅ Transactions appear immediately after adding
- ✅ Modern, clean UI that looks professional
- ✅ Consistent styling across all screens
- ✅ Smooth user experience

### Nice to Have:
- Beautiful animations
- Delightful micro-interactions
- Advanced filtering/search
- Custom themes
- Dark mode enhancement

---

## 📊 Progress Tracking

**Total Tasks**: 17
**Completed**: 0
**In Progress**: 0
**Pending**: 17

**Estimated Total Time**: 6-9 hours

---

## 🔗 Related Files

**Bug Fixes:**
- `lib/screens/settings_screen.dart` - Settings save logic
- `lib/providers/transaction_provider.dart` - State management
- `lib/screens/add_expense_screen.dart` - Add expense flow
- `lib/screens/home_screen.dart` - Home screen refresh

**UI Redesign:**
- `lib/main.dart` - App theme configuration
- `lib/screens/home_screen.dart` - Home screen
- `lib/screens/add_expense_screen.dart` - Add expense
- `lib/screens/transaction_history_screen.dart` - History
- `lib/screens/analytics_dashboard_screen.dart` - Analytics
- `lib/screens/settings_screen.dart` - Settings

---

**Next Steps:**
1. Fix the two critical bugs first
2. Test and verify fixes work
3. Build new iOS release with fixes
4. Then start UI redesign
5. Test thoroughly and release final version

**Let's make FutureProof amazing!** 🚀
