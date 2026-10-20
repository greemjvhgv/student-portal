import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Owner: Annuschka.
///
/// Watches the phone's connection (connectivity_plus). [isOnline] drives
/// the offline banners, and SyncService listens to it to sync
/// automatically when the connection returns (FR7).
class ConnectivityService {
  ConnectivityService._internal();
  static final ConnectivityService instance = ConnectivityService._internal();

  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<void> start() async {
    if (_subscription != null) return;
    _update(await Connectivity().checkConnectivity());
    _subscription = Connectivity().onConnectivityChanged.listen(_update);
  }

  void _update(List<ConnectivityResult> results) {
    isOnline.value = results.any((result) => result != ConnectivityResult.none);
  }
}
