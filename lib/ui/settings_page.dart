import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../lock/lock_controller.dart';
import 'content_width.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.lock});

  final LockController lock;

  /// Selectable re-lock delays, in seconds.
  static const _timeouts = [0, 30, 60, 300];

  static String _timeoutLabel(AppLocalizations l10n, int seconds) => switch (seconds) {
        0 => l10n.lockImmediately,
        < 60 => l10n.lockAfterSeconds(seconds),
        _ => l10n.lockAfterMinutes(seconds ~/ 60),
      };

  Future<void> _toggle(BuildContext context, bool value) async {
    final l10n = AppLocalizations.of(context);
    final ok = await lock.setEnabled(value);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(value ? l10n.lockNeedsScreenLock : l10n.lockNotTurnedOff),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ContentWidth(
          child: ListenableBuilder(
        listenable: lock,
        builder: (context, _) => ListView(
          children: [
            if (!lock.supported)
              ListTile(
                leading: Icon(Icons.warning_amber, color: Theme.of(context).colorScheme.error),
                title: Text(l10n.noScreenLockTitle),
                subtitle: Text(l10n.noScreenLockBody),
              ),
            SwitchListTile(
              title: Text(l10n.appLockTitle),
              subtitle: Text(l10n.appLockSubtitle),
              value: lock.enabled && lock.supported,
              onChanged: (v) => _toggle(context, v),
            ),
            ListTile(
              enabled: lock.enabled && lock.supported,
              title: Text(l10n.lockAfterTitle),
              trailing: DropdownButton<int>(
                value: _timeouts.contains(lock.timeoutSeconds) ? lock.timeoutSeconds : 0,
                onChanged: lock.enabled && lock.supported
                    ? (v) => lock.setTimeoutSeconds(v ?? 0)
                    : null,
                items: [
                  for (final s in _timeouts)
                    DropdownMenuItem(value: s, child: Text(_timeoutLabel(l10n, s))),
                ],
              ),
            ),
          ],
        ),
      )),
    );
  }
}
