import 'bank_profile.dart';

class SessionState {
  final String parsedUpiId;
  final String parsedPayeeName;
  final String merchantCode;
  final String enteredAmount;
  final ErrorType? activeErrorOverride;
  final BankProfile? selectedBank;
  final bool isBankBottomSheetOpen;
  final bool isBalanceCheck;

  const SessionState({
    this.parsedUpiId = '',
    this.parsedPayeeName = '',
    this.merchantCode = '',
    this.enteredAmount = '',
    this.activeErrorOverride,
    this.selectedBank,
    this.isBankBottomSheetOpen = false,
    this.isBalanceCheck = false,
  });

  SessionState copyWith({
    String? parsedUpiId,
    String? parsedPayeeName,
    String? merchantCode,
    String? enteredAmount,
    ErrorType? activeErrorOverride,
    BankProfile? selectedBank,
    bool? isBankBottomSheetOpen,
    bool? isBalanceCheck,
    bool clearErrorOverride = false,
  }) {
    return SessionState(
      parsedUpiId: parsedUpiId ?? this.parsedUpiId,
      parsedPayeeName: parsedPayeeName ?? this.parsedPayeeName,
      merchantCode: merchantCode ?? this.merchantCode,
      enteredAmount: enteredAmount ?? this.enteredAmount,
      activeErrorOverride: clearErrorOverride ? null : (activeErrorOverride ?? this.activeErrorOverride),
      selectedBank: selectedBank ?? this.selectedBank,
      isBankBottomSheetOpen: isBankBottomSheetOpen ?? this.isBankBottomSheetOpen,
      isBalanceCheck: isBalanceCheck ?? this.isBalanceCheck,
    );
  }

  static const empty = SessionState();
}
