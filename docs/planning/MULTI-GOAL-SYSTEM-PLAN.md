# FutureProof Multi-Goal System - Implementation Plan

**Created**: January 11, 2026
**Status**: Ready for Implementation
**Goal**: Transform from passive expense tracker to active decision-support system

---

## 🎯 Vision Statement

**From**: "Passive Tracker" (just recording what happened)
**To**: "Active Decision Support System" (helping you decide before you spend)

**The Killer Feature**: When a user tries to add an expense, the app instantly calculates:
> "If you buy this, how does it affect your goal to eat nice food on Friday? How does it affect your House Fund in 5 years?"

---

## 🧠 Core Philosophy

**Old Model**: Income - Expense = Savings
**New Model**: Income - Expense = Goal Allocation

### The Impact Logic

Every expense entry triggers impact calculation across time horizons:

| Time Horizon | Goal Examples | Sensitivity | Impact Display |
|--------------|--------------|-------------|----------------|
| **Short Term** (< 30 days) | Fancy Dinner, Weekend Trip | 🔴 HIGH | "This $50 kills your Friday goal" |
| **Medium Term** (1-12 months) | New iPhone, Vacation | 🟡 MEDIUM | "Delays purchase by 4 days" |
| **Long Term** (> 1 year) | House, Retirement | 🟢 LOW (cumulative) | "5th time you delayed this goal" |

---

## 📦 Phase 1: Data Model & Database

### Objective
Create the foundational data structures to support multiple financial goals with deadlines.

### Tasks

#### Task 1.1: Create FinancialGoal Model
**File**: `lib/models/goal.dart`

```dart
class FinancialGoal {
  final String id;
  final String name;          // e.g., "Omakase Dinner" or "Buy House"
  final double targetAmount;  // e.g., 200.0 or 500000.0
  final double savedAmount;   // How much currently allocated
  final DateTime deadline;    // The "Time Point"
  final String emoji;         // Visual cue (🏠, 🍣, 📱)
  final int priority;         // 1 = Critical, 3 = Nice to have

  // Calculate daily savings needed to reach goal on time
  double get dailySavingsNeeded {
    int daysLeft = deadline.difference(DateTime.now()).inDays;
    if (daysLeft <= 0) return 0;
    return (targetAmount - savedAmount) / daysLeft;
  }

  // Calculate progress percentage
  double get progress {
    if (targetAmount == 0) return 0;
    return (savedAmount / targetAmount).clamp(0.0, 1.0);
  }

  // Determine status
  GoalStatus get status {
    double daily = dailySavingsNeeded;
    double currentSaveRate = /* calculate from income */;

    if (daily <= currentSaveRate) return GoalStatus.onTrack;
    if (daily <= currentSaveRate * 1.5) return GoalStatus.atRisk;
    return GoalStatus.delayed;
  }
}

enum GoalStatus { onTrack, atRisk, delayed }
```

**Verification**:
- Model compiles without errors
- `dailySavingsNeeded` returns correct values for test cases
- `progress` clamps between 0-1

---

#### Task 1.2: Update DatabaseService
**File**: `lib/services/database_service.dart`

**Add Methods**:
```dart
// CRUD operations for goals
Future<void> saveGoal(FinancialGoal goal) async { /* ... */ }
Future<List<FinancialGoal>> getAllGoals() async { /* ... */ }
Future<void> updateGoal(String id, FinancialGoal updated) async { /* ... */ }
Future<void> deleteGoal(String id) async { /* ... */ }
Future<FinancialGoal?> getGoalById(String id) async { /* ... */ }
```

**SQLite Schema**:
```sql
CREATE TABLE goals (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  targetAmount REAL NOT NULL,
  savedAmount REAL DEFAULT 0,
  deadline INTEGER NOT NULL,
  emoji TEXT DEFAULT '🎯',
  priority INTEGER DEFAULT 2
)
```

**Verification**:
- `flutter test` passes for database tests
- Goals persist across app restarts
- Can save/retrieve multiple goals

---

#### Task 1.3: Data Migration
**File**: `lib/services/migration_service.dart`

**Migration Logic**:
1. Check if old `savingsGoal` (single value) exists
2. If exists, create default `FinancialGoal`:
   - Name: "General Savings"
   - Target: old savings goal amount
   - Deadline: DateTime.now().add(Duration(days: 365))
   - Emoji: "💰"
3. Clear old `savingsGoal` preference
4. Save new goal to database

