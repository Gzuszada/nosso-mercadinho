import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mercado/app_providers.dart';
import 'package:mercado/features/cloud/data/cloud_auth_service.dart';
import 'package:mercado/features/cloud/presentation/auth_screen.dart';

class _RecordingFirebaseAuth extends MockFirebaseAuth {
  String? sentEmail;
  ActionCodeSettings? sentActionCodeSettings;
  final String? errorCode;

  _RecordingFirebaseAuth({this.errorCode});

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async {
    if (errorCode != null) {
      throw FirebaseAuthException(code: errorCode!);
    }
    sentEmail = email;
    sentActionCodeSettings = actionCodeSettings;
  }
}

void main() {
  group('CloudAuthService.sendPasswordResetEmail', () {
    test('envia o e-mail com a URL de retorno do site', () async {
      final auth = _RecordingFirebaseAuth();
      final service = CloudAuthService(
        auth: auth,
        firestore: FakeFirebaseFirestore(),
      );

      await service.sendPasswordResetEmail(email: '  pessoa@example.com  ');

      expect(auth.sentEmail, 'pessoa@example.com');
      expect(
        auth.sentActionCodeSettings?.url,
        'https://nosso-mercado-casa.web.app',
      );
      expect(auth.sentActionCodeSettings?.handleCodeInApp, isFalse);
    });

    test('recusa e-mail vazio ou sem @ antes de chamar o Firebase', () async {
      final auth = _RecordingFirebaseAuth();
      final service = CloudAuthService(
        auth: auth,
        firestore: FakeFirebaseFirestore(),
      );

      await expectLater(
        service.sendPasswordResetEmail(email: 'email-invalido'),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Informe um e-mail válido.',
          ),
        ),
      );
      expect(auth.sentEmail, isNull);
    });

    test('não revela quando o e-mail não possui uma conta', () async {
      final auth = _RecordingFirebaseAuth(errorCode: 'user-not-found');
      final service = CloudAuthService(
        auth: auth,
        firestore: FakeFirebaseFirestore(),
      );

      await expectLater(
        service.sendPasswordResetEmail(email: 'sem-conta@example.com'),
        completes,
      );
    });
  });

  testWidgets('aplicativo oferece recuperação de senha e confirma o envio', (
    tester,
  ) async {
    final auth = _RecordingFirebaseAuth();
    final service = CloudAuthService(
      auth: auth,
      firestore: FakeFirebaseFirestore(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [cloudAuthServiceProvider.overrideWithValue(service)],
        child: const MaterialApp(home: AuthScreen()),
      ),
    );

    expect(find.text('Esqueci minha senha'), findsOneWidget);
    expect(
      find.text('A redefinição será concluída com segurança no navegador.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('auth-forgot-password-unavailable')),
      findsNothing,
    );

    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'pessoa@example.com',
    );
    await tester.tap(find.byKey(const Key('auth-forgot-password')));
    await tester.pumpAndSettle();

    expect(auth.sentEmail, 'pessoa@example.com');
    expect(
      find.text(
        'Se o e-mail tiver uma conta, enviaremos as instruções para '
        'redefinir a senha.',
      ),
      findsOneWidget,
    );
  });
}
