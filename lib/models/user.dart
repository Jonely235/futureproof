// NOTE: User model removed - no longer needed for MVP (Phase 1)
// This file is kept for backwards compatibility but is not used.
// Firebase authentication and households have been removed for iOS compatibility.

/// User model representing app users (UNUSED in MVP)
///
/// This is kept for backwards compatibility but is not used in Phase 1 MVP.
/// Firebase authentication and multi-user households have been removed
/// to fix iOS build issues.
@Deprecated('User model not used in MVP (Phase 1)')
class User {
  final String id;
  final String email;
  final String name;

  User({
    required this.id,
    required this.email,
    required this.name,
  });
}

