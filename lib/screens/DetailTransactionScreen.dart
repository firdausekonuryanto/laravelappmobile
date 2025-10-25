import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DetailTransactionScreen extends StatelessWidget {
  final Map<String, dynamic> transactionData;
  // Menggunakan NumberFormat untuk memformat angka Rupiah
  final NumberFormat _formatter = NumberFormat("#,##0", "id_ID");

  DetailTransactionScreen({super.key, required this.transactionData});

  // Helper untuk memformat angka ke string Rupiah
  String formatRupiah(dynamic amount) {
    if (amount == null) return '0';
    try {
      // Pastikan amount adalah double atau int sebelum diformat
      return _formatter.format(amount);
    } catch (e) {
      return amount.toString();
    }
  }

  // Widget helper untuk menampilkan satu baris detail
  Widget _buildDetailRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140, // Lebar tetap untuk label
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Text(": "),
          Expanded(child: Text(value, style: valueStyle)),
        ],
      ),
    );
  }

  // Widget helper untuk Badge Status
  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'paid':
      case 'complete':
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
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = transactionData;
    print("cek data : ");
    print(transactionData);
    final List<dynamic> details = t['details'] ?? []; // Ambil array produk

    // Ambil data dari Map. Gunakan null-aware operator untuk keamanan
    final customerName = t['customer_name'] ?? t['customer']?['name'] ?? '-';
    final userName = t['user_name'] ?? t['user']?['name'] ?? '-';
    final paymentName =
        t['payment_method_name'] ?? t['payment_method']?['name'] ?? '-';
    final status = t['status'] ?? 'UNKNOWN';

    return Scaffold(
      appBar: AppBar(title: const Text("Detail Transaksi")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Invoice
            Text(
              "Invoice: ${t['invoice_number']}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Card Detail Transaksi
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow("Customer", customerName),
                    _buildDetailRow("Cashier (User)", userName),
                    _buildDetailRow("Payment Method", paymentName),
                    const Divider(),
                    _buildDetailRow(
                      "Total Quantity",
                      (t['total_qty'] ?? 0).toString(),
                    ),
                    _buildDetailRow(
                      "Total Price",
                      'Rp${formatRupiah(t['total_price'])}',
                    ),
                    _buildDetailRow(
                      "Discount",
                      'Rp${formatRupiah(t['discount'])}',
                    ),
                    _buildDetailRow("Tax", 'Rp${formatRupiah(t['tax'])}'),

                    const Divider(height: 16),

                    // Grand Total
                    _buildDetailRow(
                      "Grand Total",
                      'Rp${formatRupiah(t['grand_total'])}',
                      valueStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),

                    // Amount Paid & Change
                    _buildDetailRow(
                      "Amount Paid",
                      'Rp${formatRupiah(t['paid_amount'] ?? 0)}',
                    ),
                    _buildDetailRow(
                      "Change (Kembalian)",
                      'Rp${formatRupiah(t['change_amount'] ?? 0)}',
                      valueStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),

                    const Divider(height: 16),

                    // Status dan Tanggal
                    Row(
                      children: [
                        const Text(
                          "Status: ",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        _buildStatusBadge(status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      "Date",
                      // Menggunakan DateFormat jika tanggalnya dalam format string
                      t['created_at'] != null
                          ? DateFormat(
                              'd MMM yyyy HH:mm',
                            ).format(DateTime.parse(t['created_at']))
                          : '-',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Detail Produk
            const Text(
              "Purchased Products",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Tabel Produk
            details.isEmpty
                ? const Center(
                    child: Text(
                      'No products found for this transaction.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  )
                : _buildProductTable(details),

            const SizedBox(height: 24),

            // Tombol Kembali
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text("Kembali ke Daftar"),
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk membuat Tabel Produk
  Widget _buildProductTable(List<dynamic> details) {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {
        0: FixedColumnWidth(40), // No.
        1: FlexColumnWidth(3), // Product
        2: FlexColumnWidth(2.5), // Price
        3: FixedColumnWidth(60), // Qty
        4: FlexColumnWidth(2.5), // Subtotal
      },
      children: [
        // Header Tabel
        const TableRow(
          decoration: BoxDecoration(color: Color(0xFFE0E0E0)),
          children: [
            _TableHeaderCell('#'),
            _TableHeaderCell('Product'),
            _TableHeaderCell('Price'),
            _TableHeaderCell('Qty'),
            _TableHeaderCell('Subtotal'),
          ],
        ),
        // Baris Detail Produk
        ...details.asMap().entries.map((entry) {
          int index = entry.key;
          var detail = entry.value;
          return TableRow(
            children: [
              _TableDataCell((index + 1).toString()),
              _TableDataCell(detail['product']['name'] ?? '-'),
              _TableDataCell(
                'Rp${formatRupiah(detail['price'])}',
                alignment: TextAlign.right,
              ),
              _TableDataCell(
                (detail['quantity'] ?? 0).toString(),
                alignment: TextAlign.center,
              ),
              _TableDataCell(
                'Rp${formatRupiah(detail['subtotal'])}',
                alignment: TextAlign.right,
              ),
            ],
          );
        }).toList(),
      ],
    );
  }
}

// Widget helper untuk cell header tabel
class _TableHeaderCell extends StatelessWidget {
  final String text;
  const _TableHeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// Widget helper untuk cell data tabel
class _TableDataCell extends StatelessWidget {
  final String text;
  final TextAlign alignment;
  const _TableDataCell(this.text, {this.alignment = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
      child: Text(
        text,
        textAlign: alignment,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}
