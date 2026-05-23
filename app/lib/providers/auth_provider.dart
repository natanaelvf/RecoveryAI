import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

// ---------------------------------------------------------------------------
// Auth state model
// ---------------------------------------------------------------------------

/// Immutable snapshot of the current auth state.
class AuthState {
  final bool isAuthenticated;
  final User? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.isAuthenticated = false,
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    User? user,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ---------------------------------------------------------------------------
// Auth notifier — real Supabase Auth
// ---------------------------------------------------------------------------

class AuthNotifier extends ChangeNotifier {
  AuthState _state = const AuthState();

  AuthState get state => _state;

  // Convenience getters used by the router and UI.
  bool get isAuthenticated => _state.isAuthenticated;
  bool get isLoading => _state.isLoading;
  String? get errorMessage => _state.errorMessage;
  User? get user => _state.user;

  AuthNotifier() {
    // Seed initial state from the persisted session (if any).
    final session = supabase.auth.currentSession;
    if (session != null) {
      _state = AuthState(
        isAuthenticated: true,
        user: supabase.auth.currentUser,
      );
    }

    // Listen for auth changes (login, logout, token refresh).
    supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;

      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed ||
          event == AuthChangeEvent.userUpdated) {
        _state = _state.copyWith(
          isAuthenticated: true,
          user: data.session?.user,
          isLoading: false,
          clearError: true,
        );
        notifyListeners();
      } else if (event == AuthChangeEvent.signedOut) {
        _state = const AuthState();
        notifyListeners();
      }
    });
  }

  // ---- Email / password ---------------------------------------------------

  /// Sign in with email and password.
  Future<void> signInWithEmail(String email, String password) async {
    _state = _state.copyWith(isLoading: true, clearError: true);
    notifyListeners();

    try {
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      // State is updated via the onAuthStateChange listener.
    } on AuthException catch (e) {
      _state = _state.copyWith(isLoading: false, errorMessage: e.message);
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
      notifyListeners();
    }
  }

  /// Create a new account with email and password.
  Future<void> signUpWithEmail(String email, String password) async {
    _state = _state.copyWith(isLoading: true, clearError: true);
    notifyListeners();

    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null &&
          response.user!.identities != null &&
          response.user!.identities!.isEmpty) {
        // User already exists (Supabase returns empty identities).
        _state = _state.copyWith(
          isLoading: false,
          errorMessage: 'An account with this email already exists.',
        );
        notifyListeners();
        return;
      }

      // If email confirmation is enabled, user won't be signed in yet.
      if (response.session == null) {
        _state = _state.copyWith(
          isLoading: false,
          errorMessage: 'Check your email for a confirmation link.',
        );
        notifyListeners();
        return;
      }

      // Auto-signed in (email confirmation disabled).
      // State is updated via the onAuthStateChange listener.
    } on AuthException catch (e) {
      _state = _state.copyWith(isLoading: false, errorMessage: e.message);
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
      notifyListeners();
    }
  }

  // ---- Google native sign-in ----------------------------------------------

  /// Sign in using the native Google credential flow.
  /// Uses the `google_sign_in` package → sends the ID token to Supabase.
  Future<void> signInWithGoogle() async {
    _state = _state.copyWith(isLoading: true, clearError: true);
    notifyListeners();

    try {
      final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
      if (webClientId == null || webClientId.isEmpty) {
        throw Exception('GOOGLE_WEB_CLIENT_ID not configured in .env');
      }

      final googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
        scopes: ['email', 'profile'],
      );

      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled — silently reset loading.
        _state = _state.copyWith(isLoading: false);
        notifyListeners();
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw AuthException('Google sign-in did not return an ID token.');
      }

      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );
      // State is updated via the onAuthStateChange listener.
    } on AuthException catch (e) {
      _state = _state.copyWith(isLoading: false, errorMessage: e.message);
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Google sign-in error: $e');
      debugPrint('Stack trace: $stackTrace');
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: 'Google sign-in failed: $e',
      );
      notifyListeners();
    }
  }

  // ---- Password reset -----------------------------------------------------

  /// Send a password reset email.
  Future<void> resetPassword(String email) async {
    _state = _state.copyWith(isLoading: true, clearError: true);
    notifyListeners();

    try {
      await supabase.auth.resetPasswordForEmail(email);
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: 'Password reset link sent — check your email.',
      );
      notifyListeners();
    } on AuthException catch (e) {
      _state = _state.copyWith(isLoading: false, errorMessage: e.message);
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: 'Could not send reset email. Please try again.',
      );
      notifyListeners();
    }
  }

  // ---- Sign out ------------------------------------------------------------

  Future<void> signOut() async {
    await supabase.auth.signOut();
    _state = const AuthState();
    notifyListeners();
  }

  /// Clear any displayed error.
  void clearError() {
    _state = _state.copyWith(clearError: true);
    notifyListeners();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final authProvider = ChangeNotifierProvider<AuthNotifier>((ref) {
  return AuthNotifier();
});
