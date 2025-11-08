import 'package:flutter/material.dart';
import 'package:laravelappmobile/screens/index_transaction_screen.dart';
import 'create_transaction_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final GlobalKey _indexScreenKey = GlobalKey();

  void _onItemTapped(int index) {
    final bool isIndexTab = index == 0;

    if (index != _selectedIndex) {
      setState(() => _selectedIndex = index);
    }

    // ✅ Panggil refreshData() jika kembali ke tab Index
    if (isIndexTab && _indexScreenKey.currentState != null) {
      try {
        (_indexScreenKey.currentState as dynamic).refreshData();
      } catch (e) {
        // optional: ignore kalau method tidak ada
      }
    }
  }

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
