import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  List<Map<String, dynamic>> selectedProducts = [];

  int? selectedCustomer;
  int? selectedUser;
  int? selectedPayment;

  double discount = 0;
  double paidAmount = 0;
  bool isLoading = true;

  final TextEditingController discountController = TextEditingController();
  final TextEditingController paidAmountController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  // Pagination control
  int itemsPerPage = 5;
  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    loadCreateData();
  }

  Future<void> loadCreateData() async {
    try {
      final response = await _service.fetchCreateData();
      final data = response['data'];
      setState(() {
        customers = data['customers'];
        users = data['users'];
        paymentMethods = data['paymentMethods'];
        products = data['products'];

        selectedCustomer = customers.firstWhere(
          (c) => c['name'] == 'Pelanggan Umum',
        )['id'];
        selectedUser = users.firstWhere(
          (u) => u['name'] == 'Administrator Toko',
        )['id'];
        selectedPayment = paymentMethods.firstWhere(
          (p) => p['name'].toLowerCase() == 'cash',
        )['id'];

        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error load data: $e');
      setState(() => isLoading = false);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Filtering produk berdasarkan pencarian
    final filteredProducts = products.where((p) {
      final query = searchController.text.toLowerCase();
      return p['name'].toString().toLowerCase().contains(query);
    }).toList();

    // Pagination
    int totalPages = (filteredProducts.length / itemsPerPage).ceil();
    final paginatedProducts = filteredProducts
        .skip(currentPage * itemsPerPage)
        .take(itemsPerPage)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Create Transaction")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =============================
            // 🧍 Dropdown Customer, User, Payment
            // =============================
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: "Customer"),
              value: selectedCustomer,
              items: customers.map((c) {
                return DropdownMenuItem<int>(
                  value: c['id'],
                  child: Text(c['name']),
                );
              }).toList(),
              onChanged: (v) => setState(() => selectedCustomer = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: "User"),
              value: selectedUser,
              items: users.map((u) {
                return DropdownMenuItem<int>(
                  value: u['id'],
                  child: Text(u['name']),
                );
              }).toList(),
              onChanged: (v) => setState(() => selectedUser = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: "Payment Method"),
              value: selectedPayment,
              items: paymentMethods.map((p) {
                return DropdownMenuItem<int>(
                  value: p['id'],
                  child: Text(p['name']),
                );
              }).toList(),
              onChanged: (v) => setState(() => selectedPayment = v),
            ),

            const Divider(height: 32),
            const Text(
              "Cari & Tambah Produk",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // 🔍 Pencarian produk
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: "Cari produk...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {
                currentPage = 0;
              }),
            ),
            const SizedBox(height: 8),

            // =============================
            // 📋 Daftar Produk dengan pagination
            // =============================
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
                        Expanded(flex: 4, child: Center(child: Text("Nama"))),
                        Expanded(flex: 3, child: Center(child: Text("Harga"))),
                        Expanded(flex: 2, child: Center(child: Text("Aksi"))),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 250,
                    child: ListView.builder(
                      itemCount: paginatedProducts.length,
                      itemBuilder: (context, index) {
                        final p = paginatedProducts[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: Colors.grey)),
                          ),
                          child: Row(
                            children: [
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

                  // 🔹 Pagination control
                  if (totalPages > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios, size: 18),
                            onPressed: currentPage > 0
                                ? () => setState(() => currentPage--)
                                : null,
                          ),
                          Text(
                            "Halaman ${currentPage + 1} dari $totalPages",
                            style: const TextStyle(fontSize: 14),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, size: 18),
                            onPressed: currentPage < totalPages - 1
                                ? () => setState(() => currentPage++)
                                : null,
                          ),
                        ],
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

            // =============================
            // 🧾 Produk Dipilih dengan scroll
            // =============================
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
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              title: Text(product['name']),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Harga: Rp${_formatter.format(product['price'])}",
                                  ),
                                  Row(
                                    children: [
                                      const Text("Qty: "),
                                      SizedBox(
                                        width: 60,
                                        child: TextField(
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          controller: TextEditingController(
                                            text: item['quantity'].toString(),
                                          ),
                                          onChanged: (v) {
                                            final qty = int.tryParse(v) ?? 1;
                                            setState(() {
                                              item['quantity'] = qty > 0
                                                  ? qty
                                                  : 1;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        "Subtotal: Rp${_formatter.format(calculateSubtotal(item))}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => removeProduct(
                                  selectedProducts.indexOf(item),
                                ),
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: paidAmountController,
              decoration: const InputDecoration(labelText: "Uang Dibayar (Rp)"),
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

                try {
                  final result = await _service.createTransaction(
                    customerId: selectedCustomer!,
                    userId: selectedUser!,
                    paymentMethodId: selectedPayment!,
                    products: selectedProducts.map((item) {
                      return {
                        'product_id': item['product_id'],
                        'quantity': item['quantity'],
                      };
                    }).toList(),
                    discount: discount,
                    paidAmount: paidAmount,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result['message'] ?? 'Transaksi berhasil disimpan',
                      ),
                    ),
                  );

                  setState(() {
                    selectedProducts.clear();
                    discount = 0;
                    paidAmount = 0;
                    discountController.clear();
                    paidAmountController.clear();
                  });

                  widget.onTransactionSuccess();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menyimpan transaksi: $e')),
                  );
                }
              },
              child: const Text("Simpan Transaksi"),
            ),
          ],
        ),
      ),
    );
  }
}