**Verification**:
- Existing users see their old savings goal as a financial goal
- New users start with empty goal list
- No data loss during migration

---

## 🎨 Phase 2: Settings Page Overhaul

### Objective
Redesign settings page to allow users to input multiple goals with deadlines.

### Tasks

#### Task 2.1: Create Goal Manager UI
**File**: `lib/screens/settings_screen.dart`

**New Section Structure**:
```dart
Widget _buildGoalManager() {
  return Column(
    children: [
      // Header: "Your Dream List"
      // Goal List (ListView.builder)
      //   Each goal shows: emoji, name, progress bar, deadline
      //   Swipe to delete
      //   Tap to edit
      // "Add Goal" button (FAB or bottom button)
    ],
  );
}
```

**Goal Card Design**:
```
┌─────────────────────────────────────┐
│ 🏠 Buy House                        │
│ $50,000 / $500,000 (10%)           │
│ ████████░░░░░░░░░░░░░░░░░░░░░░░░  │
│ ⏰ 5 years left                     │
│ 🟢 On Track                         │
└─────────────────────────────────────┘
```

---

#### Task 2.2: Create Add/Edit Goal Modal
**File**: `lib/screens/goal_form_screen.dart`

**Form Fields**:
- **Name**: Text input (e.g., "Weekend Trip")
- **Target Amount**: Currency input (e.g., "$500")
- **Saved So Far**: Currency input (default: 0)
- **Deadline**: Date picker (show "By [date]" format)
- **Priority**: Segmented control (Critical / Normal / Nice to have)
- **Emoji**: Emoji picker (grid of common emojis)

**Validation Logic**:
```dart
String? validateGoal(String name, double target, DateTime deadline) {
  if (name.isEmpty) return "Name required";
  if (target <= 0) return "Target must be positive";
  if (deadline.isBefore(DateTime.now())) return "Deadline must be in future";

  // Check if all goals fit in income
  double totalMonthlyNeeded = calculateTotalMonthlyGoalNeed();
  if (totalMonthlyNeeded > monthlyIncome) {
    return "⚠️ Warning: Goals need $${totalMonthlyNeeded}/month but income is $${monthlyIncome}";
  }

  return null; // Valid
}
```

**Verification**:
- Form validates all fields correctly
- Date picker works on all platforms
- Emoji picker displays properly
- Warning shows for unrealistic goals

---

## 🏠 Phase 3: Home Screen Dashboard

### Objective
Replace static savings display with dynamic goal progress visualization.

### Tasks

#### Task 3.1: Create Goal Carousel
**File**: `lib/screens/home_screen.dart`

**Replace**: "Total Savings" static card
**With**: Horizontal scrolling goal cards

```dart
Widget _buildGoalCarousel() {
  return SizedBox(
    height: 180,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: goals.length,
      itemBuilder: (context, index) {
        return _buildGoalCard(goals[index]);
      },
    ),
  );
}

Widget _buildGoalCard(FinancialGoal goal) {
  return Container(
    width: 280,
    margin: EdgeInsets.only(right: 16),
    child: Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(goal.emoji, style: TextStyle(fontSize: 32)),
                SizedBox(width: 12),
                Expanded(child: Text(goal.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              ],
            ),
            SizedBox(height: 12),
            LinearProgressIndicator(value: goal.progress),
            SizedBox(height: 8),
            Text("\$${goal.savedAmount.toStringAsFixed(0)} / \$${goal.targetAmount.toStringAsFixed(0)}"),
            Spacer(),
            _buildStatusBadge(goal),
          ],
        ),
      ),
    ),
  );
}
```

---

#### Task 3.2: Status Badge Widget
**File**: `lib/widgets/goal_status_badge.dart`

```dart
Widget _buildStatusBadge(FinancialGoal goal) {
  Color color;
  String text;
  IconData icon;

  switch (goal.status) {
    case GoalStatus.onTrack:
      color = Colors.green;
      text = "🟢 On Track";
      icon = Icons.check_circle;
      break;
    case GoalStatus.atRisk:
      color = Colors.orange;
      text = "🟡 At Risk";
      icon = Icons.warning;
      break;
    case GoalStatus.delayed:
      color = Colors.red;
      text = "🔴 Delayed";
      icon = Icons.error;
      break;
  }

  return Row(
    children: [
      Icon(icon, size: 16, color: color),
      SizedBox(width: 4),
      Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    ],
  );
}
```

