import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/palette.dart';
import '../../widgets/choose_account_sheet.dart';
import '../../widgets/timed_long_press.dart';
import '../entry/manual_entry_screen.dart';

const _actionBlue = Color(0xFF0B57D0);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _people = [
    ('Arjun', Color(0xFFF4511E)),
    ('Rahul', Color(0xFFB85C00)),
    ('Priya', Color(0xFF00796B)),
    ('Sneha', Color(0xFF0288D1)),
    ('Vikram', Color(0xFF5E2D91)),
    ('Karthik', Color(0xFF2A2B2D)),
    ('Neha', Color(0xFF0B57D0)),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _actionBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan QR'),
        onPressed: () => context.push(AppRouter.scanner),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        height: 68,
        backgroundColor: palette.surface,
        indicatorColor: _actionBlue,
        onDestinationSelected: (i) {
          if (i != 0) _unavailable(context);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home, color: Colors.white), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.currency_rupee), label: 'Money'),
          NavigationDestination(icon: Icon(Icons.account_circle_outlined), label: 'You'),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            _TopBar(palette: palette),
            const SizedBox(height: 12),
            _OfferBanner(onTap: () => _unavailable(context)),
            const SizedBox(height: 20),
            _IconRow(items: [
              _Item(Icons.qr_code_scanner, 'Scan any QR code', () => context.push(AppRouter.scanner)),
              _Item(Icons.perm_contact_calendar_outlined, 'Pay anyone',
                  () => context.push(AppRouter.entry, extra: EntryMode.contacts)),
              _Item(Icons.account_balance, 'Bank transfer',
                  () => context.push(AppRouter.entry, extra: EntryMode.bankTransfer)),
              _Item(Icons.phone_android, 'Mobile recharge',
                  () => context.push(AppRouter.entry, extra: EntryMode.phone)),
            ], square: true),
            const SizedBox(height: 16),
            _ChipRow(palette: palette, onTap: () => _unavailable(context)),
            const SizedBox(height: 24),
            _SectionTitle('Send money', palette),
            const SizedBox(height: 12),
            _PeopleGrid(people: _people, onPerson: (name) => _pay(context, name), palette: palette),
            const SizedBox(height: 24),
            _SectionTitle('Bills & recharges', palette,
                trailing: 'Manage', onTrailing: () => _unavailable(context)),
            const SizedBox(height: 12),
            _IconRow(items: [
              _Item(Icons.credit_card, 'Credit card bill', () => _unavailable(context)),
              _Item(Icons.sim_card_outlined, 'Prepaid mobile', () => _unavailable(context)),
              _Item(Icons.satellite_alt, 'DTH / Cable TV', () => _unavailable(context)),
              _Item(Icons.phone_android, 'Mobile recharge', () => _unavailable(context)),
            ]),
            const SizedBox(height: 12),
            _IconRow(items: [
              _Item(Icons.tv, 'Broadband', () => _unavailable(context)),
              _Item(Icons.lightbulb_outline, 'Electricity', () => _unavailable(context)),
              _Item(Icons.directions_car_outlined, 'FASTag recharge', () => _unavailable(context)),
              _Item(Icons.smartphone, 'Postpaid mobile', () => _unavailable(context)),
            ]),
            const SizedBox(height: 24),
            _SectionTitle('Credit cards & loans', palette),
            const SizedBox(height: 12),
            _IconRow(items: [
              _Item(Icons.speed, 'Credit score', () => _unavailable(context)),
              _Item(Icons.savings_outlined, 'Personal loan', () => _unavailable(context)),
              _Item(Icons.credit_card, 'Flex credit card', () => _unavailable(context)),
              _Item(Icons.monetization_on_outlined, 'Gold loan', () => _unavailable(context)),
            ]),
            const SizedBox(height: 24),
            _SectionTitle('Offers & rewards', palette),
            const SizedBox(height: 12),
            _IconRow(items: [
              _Item(Icons.emoji_events_outlined, 'Rewards', () => _unavailable(context), const Color(0xFFF9AB00)),
              _Item(Icons.local_offer_outlined, 'Offers', () => _unavailable(context), const Color(0xFFEA6A5E)),
              _Item(Icons.confirmation_number_outlined, 'Referrals', () => _unavailable(context), const Color(0xFF4285F4)),
              _Item(Icons.handshake_outlined, 'Pocket money', () => _unavailable(context), const Color(0xFFE8710A)),
            ]),
            const SizedBox(height: 24),
            _SectionTitle('Manage your money', palette),
            const SizedBox(height: 4),
            _UtilityRow(
              icon: Icons.history,
              label: 'See transaction history',
              palette: palette,
              onTap: () => context.push(AppRouter.history),
            ),
            _UtilityRow(
              icon: Icons.account_balance_outlined,
              label: 'Check bank balance',
              palette: palette,
              onTap: () => _checkBalance(context),
            ),
          ],
        ),
      ),
    );
  }

  void _pay(BuildContext context, String name) {
    final provider = context.read<AppProvider>();
    provider.updateSession(provider.session.copyWith(
      parsedPayeeName: name,
      parsedUpiId: '${name.toLowerCase()}@okaxis',
      merchantCode: '',
    ));
    context.push(AppRouter.amount);
  }

  void _checkBalance(BuildContext context) {
    final provider = context.read<AppProvider>();
    showChooseAccountSheet(context, onContinue: () {
      provider.updateSession(provider.session.copyWith(isBalanceCheck: true));
      context.push(AppRouter.pin);
    });
  }

  void _unavailable(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Service temporarily unavailable. Please try again later.')));
  }
}

