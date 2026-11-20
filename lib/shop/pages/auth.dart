import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/shop_providers.dart';
import '../services/shop_service.dart';
import 'appearance.dart';

enum _Step { signIn, register, confirm }

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key, this.initialEmail});
  final String? initialEmail;
  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(),
      password = TextEditingController(),
      first = TextEditingController(),
      last = TextEditingController();
  _Step step = _Step.signIn;
  bool busy = false, hidden = true, isError = false;
  String? message, activeEmail, coolingEmail;
  Timer? cooldown;

  @override
  void initState() {
    super.initState();
    activeEmail = widget.initialEmail;
    email.text = activeEmail ?? '';
  }

  @override
  void dispose() {
    cooldown?.cancel();
    for (final field in [email, password, first, last]) {
      field.dispose();
    }
    super.dispose();
  }

  void go(_Step next, {String? address, String? note}) {
    FocusManager.instance.primaryFocus?.unfocus();
    form.currentState?.reset();
    setState(() {
      step = next;
      activeEmail = address;
      if (address != null) email.text = address;
      password.clear();
      hidden = true;
      message = note;
      isError = false;
    });
  }

  void startCooldown(String address) {
    cooldown?.cancel();
    coolingEmail = address;
    cooldown = Timer(const Duration(minutes: 1), () {
      if (mounted) setState(() => coolingEmail = null);
    });
  }

  Future<void> submit({bool google = false, bool resend = false}) async {
    if (busy || (!google && !resend && !form.currentState!.validate())) return;
    final address = activeEmail ?? email.text.trim();
    setState(() {
      busy = true;
      message = null;
      isError = false;
    });
    final actions = ref.read(authActions);
    try {
      if (resend) {
        await actions.resendConfirmation(address);
        if (!mounted) return;
        setState(() {
          startCooldown(address);
          message = 'Request received. Check your inbox and spam folder.';
        });
      } else if (google) {
        await actions.google();
      } else if (step == _Step.register) {
        final needsConfirmation = await actions.signup(
          address,
          password.text,
          first.text.trim(),
          last.text.trim(),
        );
        if (!mounted) return;
        if (needsConfirmation) {
          startCooldown(address);
          go(_Step.confirm, address: address);
        } else {
          ref.invalidate(sessionProvider);
        }
      } else {
        await actions.login(address, password.text);
        if (mounted) ref.invalidate(sessionProvider);
      }
    } on EmailConfirmationNeeded {
      if (mounted) go(_Step.confirm, address: address);
    } on EmailAlreadyRegistered {
      if (mounted) {
        go(
          _Step.signIn,
          address: address,
          note:
              'This email is already registered. Use your usual sign-in method.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          message = shopMessage(e);
          isError = true;
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    final signup = step == _Step.register, pending = step == _Step.confirm;
    final selected = activeEmail;
    Widget textField(
      TextEditingController controller,
      String label, {
      bool isEmail = false,
      bool isPassword = false,
    }) => TextFormField(
      key: ValueKey(label),
      controller: controller,
      enabled: !busy,
      obscureText: isPassword && hidden,
      keyboardType: isEmail ? TextInputType.emailAddress : null,
      textInputAction: isPassword ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: isPassword ? (_) => submit() : null,
      autofillHints: isEmail
          ? const [AutofillHints.email]
          : isPassword
          ? [signup ? AutofillHints.newPassword : AutofillHints.password]
          : null,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: isPassword
            ? IconButton(
                tooltip: hidden ? 'Show password' : 'Hide password',
                onPressed: busy ? null : () => setState(() => hidden = !hidden),
                icon: Icon(
                  hidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              )
            : null,
      ),
      validator: (v) {
        if (v == null || (isPassword ? v.isEmpty : v.trim().isEmpty)) {
          return 'Enter your ${label.toLowerCase()}';
        }
        if (isEmail && !v.trim().contains('@')) {
          return 'Enter your email address';
        }
        if (isPassword && signup && v.length < 6) {
          return 'Use at least 6 characters';
        }
        return null;
      },
    );
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              'assets/branding/magistore.png',
                              width: 44,
                              height: 44,
                              excludeFromSemantics: true,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'MagiStore',
                              style: theme.textTheme.titleLarge,
                            ),
                            const Spacer(),
                            const ShopThemeToggle(),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          pending
                              ? 'Confirm your email'
                              : signup
                              ? 'Create your account'
                              : selected == null
                              ? 'Sign in to MagiStore'
                              : 'Welcome back',
                          style: theme.textTheme.headlineMedium,
                        ),
                        Text(
                          pending
                              ? 'Look for a MagiStore confirmation link in the inbox below.'
                              : signup
                              ? 'Shop books and campus essentials.'
                              : selected == null
                              ? 'Sign in to your campus shop.'
                              : 'Sign in with the account below.',
                        ),
                        const SizedBox(height: 20),
                        if (signup) ...[
                          textField(first, 'First name'),
                          const SizedBox(height: 10),
                          textField(last, 'Last name'),
                          const SizedBox(height: 10),
                        ],
                        if (selected != null)
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.mail_outline,
                                    color: colors.primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      selected,
                                      style: theme.textTheme.titleMedium,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: busy
                                        ? null
                                        : () {
                                            go(
                                              pending
                                                  ? _Step.register
                                                  : _Step.signIn,
                                            );
                                            email.text = selected;
                                          },
                                    child: const Text('Change'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          textField(email, 'Email', isEmail: true),
                        const SizedBox(height: 10),
                        if (pending)
                          Text(
                            'Open the link to confirm your address. If nothing arrives, check spam or request another link.',
                            style: theme.textTheme.bodyMedium,
                          )
                        else
                          textField(password, 'Password', isPassword: true),
                        if (message != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Semantics(
                              liveRegion: true,
                              child: Text(
                                message!,
                                style: TextStyle(
                                  color: isError
                                      ? colors.error
                                      : colors.onSurface,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        if (pending) ...[
                          FilledButton(
                            onPressed: busy
                                ? null
                                : () => go(_Step.signIn, address: selected),
                            child: const Text('Back to sign in'),
                          ),
                          TextButton.icon(
                            onPressed: busy || coolingEmail == selected
                                ? null
                                : () => submit(resend: true),
                            icon: const Icon(Icons.refresh),
                            label: Text(
                              busy
                                  ? 'Requesting link…'
                                  : coolingEmail == selected
                                  ? 'Resend available in a minute'
                                  : 'Resend confirmation email',
                            ),
                          ),
                        ] else ...[
                          FilledButton(
                            onPressed: busy ? null : () => submit(),
                            child: Text(
                              busy
                                  ? (signup
                                        ? 'Creating account…'
                                        : 'Signing in…')
                                  : (signup ? 'Create account' : 'Sign in'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: busy ? null : () => submit(google: true),
                            icon: const Icon(Icons.account_circle_outlined),
                            label: const Text('Continue with Google'),
                          ),
                          TextButton(
                            onPressed: busy
                                ? null
                                : () {
                                    final entered = email.text.trim();
                                    go(
                                      signup ? _Step.signIn : _Step.register,
                                      address: signup && entered.contains('@')
                                          ? entered
                                          : null,
                                    );
                                    email.text = entered;
                                  },
                            child: Text(
                              signup
                                  ? 'Already have an account? Sign in'
                                  : 'New here? Create an account',
                            ),
                          ),
                        ],
                      ],
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