**Verification**:
- Carousel scrolls smoothly
- All goals display correctly
- Status badges show accurate colors
- Progress bars update in real-time

---

## ⚡ Phase 4: Impact Calculator Service

### Objective
Build the logic engine that calculates spending impact on goals.

### Tasks

#### Task 4.1: Create GoalImpact Model
**File**: `lib/models/goal_impact.dart`

```dart
class GoalImpact {
  final String goalId;
  final String goalName;
  final double remainingAmount;
  final int daysUntilDeadline;
  final double dailySavingsNeeded;
  final double impactAmount;  // How much this expense delays the goal
  final int daysDelayed;      // How many DAYS this expense adds
  final ImpactLevel level;    // SAFE, WARNING, CRITICAL

  String get warningMessage {
    switch (level) {
      case ImpactLevel.safe:
        return "✅ Safe to spend! Your goals are on track.";
      case ImpactLevel.warning:
        return "⚠️ This will delay '$goalName' by $daysDelayed days.";
      case ImpactLevel.critical:
        return "🚨 STOP! You'll be short \$${impactAmount.toStringAsFixed(0)} for '$goalName'.";
    }
  }
}

enum ImpactLevel { safe, warning, critical }
```

---

#### Task 4.2: Create GoalCalculator Service
**File**: `lib/services/goal_calculator.dart`

**Core Algorithm**:
```dart
class GoalCalculator {
  final double monthlyIncome;
  final List<FinancialGoal> goals;
  final double currentMonthExpenses;

  // Calculate "free cash flow" for current month
  double get freeCashFlow {
    double totalGoalNeeds = goals.fold(0, (sum, g) => sum + g.dailySavingsNeeded * 30);
    return monthlyIncome - currentMonthExpenses - totalGoalNeeds;
  }

  // Main impact calculation
  List<GoalImpact> calculateImpact(double expenseAmount) {
    List<GoalImpact> impacts = [];

    for (var goal in goals) {
      double remaining = goal.targetAmount - goal.savedAmount;
      int daysLeft = goal.deadline.difference(DateTime.now()).inDays;

      if (daysLeft <= 0) continue; // Skip expired goals

      double dailyNeeded = remaining / daysLeft;

      // How much does this expense reduce our daily saving capacity?
      double reducedDailyCapacity = expenseAmount / 30; // Amortize over month
      double newDailyCapacity = dailyNeeded - reducedDailyCapacity;

      int daysDelayed = 0;
      if (newDailyCapacity < 0) {
        // We can't save anything now!
        daysDelayed = daysLeft; // Infinite delay
      } else {
        double newDaysNeeded = remaining / newDailyCapacity;
        daysDelayed = (newDaysNeeded - daysLeft).round();
      }

      ImpactLevel level = _determineLevel(goal, daysDelayed, expenseAmount);

      impacts.add(GoalImpact(
        goalId: goal.id,
        goalName: goal.name,
        remainingAmount: remaining,
        daysUntilDeadline: daysLeft,
        dailySavingsNeeded: dailyNeeded,
        impactAmount: expenseAmount,
        daysDelayed: daysDelayed,
        level: level,
      ));
    }

    // Sort: CRITICAL first, then WARNING, then SAFE
    impacts.sort((a, b) => a.level.index.compareTo(b.level.index));

    return impacts;
  }

  ImpactLevel _determineLevel(FinancialGoal goal, int daysDelayed, double expenseAmount) {
    double remaining = goal.targetAmount - goal.savedAmount;
    int daysLeft = goal.deadline.difference(DateTime.now()).inDays;

    // Short-term goals (< 30 days): HIGH sensitivity
    if (daysLeft < 30) {
      if (expenseAmount > remaining * 0.5) return ImpactLevel.critical;
      if (expenseAmount > remaining * 0.2) return ImpactLevel.warning;
    }

    // Medium-term goals (1-12 months): MEDIUM sensitivity
    if (daysLeft < 365) {
      if (daysDelayed > 14) return ImpactLevel.critical;
      if (daysDelayed > 7) return ImpactLevel.warning;
    }

    // Long-term goals: LOW sensitivity (but warn if cumulative)
    if (daysDelayed > 30) return ImpactLevel.warning;

    return ImpactLevel.safe;
  }
}
```

**Verification**:
- Test A: $50 goal due tomorrow + $60 expense = CRITICAL
- Test B: $5000 goal due in 1 year + $10 expense = SAFE
- Test C: $1000 goal due in 3 months + $50 expense = WARNING (4 days delayed)
- Unit tests cover all three time horizons

