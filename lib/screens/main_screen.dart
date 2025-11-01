import 'package:flutter/material.dart';
import 'package:laravelappmobile/screens/index_transaction_screen.dart';
import 'create_transaction_screen.dart';
// import 'rekap_screen.dart';
// import 'setting_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // ✅ Gunakan GlobalKey untuk mengakses IndexTransactionScreenState dari luar
  final GlobalKey<IndexTransactionScreenState> _indexScreenKey = GlobalKey();

  // Fungsi untuk menangani klik pada item bottom navigation
  void _onItemTapped(int index) {
    final isIndexTab = index == 0;

    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
    }

    // ✅ Jika kembali ke tab Index, refresh otomatis
    if (isIndexTab && _indexScreenKey.currentState != null) {
      _indexScreenKey.currentState!.refreshData();
    }
  }

  // ✅ Gunakan late final agar hanya diinisialisasi sekali
  late final List<Widget> _screens = [
    IndexTransactionScreen(key: _indexScreenKey),
    CreateTransactionScreen(onTransactionSuccess: () => _onItemTapped(0)),
    const Center(child: Text("📊 Rekap Screen (Coming Soon)")),
    const Center(child: Text("⚙️ Setting Screen (Coming Soon)")),
  ];

  final List<BottomNavigationBarItem> _bottomItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Index'),
    BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Create'),
    BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Rekap'),
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setting'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ IndexedStack memastikan state antar-tab tetap dipertahankan
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        items: _bottomItems,
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }
}