class _TopBar extends StatelessWidget {
  final Palette palette;
  const _TopBar({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: palette.container,
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.push(AppRouter.entry, extra: EntryMode.search),
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Icon(Icons.search, color: palette.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Pay friends and merchants',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 15, color: palette.textSecondary)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        TimedLongPress(
          duration: const Duration(seconds: 2),
          onLongPress: () => context.push(AppRouter.stealth),
          child: CircleAvatar(
            key: const Key('profile-avatar'),
            radius: 20,
            backgroundColor: const Color(0xFF00695C),
            child: Text(
              context.select<AppProvider, String>((p) => p.avatarInitial),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

class _OfferBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _OfferBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(colors: [Color(0xFF0E1B33), Color(0xFF16345E)]),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Text('Special pre-approved\nloan offer for you!',
                      overflow: TextOverflow.fade,
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, height: 1.3)),
                ),
                InkWell(
                  onTap: onTap,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(child: Text('Check now', style: TextStyle(color: Color(0xFFA8C7FA)))),
                      SizedBox(width: 8),
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: Color(0xFFA8C7FA),
                        child: Icon(Icons.arrow_forward, size: 16, color: Color(0xFF062E6F)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const CircleAvatar(
            radius: 36,
            backgroundColor: Color(0xFFF9AB00),
            child: Icon(Icons.currency_rupee, size: 36, color: Color(0xFF7A4B00)),
          ),
        ],
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  final Palette palette;
  final VoidCallback onTap;
  const _ChipRow({required this.palette, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const chips = [
      (Icons.contactless_outlined, 'Tap & Pay', 'View cards'),
      (Icons.rocket_launch_outlined, 'UPI Lite', 'Activate'),
      (Icons.emoji_events_outlined, 'Rewards', 'New'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips.map((c) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Material(
            color: palette.container,
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Row(
                  children: [
                    Icon(c.$1, size: 20, color: palette.accent),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.$2, style: TextStyle(fontSize: 11, color: palette.textSecondary)),
                        Text(c.$3, style: TextStyle(fontSize: 12, color: palette.textPrimary)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Palette palette;
  final String? trailing;
  final VoidCallback? onTrailing;

  const _SectionTitle(this.title, this.palette, {this.trailing, this.onTrailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: palette.textPrimary)),
        ),
        if (trailing != null)
          GestureDetector(
            onTap: onTrailing,
            child: Row(
              children: [
                Text(trailing!, style: TextStyle(fontSize: 14, color: palette.accent)),
                Icon(Icons.chevron_right, size: 18, color: palette.accent),
              ],
            ),
          ),
      ],
    );
  }
}

class _Item {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _Item(this.icon, this.label, this.onTap, [this.color]);
}

class _IconRow extends StatelessWidget {
  final List<_Item> items;
  final bool square;
  const _IconRow({required this.items, this.square = false});

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) => Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: item.onTap,
          child: Column(
            children: [
              Container(
                width: square ? 64 : 56,
                height: square ? 56 : 56,
                decoration: BoxDecoration(
                  color: item.color ?? _actionBlue,
                  borderRadius: BorderRadius.circular(square ? 20 : 28),
                ),
                child: Icon(item.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 6),
              Text(item.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: palette.textPrimary)),
            ],
          ),
        ),
      )).toList(),
    );
  }
}

class _PeopleGrid extends StatelessWidget {
  final List<(String, Color)> people;
  final ValueChanged<String> onPerson;
  final Palette palette;

  const _PeopleGrid({required this.people, required this.onPerson, required this.palette});

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[
      ...people.map((p) => _PersonCell(
        name: p.$1,
        palette: palette,
        color: p.$2,
        onTap: () => onPerson(p.$1),
      )),
      _PersonCell(name: 'More', palette: palette, color: palette.container),
    ];
    return Column(
      children: [
        Row(children: cells.sublist(0, 4).map((c) => Expanded(child: c)).toList()),
        const SizedBox(height: 16),
        Row(children: cells.sublist(4).map((c) => Expanded(child: c)).toList()),
      ],
    );
  }
}

class _PersonCell extends StatelessWidget {
  final String name;
  final Color color;
  final Palette palette;
  final VoidCallback? onTap;

  const _PersonCell({required this.name, required this.color, required this.palette, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color,
            child: onTap == null
                ? Icon(Icons.keyboard_arrow_down, color: palette.textPrimary)
                : Text(name[0], style: const TextStyle(fontSize: 24, color: Colors.white)),
          ),
          const SizedBox(height: 6),
          Text(name, style: TextStyle(fontSize: 12, color: palette.textPrimary)),
        ],
      ),
    );
  }
}

class _UtilityRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Palette palette;
  final VoidCallback onTap;

  const _UtilityRow({required this.icon, required this.label, required this.palette, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: palette.textSecondary),
      title: Text(label, style: TextStyle(fontSize: 15, color: palette.textPrimary)),
      trailing: Icon(Icons.chevron_right, color: palette.textSecondary),
      onTap: onTap,
    );
  }
}
