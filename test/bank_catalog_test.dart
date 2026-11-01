import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zpay/core/models/bank_catalog.dart';
import 'package:zpay/core/models/bank_profile.dart';
import 'package:zpay/core/providers/app_provider.dart';
import 'package:zpay/screens/stealth/bank_profile_editor.dart';
import 'package:zpay/widgets/bank_badge.dart';

Future<AppProvider> pumpEditor(WidgetTester tester, {BankProfile? profile}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  FlutterSecureStorage.setMockInitialValues({});
  final provider = AppProvider();
  await provider.init();
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(home: BankProfileEditor(profile: profile)),
    ),
  );
  await tester.pumpAndSettle();
  return provider;
}

Future<void> choose(WidgetTester tester, String item) async {
  await tester.tap(find.byKey(const Key('bank-dropdown')));
  await tester.pumpAndSettle();
  await tester.dragUntilVisible(find.text(item), find.byType(Scrollable).last, const Offset(0, -200));
  await tester.pumpAndSettle();
  await tester.tap(find.text(item).last);
  await tester.pumpAndSettle();
}

Future<void> save(WidgetTester tester) async {
  await tester.scrollUntilVisible(find.text('Add Profile'), 300, scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Add Profile'));
  await tester.pumpAndSettle();
}

void main() {
  test('every catalog bank has a bundled logo and valid colour', () {
    expect(BankCatalog.all.length, greaterThanOrEqualTo(25));
    expect(BankCatalog.all.map((b) => b.name).toSet().length, BankCatalog.all.length);
    for (final bank in BankCatalog.all) {
      expect(File(bank.assetPath).existsSync(), isTrue, reason: bank.assetPath);
      expect(parseHexColor(bank.colorHex), isNotNull, reason: bank.name);
    }
  });

  test('default accounts resolve to catalog logos', () {
    for (final profile in BankProfile.defaults()) {
      expect(BankCatalog.find(profile.bankName), isNotNull, reason: profile.bankName);
    }
  });

  test('bank names match loosely and unknown names stay custom', () {
    expect(BankCatalog.find('  hdfc bank ')?.code, 'hdfc');
    expect(BankCatalog.find('Fake Bank'), isNull);
  });

  test('hex colours need six digits', () {
    expect(parseHexColor('#004C8F'), const Color(0xFF004C8F));
    expect(parseHexColor('004c8f'), const Color(0xFF004C8F));
    expect(parseHexColor('#04F'), isNull);
    expect(parseHexColor('blue'), isNull);
  });

  testWidgets('choosing a listed bank saves its name and shows no custom fields', (tester) async {
    final provider = await pumpEditor(tester);
    await choose(tester, 'Axis Bank');
    expect(find.text('Badge Color (hex)'), findsNothing);

    await tester.enterText(find.widgetWithText(TextField, 'Last 4 Digits'), '1234');
    await save(tester);
    final saved = provider.profiles.firstWhere((p) => p.accountLast4 == '1234');
    expect(saved.bankName, 'Axis Bank');
    expect(saved.badgeColorHex, '#97144D');
  });

  testWidgets('Other takes a custom name and blocks an invalid hex', (tester) async {
    final provider = await pumpEditor(tester);
    final before = provider.profiles.length;
    await choose(tester, 'Other');
    await tester.enterText(find.widgetWithText(TextField, 'Bank Name'), 'Town Bank');
    await tester.enterText(find.widgetWithText(TextField, 'Badge Color (hex)'), 'blue');
    await tester.enterText(find.widgetWithText(TextField, 'Last 4 Digits'), '1234');
    await tester.pump();
    expect(find.text('Use 6 hex digits, like #004C8F'), findsOneWidget);

    await save(tester);
    expect(provider.profiles.length, before);

    await tester.drag(find.byType(ListView), const Offset(0, 3000));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Badge Color (hex)'), '#123456');
    await save(tester);
    final saved = provider.profiles.firstWhere((p) => p.bankName == 'Town Bank');
    expect(saved.badgeColorHex, '#123456');
  });

  testWidgets('editing a custom bank opens on Other', (tester) async {
    final custom = BankProfile.create(bankName: 'Town Bank', accountLast4: '1111', accountType: 'Savings Account', badgeColorHex: '#123456');
    await pumpEditor(tester, profile: custom);
    expect(find.widgetWithText(TextField, 'Bank Name'), findsOneWidget);
    expect(find.text('#123456'), findsOneWidget);
  });
}
