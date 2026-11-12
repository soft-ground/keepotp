import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../otp/base32.dart';
import '../otp/otp_account.dart';
import 'scan_page.dart';

/// Add an account by QR scan, pasted `otpauth://` link, or manual entry.
class AddAccountPage extends StatefulWidget {
  const AddAccountPage({super.key});

  @override
  State<AddAccountPage> createState() => _AddAccountPageState();
}

class _AddAccountPageState extends State<AddAccountPage> {
  final _form = GlobalKey<FormState>();
  final _issuer = TextEditingController();
  final _name = TextEditingController();
  final _secret = TextEditingController();
  final _uri = TextEditingController();
  bool _uriInvalid = false;

  @override
  void dispose() {
    _issuer.dispose();
    _name.dispose();
    _secret.dispose();
    _uri.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final account = await Navigator.of(context).push<OtpAccount>(
      MaterialPageRoute(builder: (_) => const ScanPage()),
    );
    if (account != null && mounted) Navigator.of(context).pop(account);
  }

  void _submitUri() {
    try {
      Navigator.of(context).pop(OtpAccount.fromUri(_uri.text));
    } on FormatException {
      setState(() => _uriInvalid = true);
    }
  }

  void _submitManual() {
    if (!_form.currentState!.validate()) return;
    Navigator.of(context).pop(OtpAccount(
      type: OtpType.totp,
      secret: base32Decode(_secret.text),
      accountName: _name.text.trim(),
      issuer: _issuer.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.addAccount)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.icon(
            onPressed: _scan,
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(l10n.scanQrCode),
          ),
          const SizedBox(height: 24),
          Text(l10n.pasteLinkTitle, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _uri,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: 'otpauth://totp/...',
              errorText: _uriInvalid ? l10n.invalidLink : null,
            ),
            onChanged: (_) => setState(() => _uriInvalid = false),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(onPressed: _submitUri, child: Text(l10n.addFromLink)),
          ),
          const Divider(height: 40),
          Text(l10n.enterManually, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Form(
            key: _form,
            child: Column(
              children: [
                TextFormField(
                  controller: _issuer,
                  decoration: InputDecoration(
                      labelText: l10n.serviceLabel, border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(
                      labelText: l10n.accountLabel, border: const OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _secret,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                      labelText: l10n.secretLabel, border: const OutlineInputBorder()),
                  validator: (v) {
                    try {
                      base32Decode(v ?? '');
                      return null;
                    } on FormatException {
                      return l10n.invalidBase32;
                    }
                  },
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(onPressed: _submitManual, child: Text(l10n.add)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
