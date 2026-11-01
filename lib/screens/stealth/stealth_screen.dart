import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/models/bank_profile.dart';
import '../../core/providers/app_provider.dart';
import '../../core/theme/palette.dart';
import '../../core/utils/app_exit.dart';
import '../../core/utils/error_content.dart';
import '../../widgets/bank_badge.dart';
import 'bank_profile_editor.dart';

class StealthScreen extends StatelessWidget {
  const StealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final palette = Palette.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: palette.surface,
        title: const Text('Configuration'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Row(
            children: [
              Expanded(child: _Heading('Simulated Bank Profiles', palette)),
              TextButton.icon(
                onPressed: () => _openEditor(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Profile'),
              ),
            ],
          ),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: provider.profiles.length,
            onReorderItem: (oldIdx, newIdx) => provider.reorderProfiles(oldIdx, newIdx),
            itemBuilder: (context, idx) {
              final p = provider.profiles[idx];
              return Padding(
                key: ValueKey(p.id),
                padding: const EdgeInsets.only(bottom: 8),
                child: _ProfileCard(
                  profile: p,
                  index: idx,
                  palette: palette,
                  onEdit: () => _openEditor(context, p),
                  onDelete: provider.profiles.length > 1 ? () => _confirmDelete(context, provider, p) : null,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _AvatarCard(provider: provider, palette: palette),
          const SizedBox(height: 16),
          _Heading('Default Launch Route', palette),
          const SizedBox(height: 8),
          _RouteTile(
            icon: Icons.dashboard_outlined,
            title: 'Screen 0: GPay Dashboard',
            subtitle: 'Contacts, search pill & balance traps',
            selected: provider.launchRoute == LaunchRoute.home,
            palette: palette,
            onTap: () => provider.setLaunchRoute(LaunchRoute.home),
          ),
          const SizedBox(height: 8),
          _RouteTile(
            icon: Icons.qr_code_scanner,
            title: 'Screen 1: Direct Scanner',
            subtitle: 'Instant full viewfinder for rapid deployment',
            selected: provider.launchRoute == LaunchRoute.scanner,
            palette: palette,
            onTap: () => provider.setLaunchRoute(LaunchRoute.scanner),
          ),
          const SizedBox(height: 16),
          _ConnectionDelayCard(provider: provider, palette: palette),
          const SizedBox(height: 16),
          _Card(
            palette: palette,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Heading('Biometric Unlock', palette),
                      const SizedBox(height: 4),
                      Text('Fingerprint, face or phone PIN whenever the app is opened.',
                          style: TextStyle(fontSize: 13, color: palette.textSecondary)),
                    ],
                  ),
                ),
                Switch(value: provider.appLock, onChanged: provider.setAppLock),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Card(
            palette: palette,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Heading('Hidden Pay Button Zones', palette),
                      const SizedBox(height: 4),
                      Text('Left of Pay shows no balance, right shows server down, both before the PIN. The middle follows the account.',
                          style: TextStyle(fontSize: 13, color: palette.textSecondary)),
                    ],
                  ),
                ),
                Switch(
                  key: const Key('tap-zones'),
                  value: provider.tapZones,
                  onChanged: provider.setTapZones,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _CamouflageCard(provider: provider, palette: palette),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: palette.accent,
                foregroundColor: palette.onAccent,
                shape: const StadiumBorder(),
              ),
              onPressed: () => _saveAndDisguise(provider),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save & Disguise Now', overflow: TextOverflow.ellipsis),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: palette.container,
                foregroundColor: palette.error,
                shape: const StadiumBorder(),
              ),
              onPressed: () => _confirmWipe(context, provider),
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('Emergency Wipe & Exit', overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAndDisguise(AppProvider provider) async {
    provider.clearSession();
    await setLauncherAlias(provider.launcherName.alias);
    await finishTask();
  }

  void _openEditor(BuildContext context, [BankProfile? profile]) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => BankProfileEditor(profile: profile)));
  }

  void _confirmDelete(BuildContext context, AppProvider provider, BankProfile p) {
    showDialog(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Delete profile?'),
        content: Text('Remove ${p.bankName} •••• ${p.accountLast4}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.deleteProfile(p.id);
              Navigator.pop(dialog);
            },
            child: Text('Delete', style: TextStyle(color: Palette.of(context).error)),
          ),
        ],
      ),
    );
  }

  void _confirmWipe(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Wipe everything?'),
        content: const Text('All bank profiles and settings will be erased and the app will close.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await provider.wipeAll();
              await setLauncherAlias(provider.launcherName.alias);
              await finishTask();
            },
            child: Text('Wipe & Exit', style: TextStyle(color: Palette.of(context).error)),
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;
  final Palette palette;
  const _Heading(this.text, this.palette);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: palette.textPrimary));
  }
}

