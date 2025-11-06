import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:laravelappmobile/screens/DetailTransactionScreen.dart';
import '../services/transaction_service.dart';
import '../services/local_db_service.dart';
import 'package:laravelappmobile/utils/connectivity_helper.dart';

class IndexTransactionScreen extends StatefulWidget {
  const IndexTransactionScreen({super.key});

  @override
  State<IndexTransactionScreen> createState() => IndexTransactionScreenState();
}

class IndexTransactionScreenState extends State<IndexTransactionScreen> {
  final TransactionService _service = TransactionService();
  final LocalDBService _localDB = LocalDBService();
  final _formatter = NumberFormat("#,###", "id_ID");

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // Data
  List<Map<String, dynamic>> _transactions = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = true;
  bool isOffline = false;

  // Pagination
  int _currentPage = 1;
  int _lastPage = 1;

  // Filter
  String _searchTerm = '';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isFiltering = false;

  @override
  void initState() {
    super.initState();
    loadTransactions();
    _searchController.addListener(_onSearchChanged);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !isLoadingMore &&
          hasMore) {
        _loadMoreTransactions();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Ketika teks pencarian berubah
  void _onSearchChanged() {
    final term = _searchController.text.trim();
    if (term != _searchTerm) {
      _searchTerm = term;
      _refreshTransactions();
    }
  }

  Future<void> loadTransactions({
    String? search,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    setState(() => isLoading = true);

    final isOnline = await ConnectivityHelper.hasConnection();
    print('🔌 Status koneksi: ${isOnline ? "ONLINE" : "OFFLINE"}');

    try {
      if (isOnline) {
        // 🟢 Mode Online
        isOffline = false;

        final result = await _service.fetchTransactions(
          page: 1,
          searchTerm: search,
          startDate: startDate,
          endDate: endDate,
        );

        setState(() {
          _transactions = result['transactions'];
          _currentPage = result['current_page'];
          _lastPage = result['last_page'];
          hasMore = _currentPage < _lastPage;
          isLoading = false;
          _isFiltering =
              (search?.isNotEmpty == true ||
              startDate != null ||
              endDate != null);
        });
      } else {
        // 🔴 Mode Offline
        isOffline = true;
        print("📴 Offline mode — memuat transaksi dari SQLite...");

        final pending = await _localDB.getPendingTransactions();

        final localTransactions = pending.map((row) {
          final data = jsonDecode(row['data']);
          return {
            'invoice_number': 'OFF-${row['id']}',
            'customer': {'name': data['customerId'].toString()},
            'user': {'name': data['userId'].toString()},
            'status': 'pending',
            'grand_total': data['paidAmount'] ?? 0,
            'created_at': data['createdAt'] ?? DateTime.now().toIso8601String(),
          };
        }).toList();

        setState(() {
          _transactions = localTransactions;
          isLoading = false;
          hasMore = false;
        });
      }
    } catch (e) {
      // Kalau error (misalnya server mati), fallback ke offline juga
      print("⚠️ Gagal memuat data online: $e");
      final pending = await _localDB.getPendingTransactions();

      final localTransactions = pending.map((row) {
        final data = jsonDecode(row['data']);
        return {
          'invoice_number': 'OFF-${row['id']}',
          'customer': {'name': data['customerId'].toString()},
          'user': {'name': data['userId'].toString()},
          'status': 'pending',
          'grand_total': data['paidAmount'] ?? 0,
          'created_at': data['createdAt'] ?? DateTime.now().toIso8601String(),
        };
      }).toList();

      setState(() {
        _transactions = localTransactions;
        isLoading = false;
        hasMore = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memuat transaksi online: $e\nTampilkan data lokal.',
          ),
        ),
      );
    }
  }

  // Load halaman berikutnya (hanya jika online)
  Future<void> _loadMoreTransactions() async {
    if (isOffline || _currentPage >= _lastPage) return;
    setState(() => isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final result = await _service.fetchTransactions(
        page: nextPage,
        searchTerm: _searchTerm,
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        _transactions.addAll(result['transactions']);
        _currentPage = result['current_page'];
        hasMore = _currentPage < _lastPage;
        isLoadingMore = false;
      });
    } catch (e) {
      setState(() => isLoadingMore = false);
    }
  }

  // Refresh manual
  Future<void> _refreshTransactions() async {
    await loadTransactions(
      search: _searchTerm,
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  Future<void> refreshData() => _refreshTransactions();

  // Pilih tanggal
  Future<void> _selectDate(
    BuildContext context, {
    required bool isStart,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
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
      _refreshTransactions();
    }
  }

  // Reset filter
  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchTerm = '';
      _startDate = null;
      _endDate = null;
      _isFiltering = false;
    });
    _refreshTransactions();
  }

  // Badge status
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isOffline ? "Daftar Transaksi (Offline)" : "Daftar Transaksi",
        ),
        backgroundColor: isOffline ? Colors.orange : Colors.blue,
      ),
      body: Column(
        children: [
          // Filter Bar
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Cari Invoice / Nama Customer',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchTerm.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _resetFilters,
                          )
                        : null,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
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
            child: RefreshIndicator(
              onRefresh: _refreshTransactions,
              child: isLoading && _transactions.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _transactions.isEmpty
                  ? const Center(child: Text("Belum ada transaksi"))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _transactions.length + (isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _transactions.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final t = _transactions[index];
                        final no = index + 1;

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
                            title: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.blue.shade700,
                                  child: Text(
                                    '$no',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    t['invoice_number'] ?? 'N/A',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Customer: ${t['customer']?['name'] ?? '-'}",
                                    ),
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
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey,
                            ),
                            onTap: () {
                              if (isOffline) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Transaksi offline belum bisa dibuka detailnya.",
                                    ),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DetailTransactionScreen(
                                          transactionData: t,
                                        ),
                                  ),
                                ).then((_) => _refreshTransactions());
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
