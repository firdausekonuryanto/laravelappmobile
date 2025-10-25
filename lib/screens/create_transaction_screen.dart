import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/transaction_service.dart';
import 'package:dropdown_search/dropdown_search.dart';

class CreateTransactionScreen extends StatefulWidget {
  final VoidCallback onTransactionSuccess;

  // Ubah constructor untuk menerima callback
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

  int? selectedCustomer;
  int? selectedUser;
  int? selectedPayment;
  List<Map<String, dynamic>> selectedProducts = [];

  double discount = 0;
  double paidAmount = 0;

  bool isLoading = true;

  final TextEditingController discountController = TextEditingController();
  final TextEditingController paidAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadCreateData();
  }

  @override
  Future<void> loadCreateData() async {
    try {
      final response = await _service.fetchCreateData();
      final data = response['data'];
      setState(() {
        customers = data['customers'];
        users = data['users'];
        paymentMethods = data['paymentMethods'];
        products = data['products'];

        // Set default values
        selectedCustomer =
            customers.firstWhere((c) => c['name'] == 'Pelanggan Umum')['id']
                as int;
        selectedUser =
            users.firstWhere((u) => u['name'] == 'Administrator Toko')['id']
                as int;
        selectedPayment =
            paymentMethods.firstWhere(
                  (p) => p['name'].toLowerCase() == 'cash',
                )['id']
                as int;

        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
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

  void addProduct() {
    setState(() {
      selectedProducts.add({'product_id': null, 'quantity': 1});
    });
  }

  void removeProduct(int index) {
    setState(() {
      selectedProducts.removeAt(index);
    });
  }

  @override
  void dispose() {
    discountController.dispose();
    paidAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Create Transaction")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🟢 Customer Dropdown
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: "Customer"),
              value: selectedCustomer,
              items: customers.map<DropdownMenuItem<int>>((c) {
                return DropdownMenuItem<int>(
                  value: c['id'] as int,
                  child: Text(c['name']),
                );
              }).toList(),
              onChanged: (v) => setState(() => selectedCustomer = v),
            ),

            const SizedBox(height: 12),
            // 🟢 User Dropdown
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: "User"),
              value: selectedUser,
              items: users
                  .map<DropdownMenuItem<int>>(
                    (u) => DropdownMenuItem<int>(
                      value: (u['id'] as int), // pastikan dikonversi ke int
                      child: Text(
                        u['name'].toString(),
                      ), // pastikan teks adalah string
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => selectedUser = v),
            ),

            const SizedBox(height: 12),
            // 🟢 Payment Method Dropdown
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: "Payment Method"),
              value: selectedPayment,
              items: paymentMethods
                  .map<DropdownMenuItem<int>>(
                    (p) => DropdownMenuItem<int>(
                      value: (p['id'] as int),
                      child: Text(p['name'].toString()),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => selectedPayment = v),
            ),

            const Divider(height: 32),
            const Text(
              "Products",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            Column(
              children: [
                for (int i = 0; i < selectedProducts.length; i++) ...[
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: "Product",
                            ),
                            value:
                                selectedProducts[i]['product_id']
                                    as int?, // pastikan nullable int
                            items: products
                                .map<DropdownMenuItem<int>>(
                                  (p) => DropdownMenuItem<int>(
                                    value: p['id'] as int,
                                    child: Text(
                                      "${p['name']} (Rp${_formatter.format(p['price'])})",
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              setState(() {
                                selectedProducts[i]['product_id'] = v;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: "Qty",
                                  ),
                                  keyboardType: TextInputType.number,
                                  initialValue: selectedProducts[i]['quantity']
                                      .toString(),
                                  onChanged: (v) => setState(
                                    () => selectedProducts[i]['quantity'] =
                                        int.tryParse(v) ?? 1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                "Rp${_formatter.format(calculateSubtotal(selectedProducts[i]))}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => removeProduct(i),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                ElevatedButton.icon(
                  onPressed: addProduct,
                  icon: const Icon(Icons.add),
                  label: const Text("Add Product"),
                ),
              ],
            ),
            const Divider(height: 32),
            TextFormField(
              controller: discountController,
              decoration: const InputDecoration(labelText: "Discount (Rp)"),
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
                    selectedProducts.isEmpty ||
                    selectedProducts.any((p) => p['product_id'] == null)) {
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

                  // Snackbar success
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result['message'] ?? 'Transaksi berhasil disimpan',
                      ),
                    ),
                  );

                  // Reset form
                  setState(() {
                    selectedCustomer = null;
                    selectedUser = null;
                    selectedPayment = null;
                    selectedProducts.clear();
                    discount = 0;
                    paidAmount = 0;
                    discountController.text = '';
                    paidAmountController.text = '';
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
