import 'dart:convert';
import 'dart:isolate';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../backup/backup.dart';
import '../l10n/app_localizations.dart';
import '../state/accounts_controller.dart';

const minBackupPasswordLength = 8;
const _maxBackupBytes = 5 * 1024 * 1024;

void _snack(BuildContext context, String msg) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

Future<String?> _askPassword(BuildContext context, {required bool confirm}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _PasswordDialog(confirm: confirm),
  );
}

/// Runs [work] in a background isolate behind a progress dialog (Argon2id is slow).
Future<T> _withProgress<T>(BuildContext context, Future<T> Function() work) async {
  final nav = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 20),
          Expanded(child: Text(AppLocalizations.of(ctx).working)),
        ]),
      ),
    ),
  );
  try {
    return await work();
  } finally {
    nav.pop();
  }
}

Future<void> exportEncryptedBackup(BuildContext context, AccountsController c) async {
  final l10n = AppLocalizations.of(context);
  if (c.accounts.isEmpty) return _snack(context, l10n.nothingToBackUp);
  final password = await _askPassword(context, confirm: true);
  if (password == null || !context.mounted) return;

  final accounts = c.accounts;
  final String file;
  try {
    file = await _withProgress(
        context, () => Isolate.run(() => BackupCodec().encrypt(accounts, password)));
  } catch (_) {
    if (context.mounted) _snack(context, l10n.backupFailed);
    return;
  }
  if (!context.mounted) return;

  final path = await FilePicker.saveFile(
    dialogTitle: l10n.saveBackupDialogTitle,
    fileName: 'keep-otp-backup.json',
    bytes: utf8.encode(file),
  );
  if (!context.mounted) return;
  _snack(context, path == null ? l10n.backupCancelled : l10n.backupSaved);
}

Future<void> importEncryptedBackup(BuildContext context, AccountsController c) async {
  final l10n = AppLocalizations.of(context);
  final picked = await FilePicker.pickFiles();
  if (picked.isEmpty || !context.mounted) return;
  final file = picked.first;
  if (((await file.length()) ?? 0) > _maxBackupBytes) {
    if (context.mounted) _snack(context, l10n.invalidBackupFile);
    return;
  }
  final bytes = await file.readAsBytes();
  if (!context.mounted) return;
  final password = await _askPassword(context, confirm: false);
  if (password == null || !context.mounted) return;

  try {
    final text = utf8.decode(bytes);
    final restored =
        await _withProgress(context, () => Isolate.run(() => BackupCodec().decrypt(text, password)));
    final added = await c.addAll(restored);
    if (context.mounted) _snack(context, l10n.importedAccounts(added));
  } on BackupAuthenticationException {
    if (context.mounted) _snack(context, l10n.wrongPasswordOrModified);
  } on BackupFormatException {
    if (context.mounted) _snack(context, l10n.invalidBackupFile);
  } on FormatException {
    if (context.mounted) _snack(context, l10n.invalidBackupFile);
  }
}

/// Plain `otpauth://` export, one link per line. Anyone who gets this file can
/// generate your codes, so the user must confirm the risk first.
Future<void> exportPlainText(BuildContext context, AccountsController c) async {
  final l10n = AppLocalizations.of(context);
  if (c.accounts.isEmpty) return _snack(context, l10n.nothingToExport);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.exportPlainTitle),
      content: Text(l10n.exportPlainBody),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.exportAnyway)),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  final text = c.accounts.map((a) => a.toUri()).join('\n');
  final path = await FilePicker.saveFile(
    dialogTitle: l10n.savePlainDialogTitle,
    fileName: 'keep-otp-export.txt',
    bytes: utf8.encode(text),
  );
  if (context.mounted) _snack(context, path == null ? l10n.exportCancelled : l10n.exported);
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({required this.confirm});
  final bool confirm;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pw.dispose();
    _pw2.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    if (widget.confirm) {
      if (_pw.text.length < minBackupPasswordLength) {
        return setState(() => _error = l10n.passwordTooShort(minBackupPasswordLength));
      }
      if (_pw.text != _pw2.text) return setState(() => _error = l10n.passwordsDoNotMatch);
    } else if (_pw.text.isEmpty) {
      return setState(() => _error = l10n.enterPassword);
    }
    Navigator.pop(context, _pw.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.confirm ? l10n.setBackupPassword : l10n.backupPassword),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.confirm)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(l10n.forgetPasswordWarning),
            ),
          TextField(
            controller: _pw,
            obscureText: true,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.passwordLabel),
          ),
          if (widget.confirm)
            TextField(
              controller: _pw2,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.confirmPasswordLabel),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(onPressed: _submit, child: Text(l10n.ok)),
      ],
    );
  }
}
