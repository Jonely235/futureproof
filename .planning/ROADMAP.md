# Roadmap: FutureProof Technical Debt Cleanup

## Overview

Transform FutureProof's codebase from functional-but-debt-ridden to maintainable, testable, and production-ready. This refactoring milestone focuses on internal quality improvements while preserving all existing features. No new features will be added during this cleanup.

## Domain Expertise

None (standard Flutter/Dart patterns apply)

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Logging Foundation** - Set up structured logging framework
- [ ] **Phase 2: Constants & Config** - Extract magic numbers and hardcoded values
- [ ] **Phase 3: Error Handling** - Standardize error handling across services
- [ ] **Phase 4: Settings Screen Refactor** - Break down 1274-line settings screen
- [ ] **Phase 5: Service Tests** - Add tests for analytics, backup, database services
- [ ] **Phase 6: Provider & Widget Tests** - Test state management and UI components
- [ ] **Phase 7: Code Organization** - Clean up imports and naming conventions
- [ ] **Phase 8: Final Verification** - Ensure all tests pass and features work

## Phase Details

### Phase 1: Logging Foundation
**Goal**: Replace print statements with structured logging framework
**Depends on**: Nothing (first phase)
**Research**: Unlikely (logging package already configured, use established patterns)
**Plans**: TBD

Plans:
- [x] 01-01: Configure logging levels and output format
- [x] 01-02: Replace print statements in services
- [x] 01-03: Replace print statements in screens

### Phase 2: Constants & Config
**Goal**: Extract magic numbers and hardcoded values to constants
**Depends on**: Phase 1
**Research**: Unlikely (standard Flutter constants pattern)
**Plans**: TBD

Plans:
- [x] 02-01: Create constants files for colors and strings
- [x] 02-02: Extract hardcoded values from screens
- [ ] 02-03: Extract hardcoded values from services

### Phase 3: Error Handling
**Goal**: Standardize error handling across services and UI
**Depends on**: Phase 1 (logging foundation)
**Research**: Unlikely (established error handling patterns)
**Plans**: TBD

Plans:
- [ ] 03-01: Standardize service layer error handling
- [ ] 03-02: Standardize UI error display (SnackBar patterns)
- [ ] 03-03: Add error tracking for debugging

### Phase 4: Settings Screen Refactor
**Goal**: Break down 1274-line settings screen into focused widgets
**Depends on**: Phase 2 (constants extraction)
**Research**: Unlikely (widget extraction follows existing patterns)
**Plans**: TBD

Plans:
- [x] 04-01: Extract theme picker widget
- [ ] 04-02: Extract smart insights widget
- [ ] 04-03: Extract settings form widget
- [ ] 04-04: Extract backup section widget

### Phase 5: Service Tests
**Goal**: Add comprehensive tests for business logic layer
**Depends on**: Phase 3 (error handling improvements)
**Research**: Unlikely (Flutter test framework established)
**Plans**: TBD

Plans:
- [x] 05-01: Add AnalyticsService tests
- [x] 05-02: Add BackupService tests
- [ ] 05-03: Expand DatabaseService tests
- [ ] 05-04: Add FinanceCalculator tests

### Phase 6: Provider & Widget Tests
**Goal**: Test state management and UI components
**Depends on**: Phase 4 (refactored widgets easier to test)
**Research**: Unlikely (widget testing patterns exist)
**Plans**: TBD

Plans:
- [ ] 06-01: Add TransactionProvider tests
- [ ] 06-02: Add key widget tests (settings components)
- [ ] 06-03: Add ThemeManager tests

### Phase 7: Code Organization
**Goal**: Clean up imports and standardize naming conventions
**Depends on**: Phase 4 (refactored code has consistent structure)
**Research**: Unlikely (Dart style guide established)
**Plans**: TBD

Plans:
- [ ] 07-01: Organize imports consistently across all files
- [ ] 07-02: Remove unused imports and dead code
- [ ] 07-03: Verify naming conventions compliance

### Phase 8: Final Verification
**Goal**: Ensure all tests pass and features work correctly
**Depends on**: All previous phases
**Research**: Unlikely (verification only)
**Plans**: TBD

Plans:
- [ ] 08-01: Run full test suite and verify 80%+ coverage
- [ ] 08-02: Manual testing of all features (regression check)
- [ ] 08-03: Update documentation and guides

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Logging Foundation | 3/3 | Complete | 2026-01-11 |
| 2. Constants & Config | 2/3 | In progress | - |
| 3. Error Handling | 0/3 | Not started | - |
| 4. Settings Screen Refactor | 1/4 | In progress | 2026-01-11 |
| 5. Service Tests | 2/4 | In progress | 2026-01-11 |
| 6. Provider & Widget Tests | 0/3 | Not started | - |
| 7. Code Organization | 0/3 | Not started | - |
| 8. Final Verification | 0/3 | Not started | - |
