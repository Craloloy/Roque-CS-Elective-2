import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ecommerce_app/shop/models/shop.dart';
import 'package:flutter_ecommerce_app/shop/pages/app.dart';
import 'package:flutter_ecommerce_app/shop/pages/auth.dart';
import 'package:flutter_ecommerce_app/shop/providers/shop_providers.dart';
import 'package:flutter_ecommerce_app/shop/services/shop_service.dart';

const address = 'student@example.test';

class AuthFixture extends Fake implements ShopService {
  final signInResult = Completer<void>();
  final profileResult = Completer<Account>();
  String? signedInEmail, resentTo;
  int profileAttempts = 0;
  @override
  Future<bool> signup(
    String email,
    String password,
    String first,
    String last,
  ) async => true;
  @override
  Future<void> login(String email, String password) {
    signedInEmail = email;
    return signInResult.future;
  }

  @override
  Future<void> resendConfirmation(String email) async {
    resentTo = email;
  }

  @override
  Stream<String?> sessions() => Stream.value('demo-user');
  @override
  Future<Account> account(String id) {
    if (++profileAttempts == 1) return profileResult.future;
    throw const ShopIssue('No shop profile yet.');
  }
}

Future<void> start(WidgetTester t, ShopService service, Widget home) async {
  await t.pumpWidget(
    ProviderScope(
      overrides: [serviceProvider.overrideWithValue(service)],
      child: home,
    ),
  );
  await t.pump();
}

Future<void> press(WidgetTester t, String label) async {
  final f = find.text(label);
  await t.ensureVisible(f);
  await t.tap(f);
  await t.pump();
}

void main() {
  testWidgets(
    'unconfirmed returning user can request a new link for the same email',
    (t) async {
      final service = AuthFixture();
      await start(
        t,
        service,
        const MaterialApp(home: SignInPage(initialEmail: address)),
      );
      expect(find.text('Welcome back'), findsOneWidget);
      await t.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'sample-pass',
      );
      await press(t, 'Sign in');
      service.signInResult.completeError(const EmailConfirmationNeeded());
      await t.pump();
      expect(find.text('Confirm your email'), findsOneWidget);
      await press(t, 'Resend confirmation email');
      expect(service.resentTo, address);
      await t.pumpWidget(const SizedBox());
      await t.pump();
    },
  );

  testWidgets(
    'signup keeps the email through confirmation, resend and sign-in',
    (t) async {
      final service = AuthFixture();
      await start(t, service, const MaterialApp(home: SignInPage()));
      await press(t, 'New here? Create an account');
      for (final field in {
        'First name': 'Demo',
        'Last name': 'Student',
        'Email': address,
        'Password': 'sample-pass',
      }.entries) {
        await t.enterText(
          find.widgetWithText(TextFormField, field.key),
          field.value,
        );
      }
      await press(t, 'Create account');
      expect(find.text('Confirm your email'), findsOneWidget);
      expect(find.text('Welcome back'), findsNothing);
      expect(find.text(address), findsOneWidget);
      await t.pump(const Duration(minutes: 1));
      await press(t, 'Resend confirmation email');
      expect(service.resentTo, address);
      await press(t, 'Back to sign in');
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text(address), findsOneWidget);
      await t.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'sample-pass',
      );
      await press(t, 'Sign in');
      expect(service.signedInEmail, address);
      await t.pump(shopRequestWait);
      await t.pump();
      expect(find.textContaining('Sign-in took too long'), findsOneWidget);
      await press(t, 'Change');
      expect(
        t
            .widget<TextFormField>(find.widgetWithText(TextFormField, 'Email'))
            .controller!
            .text,
        address,
      );
      await t.pumpWidget(const SizedBox());
      await t.pump();
    },
  );

  testWidgets(
    'a stalled profile lookup shows a manual retry without repeating sign-in',
    (t) async {
      final service = AuthFixture();
      await start(t, service, const SessionGate());
      await t.pump();
      expect(
        find.text('Signed in. Opening your shop profile…'),
        findsOneWidget,
      );
      await t.pump(shopRequestWait);
      await t.pump();
      expect(
        find.textContaining('your shop profile took too long'),
        findsOneWidget,
      );
      await press(t, 'Retry profile');
      await t.pump();
      expect(service.profileAttempts, 2);
      expect(find.text('No shop profile yet.'), findsOneWidget);
      expect(service.signedInEmail, isNull);
    },
  );
}
