import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/services/linkedin_auth_service.dart';
import 'package:flutter_application_1/utils/email_validator.dart';
import 'package:flutter_application_1/utils/password_policy.dart';

void main() {
  group('LoginPage widget', () {
    Future<void> pumpLoginPage(
      WidgetTester tester, {
      LinkedInAuthResult? linkedInResult,
      PasswordResetCodeSender? passwordResetCodeSender,
      PasswordResetSubmitter? passwordResetSubmitter,
    }) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(
            linkedInResult: linkedInResult,
            passwordResetCodeSender: passwordResetCodeSender,
            passwordResetSubmitter: passwordResetSubmitter,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('prefills LinkedIn email and shows returned message', (
      tester,
    ) async {
      await pumpLoginPage(
        tester,
        linkedInResult: const LinkedInAuthResult(
          authFlow: 'linkedin_login_callback',
          provider: 'linkedin',
          email: ' alum@example.com ',
          message: 'LinkedIn sign-in completed.',
          error: '',
          prefill: null,
          user: null,
        ),
      );

      expect(find.text('LinkedIn sign-in completed.'), findsOneWidget);
      expect(find.text('alum@example.com'), findsOneWidget);
    });

    testWidgets('shows email validation error when sign in is tapped empty', (
      tester,
    ) async {
      await pumpLoginPage(tester);

      await tester.tap(find.text('SIGN IN'));
      await tester.pumpAndSettle();

      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Email is required.'), findsOneWidget);
    });

    testWidgets('shows password required after valid email is entered', (
      tester,
    ) async {
      await pumpLoginPage(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'alum@example.com',
      );
      await tester.tap(find.text('SIGN IN'));
      await tester.pumpAndSettle();

      expect(find.text('Password is required.'), findsOneWidget);
    });

    testWidgets('toggles password visibility', (tester) async {
      await pumpLoginPage(tester);

      final passwordField = find.widgetWithText(TextField, 'Password');
      expect(tester.widget<TextField>(passwordField).obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(passwordField).obscureText, isFalse);
    });

    testWidgets('forgot password dialog validates mismatched passwords', (
      tester,
    ) async {
      await pumpLoginPage(
        tester,
        passwordResetCodeSender: ({required email}) async => {
          'ok': true,
          'message': 'Code sent.',
        },
      );

      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'alum@example.com',
      );

      await tester.tap(find.text('Send Code'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Verification Code'),
        '123456',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'New Password'),
        'Password1',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm New Password'),
        'Password2',
      );

      await tester.tap(find.text('Submit New Password'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match.'), findsOneWidget);
    });

    testWidgets('opens register page from login screen', (tester) async {
      await pumpLoginPage(tester);

      await tester.tap(find.text('Register here'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Create your alumni access'), findsOneWidget);
    });
  });

  group('EmailValidator', () {
    test('rejects empty email', () {
      expect(EmailValidator.validate(''), 'Email is required.');
    });

    test('rejects malformed email', () {
      expect(
        EmailValidator.validate('not-an-email'),
        'Enter a valid email address.',
      );
    });

    test('accepts valid email', () {
      expect(EmailValidator.validate('user@example.com'), isNull);
    });
  });

  group('PasswordPolicy', () {
    test('rejects short password', () {
      expect(
        PasswordPolicy.validate('Abc123'),
        'Password must be at least 8 characters long.',
      );
    });

    test('rejects password without uppercase', () {
      expect(
        PasswordPolicy.validate('password1'),
        'Password must include at least one uppercase letter.',
      );
    });

    test('accepts strong password', () {
      expect(PasswordPolicy.validate('Password1'), isNull);
    });
  });
}
