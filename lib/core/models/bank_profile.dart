import 'package:uuid/uuid.dart';

enum ErrorType {
  serverUnavailable,
  insufficientFunds,
  beneficiaryBankDown,
  dailyLimitExceeded,
  accountFrozen,
  paymentNotAllowed,
}

enum FailureMode { beforePin, afterPin, longDelay, indefinite }

enum BadgeShape { squareKeyhole, circle, roundedRect }

class BankProfile {
  final String id;
  final String bankName;
  final String accountLast4;
  final String accountType;
  final String badgeColorHex;
  final BadgeShape badgeShape;
  final int pinLength;
  final ErrorType defaultErrorType;
  final bool isPrimary;
  final FailureMode failureMode;
  final int latencyMs;

  const BankProfile({
    required this.id,
    required this.bankName,
    required this.accountLast4,
    required this.accountType,
    required this.badgeColorHex,
    required this.badgeShape,
    required this.pinLength,
    required this.defaultErrorType,
    required this.isPrimary,
    this.failureMode = FailureMode.beforePin,
    this.latencyMs = 2500,
  });

  factory BankProfile.create({
    required String bankName,
    required String accountLast4,
    required String accountType,
    required String badgeColorHex,
    BadgeShape badgeShape = BadgeShape.squareKeyhole,
    int pinLength = 4,
    ErrorType defaultErrorType = ErrorType.serverUnavailable,
    bool isPrimary = false,
    FailureMode failureMode = FailureMode.beforePin,
    int latencyMs = 2500,
  }) {
    return BankProfile(
      id: const Uuid().v4(),
      bankName: bankName,
      accountLast4: accountLast4,
      accountType: accountType,
      badgeColorHex: badgeColorHex,
      badgeShape: badgeShape,
      pinLength: pinLength,
      defaultErrorType: defaultErrorType,
      isPrimary: isPrimary,
      failureMode: failureMode,
      latencyMs: latencyMs,
    );
  }

  BankProfile copyWith({
    String? bankName,
    String? accountLast4,
    String? accountType,
    String? badgeColorHex,
    BadgeShape? badgeShape,
    int? pinLength,
    ErrorType? defaultErrorType,
    bool? isPrimary,
    FailureMode? failureMode,
    int? latencyMs,
  }) {
    return BankProfile(
      id: id,
      bankName: bankName ?? this.bankName,
      accountLast4: accountLast4 ?? this.accountLast4,
      accountType: accountType ?? this.accountType,
      badgeColorHex: badgeColorHex ?? this.badgeColorHex,
      badgeShape: badgeShape ?? this.badgeShape,
      pinLength: pinLength ?? this.pinLength,
      defaultErrorType: defaultErrorType ?? this.defaultErrorType,
      isPrimary: isPrimary ?? this.isPrimary,
      failureMode: failureMode ?? this.failureMode,
      latencyMs: latencyMs ?? this.latencyMs,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'bankName': bankName,
    'accountLast4': accountLast4,
    'accountType': accountType,
    'badgeColorHex': badgeColorHex,
    'badgeShape': badgeShape.name,
    'pinLength': pinLength,
    'defaultErrorType': defaultErrorType.name,
    'isPrimary': isPrimary,
    'failureMode': failureMode.name,
    'latencyMs': latencyMs,
  };

  factory BankProfile.fromJson(Map<String, dynamic> json) => BankProfile(
    id: json['id'] as String,
    bankName: json['bankName'] as String,
    accountLast4: json['accountLast4'] as String,
    accountType: json['accountType'] as String,
    badgeColorHex: json['badgeColorHex'] as String,
    badgeShape: BadgeShape.values.byName(json['badgeShape'] as String),
    pinLength: json['pinLength'] as int,
    defaultErrorType: ErrorType.values.byName(json['defaultErrorType'] as String),
    isPrimary: json['isPrimary'] as bool,
    failureMode: FailureMode.values.byName(json['failureMode'] as String? ?? FailureMode.beforePin.name),
    latencyMs: json['latencyMs'] as int? ?? 2500,
  );

  static List<BankProfile> defaults() => [
    BankProfile(
      id: 'sbi-default',
      bankName: 'State Bank of India',
      accountLast4: '8912',
      accountType: 'Savings Account',
      badgeColorHex: '#22409A',
      badgeShape: BadgeShape.squareKeyhole,
      pinLength: 6,
      defaultErrorType: ErrorType.serverUnavailable,
      isPrimary: true,
    ),
    BankProfile(
      id: 'hdfc-default',
      bankName: 'HDFC Bank',
      accountLast4: '4821',
      accountType: 'Savings Account',
      badgeColorHex: '#004C8F',
      badgeShape: BadgeShape.squareKeyhole,
      pinLength: 4,
      defaultErrorType: ErrorType.insufficientFunds,
      isPrimary: false,
      failureMode: FailureMode.afterPin,
    ),
    BankProfile(
      id: 'icici-default',
      bankName: 'ICICI Bank',
      accountLast4: '3309',
      accountType: 'Salary Account',
      badgeColorHex: '#B02A28',
      badgeShape: BadgeShape.squareKeyhole,
      pinLength: 4,
      defaultErrorType: ErrorType.beneficiaryBankDown,
      isPrimary: false,
      failureMode: FailureMode.longDelay,
    ),
  ];
}
