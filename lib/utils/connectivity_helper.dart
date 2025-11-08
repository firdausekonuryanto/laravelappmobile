import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityHelper {
  static final Connectivity _connectivity = Connectivity();
  static final StreamController<void> _connectionRestoredController =
      StreamController.broadcast();

  static Stream<void> get onConnectionRestored =>
      _connectionRestoredController.stream;

  static bool _wasOffline = false;

  /// Cek koneksi saat ini
  static Future<bool> hasConnection() async {
    final results = await _connectivity.checkConnectivity();
    return results.isNotEmpty && results.first != ConnectivityResult.none;
  }

  /// Jalankan listener perubahan koneksi
  static void initialize() {
    _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) async {
      final bool isOnline =
          results.isNotEmpty && results.first != ConnectivityResult.none;

      // Deteksi perubahan dari offline → online
      if (isOnline && _wasOffline) {
        _connectionRestoredController.add(null);
      }

      _wasOffline = !isOnline;
    });
  }

  /// Jangan lupa dipanggil sekali di main.dart
  static void dispose() {
    _connectionRestoredController.close();
  }
}
