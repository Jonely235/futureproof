import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../services/auth_service.dart';
import '../services/firestore_sync_service.dart';
import '../screens/login_screen.dart';
import '../screens/household_setup_screen.dart';
import '../widgets/main_navigation.dart';

/// Authentication Wrapper Widget
///
/// Checks authentication state and shows appropriate screen:
/// - Login/Signup if not authenticated
/// - Main app if authenticated
/// - Household setup if authenticated but no household
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  final FirestoreSyncService _syncService = FirestoreSyncService();
  bool _isCheckingAuth = true;
  bool _isAuthenticated = false;
  bool _needsHousehold = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();

    // Listen to auth state changes
    _authService.authStateChanges.listen((user) {
      if (user != null) {
        _checkHouseholdStatus();
      } else {
        setState(() {
          _isAuthenticated = false;
          _needsHousehold = false;
        });
      }
    });
  }

  Future<void> _checkAuthStatus() async {
    final isAuthenticated = _authService.isAuthenticated;

    if (isAuthenticated) {
      await _checkHouseholdStatus();
    } else {
      setState(() {
        _isCheckingAuth = false;
        _isAuthenticated = false;
      });
    }
  }

  Future<void> _checkHouseholdStatus() async {
    try {
      final user = await _authService.getCurrentAppUser();

      if (user != null) {
        final hasHousehold = user.hasHousehold;

        setState(() {
          _isCheckingAuth = false;
          _isAuthenticated = true;
          _needsHousehold = !hasHousehold;
        });

        // Auto-sync from cloud if has household
        if (hasHousehold && user.householdId != null) {
          try {
            print('Auto-syncing transactions from cloud...');
            await _syncService.fullSync(user.householdId!);
            print('Auto-sync complete!');
          } catch (e) {
            print('Auto-sync failed (non-critical): $e');
            // Don't fail the app if sync fails
          }
        }
      } else {
        setState(() {
          _isCheckingAuth = false;
          _isAuthenticated = false;
        });
      }
    } catch (e) {
      print('Error checking household status: $e');
      setState(() {
        _isCheckingAuth = false;
        _isAuthenticated = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isAuthenticated) {
      // Show login screen (could also show a welcome screen)
      return const LoginScreen();
    }

    if (_needsHousehold) {
      // Show household setup
      return const HouseholdSetupScreen();
    }

    // Show main app
    return const MainNavigation();
  }
}
