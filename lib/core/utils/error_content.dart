import '../models/bank_profile.dart';

class ErrorContent {
  final String title;
  final String body;
  final String code;

  const ErrorContent({
    required this.title,
    required this.body,
    required this.code,
  });
}

String failureModeLabel(FailureMode mode) => switch (mode) {
  FailureMode.beforePin => 'Before PIN',
  FailureMode.afterPin => 'After PIN',
  FailureMode.longDelay => 'Long Delay',
  FailureMode.indefinite => 'Indefinite',
};

String failureModeDescription(FailureMode mode) => switch (mode) {
  FailureMode.beforePin => 'Fails on the amount screen; PIN is never asked',
  FailureMode.afterPin => 'PIN, then the full failure screen',
  FailureMode.longDelay => 'PIN, 10–20s spinner, then the failure screen',
  FailureMode.indefinite => 'PIN, endless spinner. Hold it 2s to show the error',
};

String errorEnumName(ErrorType type) => switch (type) {
  ErrorType.serverUnavailable => 'SERVER_UNAVAILABLE',
  ErrorType.insufficientFunds => 'INSUFFICIENT_FUNDS',
  ErrorType.beneficiaryBankDown => 'BENEFICIARY_BANK_DOWN',
  ErrorType.dailyLimitExceeded => 'DAILY_LIMIT_EXCEEDED',
  ErrorType.accountFrozen => 'ACCOUNT_FROZEN',
  ErrorType.paymentNotAllowed => 'PAYMENT_NOT_ALLOWED',
};

String errorShortLabel(ErrorType type) => switch (type) {
  ErrorType.serverUnavailable => 'Bank server unavailable',
  ErrorType.insufficientFunds => 'Insufficient funds',
  ErrorType.beneficiaryBankDown => 'Beneficiary bank down',
  ErrorType.dailyLimitExceeded => 'Daily limit reached',
  ErrorType.accountFrozen => 'Debit blocked / Frozen',
  ErrorType.paymentNotAllowed => 'Payment not allowed (refund)',
};

ErrorContent preflightContentFor(ErrorType type) {
  final code = errorContentFor(type).code;
  ErrorContent content(String title, String body) => ErrorContent(title: title, body: body, code: code);
  const notDebited = 'Your money has not been debited';
  return switch (type) {
    ErrorType.serverUnavailable => content(
      'Your bank network is down',
      "You're not able to make payment with your bank. Please try paying from a different bank account.",
    ),
    ErrorType.beneficiaryBankDown => content(
      "Recipient's bank network is down",
      "You're not able to make payment to your recipient's bank. Please try paying to a different bank account.",
    ),
    ErrorType.dailyLimitExceeded => content(notDebited, "You've exceeded the bank limit for this payment."),
    ErrorType.insufficientFunds => content(notDebited, 'Your bank declined this payment due to low account balance.'),
    ErrorType.accountFrozen => content(
      notDebited,
      'Outgoing UPI transfers are temporarily restricted on this account by your bank.',
    ),
    ErrorType.paymentNotAllowed => content(
      'Money will be refunded',
      "Receiver's bank does not allow payments to this bank account. If money was debited, it will be refunded within the next 3 days.",
    ),
  };
}

/// The line under the status steps on the after-PIN failure page.
String receiptErrorLine(ErrorType type) {
  const refund = 'Any amount deducted will be refunded in 3-5 business days.';
  return switch (type) {
    ErrorType.serverUnavailable => "Can't complete payment. Your bank's server isn't responding. $refund",
    ErrorType.insufficientFunds => "Can't complete payment. Your bank declined this due to low account balance.",
    ErrorType.beneficiaryBankDown => "Can't complete payment. Recipient's bank isn't responding. $refund",
    ErrorType.dailyLimitExceeded => "Can't complete payment. You've reached the daily limit set by your bank.",
    ErrorType.accountFrozen => "Can't complete payment. Your bank has restricted outgoing UPI transfers on this account.",
    ErrorType.paymentNotAllowed => "Can't complete payment. Receiver's bank doesn't allow payments to this account. $refund",
  };
}

ErrorContent errorContentFor(ErrorType type, {String bankName = '', String payeeName = ''}) {
  switch (type) {
    case ErrorType.serverUnavailable:
      return const ErrorContent(
        title: 'Bank server unavailable',
        body: "Your bank's servers didn't respond in time. No money has been deducted from your account.",
        code: 'U16',
      );
    case ErrorType.insufficientFunds:
      return ErrorContent(
        title: 'Insufficient funds in account',
        body: 'Your payment was declined by $bankName due to low account balance.',
        code: 'Z9',
      );
    case ErrorType.beneficiaryBankDown:
      return ErrorContent(
        title: "Recipient's bank server is down",
        body: "$payeeName's bank is currently experiencing high transaction failures. Please try another payment method.",
        code: 'U28',
      );
    case ErrorType.dailyLimitExceeded:
      return ErrorContent(
        title: 'Daily UPI limit reached',
        body: "You've reached the maximum daily transaction count or amount permitted by $bankName.",
        code: 'U69',
      );
    case ErrorType.accountFrozen:
      return const ErrorContent(
        title: 'Debit blocked on account',
        body: 'Outgoing UPI transfers are temporarily restricted on this account by your bank.',
        code: 'XK',
      );
    case ErrorType.paymentNotAllowed:
      return const ErrorContent(
        title: 'Money will be refunded',
        body: "Receiver's bank does not allow payments to this bank account. If money was debited, it will be refunded within the next 3 days.",
        code: 'U30',
      );
  }
}
