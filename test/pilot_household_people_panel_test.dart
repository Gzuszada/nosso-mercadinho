import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mercado/app_providers.dart';
import 'package:mercado/features/cloud/data/pilot_household_administration_service.dart';
import 'package:mercado/features/cloud/presentation/pilot_household_people_panel.dart';

void main() {
  testWidgets('owner vê pessoas, papel, entrada, e-mail e ações', (
    tester,
  ) async {
    final service = _FakeAdministrationService(
      currentUid: 'owner',
      roster: CloudHouseholdRoster(
        householdId: 'casa',
        ownerUid: 'owner',
        members: [
          CloudHouseholdMember(
            uid: 'owner',
            displayName: 'Owner',
            email: 'owner@example.com',
            role: 'owner',
            joinedAt: DateTime(2026, 11, 19),
          ),
          CloudHouseholdMember(
            uid: 'membro',
            displayName: 'Ana',
            email: 'ana@example.com',
            role: 'member',
            joinedAt: DateTime(2026, 11, 20),
          ),
        ],
      ),
      invites: [
        CloudHouseholdInvite(
          code: 'ABCD1234',
          email: 'convite@example.com',
          expiresAt: DateTime.now().add(const Duration(days: 3)),
        ),
      ],
    );

    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    expect(find.text('Pessoas da casa'), findsOneWidget);
    expect(find.text('Esta casa possui 2 pessoas.'), findsOneWidget);
    expect(find.text('Você é o dono desta casa'), findsOneWidget);
    expect(find.textContaining('Dono'), findsOneWidget);
    expect(find.textContaining('Membro'), findsOneWidget);
    expect(find.textContaining('Entrou em 20/11/2026'), findsOneWidget);
    expect(find.textContaining('ana@example.com'), findsOneWidget);
    expect(find.text('Convites pendentes'), findsOneWidget);
    expect(find.text('convite@example.com'), findsOneWidget);
    expect(find.textContaining('expira em 3 dias'), findsOneWidget);
    expect(find.byKey(const Key('member-actions-membro')), findsOneWidget);

    await tester.tap(find.byKey(const Key('member-actions-membro')));
    await tester.pumpAndSettle();
    expect(find.text('Transferir propriedade'), findsOneWidget);
    expect(find.text('Remover da casa'), findsOneWidget);
  });

  testWidgets('membro vê a lista sem ações administrativas ou e-mails', (
    tester,
  ) async {
    final service = _FakeAdministrationService(
      currentUid: 'membro',
      roster: const CloudHouseholdRoster(
        householdId: 'casa',
        ownerUid: 'owner',
        members: [
          CloudHouseholdMember(
            uid: 'owner',
            displayName: 'Owner',
            email: 'owner@example.com',
            role: 'owner',
            joinedAt: null,
          ),
          CloudHouseholdMember(
            uid: 'membro',
            displayName: 'Ana',
            email: 'ana@example.com',
            role: 'member',
            joinedAt: null,
          ),
        ],
      ),
    );

    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    expect(find.text('Esta casa possui 2 pessoas.'), findsOneWidget);
    expect(find.text('Você é o dono desta casa'), findsNothing);
    expect(find.textContaining('ana@example.com'), findsNothing);
    expect(find.text('Convites pendentes'), findsNothing);
    expect(find.byKey(const Key('member-actions-membro')), findsNothing);
    expect(find.byKey(const Key('member-actions-owner')), findsNothing);
  });
}

Widget _app(PilotHouseholdAdministrationService service) {
  return ProviderScope(
    overrides: [
      pilotHouseholdAdministrationServiceProvider.overrideWithValue(service),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: PilotHouseholdPeoplePanel(householdId: 'casa'),
        ),
      ),
    ),
  );
}

class _FakeAdministrationService extends PilotHouseholdAdministrationService {
  _FakeAdministrationService({
    required this.currentUid,
    required this.roster,
    this.invites = const [],
  }) : super(
         auth: MockFirebaseAuth(
           signedIn: true,
           mockUser: MockUser(uid: currentUid),
         ),
         firestore: FakeFirebaseFirestore(),
         httpClient: MockClient((_) async => http.Response('{}', 200)),
       );

  @override
  final String currentUid;
  final CloudHouseholdRoster roster;
  final List<CloudHouseholdInvite> invites;

  @override
  Future<CloudHouseholdRoster> readRoster(String householdId) async => roster;

  @override
  Future<List<CloudHouseholdInvite>> readInvites(String householdId) async =>
      invites;
}
