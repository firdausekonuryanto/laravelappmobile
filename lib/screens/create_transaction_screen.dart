import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:laravelappmobile/services/local_db_service.dart';
import 'package:laravelappmobile/utils/connectivity_helper.dart';
import '../services/transaction_service.dart';

class CreateTransactionScreen extends StatefulWidget {
  final VoidCallback onTransactionSuccess;

  const CreateTransactionScreen({
    super.key,
    required this.onTransactionSuccess,
  });

  @override
  State<CreateTransactionScreen> createState() =>
      _CreateTransactionScreenState();
}

class _CreateTransactionScreenState extends State<CreateTransactionScreen> {
  final TransactionService _service = TransactionService();
  final _formatter = NumberFormat("#,###", "id_ID");

  List<dynamic> customers = [];
  List<dynamic> users = [];
  List<dynamic> paymentMethods = [];
  List<dynamic> products = [];
  bool isOnline = true;

  List<Map<String, dynamic>> selectedProducts = [];

  int? selectedCustomer;
  int? selectedUser;
  int? selectedPayment;

  double discount = 0;
  double paidAmount = 0;
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = true;
  int currentPage = 1;
  final int limit = 20;

  final TextEditingController discountController = TextEditingController();
  final TextEditingController paidAmountController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initConnectivityListener();
    loadCreateData();
    _scrollController.addListener(_onScroll);
  }

  void _initConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) async {
      final hasConnection =
          results.isNotEmpty &&
          results.any((r) => r != ConnectivityResult.none);

      setState(() => isOnline = hasConnection);

      debugPrint(
        '🌐 Status koneksi berubah: ${hasConnection ? 'Online' : 'Offline'}',
      );
      if (hasConnection) {
        debugPrint("🔁 Online kembali — mulai sync data...");
        await loadCreateData(loadMore: false, isResync: true);
      }
    });

    ConnectivityHelper.hasConnection().then((value) {
      setState(() => isOnline = value);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore &&
        hasMore) {
      setState(() => currentPage++);
      loadCreateData(loadMore: true);
    }
  }

  Future<void> loadCreateData({
    bool loadMore = false,
    bool isResync = false,
  }) async {
    try {
      final localDB = LocalDBService();

      if (isOnline) {
        print("🟢 Online — mulai sync data dari server...");

        List allProducts = [];
        int page = 1;
        bool hasMorePages = true;

        Map<String, dynamic> firstPageData = {};

        while (hasMorePages) {
          final response = await _service.fetchCreateData(
            page: page,
            limit: limit,
          );
          final data = response['data'];

          if (page == 1) {
            firstPageData = data;
          }

          final productsPage = data['products'] ?? [];
          hasMorePages = data['hasMore'] ?? false;

          allProducts.addAll(productsPage);
          page++;
        }

        final mergedData = {
          'customers': firstPageData['customers'] ?? [],
          'users': firstPageData['users'] ?? [],
          'paymentMethods': firstPageData['paymentMethods'] ?? [],
          'products': allProducts,
        };

        await localDB.saveSyncData(mergedData);

        setState(() {
          customers = mergedData['customers'];
          users = mergedData['users'];
          paymentMethods = mergedData['paymentMethods'];
          products = mergedData['products'];
        });
      } else {
        print("📴 Offline — load data dari SQLite");

        customers = await localDB.getCustomers();
        users = await localDB.getUsers();
        paymentMethods = await localDB.getPaymentMethods();
        products = await localDB.getProducts();
      }

      if (customers.isNotEmpty) {
        selectedCustomer ??= customers.firstWhere(
          (c) => c['name'] == 'Pelanggan Umum',
          orElse: () => customers.first,
        )['id'];
      }

      if (users.isNotEmpty) {
        selectedUser ??= users.firstWhere(
          (u) => u['name'] == 'Administrator Toko',
          orElse: () => users.first,
        )['id'];
      }

      if (paymentMethods.isNotEmpty) {
        selectedPayment ??= paymentMethods.firstWhere(
          (p) => p['name'].toLowerCase() == 'cash',
          orElse: () => paymentMethods.first,
        )['id'];
      } else {
        print("🔴 Offline — ambil data dari SQLite");
        customers = await localDB.getCustomers();
        users = await localDB.getUsers();
        paymentMethods = await localDB.getPaymentMethods();
        products = await localDB.getProducts();
      }
    } catch (e) {
      debugPrint('❌ Error load data: $e');
    } finally {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  double calculateSubtotal(Map<String, dynamic> item) {
    final product = products.firstWhere(
      (p) => p['id'] == item['product_id'],
      orElse: () => {'price': 0},
    );
    final price = (product['price'] ?? 0).toDouble();
    final qty = (item['quantity'] ?? 0).toDouble();
    return price * qty;
  }

  double calculateGrandTotal() {
    double total = selectedProducts.fold(
      0,
      (sum, item) => sum + calculateSubtotal(item),
    );
    return total - discount;
  }

  double calculateChange() {
    double total = calculateGrandTotal();
    return (paidAmount - total).clamp(0, double.infinity);
  }

  void addProductFromList(dynamic product) {
    final existingIndex = selectedProducts.indexWhere(
      (item) => item['product_id'] == product['id'],
    );

    setState(() {
      if (existingIndex != -1) {
        selectedProducts[existingIndex]['quantity']++;
      } else {
        selectedProducts.add({'product_id': product['id'], 'quantity': 1});
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Produk '${product['name']}' ditambahkan")),
    );
  }

  void removeProduct(int index) {
    setState(() => selectedProducts.removeAt(index));
  }

  @override
  void dispose() {
    discountController.dispose();
    paidAmountController.dispose();
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final filteredProducts = products.where((p) {
      final query = searchController.text.toLowerCase();
      return p['name'].toString().toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Create Transaction")),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            isLoading = true;
            currentPage = 1;
            hasMore = true;
          });
          await loadCreateData(loadMore: false, isResync: true);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isOnline
                    ? "🟢 Terhubung ke server — transaksi disimpan langsung."
                    : "🔴 Terputus — transaksi disimpan sementara (offline).",
                style: TextStyle(
                  color: isOnline ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: "Customer"),
                value: selectedCustomer,
                items: customers
                    .map(
                      (c) => DropdownMenuItem<int>(
                        value: c['id'],
                        child: Text(c['name']),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => selectedCustomer = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: "User"),
                value: selectedUser,
                items: users
                    .map(
                      (u) => DropdownMenuItem<int>(
                        value: u['id'],
                        child: Text(u['name']),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => selectedUser = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: "Payment Method"),
                value: selectedPayment,
                items: paymentMethods
                    .map(
                      (p) => DropdownMenuItem<int>(
                        value: p['id'],
                        child: Text(p['name']),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => selectedPayment = v),
              ),
              const Divider(height: 32),
              const Text(
                "Cari & Tambah Produk",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  labelText: "Cari produk...",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Container(
                      color: Colors.grey.shade200,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: const Row(
                        children: [
                          Expanded(flex: 1, child: Center(child: Text("No"))),
                          Expanded(flex: 4, child: Center(child: Text("Nama"))),
                          Expanded(
                            flex: 3,
                            child: Center(child: Text("Harga")),
                          ),
                          Expanded(flex: 2, child: Center(child: Text("Aksi"))),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 250,
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount:
                            filteredProducts.length + (isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == filteredProducts.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final p = filteredProducts[index];
                          final number = index + 1;
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.grey),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Center(child: Text("$number")),
                                ),
                                Expanded(flex: 4, child: Text(p['name'])),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    "Rp${_formatter.format(p['price'])}",
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.add_circle,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () => addProductFromList(p),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 32),
              const Text(
                "Produk Dipilih",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 250),
                child: SingleChildScrollView(
                  child: Column(
                    children: selectedProducts.isEmpty
                        ? [const Text('Belum ada produk dipilih.')]
                        : selectedProducts.map((item) {
                            final product = products.firstWhere(
                              (p) => p['id'] == item['product_id'],
                              orElse: () => {'name': 'Unknown', 'price': 0},
                            );
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 8,
                              ),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product['name'],
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Harga: Rp${_formatter.format(product['price'])}",
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 8),

                                          Row(
                                            children: [
                                              const Text("Qty: "),
                                              SizedBox(
                                                width: 55,
                                                child: TextField(
                                                  keyboardType:
                                                      TextInputType.number,
                                                  textAlign: TextAlign.center,
                                                  decoration:
                                                      const InputDecoration(
                                                        isDense: true,
                                                        contentPadding:
                                                            EdgeInsets.symmetric(
                                                              vertical: 6,
                                                            ),
                                                        border:
                                                            OutlineInputBorder(),
                                                      ),
                                                  controller:
                                                      TextEditingController(
                                                        text: item['quantity']
                                                            .toString(),
                                                      ),
                                                  onChanged: (v) {
                                                    final qty =
                                                        int.tryParse(v) ?? 1;
                                                    setState(() {
                                                      item['quantity'] = qty > 0
                                                          ? qty
                                                          : 1;
                                                    });
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  "Subtotal: Rp${_formatter.format(calculateSubtotal(item))}",
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      color: Colors.red.shade400,
                                      tooltip: "Hapus produk",
                                      onPressed: () => removeProduct(
                                        selectedProducts.indexOf(item),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                  ),
                ),
              ),

              const Divider(height: 32),
              TextFormField(
                controller: discountController,
                decoration: const InputDecoration(labelText: "Diskon (Rp)"),
                keyboardType: TextInputType.number,
                onChanged: (v) =>
                    setState(() => discount = double.tryParse(v) ?? 0),
              ),
              const SizedBox(height: 8),
              Text(
                "Total: Rp${_formatter.format(calculateGrandTotal())}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: paidAmountController,
                decoration: const InputDecoration(
                  labelText: "Uang Dibayar (Rp)",
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) =>
                    setState(() => paidAmount = double.tryParse(v) ?? 0),
              ),
              const SizedBox(height: 8),
              Text(
                "Kembalian: Rp${_formatter.format(calculateChange())}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (selectedCustomer == null ||
                      selectedUser == null ||
                      selectedPayment == null ||
                      selectedProducts.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lengkapi semua data transaksi'),
                      ),
                    );
                    return;
                  }

                  final transactionData = {
                    'customerId': selectedCustomer,
                    'userId': selectedUser,
                    'paymentMethodId': selectedPayment,
                    'products': selectedProducts
                        .map(
                          (p) => {
                            'product_id': p['product_id'],
                            'quantity': p['quantity'],
                          },
                        )
                        .toList(),
                    'discount': discount,
                    'paidAmount': paidAmount,
                    'createdAt': DateTime.now().toIso8601String(),
                  };

                  final localDB = LocalDBService();
                  final isOnline = await ConnectivityHelper.hasConnection();

                  try {
                    if (isOnline) {
                      // 🔹 Mode Online
                      final result = await _service.createTransaction(
                        customerId: selectedCustomer!,
                        userId: selectedUser!,
                        paymentMethodId: selectedPayment!,
                        products: selectedProducts,
                        discount: discount,
                        paidAmount: paidAmount,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            result['message'] ?? 'Transaksi berhasil',
                          ),
                        ),
                      );
                    } else {
                      // 🔹 Mode Offline
                      await localDB.saveOfflineTransaction(transactionData);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            '📴 Offline — transaksi disimpan sementara',
                          ),
                        ),
                      );
                    }
                  } catch (e, st) {
                    // 🔹 Gagal kirim ke server → simpan offline
                    print("❌ Gagal online: $e");
                    print(st);

                    try {
                      await localDB.saveOfflineTransaction(transactionData);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            '⚠️ Koneksi gagal — transaksi disimpan offline',
                          ),
                        ),
                      );
                    } catch (err) {
                      print("❌ Gagal menyimpan offline: $err");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal simpan offline: $err')),
                      );
                    }
                  }

                  // 🔹 Reset form setelah simpan
                  setState(() {
                    selectedProducts.clear();
                    discount = 0;
                    paidAmount = 0;
                    discountController.clear();
                    paidAmountController.clear();
                  });

                  // 🔹 Debug info (cek isi tabel lokal)
                  await localDB.printTableCount();

                  widget.onTransactionSuccess();
                },
                child: const Text("Simpan Transaksi"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
