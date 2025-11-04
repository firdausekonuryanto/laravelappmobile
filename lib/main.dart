import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'screens/main_screen.dart';
import 'services/sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    print("✅ ENV loaded successfully: ${dotenv.env['API_BASE_URL']}");
  } catch (e) {
    print("❌ Error loading .env: $e");
  }

  // Jalankan sinkronisasi transaksi offline saat startup
  await SyncService().syncPendingTransactions();

  // Jalankan listener untuk koneksi (akan sinkron otomatis jika online)
  Connectivity().onConnectivityChanged.listen((
    List<ConnectivityResult> results,
  ) async {
    final hasConnection =
        results.isNotEmpty && results.any((r) => r != ConnectivityResult.none);

    if (hasConnection) {
      print("📶 Koneksi internet aktif — sinkronisasi transaksi...");
      await SyncService().syncPendingTransactions();
    } else {
      print("📴 Tidak ada koneksi — mode offline aktif");
    }
  });

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
