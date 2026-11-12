import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'lock_controller.dart';

/// Hides [child] while the app is locked and whenever the app is not in the
/// foreground (so the iOS app-switcher snapshot never shows codes).
///
/// While locked the child is not built at all, so no secrets stay in the
/// widget tree. While merely covered (backgrounded but unlocked) the child
/// stays mounted and keeps its state; it is only hidden.
class LockGate extends StatefulWidget {
  const LockGate({super.key, required this.controller, required this.child});

  final LockController controller;
  final Widget child;

  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> with WidgetsBindingObserver {
  bool _foreground = true;
  final _childKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final fg = state == AppLifecycleState.resumed;
    if (state == AppLifecycleState.hidden || state == AppLifecycleState.paused) {
      widget.controller.onBackgrounded();
    } else if (fg) {
      widget.controller.onForegrounded();
    }
    setState(() => _foreground = fg);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final c = widget.controller;
        final covered = !c.loaded || !_foreground;
        return Stack(
          fit: StackFit.expand,
          children: [
            // The app stays mounted while covered (only hidden): tearing it down
            // on every background trip would drop open screens and orphan
            // pending futures (file picker, camera permission, dialogs).
            if (c.loaded && !c.locked)
              Offstage(
                offstage: covered,
                child: KeyedSubtree(key: _childKey, child: widget.child),
              ),
            if (c.loaded && c.locked) LockScreen(controller: c),
            if (covered) const _PrivacyCover(),
          ],
        );
      },
    );
  }
}

class _PrivacyCover extends StatelessWidget {
  const _PrivacyCover();

  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: Theme.of(context).colorScheme.surface, child: const SizedBox.expand());
}

class LockScreen extends StatefulWidget {
  const LockScreen({super.key, required this.controller});

  final LockController controller;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  @override
  void initState() {
    super.initState();
    // Prompt once when the lock screen appears; the button retries after a cancel.
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.controller.unlock());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context).lockedTitle,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: widget.controller.unlock,
                icon: const Icon(Icons.fingerprint),
                label: Text(AppLocalizations.of(context).unlock),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
