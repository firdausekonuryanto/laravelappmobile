import 'package:flutter/material.dart';
import 'package:laravelappmobile/screens/DetailTransactionScreen.dart';
import '../services/transaction_service.dart'; // Pastikan path ini benar
import 'package:intl/intl.dart';

// ✅ IndexTransactionScreenState: Dibuat publik
class IndexTransactionScreen extends StatefulWidget {
  const IndexTransactionScreen({super.key});

  @override
  State<IndexTransactionScreen> createState() => IndexTransactionScreenState();
}

class IndexTransactionScreenState extends State<IndexTransactionScreen> {
  final TransactionService _service = TransactionService();
  final _formatter = NumberFormat("#,###", "id_ID");

  // State untuk Data
  List<Map<String, dynamic>> _filteredTransactions = [];
  bool isLoading = true;

  // State untuk Filter
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isFiltering = false;

  @override
  void initState() {
    super.initState();
    // Muat data saat inisialisasi tanpa filter
    loadTransactions();

    // Listener untuk pencarian langsung (optional, bisa juga pakai tombol search)
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Dipanggil setiap kali teks pencarian berubah
  void _onSearchChanged() {
    if (_searchController.text != _searchTerm) {
      _searchTerm = _searchController.text;
      // Debounce atau langsung panggil loadTransactions
      // Untuk contoh ini, kita panggil langsung:
      loadTransactions(
        search: _searchTerm,
        startDate: _startDate,
        endDate: _endDate,
      );
    }
  }

  // Metode pemuatan data utama dengan parameter filter
  Future<void> loadTransactions({
    String? search,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Jangan tampilkan indicator jika data sudah ada, kecuali pull-to-refresh
    if (_filteredTransactions.isEmpty) {
      setState(() => isLoading = true);
    }

    try {
      // ✅ Mengirim parameter filter ke service
      final data = await _service.fetchTransactions(
        searchTerm: search,
        startDate: startDate,
        endDate: endDate,
      );

      if (mounted) {
        setState(() {
          _filteredTransactions = data;
          isLoading = false;
          // Tentukan status filter aktif
          _isFiltering =
              (search?.isNotEmpty == true ||
              startDate != null ||
              endDate != null);
        });
      }
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat transaksi: ${e.toString()}')),
        );
        setState(() => isLoading = false);
      }
    }
  }

  // Public method untuk refresh data
  Future<void> refreshData() async {
    await loadTransactions(
      search: _searchTerm,
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  // Pemilih Tanggal
  Future<void> _selectDate(
    BuildContext context, {
    required bool isStart,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? _startDate ?? DateTime.now()
          : _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
      // Setelah memilih tanggal, muat ulang data
      loadTransactions(
        search: _searchTerm,
        startDate: _startDate,
        endDate: _endDate,
      );
    }
  }

  // Reset Filter
  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchTerm = '';
      _startDate = null;
      _endDate = null;
      _isFiltering = false;
    });
    // Muat ulang data tanpa filter
    loadTransactions();
  }

  // Widget untuk menampilkan badge status
  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'paid':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'canceled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (isLoading && _filteredTransactions.isEmpty) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_filteredTransactions.isEmpty) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _isFiltering
                    ? 'Tidak ada transaksi yang cocok dengan filter.'
                    : 'Belum ada transaksi.',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.clear),
                label: const Text('Hapus Filter & Muat Ulang'),
              ),
            ],
          ),
        ),
      );
    } else {
      // ✅ Menggunakan ListView.builder untuk menampilkan data
      content = ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredTransactions.length,
        itemBuilder: (context, index) {
          final t = _filteredTransactions[index];
          // Menggunakan Card untuk tampilan yang lebih terstruktur
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 16,
              ),
              title: Text(
                t['invoice_number'] ?? 'N/A',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Customer: ${t['customer']?['name'] ?? '-'}"),
                      _buildStatusBadge(t['status'] ?? 'N/A'),
                    ],
                  ),
                  Text("Cashier: ${t['user']?['name'] ?? '-'}"),
                  Text(
                    "Total: Rp${_formatter.format(t['grand_total'] ?? 0)}",
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "Tgl: ${DateFormat('dd MMM yyyy').format(DateTime.parse(t['created_at']))}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DetailTransactionScreen(transactionData: t),
                  ),
                ).then(
                  (_) => refreshData(),
                ); // Refresh setelah kembali dari detail
              },
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Daftar Transaksi")),
      body: Column(
        children: [
          // Filter Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Cari Invoice / Nama Customer',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchTerm.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged();
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (value) => loadTransactions(
                    search: value,
                    startDate: _startDate,
                    endDate: _endDate,
                  ),
                ),
                const SizedBox(height: 8),

                // Date Range & Reset Button
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          _startDate == null
                              ? 'Start Date'
                              : DateFormat('dd/MM/yy').format(_startDate!),
                        ),
                        onPressed: () => _selectDate(context, isStart: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          _endDate == null
                              ? 'End Date'
                              : DateFormat('dd/MM/yy').format(_endDate!),
                        ),
                        onPressed: () => _selectDate(context, isStart: false),
                      ),
                    ),
                    if (_isFiltering) ...[
                      const SizedBox(width: 8),
                      // Reset Button
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.red),
                        tooltip: 'Reset Filter',
                        onPressed: _resetFilters,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Data List
          Expanded(
            // Menggunakan RefreshIndicator di sini agar hanya list yang bisa ditarik
            child: RefreshIndicator(onRefresh: refreshData, child: content),
          ),
        ],
      ),
      // FloatingActionButton dipertahankan, asumsikan berfungsi untuk navigasi ke tab pembuatan
    );
  }
}
