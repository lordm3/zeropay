# ZPay

ZPay is a private Android app for de-escalating street solicitation or extortion. It looks and feels like a real UPI payment app, but it can't move money and every payment ends in a believable banking failure.

The full specification is in [`../zeropay_prd.md`](../zeropay_prd.md).

> **Private use only. Do not publish or share this app or its APK.** It includes real bank logos, a GPay-like icon and the label "Google transaction ID". These are approved exceptions for personal use on your own phone.

## Safety rules

- **Never a success:** no success, paid or completed state exists. The app also avoids green ticks and success sounds.
- **No network:** the internet permission is removed, so the app works fully offline.
- **No transaction records:** scans, amounts and notes stay in memory and are never saved.
- **Session purge:** pressing Home, locking the phone or switching apps clears the session and returns to the launch screen.
- **Screenshots blocked:** screenshots, screen recording and the Recents preview are disabled.
- **Encrypted settings:** bank profiles and settings are kept in encrypted local storage.
- **No backups:** Android app backup is turned off.

## Payment flow

### Unlock

Biometric Unlock is on by default. The app asks for fingerprint, face or phone PIN on launch and whenever it returns from the background. The check is skipped if the phone has no screen lock.

### Home

- GPay-style home screen with search, Scan QR, quick actions, People and Businesses.
- Search, Pay anyone and Mobile recharge lead to a dummy entry screen, then the payment page.
- Bank transfer fails with a bank server error.
- Bills, loans, rewards and offers are there for looks and only show an unavailable message.
- Tapping a sample contact opens the payment page for that name. The app has no contacts permission.
- **See transaction history** loads, then fails with a server error.
- **Check bank balance** asks for an account and PIN, then ends in "Unable to check balance".

### Scanner

- Live camera with a GPay-style viewfinder, animated corners and flashlight.
- Reads standard UPI QR codes for the payee name and UPI ID.
- A non-UPI code, or a double-tap inside the viewfinder, uses a fallback "Verified Merchant".
- **Upload from gallery** always fails with a message.
- X and back return to the previous screen. If the app opened directly on the scanner, they go to the home screen.

### Payment page

- After a QR scan, the payee name loads after a simulated network delay. Pay stays disabled until it finishes.
- Shows the payee, amount, selected bank and number pad together.
- **Add a note** is typed directly in the pill, up to 50 characters. The bank row and number pad stay hidden until the keyboard has closed.
- The bank row opens the account picker. Its **Check balance** link and **Add bank account** button both fail with a network-style error.

### PIN page

A UPI PIN page styled like the real one, always light themed. It loads after a simulated delay, then shows the account, amount, 4 or 6 PIN circles and a number pad. Any PIN is accepted, and an incomplete PIN shakes the circles.

### Failure

Each account sets when its error appears:

| Timing | What happens |
|---|---|
| **Before PIN** | Pay spins for the account's delay, then an error card appears on the payment page. No PIN is asked for. |
| **After PIN** | PIN, then a spinner for the account's delay, then the failure page. |
| **Long Delay** | PIN, then a random 10–20 second spinner, then the failure page. |
| **Indefinite** | PIN, then an endless spinner. Hold the spinner for 2 seconds to show the error, or leave the app to clear the session. |

The **before-PIN card** matches GPay's error cards. It offers Dismiss and account switching, and the refund message has an English / हिन्दी toggle.

The **after-PIN failure page** matches GPay's failed payment page, with the status steps, error message, bank, UPI transaction ID and Google transaction ID. It deliberately shows "To" instead of "Paid to" and a grey tick instead of a green one. **Try again** returns to the payment page with the account picker open, and **Close** exits the app.

There are six errors, and each account can use any one:

| Error | Code |
|---|---|
| Server unavailable | U16 |
| Insufficient funds | Z9 |
| Recipient's bank down | U28 |
| Daily limit reached | U69 |
| Account frozen | XK |
| Payment not allowed (refund message) | U30 |

Failures use a double-pulse vibration.

## Configuration

Configuration is hidden. Open it in any of these ways:

- Hold the profile avatar on the home screen for 2 seconds.
- Hold the scanner's flashlight for 3 seconds.
- Hold **Add bank account** in the account picker for 2 seconds.
- Type `0000` as the amount, then tap **Add a note**.

| Setting | What it does |
|---|---|
| **Bank profiles** | Add, edit, reorder or delete accounts. |
| **Profile Initial** | Sets the letter on the home avatar. The default is `A`. |
| **Default Launch Route** | Opens the app on the home screen or directly on the scanner. |
| **App theme** | Follow system, dark (default) or light. |
| **Connection Delay** | 0–3 seconds, default 1.5, with ±30% variation. Used for the payee name and PIN page loading. |
| **Biometric Unlock** | On by default. |
| **Hidden Pay Button Zones** | Off by default. See below. |
| **Launcher name** | Shows the app as ZPay, QuickScan QR or Scanner Utility. |
| **Save & Disguise Now** | Applies the launcher name, clears the session and exits. |
| **Emergency Wipe & Exit** | After confirmation, erases all profiles and settings, restores defaults and exits. |

### Bank profiles

Each account has its own:

- **Bank:** choose from 34 Indian banks with logos, or **Other** for a custom name and hex colour with a live preview.
- **Account details:** last 4 digits, account type and primary account.
- **PIN length:** 4 or 6 digits.
- **Failure behaviour:** error, timing, and a delay of 1.5–5 seconds for Before PIN and After PIN.

Default accounts on a fresh install or after a wipe:

| Account | Timing | Error |
|---|---|---|
| State Bank of India (primary) | Before PIN | Server unavailable |
| HDFC Bank | After PIN | Insufficient funds |
| ICICI Bank | Long Delay | Recipient's bank down |

### Hidden Pay Button Zones

When this is on, where you tap Pay overrides the account:

| Tap | Result |
|---|---|
| **Left 30%** | No balance error, before PIN |
| **Middle 40%** | The account's own error and timing |
| **Right 30%** | Server error, before PIN |

When it's off, the whole button follows the account.

## Development

Built with Flutter 3.44 and Dart 3.12 for Android. It uses provider, go_router, mobile_scanner, flutter_secure_storage, local_auth and vibration.

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

| Path | Contents |
|---|---|
| `lib/screens/` | App screens |
| `lib/widgets/` | Shared widgets, including the bank badge and account picker |
| `lib/core/` | Models, provider, routing, theme and utilities |
| `lib/core/models/bank_catalog.dart` | The bank list |
| `assets/banks/` | Bank logos |
| `assets/branding/` | App logo |
| `design/` | Design references and GPay screenshots |
| `test/` | Automated tests |

To add a bank, put a PNG in `assets/banks/` and add it to `bank_catalog.dart`. Logos come from [`praveenpuglia/indian-banks`](https://github.com/praveenpuglia/indian-banks).

On Windows, `kotlin.incremental=false` in `android/gradle.properties` works around a build failure when the project and the Flutter cache are on different drives.
