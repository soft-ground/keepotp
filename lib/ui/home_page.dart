import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../lock/lock_controller.dart';
import '../otp/otp_account.dart';
import '../state/accounts_controller.dart';
import 'add_account_page.dart';
import 'backup_actions.dart';
import 'settings_page.dart';

typedef Clock = int Function(); // current Unix time in seconds

int systemClock() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

/// How long a copied code stays on the clipboard before it is cleared.
const _clipboardClearSeconds = 30;

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.controller, required this.lock, this.clock = systemClock});

  final AccountsController controller;
  final LockController lock;
  final Clock clock;

  @override
  State<HomePage> createState() => _HomePageState();
}

/// The search button appears once the list is long enough to need it.
const _searchMinAccounts = 6;

class _HomePageState extends State<HomePage> {
  Timer? _ticker;
  int _now = 0;
  bool _searching = false;
  final _searchField = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _now = widget.clock();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = widget.clock());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _searchField.dispose();
    super.dispose();
  }

  void _setSearching(bool on) {
    setState(() {
      _searching = on;
      if (!on) {
        _searchField.clear();
        _query = '';
      }
    });
  }

  Future<void> _edit(OtpAccount a) async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _EditDialog(account: a),
    );
    if (result != null) {
      await widget.controller.rename(a, issuer: result.$1, accountName: result.$2);
    }
  }

  Future<void> _add() async {
    // The scan screen asks for camera permission, which backgrounds the app.
    final accounts = await widget.lock.external(() => Navigator.of(context).push<List<OtpAccount>>(
          MaterialPageRoute(builder: (_) => const AddAccountPage()),
        ));
    if (accounts == null || accounts.isEmpty) return;
    if (accounts.length == 1) {
      await widget.controller.add(accounts.single);
      return;
    }
    // An export from another app: skip accounts that are already here.
    final added = await widget.controller.addAll(accounts);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).importedAccounts(added))));
  }

  Future<void> _copy(OtpAccount a) async {
    final code = a.code(_now);
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).codeCopied(_clipboardClearSeconds))));
    // Clear the clipboard later. The clipboard is deliberately not read first:
    // Android 13+ shows a "pasted from your clipboard" notice on every read.
    // Trade-off: anything the user copies elsewhere within the window is cleared too.
    _clipboardTimer?.cancel();
    _clipboardTimer = Timer(const Duration(seconds: _clipboardClearSeconds), () {
      Clipboard.setData(const ClipboardData(text: ''));
    });
  }

  Timer? _clipboardTimer;

  Future<void> _confirmDelete(OtpAccount a) async {
    final l10n = AppLocalizations.of(context);
    final name = a.issuer.isEmpty ? a.accountName : '${a.issuer} (${a.accountName})';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeAccountTitle),
        content: Text(l10n.removeAccountBody(name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.remove)),
        ],
      ),
    );
    if (ok == true) await widget.controller.remove(a);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) => _scaffold(context, l10n),
    );
  }

  Widget _scaffold(BuildContext context, AppLocalizations l10n) {
    final accounts = widget.controller.accounts;
    final canSearch = widget.controller.loaded && accounts.length >= _searchMinAccounts;
    final searching = _searching && canSearch;
    return Scaffold(
      appBar: AppBar(
        title: searching
            ? TextField(
                controller: _searchField,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(hintText: l10n.searchHint, border: InputBorder.none),
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              )
            : Text(l10n.appTitle),
        actions: [
          if (canSearch)
            IconButton(
              tooltip: searching ? l10n.closeSearchTooltip : l10n.searchTooltip,
              icon: Icon(searching ? Icons.close : Icons.search),
              onPressed: () => _setSearching(!searching),
            ),
          PopupMenuButton<String>(
            onSelected: (v) => switch (v) {
              'export' => widget.lock.external(() => exportEncryptedBackup(context, widget.controller)),
              'import' => widget.lock.external(() => importEncryptedBackup(context, widget.controller)),
              'plain' => widget.lock.external(() => exportPlainText(context, widget.controller)),
              _ => Navigator.of(context).push<void>(
                  MaterialPageRoute(builder: (_) => SettingsPage(lock: widget.lock))),
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'settings', child: Text(l10n.menuSettings)),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'export', child: Text(l10n.menuExportEncrypted)),
              PopupMenuItem(value: 'import', child: Text(l10n.menuImportBackup)),
              PopupMenuItem(value: 'plain', child: Text(l10n.menuExportPlain)),
            ],
          ),
        ],
      ),
      body: _body(accounts, filter: searching ? _query : ''),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: Text(l10n.addAccount),
      ),
    );
  }
}

