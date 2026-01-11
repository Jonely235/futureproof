---
phase: 03-error-handling
plan: 01
subsystem: services
tags: [error-handling, app-error, dart, flutter]

# Dependency graph
requires:
  - phase: 01-logging-foundation
    plan: 01
    provides: AppLogger utility, logging configuration
  - phase: 01-logging-foundation
    plan: 02
    provides: Service layer logging patterns
  - phase: 01-logging-foundation
    plan: 03
    provides: Complete logging foundation
provides:
  - AppError class hierarchy for structured error handling
  - DatabaseService throwing AppError for all database operations
  - AnalyticsService throwing AppError for validation/analysis errors
  - BackupService throwing AppError for backup operations
affects: [ui, error-tracking]

# Tech tracking
tech-stack:
  added: [AppError class, AppErrorType enum]
  patterns: [structured-error-throwing, error-context-inclusion, stack-trace-preservation]

key-files:
  created: [lib/models/app_error.dart]
  modified: [lib/services/database_service.dart, lib/services/analytics_service.dart, lib/services/backup_service.dart]

key-decisions:
  - "Single AppError class with type enum (not inheritance) - simpler and sufficient"
  - "Graceful degradation preserved for non-critical failures (partial imports, settings export)"
  - "All critical paths throw structured errors with context"

# Phase 3 Plan 1: Service Error Handling Summary

**Standardized service layer error handling with AppError class hierarchy**

## Accomplishments

- Created AppError class with structured error types and context
- Updated DatabaseService to throw AppError for all database operations
- Updated AnalyticsService to use AppError, removed silent failures
- Updated BackupService to use AppError for critical failures

## Files Created/Modified

### Created
- `lib/models/app_error.dart` - New error class hierarchy with AppErrorType enum (database, network, validation, backup, unknown)

### Modified
- `lib/services/database_service.dart` - All database operations now throw AppError with type=database
- `lib/services/analytics_service.dart` - All methods throw AppError, silent JSON catch replaced with validation error
- `lib/services/backup_service.dart` - Export/import critical failures throw AppError with type=backup

## Decisions Made

- Single AppError class with type enum (not inheritance) - simpler and sufficient
- Graceful degradation preserved for non-critical failures (partial imports continue, settings export returns empty map)
- All critical paths throw structured errors with context (message, technicalDetails, originalError, stackTrace)
- Replaced UnimplementedError for web platform with AppError for consistency

## Issues Encountered

None

## Deviations from Plan

- Removed unused `material.dart` import from backup_service.dart (linter warning)

## Next Phase Readiness

Ready for 03-02-PLAN.md - Standardize UI error display patterns

All services now consistently throw AppError exceptions that the UI layer can catch and display to users. The structured error format includes user-friendly messages, technical details for debugging, and preserved stack traces.
