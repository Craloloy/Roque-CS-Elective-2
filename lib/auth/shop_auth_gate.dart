import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show AutofillHints;
import 'package:supabase_flutter/supabase_flutter.dart';

const _mobileCallback = 'com.craloloy.apexcomputing://auth-callback/';
const _brand = 'MagiStore';

String? get _callbackUrl {
  if (kIsWeb) return '${Uri.base.origin}/';
  return switch (defaultTargetPlatform) {
    TargetPlatform.android || TargetPlatform.iOS => _mobileCallback,
    _ => null,
  };
}

String _authMessage(Object error) => error is AuthException
    ? error.message
    : 'Unable to complete this request. Please try again.';

class ShopAuthGate extends StatefulWidget {
  const ShopAuthGate({
    super.key,
    required this.client,
    required this.buildApp,
    required this.buildSignedIn,
  });
  final SupabaseClient client;
  final Widget Function(Widget home) buildApp;
  final Widget Function(User user) buildSignedIn;

  @override
  State<ShopAuthGate> createState() => _ShopAuthGateState();
}

class _ShopAuthGateState extends State<ShopAuthGate> {
  late Session? _session = widget.client.auth.currentSession;
  late final StreamSubscription<AuthState> _subscription;
  String? _authError;

  @override
  void initState() {
    super.initState();
    _subscription = widget.client.auth.onAuthStateChange.listen(
      (state) {
        if (!mounted) return;
        setState(() {
          _session = state.session;
          _authError = null;
        });
      },
      onError: (Object error, StackTrace _) {
        if (!mounted) return;
        setState(() => _authError = _authMessage(error));
      },
    );
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _session?.user;
    if (user == null) {
      return widget.buildApp(
        _SignInPage(
          client: widget.client,
          callbackError: _authError,
          onStart: () {
            if (_authError != null) setState(() => _authError = null);
          },
        ),
      );
    }
    return KeyedSubtree(
      key: ValueKey(user.id),
      child: widget.buildSignedIn(user),
    );
  }
}

class _SignInPage extends StatefulWidget {
  const _SignInPage({
    required this.client,
    required this.callbackError,
    required this.onStart,
  });

  final SupabaseClient client;
  final String? callbackError;
  final VoidCallback onStart;

  @override
  State<_SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<_SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _creatingAccount = false;
  bool _busy = false;
  bool _showPassword = false;
  String? _message;
  bool _hasError = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<String?> Function() action) async {
    if (_busy) return;
    widget.onStart();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _busy = true;
      _message = null;
      _hasError = false;
    });
    try {
      final message = await action();
      if (mounted) setState(() => _message = message);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = _authMessage(error);
        _hasError = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _email.text.trim();
    final password = _password.text;
    await _run(() async {
      if (_creatingAccount) {
        final result = await widget.client.auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: _callbackUrl,
        );
        return result.session == null
            ? 'Check your email to confirm your account, then sign in.'
            : null;
      }
      await widget.client.auth.signInWithPassword(email: email, password: password);
      return null;
    });
  }

  Future<void> _signInWithGitHub() => _run(() async {
    final redirect = _callbackUrl;
    if (redirect == null) {
      throw const AuthException('Use Chrome, Android, or iOS for GitHub sign-in.');
    }
    final opened = await widget.client.auth.signInWithOAuth(
      OAuthProvider.github,
      redirectTo: redirect,
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
    );
    if (!opened) throw const AuthException('Could not open GitHub sign-in.');
    return 'Finish signing in in your browser to return to the shop.';
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = widget.callbackError ?? _message;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (viewport.maxHeight - 48).clamp(0.0, double.infinity).toDouble(),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Card(
                    elevation: 0,
                    color: theme.colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(color: theme.dividerColor),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: AutofillGroup(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Icon(Icons.laptop_mac_rounded, size: 32),
                              ),
                              const SizedBox(height: 12),
                              Text(_brand, style: theme.textTheme.titleMedium),
                              const SizedBox(height: 20),
                              Text(
                                _creatingAccount ? 'Create your account' : 'Sign in to the shop',
                                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 18),
                              TextFormField(
                                controller: _email,
                                enabled: !_busy,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(labelText: 'Email'),
                                validator: (value) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                    .hasMatch(value?.trim() ?? '') ? null : 'Enter a valid email.',
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _password,
                                enabled: !_busy,
                                obscureText: !_showPassword,
                                autofillHints: [
                                  _creatingAccount ? AutofillHints.newPassword : AutofillHints.password,
                                ],
                                onFieldSubmitted: (_) {
                                  if (!_busy) unawaited(_submitEmail());
                                },
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  suffixIcon: IconButton(
                                    tooltip: _showPassword ? 'Hide password' : 'Show password',
                                    onPressed: () => setState(() => _showPassword = !_showPassword),
                                    icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Enter your password.';
                                  if (_creatingAccount && value.length < 6) return 'Use at least 6 characters.';
                                  return null;
                                },
                              ),
                              if (message != null) ...[
                                const SizedBox(height: 12),
                                Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    message,
                                    style: TextStyle(
                                      color: widget.callbackError != null || _hasError
                                          ? theme.colorScheme.error
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              if (_busy) const LinearProgressIndicator(),
                              FilledButton(
                                onPressed: _busy ? null : _submitEmail,
                                child: Text(_creatingAccount ? 'Create account' : 'Sign in with email'),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton(
                                onPressed: _busy ? null : _signInWithGitHub,
                                child: const Text('Continue with GitHub'),
                              ),
                              TextButton(
                                onPressed: _busy ? null : () {
                                  widget.onStart();
                                  setState(() {
                                    _creatingAccount = !_creatingAccount;
                                    _message = null;
                                  });
                                },
                                child: Text(_creatingAccount ? 'Already registered? Sign in' : 'New here? Create an account'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
