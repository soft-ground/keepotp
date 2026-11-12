import 'package:flutter/material.dart';

import 'data/account_store.dart';
import 'l10n/app_localizations.dart';
import 'lock/authenticator.dart';
import 'lock/lock_controller.dart';
import 'lock/lock_gate.dart';
import 'state/accounts_controller.dart';
import 'ui/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(KeepOtpApp(
    controller: AccountsController(SecureAccountStore())..load(),
    lock: LockController(SecureLockSettingsStore(), LocalAuthAuthenticator())..load(),
  ));
}

/// Matches the accent color of the launcher icon.
const _seed = Color(0xFF4FD1C5);

class KeepOtpApp extends StatelessWidget {
  const KeepOtpApp({
    super.key,
    required this.controller,
    required this.lock,
    this.clock = systemClock,
  });

  final AccountsController controller;
  final LockController lock;
  final Clock clock;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: _seed, useMaterial3: true),
      darkTheme: ThemeData(
          colorSchemeSeed: _seed, brightness: Brightness.dark, useMaterial3: true),
      builder: (context, child) => LockGate(controller: lock, child: child!),
      home: HomePage(controller: controller, lock: lock, clock: clock),
    );
  }
}
