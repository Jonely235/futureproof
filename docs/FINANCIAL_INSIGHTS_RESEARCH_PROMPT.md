# Research Prompt: Rule-Based Financial Insights System Design

> **Version:** 2.2 (Improved with financial personality types + scenario-based alert examples)
> **Last Updated:** 2025-01-24
> **Purpose:** Deep research prompt for designing an effective rule-based personal finance insights engine

---

## Prompt to Use

```
I am building a personal finance app and want to design a rule-based financial insights system that genuinely helps humans understand and control their money better.

Please conduct deep research and provide recommendations on:

## 1. BEHAVIORAL ECONOMICS & PSYCHOLOGY
- What cognitive biases cause people to fail at budgeting? (e.g., present bias, optimism bias, expense prediction bias)
- How can insights be framed to counteract these biases?
- Research on "mental accounting" and how people actually think about money categories
- Key concept: People asked to list "why spending might be different" predicted spending with significantly more accuracy

## 2. SUCCESSFUL PATTERNS FROM EXISTING APPS
- What insights/features do You Need A Budget (YNAB), Monarch Money, Rocket Money, Copilot do well?
- What are the most-loved features in r/personalfinance and rYNAB communities?
- What do people complain is MISSING from current apps?
- Case studies: What made Mint successful? Why did Intuit shut it down?
- Include: what users actually say about subscription management, recurring spending alerts, and cash flow forecasting

## 3. THE FOUR BEHAVIORAL CHALLENGES (from ideas42 research)
For each challenge, provide specific insight examples:
- **Capture Attention**: How to make insights visible at the right moment? (financial tasks only capture attention when there's immediate need)
- **Inspire Trust**: How to build confidence without human touchpoints? (people struggle to trust virtual processes, especially when cash is tight)
- **Simplify Decisions**: How to reduce cognitive load? (people scan quickly, technical language deters, too many options cause paralysis)
- **Facilitate Action**: How to prevent drop-off? (even small hassles cause procrastination, uncertainty demotivates)

## 4. RULE-BASED INSIGHT CATEGORIES
For each category, provide: the rule logic, behavioral principle, and example message:
- Budget health & velocity insights (spending pace vs daily budget)
- Spending pattern detection (recurring, one-off, trends)
- Anomaly detection (unusual spending - "this is 3x your normal restaurant spend")
- Goal progress & projection (on track, at risk, behind)
- Cash flow forecasting ("you'll run short on $X date based on upcoming bills")
- Debt payoff strategies (avalanche vs snowball impact visualization)
- Savings optimization (round-up opportunities, safe-to-save amounts)
- Subscription management ("you've spent $X on subscriptions this month")
- "What if" scenario modeling (what if I cut dining by 20%?)

## 5. SCENARIO-BASED ALERTS (Think-Ahead Insights)

Scenario-based alerts combine multiple data points to predict problems BEFORE they happen. These are more powerful than simple reminders.

**Key Principle:** The most useful alerts don't just say "something happened"—they say "this may happen if you don't act now."

### Concrete Scenario Examples with Rule Logic:

| Scenario | Rule Logic | Insight Message | Action Button |
|----------|------------|-----------------|---------------|
| **Salary Delay + EMI Risk** | `if (days_until_salary > days_until_emi) AND (balance < emi_amount)` | "Your EMI is due in 3 days, but your balance is ₹1,800 short." | "Arrange Funds" |
| **Heavy Week + Card Bill** | `if (this_week_spending > 1.3x * avg_weekly_spending)` | "You spent more than usual this week. Your card bill may feel heavy this cycle." | "View Breakdown" |
| **Goal + Festival Season** | `if (days_to_festival < 14) AND (goal_progress > 80%)` | "You're close to your Diwali goal! Avoid big new spends this week." | "Stay on Track" |
| **Subscription Cluster** | `if (count(subscriptions_renewing_in_3_days) >= 3)` | "Three OTT subscriptions will renew within 3 days—check if you still use them." | "Review Subs" |
| **Cash Flow Dip** | `if (sum(upcoming_7day_bills) > sum(upcoming_7day_income) + buffer)` | "Next 7 days show more outgoing than incoming. You may run low on Thursday." | "Adjust Spending" |
| **Repeated Unusual Category** | `if (category_spend_this_month > 1.5x * category_avg_last_3_months)` | "You've spent 30% more on food delivery this month than last month." | "View Details" |
| **Goal Almost There** | `if (goal_progress >= 80%) AND (goal_remaining < 2 * avg_monthly_contribution)` | "Only 2 more contributions needed to reach your emergency fund goal!" | "Add Now" |
| **Credit Score Risk** | `if (credit_utilization > 70%)` | "If you miss this EMI, your credit score could drop." | "Pay Now" |
| **Safe to Save** | `if (balance - upcoming_bills - minimum_buffer > 0)` | "You usually save ₹2,000 after salary. Want to move it now?" | "Save ₹2,000" |
| **Location-Based Nudge** | `if (user_in_mall) AND (remaining_budget < typical_mall_spend)` | "You're at a mall. Consider setting a spending limit for today." | "Set Limit" |

### Alert Design Principles:

1. **Always include ONE clear action** - Without it, users feel warned but not supported
2. **Tone: Friendly, not scolding** - Help users make better choices, don't shame them
3. **Be specific** - "₹1,800 short" is better than "low balance"
4. **Timing matters** - Warn 3-7 days before, not just when due
5. **Respect user control** - Let users customize alert types, frequency, and tone

### Quick Insight Message Examples (Copy-Paste Ready)

| Trigger | Message | Action |
|---------|---------|--------|
| Budget at 90% | "You've used 90% of your budget. $X remaining for the next 8 days." | "View Breakdown" |
| Unusual spend | "This restaurant charge is 3x your usual dining spend. Everything okay?" | "Categorize Anyway" |
| Streak milestone | "7 days under budget! You're building momentum. Keep it up!" | None |
| Subscription renewal | "Netflix renews in 3 days. Still watching?" | "Keep" / "Cancel" |
| Safe to save | "You have $X extra after upcoming bills. Move to savings?" | "Save $X" |
| Cash flow warning | "Based on upcoming bills, you'll run short on Thursday. Consider moving funds." | "Transfer" |
| Goal progress | "You're 80% to your vacation goal! Only $X to go." | "Add $X" |
| Spending velocity | "Averaging $X/day vs your $Y budget. At this pace, you'll exceed budget by $Z." | "Adjust Budget" |
| Recurring charge | "You've spent $X on coffee this month. That's $X/year." | "Set Limit" |
| Income ahead | "Salary arrives in 2 days. Time to set aside money for goals?" | "Save Now" |

## 6. TIMING & DELIVERY
- When should insights be delivered? (real-time, daily, weekly, monthly)
- What contexts trigger the most effective insights? (after transaction, before purchase, at decision point)
- How many insights at once before cognitive overload?
- Push vs in-app vs summary digest trade-offs
- Consider: people need physical/real-world cues since digital tools are easily forgotten

## 7. ACTIONABILITY & FEEDBACK LOOPS
- How to make insights lead to action instead of just awareness?
- What creates habit formation vs one-time changes?
- How to measure if an insight actually helped someone?
- Feedback mechanisms to learn user preferences
- Apply the "Regret Test": If users knew everything the designer knows, would they still execute the behavior?

## 8. PERSONALIZATION

### Financial Personality Types (from Britannica Money)

| Type | Traits | Insight Approach |
|------|--------|------------------|
| **Saver** | Frugal, security-focused, worries about spending | "Give money a purpose" - help them set specific goals so spending feels intentional |
| **Spender** | Impulse purchases, retail therapy, budgeting feels restrictive | "Values-based budgeting" - align spending with what truly matters to them |
| **Sharer** | Generous, puts others first, can't say no | "Sinking fund for giving" - set aside money monthly for helping others |
| **Investor** | Long-term focused, calculated risks, future-oriented | "Present balance" - remind them to enjoy today while building for tomorrow |
| **Gambler** | High risk tolerance, loves thrill, can lose big | "Risk fund" - limit risky bets to 10% of portfolio |

### How to adapt insights based on:
- Financial personality (saver, spender, sharer, investor, gambler)
- Life stage (student, early career, family, retirement)
- Financial stress level (different messages for tight vs comfortable cash flow)
- Past behavior and response patterns
- Income volatility considerations

## 9. ANTIFRAGILITY & RESILIENCE
- Insights that build financial resilience (emergency funds, buffers)
- "War mode" / crisis mode patterns (what to show when money is tight)
- Preventing financial fragility
- Income volatility management

## 10. TRUST & TRANSPARENCY
- How to communicate data usage and security clearly
- How to show users you're "on their side" not maximizing engagement at their expense
- Social proof elements (what others like them are doing)

## RESEARCH SOURCES TO REFERENCE
- ideas42 Behavioral Design Playbook for Digital Financial Services
- Financial Health Network's Behavioral Design Guide
- "Nudge" by Richard Thaler & Cass Sunstein
- Academic research on expense prediction bias
- YNAB/Monarch user communities for real-world feedback

Please cite specific research papers, books, or experts where applicable. Provide concrete examples of insight messages and the rules behind them.
```

