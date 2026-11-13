import 'package:flutter/foundation.dart';

import '../data/account_store.dart';
import '../otp/otp_account.dart';

class AccountsController extends ChangeNotifier {
  AccountsController(this._store);

  final AccountStore _store;
  List<OtpAccount> _accounts = [];
  bool loaded = false;

  List<OtpAccount> get accounts => List.unmodifiable(_accounts);

  Future<void> load() async {
    _accounts = await _store.load();
    loaded = true;
    notifyListeners();
  }

  Future<void> add(OtpAccount account) async {
    _accounts = [..._accounts, account];
    await _store.save(_accounts);
    notifyListeners();
  }

  /// Adds accounts whose secret + issuer + name are not already present.
  /// Returns how many were actually added.
  Future<int> addAll(Iterable<OtpAccount> incoming) async {
    String id(OtpAccount a) => '${a.issuer}|${a.accountName}|${a.secret.join(',')}';
    final seen = _accounts.map(id).toSet();
    final fresh = incoming.where((a) => seen.add(id(a))).toList();
    if (fresh.isEmpty) return 0;
    _accounts = [..._accounts, ...fresh];
    await _store.save(_accounts);
    notifyListeners();
    return fresh.length;
  }

  Future<void> remove(OtpAccount account) async {
    _accounts = _accounts.where((a) => !identical(a, account)).toList();
    await _store.save(_accounts);
    notifyListeners();
  }

  /// Changes the service and account name of [account]; the secret and the
  /// position in the list stay as they are.
  Future<void> rename(OtpAccount account, {required String issuer, required String accountName}) async {
    final i = _accounts.indexWhere((a) => identical(a, account));
    if (i < 0) return;
    _accounts = [..._accounts]
      ..[i] = account.copyWith(issuer: issuer.trim(), accountName: accountName.trim());
    await _store.save(_accounts);
    notifyListeners();
  }

  /// Moves the account at [oldIndex] to [newIndex], where [newIndex] is its
  /// position in the final list (the usual "remove, then insert" meaning).
  Future<void> move(int oldIndex, int newIndex) async {
    final n = _accounts.length;
    if (oldIndex < 0 || oldIndex >= n || newIndex < 0 || newIndex >= n || oldIndex == newIndex) {
      return;
    }
    final list = [..._accounts];
    list.insert(newIndex, list.removeAt(oldIndex));
    _accounts = list;
    await _store.save(_accounts);
    notifyListeners();
  }

  /// HOTP accounts advance their counter each time a code is generated.
  Future<void> advanceHotp(OtpAccount account) async {
    final i = _accounts.indexWhere((a) => identical(a, account));
    if (i < 0) return;
    _accounts = [..._accounts]..[i] = account.copyWith(counter: account.counter + 1);
    await _store.save(_accounts);
    notifyListeners();
  }
}