---

## 🚨 Phase 5: Expense Intervention UI

### Objective
Add "impact preview" to the expense entry flow.

### Tasks

#### Task 5.1: Add Impact Preview to Add Expense Modal
**File**: `lib/screens/add_expense_screen.dart`

**New UI Flow**:
1. User enters amount and category
2. User taps "Add" button
3. **BEFORE saving**: Run impact calculator
4. Show impact preview:
   ```
   ┌─────────────────────────────────────┐
   │  ⚠️ Spending Impact                 │
   ├─────────────────────────────────────┤
   │  🍣 Omakase Dinner (2 days)         │
   │  🔴 You'll be short $20. Continue?  │
   │                                      │
   │  🏠 House Fund (5 years)            │
   │  🟡 Delayed by 1 day                │
   │                                      │
   │  [Cancel]  [Add Anyway]             │
   └─────────────────────────────────────┘
   ```

5. If SAFE: Show green checkmark, auto-save after 1s delay
6. If WARNING/CRITICAL: Show dialog, require confirmation

**Implementation**:
```dart
Future<void> _onAddExpense() async {
  double amount = double.parse(_amountController.text);
  String category = _categoryController.text;

  // Calculate impact
  GoalCalculator calc = GoalCalculator(
    monthlyIncome: userIncome,
    goals: await _db.getAllGoals(),
    currentMonthExpenses: await _getMonthExpenses(),
  );

  List<GoalImpact> impacts = calc.calculateImpact(amount);

  // Filter to only show WARNING and CRITICAL
  List<GoalImpact> badImpacts = impacts.where((i) =>
    i.level != ImpactLevel.safe
  ).toList();

  if (badImpacts.isEmpty) {
    // Safe to spend
    await _saveExpense(amount, category);
    _showSuccessSnackBar("✅ Expense added! Goals are on track.");
  } else {
    // Show warning dialog
    _showImpactDialog(amount, badImpacts);
  }
}

void _showImpactDialog(double amount, List<GoalImpact> impacts) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("⚠️ Spending Impact"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: impacts.map((impact) =>
          _buildImpactCard(impact)
        ).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _saveExpense(amount, category);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text("Add Anyway"),
        ),
      ],
    ),
  );
}
```

**Verification**:
- Safe expenses auto-save with positive feedback
- Warning expenses show dialog with impact details
- Critical expenses require explicit "Add Anyway" confirmation
- Dialog displays all affected goals
- Users can cancel from warning dialog

---

## 🎭 Phase 6: AI Personality Text

### Objective
Add motivational context-aware messages.

### Tasks

#### Task 6.1: Create Message Generator
**File**: `lib/services/message_generator.dart`

```dart
class MessageGenerator {
  static String getImpactMessage(GoalImpact impact, double expenseAmount) {
    // Safe messages
    if (impact.level == ImpactLevel.safe) {
      final safeMessages = [
        "✅ Enjoy your ${_categoryToEmoji(expenseCategory)}! Your goals are safe.",
        "🎉 Go ahead! This won't affect your goals.",
        "💪 You're crushing it! This expense is totally fine.",
        "✨ Smart spending! Your goals are on track.",
      ];
      return safeMessages[Random().nextInt(safeMessages.length)];
    }

    // Warning messages (specific to goal type)
    if (impact.level == ImpactLevel.warning) {
      if (impact.daysUntilDeadline < 7) {
        return "⚠️ Heads up! This delays your '${impact.goalName}' by ${impact.daysDelayed} days.";
      }
      return "⚠️ This will push your '${impact.goalName}' back by ${impact.daysDelayed} days.";
    }

    // Critical messages (dramatic!)
    if (impact.level == ImpactLevel.critical) {
      final criticalMessages = [
        "🚨 STOP! You'll fall \$${impact.impactAmount.toStringAsFixed(0)} short for '${impact.goalName}'.",
        "💀 This kills your '${impact.goalName}' goal! Are you sure?",
        "⛔ WARNING: This expense makes '${impact.goalName}' impossible by your deadline.",
        "🚫 Your '${impact.goalName}' is due in ${impact.daysUntilDeadline} days. This will cost you the goal.",
      ];
      return criticalMessages[Random().nextInt(criticalMessages.length)];
    }

    return "";
  }

  static String _categoryToEmoji(String category) {
    // Map categories to emojis for personality
    switch (category.toLowerCase()) {
      case 'food': return '🍜';
      case 'coffee': return '☕';
      case 'shopping': return '🛍️';
      case 'transport': return '🚗';
      case 'entertainment': return '🎬';
      default: return 'treat';
    }
  }
}
```