class _Card extends StatelessWidget {
  final Palette palette;
  final Widget child;
  const _Card({required this.palette, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: palette.container, borderRadius: BorderRadius.circular(16)),
      child: child,
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Palette palette;
  const _Tag({required this.icon, required this.label, required this.color, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: ShapeDecoration(color: palette.inputPill, shape: const StadiumBorder()),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ),
        ],
      ),
    );
  }
}

String _timingLabel(BankProfile profile) {
  final label = failureModeLabel(profile.failureMode);
  final timed = profile.failureMode == FailureMode.beforePin || profile.failureMode == FailureMode.afterPin;
  return timed ? '$label · ${(profile.latencyMs / 1000).toStringAsFixed(1)}s' : label;
}

class _AvatarCard extends StatefulWidget {
  final AppProvider provider;
  final Palette palette;
  const _AvatarCard({required this.provider, required this.palette});

  @override
  State<_AvatarCard> createState() => _AvatarCardState();
}

class _AvatarCardState extends State<_AvatarCard> {
  late final _controller = TextEditingController(text: widget.provider.avatarInitial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return _Card(
      palette: palette,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Heading('Profile Initial', palette),
                const SizedBox(height: 4),
                Text('The letter on the home screen avatar.',
                    style: TextStyle(fontSize: 13, color: palette.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 56,
            child: TextField(
              key: const Key('avatar-initial'),
              controller: _controller,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              enableSuggestions: false,
              enableIMEPersonalizedLearning: false,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]')),
                LengthLimitingTextInputFormatter(1),
                TextInputFormatter.withFunction(
                  (_, next) => next.copyWith(text: next.text.toUpperCase()),
                ),
              ],
              onChanged: (value) {
                if (value.isNotEmpty) widget.provider.setAvatarInitial(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final BankProfile profile;
  final int index;
  final Palette palette;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _ProfileCard({
    required this.profile,
    required this.index,
    required this.palette,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final code = errorContentFor(profile.defaultErrorType).code;
    return _Card(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BankBadge(profile: profile, width: 40, height: 40, circular: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.bankName,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: palette.textPrimary)),
                    Text('•••• ${profile.accountLast4} • ${profile.accountType}',
                        style: TextStyle(fontSize: 13, color: palette.textSecondary)),
                    if (profile.isPrimary)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: ShapeDecoration(color: palette.accent, shape: const StadiumBorder()),
                          child: Text('Primary Active',
                              style: TextStyle(fontSize: 11, color: palette.onAccent)),
                        ),
                      ),
                  ],
                ),
              ),
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.drag_indicator, size: 20, color: palette.textSecondary),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.edit_outlined, size: 20, color: palette.textSecondary),
                onPressed: onEdit,
              ),
              if (onDelete != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.delete_outline, size: 20, color: palette.error),
                  onPressed: onDelete,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Tag(
                icon: Icons.pin_outlined,
                label: '${profile.pinLength}-digit PIN',
                color: palette.textSecondary,
                palette: palette,
              ),
              _Tag(
                icon: Icons.schedule,
                label: _timingLabel(profile),
                color: palette.textSecondary,
                palette: palette,
              ),
              _Tag(
                icon: Icons.error_outline,
                label: '${errorEnumName(profile.defaultErrorType)} ($code)',
                color: profile.isPrimary ? palette.error : palette.textSecondary,
                palette: palette,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final Palette palette;
  final VoidCallback onTap;

  const _RouteTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.container,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: selected ? palette.accent : palette.inputPill,
                child: Icon(icon, color: selected ? palette.onAccent : palette.textSecondary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: palette.textPrimary)),
                    Text(subtitle, style: TextStyle(fontSize: 13, color: palette.textSecondary)),
                  ],
                ),
              ),
              Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: selected ? palette.accent : palette.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionDelayCard extends StatelessWidget {
  final AppProvider provider;
  final Palette palette;
  const _ConnectionDelayCard({required this.provider, required this.palette});

  @override
  Widget build(BuildContext context) {
    final ms = provider.connectionDelayMs;
    return _Card(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _Heading('Connection Delay', palette)),
              Text(ms == 0 ? 'Off' : '~${(ms / 1000).toStringAsFixed(1)}s',
                  style: TextStyle(fontSize: 13, fontFamily: 'monospace', color: palette.accent)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Name lookup after a QR scan and loading before the PIN page. Varies slightly each time.',
              style: TextStyle(fontSize: 13, color: palette.textSecondary)),
          Slider(
            padding: const EdgeInsets.symmetric(vertical: 12),
            value: ms.toDouble(),
            max: 3000,
            divisions: 6,
            onChanged: (v) => provider.setConnectionDelayMs(v.round()),
          ),
        ],
      ),
    );
  }
}

