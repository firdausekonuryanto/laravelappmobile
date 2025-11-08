import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:laravelappmobile/utils/connectivity_helper.dart';
import 'screens/main_screen.dart';
import 'services/sync_service.dart';
import 'package:laravelappmobile/utils/connectivity_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 Load .env file
  try {
    await dotenv.load(fileName: ".env");
    print("✅ ENV loaded successfully: ${dotenv.env['API_BASE_URL']}");
  } catch (e) {
    print("❌ Error loading .env: $e");
  }

  // 🔹 Jalankan sinkronisasi awal (kalau ada transaksi offline)
  await SyncService().syncPendingTransactions();

  // 🔹 Inisialisasi konektivitas listener global
  ConnectivityHelper.initialize();

  // 🔹 Jalankan listener manual untuk logging dan auto-sync
  Connectivity().onConnectivityChanged.listen((
    List<ConnectivityResult> results,
  ) async {
    final bool hasConnection =
        results.isNotEmpty && results.any((r) => r != ConnectivityResult.none);

    if (hasConnection) {
      print("📶 Koneksi internet aktif — sinkronisasi transaksi...");
      await SyncService().syncPendingTransactions();
    } else {
      print("📴 Tidak ada koneksi — mode offline aktif");
    }
  });

  // 🔹 Jalankan aplikasi
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transaction App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
