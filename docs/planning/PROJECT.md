# FutureProof - Technical Debt Cleanup Project

**Project Type:** Brownfield Refactoring
**Status:** Initializing
**Focus:** Maintainability through refactoring, testing, and code cleanup

---

## What is FutureProof?

A personal finance tracking app for couples that answers the question "are we going to be okay?".

**Current State:**
- Fully functional Flutter app with 4 themes
- Transaction tracking, analytics, and local backup
- All MVP features complete (5 phases delivered)
- **Technical debt accumulated during rapid feature development**

**Next Phase:** Technical debt cleanup to improve maintainability

---

## Vision

**Goal:** Make FutureProof's codebase maintainable, testable, and production-ready.

**Why:**
- Current state has large files (1274-line settings screen), inconsistent error handling, and test gaps
- Technical debt slows down future feature development
- Need solid foundation before adding multi-goal system or cloud sync

**Success:** Codebase is easy to understand, modify, and extend. All tests pass. Features remain stable.

---

## Requirements

### Validated (Existing Features - Must Preserve)

✓ **Transaction Management** - Add, edit, delete, list transactions
✓ **Financial Analytics** - Spending analysis, insights, trends, health score
✓ **Multi-theme Support** - 4 built-in themes (Editorial, Ocean Calm, Sunset Warm, Forest)
✓ **Local Data Persistence** - SQLite for transactions, SharedPreferences for settings
✓ **Backup/Export** - JSON export/import functionality
✓ **Settings UI** - Income, savings goal, category budgets, theme picker
✓ **Navigation** - Bottom navigation with 4 tabs (Home, History, Analytics, Settings)
✓ **Smart Insights** - Visual stat cards replacing text-heavy recommendations

### Active (Technical Debt Goals)

- [ ] **Refactor Large Screens** - Break down `lib/screens/settings_screen.dart` (1274 lines) into smaller, focused widgets
- [ ] **Improve Error Handling** - Standardize error handling with proper logging framework (replace print statements)
- [ ] **Increase Test Coverage** - Add tests for analytics service, backup service, theme manager, and providers (target: 80%+)
- [ ] **Code Cleanup** - Remove magic numbers, standardize naming conventions, organize imports consistently

### Out of Scope

**New Features** - No new features during technical debt cleanup
- Multi-goal savings system (deferred to post-cleanup)
- Cloud sync/iCloud integration (deferred to post-cleanup)
- Household account sharing (deferred to post-cleanup)
- New analytics visualizations (deferred to post-cleanup)

**Non-Critical Polish:**
- Advanced animations (current animations are sufficient)
- Additional themes (4 themes are adequate)
- Performance optimization (not a current bottleneck)

---

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Focus on maintainability | Easier future development | Code is easier to understand and modify | — Pending |
| No new features | Prevents scope creep | Focus on refactoring only | — Pending |
| Backwards compatibility required | Don't break existing features | All existing features must work | — Pending |
| Incremental refactoring | Keep app working throughout | Refactor one screen at a time | — Pending |
| Test first for new code | TDD for refactored components | New components have tests from start | — Pending |

---

## Constraints

**Technical:**
- Must maintain Flutter 3.x and Dart >=3.0.0 compatibility
- Must preserve SQLite data schema (no migrations)
- Must maintain SharedPreferences keys for settings
- All existing tests must pass

**Workflow:**
- Incremental refactoring (one component at a time)
- Tests pass after each change
- No breaking changes to public APIs

**Process:**
- Codebase map available in `.planning/codebase/` (STACK.md, ARCHITECTURE.md, etc.)
- Use `docs/GUIDES/code_quality_guide.md` for standards
- Follow `docs/GUIDES/testing_guide.md` for test patterns

---

## Success Criteria

**Maintainability:**
- [ ] No file exceeds 500 lines
- [ ] Each widget has single responsibility
- [ ] Clear separation of concerns (UI → State → Service → Data)

**Code Quality:**
- [ ] No magic numbers (all constants extracted)
- [ ] Consistent naming conventions throughout
- [ ] Organized imports (flutter, packages, relative)
- [ ] Proper error handling (no print statements for errors)

**Test Coverage:**
- [ ] 80%+ test coverage (measured by flutter test --coverage)
- [ ] All services have unit tests
- [ ] All providers have tests
- [ ] Critical widgets have widget tests
- [ ] All integration tests pass

**Stability:**
- [ ] All existing features work identically
- [ ] No regressions in user-facing behavior
- [ ] Data migration not required (schemas unchanged)

---

## Project Context

**Codebase State:**
- 20 Dart files
- Provider-based architecture with layered design
- 62/62 unit tests passing
- 11 integration tests (need minor updates)
- 4 themes with ThemeManager
- Local-only (no external APIs)

**Known Issues (from `.planning/codebase/CONCERNS.md`):**
- Settings screen: 1274 lines (needs splitting)
- Inconsistent error handling (mix of print, logging, silent failures)
- Test gaps: analytics service, backup service, theme manager, providers
- Hardcoded values (colors, emoji, magic numbers)

**Technical Debt Hotspots:**
1. `lib/screens/settings_screen.dart` (1274 lines)
2. Error handling inconsistency throughout
3. Missing tests for core services
4. Import order sensitivity

---

*Last updated: 2026-01-11 after initialization*