---

## Research Sources

### Key Resources Found

1. **[Behavioral Design Guide: Tools To Manage Spending](https://finhealthnetwork.org/research/behavioral-design-guide-tools-to-manage-spending/)** - Financial Health Network
   - Covers expense prediction bias and how to improve budget accuracy
   - People who listed reasons their spending might differ predicted spending significantly more accurately

2. **[Behavioral Design for Digital Financial Services](https://www.ideas42.org/dfsplaybook/)** - ideas42
   - Four behavioral challenges: Capture Attention, Inspire Trust, Simplify Decisions, Facilitate Action
   - The "Regret Test" for ethical design

3. **[Behavioral Design in Finance](https://medium.com/nudge-notes/behavioral-design-in-finance-encouraging-sound-money-decisions-b0ca6a925127)** - Nudge Notes
   - Power of defaults (401k enrollment example)
   - Real-time feedback importance (Acorns, Robinhood examples)
   - Make it easy principle

4. **[Rule-based Personal Finance Management System](https://www.researchgate.net/publication/348962885_Design_of_a_Rule-based_Personal_Finance_Management_System_based_on_Financial_Well-being)** - Academic Research

5. **[Benefits of Behavioral Nudges](https://www.financialplanningassociation.org/learning/publications/journal/MAR24-benefits-behavioral-nudges-using-choice-architecture-improve-decisions-and-shape-outcomes-OPEN)** - March 2024

6. **[Scenario-Based Alerts in Finance Apps](https://www.billcut.com/blogs/scenario-based-alerts-in-finance-apps-think-ahead/)** - BillCut
   - Specific examples of think-ahead alerts (salary delay + EMI, subscription clusters, cash flow dips)
   - Alert design principles: friendly tone, specific amounts, clear action buttons

7. **[5 Money Personality Types](https://www.britannica.com/money/money-personality-type)** - Britannica Money
   - Saver, Spender, Sharer, Investor, Gambler types with detailed traits
   - Personalized insight approaches for each personality type

### Key Behavioral Principles Identified

| Principle | Application | Example Insight |
|-----------|-------------|-----------------|
| **Expense Prediction Bias** | People budget only for predictable expenses | "List 3 reasons next week might cost more" |
| **Present Bias** | People prioritize now over later | Show future impact of today's spending |
| **Social Proof** | People follow others' behavior | "80% of users like you saved $X this month" |
| **Loss Aversion** | Losses hurt more than gains feel good | "You're losing $X/month to unused subscriptions" |
| **Default Effect** | People stick with defaults | Pre-set safe savings amounts |
| **Cognitive Load** | Too much info = paralysis | Max 3 insights at once |
| **Regret Test** | Would users agree if fully informed? | Be transparent about data use |

---

## Improvements Made to Original Prompt (v2.2)

### From v2.0:
8. **Added Scenario-Based Alerts section** - Complete table of think-ahead insights with rule logic, messages, and action buttons
9. **Concrete rule examples** - Pseudocode-style conditions like `if (days_until_salary > days_until_emi) AND (balance < emi_amount)`
10. **Alert Design Principles** - 5 key principles for effective alerts (action, tone, specificity, timing, control)
11. **Added Financial Personality Types** - 5 types from Britannica (Saver, Spender, Sharer, Investor, Gambler) with personalized insight approaches
12. **Added Britannica Money source** - Comprehensive financial personality type reference

### From v1.0:
1. **Added ideas42's Four Behavioral Challenges Framework** - A research-backed structure for understanding adoption barriers

2. **Included "Expense Prediction Bias"** - Specific finding that asking "why might spending be different" dramatically improves budget accuracy

3. **Added "Regret Test"** - Ethical design principle from Nir Eyal

4. **Added Trust & Transparency section** - Critical for financial apps, especially without human touchpoints

5. **More specific insight examples** - Concrete rules like "3x normal restaurant spend"

6. **Added research sources to reference** - Gives AI specific material to work with

7. **Reorganized for better flow** - Starts with behavioral science foundation, then patterns, then implementation details

### From v2.0:
8. **Added Scenario-Based Alerts section** - Complete table of think-ahead insights with rule logic, messages, and action buttons

9. **Concrete rule examples** - Pseudocode-style conditions like `if (days_until_salary > days_until_emi) AND (balance < emi_amount)`

10. **Alert Design Principles** - 5 key principles for effective alerts (action, tone, specificity, timing, control)

---

## Next Steps

1. Use this prompt with a capable AI (Claude Opus, GPT-4) for deep research
2. Extract specific rule examples from the response
3. Map rules to your app's data capabilities
4. Implement insights incrementally, measuring user engagement
5. Iterate based on user feedback
