/// Budget entity - represents budget information for tracking expenses
class BudgetEntity {
  final double monthlyIncome;
  final double savingsGoal;
  final double dailyBudget;
  final double weeklyBudget;
  final double monthlyBudget;

  const BudgetEntity({
    required this.monthlyIncome,
    required this.savingsGoal,
    required this.dailyBudget,
    required this.weeklyBudget,
    required this.monthlyBudget,
  });

  /// Business rule: Calculate target budget (income - savings goal)
  factory BudgetEntity.fromIncomeAndGoals({
    required double monthlyIncome,
    required double savingsGoal,
  }) {
    final targetBudget = monthlyIncome - savingsGoal;
    return BudgetEntity(
      monthlyIncome: monthlyIncome,
      savingsGoal: savingsGoal,
      dailyBudget: targetBudget / 30,
      weeklyBudget: targetBudget / 4,
      monthlyBudget: targetBudget,
    );
  }

  /// Business rule: Get budget status percentage
  double getBudgetStatus(double spent) {
    if (monthlyBudget == 0) return 0;
    return (spent / monthlyBudget) * 100;
  }

  /// Business rule: Is spending within budget?
  bool isWithinBudget(double spent) {
    return spent <= monthlyBudget;
  }

  /// Business rule: Get remaining budget
  double getRemaining(double spent) {
    return monthlyBudget - spent;
  }

  /// Business rule: Get daily budget progress
  double getDailyProgress(double dailySpent) {
    if (dailyBudget == 0) return 0;
    return (dailySpent / dailyBudget) * 100;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BudgetEntity &&
        other.monthlyIncome == monthlyIncome &&
        other.savingsGoal == savingsGoal;
  }

  @override
  int get hashCode =>
      monthlyIncome.hashCode ^ savingsGoal.hashCode;
}