extension on _HomePageState {
  Widget _tile(OtpAccount a) => _AccountTile(
        account: a,
        now: _now,
        onCopy: () => _copy(a),
        onEdit: () => _edit(a),
        onDelete: () => _confirmDelete(a),
        onNextHotp: () => widget.controller.advanceHotp(a),
      );

  Widget _body(List<OtpAccount> accounts, {required String filter}) {
    if (!widget.controller.loaded) return const Center(child: CircularProgressIndicator());
    if (accounts.isEmpty) return const _EmptyState();

    if (filter.isNotEmpty) {
      // Reordering is off while a filter is active: positions would be ambiguous.
      final hits = [
        for (final a in accounts)
          if ('${a.issuer} ${a.accountName}'.toLowerCase().contains(filter)) a,
      ];
      if (hits.isEmpty) {
        return Center(child: Text(AppLocalizations.of(context).noSearchResults));
      }
      return ListView.separated(
        itemCount: hits.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) => _tile(hits[i]),
      );
    }

    // Long-press an account (or use the accessibility actions) to drag it.
    return ReorderableListView.builder(
      itemCount: accounts.length,
      // newIndex is already the final position (the removed item is accounted for).
      onReorderItem: (oldIndex, newIndex) => widget.controller.move(oldIndex, newIndex),
      itemBuilder: (_, i) => Column(
        key: ObjectKey(accounts[i]),
        mainAxisSize: MainAxisSize.min,
        children: [_tile(accounts[i]), const Divider(height: 1)],
      ),
    );
  }
}

class _EditDialog extends StatefulWidget {
  const _EditDialog({required this.account});

  final OtpAccount account;

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late final _issuer = TextEditingController(text: widget.account.issuer);
  late final _name = TextEditingController(text: widget.account.accountName);
  bool _nameMissing = false;

  @override
  void dispose() {
    _issuer.dispose();
    _name.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().isEmpty) {
      setState(() => _nameMissing = true);
      return;
    }
    Navigator.pop(context, (_issuer.text, _name.text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.editAccountTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _issuer,
            decoration: InputDecoration(
                labelText: l10n.serviceLabel, border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            onChanged: (_) => setState(() => _nameMissing = false),
            decoration: InputDecoration(
              labelText: l10n.accountLabel,
              border: const OutlineInputBorder(),
              errorText: _nameMissing ? l10n.fieldRequired : null,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(l10n.noAccountsTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              l10n.noAccountsBody,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.account,
    required this.now,
    required this.onCopy,
    required this.onEdit,
    required this.onDelete,
    required this.onNextHotp,
  });

  final OtpAccount account;
  final int now;
  final VoidCallback onCopy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onNextHotp;

  static String _group(String code) {
    final h = code.length ~/ 2;
    return '${code.substring(0, h)} ${code.substring(h)}';
  }

  @override
  Widget build(BuildContext context) {
    final isTotp = account.type == OtpType.totp;
    final remaining = isTotp ? account.period - (now % account.period) : 0;
    final low = isTotp && remaining <= 5;
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onCopy,
      title: Text(account.issuer.isEmpty ? account.accountName : account.issuer),
      subtitle: Text(account.issuer.isEmpty ? '' : account.accountName),
      isThreeLine: false,
      leading: isTotp
          ? SizedBox(
              width: 36,
              height: 36,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(
                  value: remaining / account.period,
                  strokeWidth: 3,
                  color: low ? scheme.error : scheme.primary,
                ),
                Text('$remaining', style: Theme.of(context).textTheme.labelSmall),
              ]),
            )
          : IconButton(
              tooltip: AppLocalizations.of(context).nextCode,
              icon: const Icon(Icons.refresh),
              onPressed: onNextHotp,
            ),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(
          _group(account.code(now)),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
                color: low ? scheme.error : null,
              ),
        ),
        PopupMenuButton<void>(
          itemBuilder: (_) => [
            PopupMenuItem(onTap: onEdit, child: Text(AppLocalizations.of(context).menuEdit)),
            PopupMenuItem(onTap: onDelete, child: Text(AppLocalizations.of(context).remove)),
          ],
        ),
      ]),
    );
  }
}
