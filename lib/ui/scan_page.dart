import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../l10n/app_localizations.dart';
import '../otp/google_migration.dart';
import '../otp/otp_account.dart';

/// Scans QR codes and pops with the accounts found.
///
/// Accepts a standard `otpauth://` code (one account) and Google Authenticator
/// export codes (several accounts, possibly spread over several QR codes; the
/// page keeps scanning until every part has been seen).
class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final _collector = MigrationCollector();
  bool _done = false;
  bool _invalid = false;

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final b in capture.barcodes) {
      final raw = b.rawValue;
      if (raw == null) continue;
      try {
        if (isMigrationUri(raw)) {
          final scannedBefore = _collector.scanned;
          final complete = _collector.add(parseMigrationUri(raw));
          if (complete) {
            _done = true;
            Navigator.of(context).pop(_collector.accounts);
          } else if (_collector.scanned != scannedBefore || _invalid) {
            setState(() => _invalid = false);
          }
        } else {
          _done = true;
          Navigator.of(context).pop([OtpAccount.fromUri(raw)]);
        }
        return;
      } on FormatException {
        setState(() => _invalid = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.scanQrCode)),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          if (_collector.scanned > 0 && !_invalid)
            Positioned(
              left: 16,
              right: 16,
              bottom: 32,
              child: Material(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(l10n.scanMigrationProgress(_collector.scanned, _collector.total)),
                ),
              ),
            ),
          if (_invalid)
            Positioned(
              left: 16,
              right: 16,
              bottom: 32,
              child: Material(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
                child: Padding(padding: const EdgeInsets.all(12), child: Text(l10n.scanInvalidQr)),
              ),
            ),
        ],
      ),
    );
  }
}