**Verification**:
- Messages are contextually appropriate
- Variety prevents message fatigue
- Tone matches severity level

---

## ✅ Phase 7: Testing & Refinement

### Tasks

#### Task 7.1: Integration Testing
**File**: `test/integration/goal_system_test.dart`

**Test Cases**:
1. **Setup**: Create income = $3000/month
2. **Add Goal 1**: $100 due in 7 days (Omakase)
3. **Add Goal 2**: $1000 due in 90 days (iPhone)
4. **Add Goal 3**: $50000 due in 5 years (House)
5. **Test Expense 1**: Add $10 coffee
   - Expected: SAFE (auto-saves)
6. **Test Expense 2**: Add $60 expense (2 days before Omakase)
   - Expected: CRITICAL for Omakase, WARNING for iPhone
7. **Test Expense 3**: Add $500 expense
   - Expected: CRITICAL for Omakase, WARNING for iPhone, delayed for House
8. **Verify**: All goals show correct status on home screen
9. **Verify**: Status badges update correctly
10. **Verify**: Progress bars accurate

---

#### Task 7.2: Performance Testing
- Test with 20+ goals
- Verify impact calculation < 100ms
- Ensure smooth carousel scrolling
- Check database query performance

---

#### Task 7.3: Edge Cases
- Goal with deadline in the past (skip or show as "Overdue")
- Zero target amount (validation error)
- Negative saved amount (validation error)
- Goal with 0 days left (high sensitivity)
- Multiple goals due same day
- Income = 0 (special handling)

---

## 📊 Success Criteria

### Phase 1 Complete When:
- [ ] FinancialGoal model created and tested
- [ ] DatabaseService supports CRUD operations for goals
- [ ] Migration from old single goal works without data loss

### Phase 2 Complete When:
- [ ] Users can add/edit/delete goals from settings
- [ ] Form validates all inputs correctly
- [ ] Date picker works on all platforms
- [ ] Goals persist across app restarts

### Phase 3 Complete When:
- [ ] Home screen shows goal carousel
- [ ] All goals display with progress bars
- [ ] Status badges show correct colors
- [ ] Carousel scrolls smoothly

### Phase 4 Complete When:
- [ ] GoalCalculator passes all unit tests
- [ ] Impact calculation is accurate for all time horizons
- [ ] Calculation completes in < 100ms

### Phase 5 Complete When:
- [ ] Safe expenses auto-save with positive feedback
- [ ] Warning expenses show impact dialog
- [ ] Critical expenses require explicit confirmation
- [ ] Dialog displays all affected goals

### Phase 6 Complete When:
- [ ] Messages are contextually appropriate
- [ ] Messages show variety
- [ ] Tone matches severity

### Phase 7 Complete When:
- [ ] All integration tests pass
- [ ] Performance acceptable with 20+ goals
- [ ] All edge cases handled

---

## 🚀 Implementation Order

**Recommended Sequence**:
1. Phase 1 (Data Model) - MUST BE FIRST
2. Phase 4 (Calculator) - Can build in parallel with UI
3. Phase 2 (Settings) - Depends on Phase 1
4. Phase 3 (Home Screen) - Depends on Phase 1
5. Phase 5 (Intervention) - Depends on Phase 2, 4
6. Phase 6 (Messages) - Can be added anytime
7. Phase 7 (Testing) - Throughout development

**Estimated Time**: 12-15 hours total
- Phase 1: 3 hours
- Phase 2: 3 hours
- Phase 3: 2 hours
- Phase 4: 2 hours
- Phase 5: 3 hours
- Phase 6: 1 hour
- Phase 7: 1 hour

---

## 🎁 Bonus Features (Future Enhancements)

1. **Goal Sharing**: Share goals with household members
2. **Goal Templates**: Pre-made goals (e.g., "Emergency Fund", "Vacation")
3. **Goal Completion Celebration**: Confetti animation when goal reached
4. **Analytics**: "Which category hurts your goals the most?"
5. **Goal Categories**: Group goals by type (Travel, Tech, Home, etc.)
6. **Smart Suggestions**: "If you reduce dining out by $50/week, you'll reach your goal 2 weeks early"

---

**Ready to build? Start with Phase 1, Task 1.1: Create FinancialGoal Model.** 🚀
