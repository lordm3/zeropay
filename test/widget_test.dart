import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zpay/core/models/bank_profile.dart';
import 'package:zpay/core/providers/app_provider.dart';
import 'package:zpay/main.dart';
import 'package:zpay/screens/amount/amount_screen.dart';

Future<AppProvider> pumpApp(WidgetTester tester, {FailureMode? mode = FailureMode.afterPin}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  FlutterSecureStorage.setMockInitialValues({});
  final provider = AppProvider();
  await provider.init();
  if (mode != null) {
    for (final profile in provider.profiles) {
      await provider.saveProfile(profile.copyWith(failureMode: mode));
    }
  }
  await provider.setAppLock(false);
  await tester.pumpWidget(ChangeNotifierProvider.value(value: provider, child: const ZPayApp()));
  await tester.pumpAndSettle();
  return provider;
}

Future<void> openConfig(WidgetTester tester) async {
  final gesture = await tester.startGesture(tester.getCenter(find.byKey(const Key('profile-avatar'))));
  await tester.pump(const Duration(milliseconds: 2100));
  await gesture.up();
  await tester.pumpAndSettle();
}

Future<void> startPayment(WidgetTester tester, {required String amount}) async {
  await tester.tap(find.text('Arjun'));
  await tester.pumpAndSettle();
  for (final digit in amount.split('')) {
    await tester.tap(find.widgetWithText(TextButton, digit));
    await tester.pump();
  }
}

Future<void> tapPay(WidgetTester tester, double fraction) async {
  final pay = find.textContaining('Pay ₹');
  final inkWell = find.ancestor(of: pay, matching: find.byType(InkWell)).first;
  final rect = tester.getRect(inkWell);
  await tester.tapAt(Offset(rect.left + rect.width * fraction, rect.center.dy));
  await tester.pumpAndSettle();
}

Future<void> enterPin(WidgetTester tester, int length, {bool settle = true}) async {
  for (var i = 0; i < length; i++) {
    await tester.tap(find.text('1'));
    await tester.pump();
  }
  await tester.tap(find.byKey(const ValueKey('pin-submit')));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }
}

Future<void> waitForFailure(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 2600));
  await tester.pump(const Duration(milliseconds: 300));
}

final appCalls = <String>[];

