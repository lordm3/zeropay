import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/bank_catalog.dart';
import '../../core/models/bank_profile.dart';
import '../../core/providers/app_provider.dart';
import '../../core/utils/error_content.dart';
import '../../widgets/bank_badge.dart';

class BankProfileEditor extends StatefulWidget {
  final BankProfile? profile;
  const BankProfileEditor({super.key, this.profile});

  @override
  State<BankProfileEditor> createState() => _BankProfileEditorState();
}

class _BankProfileEditorState extends State<BankProfileEditor> {
  static const _other = 'Other';

  late TextEditingController _nameCtrl;
  late TextEditingController _last4Ctrl;
  late TextEditingController _typeCtrl;
  late TextEditingController _colorCtrl;
  String? _bankChoice;
  int _pinLength = 4;
  ErrorType _errorType = ErrorType.serverUnavailable;
  bool _isPrimary = false;
  FailureMode _mode = FailureMode.beforePin;
  int _latencyMs = 2500;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl = TextEditingController(text: p?.bankName ?? '');
    _last4Ctrl = TextEditingController(text: p?.accountLast4 ?? '');
    _typeCtrl = TextEditingController(text: p?.accountType ?? 'Savings Account');
    _colorCtrl = TextEditingController(text: p?.badgeColorHex ?? '#004C8F');
    if (p != null) _bankChoice = BankCatalog.find(p.bankName)?.name ?? _other;
    _pinLength = p?.pinLength ?? 4;
    _errorType = p?.defaultErrorType ?? ErrorType.serverUnavailable;
    _isPrimary = p?.isPrimary ?? false;
    _mode = p?.failureMode ?? FailureMode.beforePin;
    _latencyMs = p?.latencyMs ?? 2500;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _last4Ctrl.dispose();
    _typeCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.profile != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Bank Profile' : 'Add Bank Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _bankDropdown(),
          const SizedBox(height: 12),
          if (_bankChoice == _other) ...[
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Bank Name'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _colorCtrl,
                    decoration: InputDecoration(
                      labelText: 'Badge Color (hex)',
                      hintText: '#004C8F',
                      errorText: _colorValid ? null : 'Use 6 hex digits, like #004C8F',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                if (_colorValid) ...[
                  const SizedBox(width: 12),
                  BankBadgeView(
                    bankName: _nameCtrl.text,
                    logoAsset: null,
                    color: parseHexColor(_colorCtrl.text)!,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _last4Ctrl,
            decoration: const InputDecoration(labelText: 'Last 4 Digits'),
            maxLength: 4,
            keyboardType: TextInputType.number,
          ),
          TextField(controller: _typeCtrl, decoration: const InputDecoration(labelText: 'Account Type')),
          const SizedBox(height: 12),
          const SizedBox(height: 4),
          const Text('PIN Length'),
          RadioGroup<int>(
            groupValue: _pinLength,
            onChanged: (v) => setState(() => _pinLength = v!),
            child: Row(
              children: [4, 6].map((l) => Expanded(child: ListTile(
                leading: Radio<int>(value: l),
                title: Text('$l-digit'),
                onTap: () => setState(() => _pinLength = l),
              ))).toList(),
            ),
          ),
          const Text('Error shown for this account'),
          RadioGroup<ErrorType>(
            groupValue: _errorType,
            onChanged: (v) => setState(() => _errorType = v!),
            child: Column(
              children: ErrorType.values.map((t) => ListTile(
                leading: Radio<ErrorType>(value: t),
                title: Text(_errorLabel(t)),
                onTap: () => setState(() => _errorType = t),
              )).toList(),
            ),
          ),
          const SizedBox(height: 8),
          const Text('When the error appears'),
          RadioGroup<FailureMode>(
            groupValue: _mode,
            onChanged: (v) => setState(() => _mode = v!),
            child: Column(
              children: FailureMode.values.map((m) => ListTile(
                leading: Radio<FailureMode>(value: m),
                title: Text(failureModeLabel(m)),
                subtitle: Text(failureModeDescription(m)),
                onTap: () => setState(() => _mode = m),
              )).toList(),
            ),
          ),
          if (_mode == FailureMode.beforePin || _mode == FailureMode.afterPin) ...[
            Text('Spinner before the error: ${(_latencyMs / 1000).toStringAsFixed(1)}s'),
            Slider(
              value: _latencyMs.toDouble(),
              min: 1500,
              max: 5000,
              divisions: 7,
              onChanged: (v) => setState(() => _latencyMs = v.round()),
            ),
          ],
          SwitchListTile(
            title: const Text('Set as Primary'),
            value: _isPrimary,
            onChanged: (v) => setState(() => _isPrimary = v),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _save,
            child: Text(isEdit ? 'Save Changes' : 'Add Profile'),
          ),
        ],
      ),
    );
  }

  bool get _colorValid => parseHexColor(_colorCtrl.text) != null;

  Widget _bankDropdown() {
    return DropdownButtonFormField<String>(
      key: const Key('bank-dropdown'),
      initialValue: _bankChoice,
      isExpanded: true,
      menuMaxHeight: 420,
      decoration: const InputDecoration(labelText: 'Bank'),
      items: [
        for (final bank in BankCatalog.all)
          DropdownMenuItem(
            value: bank.name,
            child: Row(
              children: [
                BankBadgeView(
                  bankName: bank.name,
                  logoAsset: bank.assetPath,
                  color: parseHexColor(bank.colorHex)!,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(bank.name, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        const DropdownMenuItem(
          value: _other,
          child: Row(
            children: [
              SizedBox(width: 36, child: Icon(Icons.palette_outlined, size: 20)),
              SizedBox(width: 12),
              Text(_other),
            ],
          ),
        ),
      ],
      onChanged: _chooseBank,
    );
  }

  void _chooseBank(String? choice) {
    if (choice == null) return;
    setState(() {
      final wasCatalog = _bankChoice != null && _bankChoice != _other;
      _bankChoice = choice;
      final bank = BankCatalog.find(choice);
      if (bank != null) {
        _nameCtrl.text = bank.name;
        _colorCtrl.text = bank.colorHex;
      } else if (wasCatalog) {
        _nameCtrl.clear();
      }
    });
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty || _last4Ctrl.text.isEmpty || !_colorValid) return;
    final provider = context.read<AppProvider>();
    final profile = widget.profile == null
        ? BankProfile.create(
            bankName: _nameCtrl.text,
            accountLast4: _last4Ctrl.text,
            accountType: _typeCtrl.text,
            badgeColorHex: _colorCtrl.text,
            pinLength: _pinLength,
            defaultErrorType: _errorType,
            isPrimary: _isPrimary,
            failureMode: _mode,
            latencyMs: _latencyMs,
          )
        : widget.profile!.copyWith(
            bankName: _nameCtrl.text,
            accountLast4: _last4Ctrl.text,
            accountType: _typeCtrl.text,
            badgeColorHex: _colorCtrl.text,
            pinLength: _pinLength,
            defaultErrorType: _errorType,
            isPrimary: _isPrimary,
            failureMode: _mode,
            latencyMs: _latencyMs,
          );
    provider.saveProfile(profile);
    Navigator.pop(context);
  }

  String _errorLabel(ErrorType t) => switch (t) {
    ErrorType.serverUnavailable => 'Server Unavailable (U16)',
    ErrorType.insufficientFunds => 'Insufficient Funds (Z9)',
    ErrorType.beneficiaryBankDown => 'Beneficiary Bank Down (U28)',
    ErrorType.dailyLimitExceeded => 'Daily Limit Exceeded (U69)',
    ErrorType.accountFrozen => 'Account Frozen (XK)',
    ErrorType.paymentNotAllowed => 'Payment Not Allowed (U30)',
  };
}