class _CamouflageCard extends StatelessWidget {
  final AppProvider provider;
  final Palette palette;
  const _CamouflageCard({required this.provider, required this.palette});

  @override
  Widget build(BuildContext context) {
    return _Card(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Heading('Visual Camouflage', palette),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Disguised Launcher Name',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: palette.textPrimary)),
                    Text('Shown in task manager and launcher',
                        style: TextStyle(fontSize: 13, color: palette.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<LauncherName>(
                initialValue: provider.launcherName,
                onSelected: provider.setLauncherName,
                itemBuilder: (_) => LauncherName.values
                    .map((n) => PopupMenuItem(value: n, child: Text(n.label)))
                    .toList(),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 130),
                  child: _Tag(
                    icon: Icons.qr_code_2,
                    label: provider.launcherName.label,
                    color: palette.accent,
                    palette: palette,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Theme Mode Override', style: TextStyle(fontSize: 14, color: palette.textPrimary)),
          const SizedBox(height: 8),
          _ThemeSelector(provider: provider, palette: palette),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: palette.inputPill, borderRadius: BorderRadius.circular(12)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, size: 20, color: palette.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FLAG_SECURE Active',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: palette.textPrimary)),
                      Text('Screenshots, screen recordings and the Recents preview are blocked.',
                          style: TextStyle(fontSize: 13, color: palette.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  final AppProvider provider;
  final Palette palette;
  const _ThemeSelector({required this.provider, required this.palette});

  @override
  Widget build(BuildContext context) {
    const options = [
      (AppThemeMode.system, 'System'),
      (AppThemeMode.dark, 'Dark Mode'),
      (AppThemeMode.light, 'Light Mode'),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: ShapeDecoration(color: palette.surface, shape: const StadiumBorder()),
      child: Row(
        children: options.map((option) {
          final selected = provider.themeMode == option.$1;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => provider.setThemeMode(option.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: selected
                    ? ShapeDecoration(color: palette.inputPill, shape: const StadiumBorder())
                    : null,
                child: Text(option.$2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      color: selected ? palette.textPrimary : palette.textSecondary,
                    )),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