void main() {
  setUp(() {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    appCalls.clear();
    messenger.setMockMethodCallHandler(const MethodChannel('zpay/app'), (call) async {
      appCalls.add('${call.method}:${call.arguments}');
      return null;
    });
    messenger.setMockMethodCallHandler(const MethodChannel('vibration'), (_) async => true);
  });

  testWidgets('with zones off the edges of Pay follow the account', (tester) async {
    final provider = await pumpApp(tester);
    expect(provider.tapZones, isFalse);
    await startPayment(tester, amount: '50');
    await tapPay(tester, 0.1);
    expect(provider.session.activeErrorOverride, isNull);
    expect(find.byKey(const ValueKey('pin-submit')), findsOneWidget);
  });

  testWidgets('zones switch persists and resets on wipe', (tester) async {
    final provider = await pumpApp(tester);
    await openConfig(tester);
    final toggle = find.byKey(const Key('tap-zones'));
    await tester.scrollUntilVisible(toggle, 200, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(provider.tapZones, isTrue);

    final reloaded = AppProvider();
    await reloaded.init();
    expect(reloaded.tapZones, isTrue);

    await provider.wipeAll();
    expect(provider.tapZones, isFalse);
  });

  testWidgets('left of Pay always shows the no-balance error before PIN (AC-4)', (tester) async {
    final provider = await pumpApp(tester);
    await startPayment(tester, amount: '2450');
    await provider.setTapZones(true);
    await tapPay(tester, 0.1);
    expect(find.text('Enter your PIN'), findsNothing);
    expect(find.text('Your bank declined this payment due to low account balance.'), findsOneWidget);
  });

  testWidgets('right of Pay always shows the server error before PIN (AC-4)', (tester) async {
    final provider = await pumpApp(tester);
    await provider.saveProfile(provider.profiles.first.copyWith(defaultErrorType: ErrorType.accountFrozen));
    await startPayment(tester, amount: '2450');
    await provider.setTapZones(true);
    await tapPay(tester, 0.85);
    expect(find.text('Enter your PIN'), findsNothing);
    expect(find.text('Your bank network is down'), findsOneWidget);
  });

  testWidgets('note is typed directly in the pill and hides everything below it', (tester) async {
    await pumpApp(tester);
    await startPayment(tester, amount: '50');
    await tester.tap(find.text('Add a note'));
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
    expect(find.widgetWithText(TextButton, '5'), findsNothing);
    expect(find.text('Pay ₹50'), findsNothing);
    expect(find.textContaining('State Bank of India'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Lunch');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'Lunch');
    expect(find.widgetWithText(TextButton, '5'), findsOneWidget);
    expect(find.text('Pay ₹50'), findsOneWidget);
    expect(find.textContaining('State Bank of India'), findsOneWidget);
  });

  testWidgets('bank row, Pay and keypad show together on the amount page', (tester) async {
    await pumpApp(tester);
    await startPayment(tester, amount: '50');
    expect(find.textContaining('State Bank of India'), findsOneWidget);
    expect(find.text('Pay ₹50'), findsOneWidget);
    expect(find.widgetWithText(TextButton, '5'), findsOneWidget);
  });

  testWidgets('dock stays hidden until the keyboard has fully closed', (tester) async {
    await pumpApp(tester);
    await startPayment(tester, amount: '50');
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    expect(find.text('Pay ₹50'), findsNothing);
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(find.text('Pay ₹50'), findsOneWidget);
  });

  testWidgets('typing 0000 and tapping the note pill still opens config', (tester) async {
    await pumpApp(tester);
    await startPayment(tester, amount: '0000');
    await tester.tap(find.text('Add a note'));
    await tester.pumpAndSettle();
    expect(find.text('Configuration'), findsOneWidget);
  });

  testWidgets('try again keeps the amount and opens the sheet, then switches bank (AC-3)', (tester) async {
    await pumpApp(tester);
    await startPayment(tester, amount: '2450');
    await tapPay(tester, 0.5);
    await enterPin(tester, 6);
    await waitForFailure(tester);
    expect(find.textContaining("server isn't responding"), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Choose account to pay with'), findsOneWidget);

    await tester.tap(find.text('HDFC Bank •••• 4821'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Continue with'));
    await tester.pumpAndSettle();
    expect(find.text('Pay ₹2,450'), findsOneWidget);

    await tapPay(tester, 0.5);
    expect(find.byKey(const ValueKey('pin-dot-3')), findsOneWidget);
    expect(find.byKey(const ValueKey('pin-dot-4')), findsNothing);
    expect(find.text('SAVINGS · HDFC Bank · ••• 4821'), findsOneWidget);
    await enterPin(tester, 4);
    await waitForFailure(tester);
    expect(find.textContaining('due to low account balance'), findsOneWidget);
  });

  testWidgets('check balance ends in the U16 failure (AC-6)', (tester) async {
    await pumpApp(tester);
    await tester.scrollUntilVisible(find.text('Check bank balance'), 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Check bank balance'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Continue with'));
    await tester.pumpAndSettle();
    await enterPin(tester, 6);
    await waitForFailure(tester);
    expect(find.text('Unable to check balance'), findsOneWidget);
    expect(find.textContaining('Error: U16'), findsOneWidget);
  });

  testWidgets('backgrounding purges the session to the launch route (AC-2)', (tester) async {
    await pumpApp(tester);
    await startPayment(tester, amount: '2450');
    for (final state in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump();
    for (final state in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();
    expect(find.text('Send money'), findsOneWidget);
    expect(find.textContaining('Paying'), findsNothing);
  });

  testWidgets('each account uses its own timing and error', (tester) async {
    await pumpApp(tester, mode: null);
    await startPayment(tester, amount: '100');
    await tapPay(tester, 0.5);
    expect(find.text('Your bank network is down'), findsOneWidget);

    await tester.tap(find.textContaining('State Bank of India'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('HDFC Bank •••• 4821'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Continue with'));
    await tester.pumpAndSettle();
    await tapPay(tester, 0.5);
    expect(find.byKey(const ValueKey('pin-dot-3')), findsOneWidget);
    await enterPin(tester, 4);
    await waitForFailure(tester);
    expect(find.textContaining('due to low account balance'), findsOneWidget);
  });

  test('profiles saved before per-account timing load with safe defaults', () {
    final json = BankProfile.defaults().first.toJson()
      ..remove('failureMode')
      ..remove('latencyMs');
    final profile = BankProfile.fromJson(json);
    expect(profile.failureMode, FailureMode.beforePin);
    expect(profile.latencyMs, 2500);
  });

  testWidgets('emergency wipe restores defaults, resets the alias and exits', (tester) async {
    final provider = await pumpApp(tester);
    await provider.setLauncherName(LauncherName.quickScan);
    await provider.deleteProfile('icici-default');
    await openConfig(tester);
    final wipe = find.text('Emergency Wipe & Exit');
    await tester.scrollUntilVisible(wipe, 300, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(wipe);
    await tester.pumpAndSettle();
    await tester.tap(wipe);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wipe & Exit'));
    await tester.pump();
    await tester.pump();

    expect(provider.profiles.length, 3);
    expect(provider.launcherName, LauncherName.zpay);
    expect(appCalls, ['setLauncherAlias:LauncherZPay', 'finishTask:null']);
  });

  testWidgets('save and disguise applies the chosen launcher name and exits', (tester) async {
    final provider = await pumpApp(tester);
    await provider.setLauncherName(LauncherName.quickScan);
    await openConfig(tester);
    final save = find.text('Save & Disguise Now');
    await tester.scrollUntilVisible(save, 300, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pump();
    await tester.pump();
    expect(appCalls, ['setLauncherAlias:LauncherQuickScan', 'finishTask:null']);
  });

  testWidgets('name lookup after a scan hides the payee and blocks Pay until it finishes', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    FlutterSecureStorage.setMockInitialValues({});
    final provider = AppProvider();
    await provider.init();
    await provider.setAppLock(false);
    provider.updateSession(provider.session.copyWith(parsedPayeeName: 'Asha', parsedUpiId: 'asha@upi'));
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(home: AmountScreen(lookupPayee: true)),
    ));
    await tester.tap(find.widgetWithText(TextButton, '5'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Paying Asha'), findsNothing);
    expect(find.text('Pay'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Paying Asha'), findsOneWidget);
    expect(find.text('Pay ₹5'), findsOneWidget);
  });

  testWidgets('PIN page shows a loading state before the keypad', (tester) async {
    await pumpApp(tester);
    await startPayment(tester, amount: '500');
    await tester.tap(find.textContaining('Pay ₹'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Enter your PIN'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pin-dot-5')), findsOneWidget);
  });

  testWidgets('connection delay of zero skips the wait', (tester) async {
    final provider = await pumpApp(tester);
    await provider.setConnectionDelayMs(0);
    expect(provider.nextConnectionDelay(), Duration.zero);
  });

  testWidgets('biometric lock blocks the app until unlocked and returns after backgrounding', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    FlutterSecureStorage.setMockInitialValues({});
    var attempts = 0;
    var allow = false;
    final provider = AppProvider(authenticator: () async {
      attempts++;
      return allow;
    });
    await provider.init();
    await tester.pumpWidget(ChangeNotifierProvider.value(value: provider, child: const ZPayApp()));
    await tester.pumpAndSettle();
    expect(attempts, 1);
    expect(find.text('Unlock to continue'), findsOneWidget);
    expect(find.text('Send money'), findsNothing);

    allow = true;
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    expect(find.text('Send money'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(provider.isLocked, isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(attempts, 3);
    expect(find.text('Send money'), findsOneWidget);
  });

  testWidgets('backgrounding during the system prompt does not cancel the unlock', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    final result = Completer<bool>();
    final provider = AppProvider(authenticator: () => result.future);
    await provider.init();
    final pending = provider.unlock();
    provider.lockIfEnabled();
    result.complete(true);
    await pending;
    expect(provider.isLocked, isFalse);
  });

  testWidgets('before PIN fails on the amount screen without asking for a PIN', (tester) async {
    await pumpApp(tester, mode: FailureMode.beforePin);
    await startPayment(tester, amount: '500');
    await tapPay(tester, 0.5);
    expect(find.text('Enter your PIN'), findsNothing);
    expect(find.text('Your bank network is down'), findsOneWidget);
    expect(find.text('Temporarily Unavailable'), findsOneWidget);
    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();
    expect(find.text('Pay ₹500'), findsOneWidget);
  });

  testWidgets('before PIN refund card switches to Hindi', (tester) async {
    final provider = await pumpApp(tester, mode: FailureMode.beforePin);
    await provider.saveProfile(provider.profiles.first.copyWith(defaultErrorType: ErrorType.paymentNotAllowed));
    await startPayment(tester, amount: '500');
    await tapPay(tester, 0.5);
    expect(find.text('Money will be refunded'), findsOneWidget);
    await tester.tap(find.text('हिन्दी'));
    await tester.pumpAndSettle();
    expect(find.text('Money will be refunded'), findsNothing);
  });

  testWidgets('long delay holds for at least 10s, then shows the account error', (tester) async {
    final provider = await pumpApp(tester, mode: FailureMode.longDelay);
    await provider.saveProfile(provider.profiles.first.copyWith(defaultErrorType: ErrorType.insufficientFunds));
    await startPayment(tester, amount: '500');
    await tapPay(tester, 0.5);
    await enterPin(tester, 6, settle: false);
    await tester.pump(const Duration(seconds: 9));
    expect(find.text('Payment failed'), findsNothing);
    await tester.pump(const Duration(seconds: 11));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('due to low account balance'), findsOneWidget);
  });

  testWidgets('indefinite never fails by itself but a 2s hold reveals the error', (tester) async {
    await pumpApp(tester, mode: FailureMode.indefinite);
    await startPayment(tester, amount: '500');
    await tapPay(tester, 0.5);
    await enterPin(tester, 6, settle: false);
    await tester.pump(const Duration(minutes: 5));
    expect(find.text('Payment failed'), findsNothing);
    final gesture = await tester.startGesture(tester.getCenter(find.byType(CircularProgressIndicator)));
    await tester.pump(const Duration(milliseconds: 2100));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining("server isn't responding"), findsOneWidget);
  });

  testWidgets('closing a direct-launch scanner goes to the landing page', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    FlutterSecureStorage.setMockInitialValues({});
    final provider = AppProvider();
    await provider.init();
    await provider.setAppLock(false);
    await provider.setLaunchRoute(LaunchRoute.scanner);
    await tester.pumpWidget(ChangeNotifierProvider.value(value: provider, child: const ZPayApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Scan any QR code to pay'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Send money'), findsOneWidget);
    expect(appCalls, isEmpty);
  });

  testWidgets('profile initial is configurable, persists and resets on wipe', (tester) async {
    final provider = await pumpApp(tester);
    Text avatarText() => tester.widget<Text>(
      find.descendant(of: find.byKey(const Key('profile-avatar')), matching: find.byType(Text)),
    );
    expect(avatarText().data, 'A');

    await openConfig(tester);
    final field = find.byKey(const Key('avatar-initial'));
    await tester.scrollUntilVisible(field, 200, scrollable: find.byType(Scrollable).first);
    await tester.enterText(field, 'm');
    await tester.pump();
    expect(tester.widget<TextField>(field).controller!.text, 'M');
    await tester.enterText(field, '7');
    await tester.pump();
    expect(provider.avatarInitial, 'M');
    await tester.enterText(field, 'k');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(avatarText().data, 'K');

    final reloaded = AppProvider();
    await reloaded.init();
    expect(reloaded.avatarInitial, 'K');

    await provider.wipeAll();
    expect(provider.avatarInitial, 'A');
  });

  testWidgets('after-PIN failure page never shows paid wording or a green tick (AC-1)', (tester) async {
    await pumpApp(tester);
    await startPayment(tester, amount: '50');
    await tapPay(tester, 0.5);
    await enterPin(tester, 6, settle: false);
    await waitForFailure(tester);
    expect(find.text('Payment failed'), findsOneWidget);
    expect(find.text('Payment started'), findsOneWidget);
    expect(find.text('To'), findsOneWidget);
    expect(find.textContaining('Paid'), findsNothing);
    final tick = tester.widget<Icon>(find.byIcon(Icons.check_circle_outline));
    final color = tick.color!;
    expect(color.g - color.r, lessThan(0.05), reason: 'tick must stay a neutral grey');
    expect(color.g - color.b, lessThan(0.05), reason: 'tick must stay a neutral grey');
  });

  testWidgets('avatar opens the config screen only after two seconds', (tester) async {
    await pumpApp(tester);
    final gesture = await tester.startGesture(tester.getCenter(find.byKey(const Key('profile-avatar'))));
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('Configuration'), findsNothing);
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('Configuration'), findsOneWidget);
  });
}
