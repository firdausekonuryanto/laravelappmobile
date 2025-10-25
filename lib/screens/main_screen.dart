import 'package:flutter/material.dart';
import 'package:laravelappmobile/screens/index_transaction_screen.dart';
import 'create_transaction_screen.dart';
// import rekap dan setting screen jika ada
// import 'rekap_screen.dart';
// import 'setting_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // ✅ GlobalKey untuk mengakses state IndexTransactionScreenState
  final GlobalKey<IndexTransactionScreenState> indexScreenKey = GlobalKey();

  void _onItemTapped(int index) {
    // Memastikan refresh dipanggil setelah tab berpindah ke Index (0)
    final shouldRefresh = index == 0;

    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
    }

    // ✅ PANGGIL REFRESH jika tab yang dipilih adalah Index
    if (shouldRefresh && indexScreenKey.currentState != null) {
      indexScreenKey.currentState!.refreshData();
    }
  }

  // ✅ FIX ERROR: Gunakan 'late final' dan tetapkan GlobalKey
  late final List<Widget> _screens = [
    // Menetapkan key agar state-nya bisa diakses
    IndexTransactionScreen(key: indexScreenKey),
    // Meneruskan _onItemTapped(0) sebagai callback sukses
    CreateTransactionScreen(onTransactionSuccess: () => _onItemTapped(0)),
    const Center(child: Text("Rekap Screen")), // placeholder
    const Center(child: Text("Setting Screen")), // placeholder
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
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        items: _bottomItems,
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}
