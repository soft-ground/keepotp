import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../l10n/app_localizations.dart';
import '../otp/otp_account.dart';

/// Scans a QR code and pops with the parsed [OtpAccount].
class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool _done = false;
  bool _invalid = false;

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final b in capture.barcodes) {
      final raw = b.rawValue;
      if (raw == null) continue;
      try {
        final account = OtpAccount.fromUri(raw);
        _done = true;
        Navigator.of(context).pop(account);
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
