import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TransactionService {
  // ⚠️ Kalau pakai emulator Android, ganti ke 10.0.2.2
  String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8001/api';

  Future<Map<String, dynamic>> _fetchCreateData() async {
    final response = await http.get(Uri.parse('$baseUrl/transactions/create'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        print("cek data di service : ");
        print(data);
        return data;
      } else {
        throw Exception('Invalid API response format');
      }
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> fetchSyncData() async {
    final response = await http.get(
      Uri.parse('http://192.168.18.15:8001/api/sync-data'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal mengambil data sinkronisasi');
    }
  }

  // ✅ Tambahkan parameter [page] dan [limit]
  Future<Map<String, dynamic>> fetchCreateData({
    int page = 1,
    int limit = 5,
  }) async {
    final uri = Uri.parse('$baseUrl/transactions/create').replace(
      queryParameters: {'page': page.toString(), 'limit': limit.toString()},
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal memuat data create transaction');
    }
  }

  Future<Map<String, dynamic>> createTransaction({
    required int customerId,
    required int userId,
    required int paymentMethodId,
    required List<Map<String, dynamic>> products,
    double? discount,
    double? paidAmount,
  }) async {
    final url = Uri.parse('$baseUrl/transactions');

    final body = json.encode({
      'customer_id': customerId,
      'user_id': userId,
      'payment_method_id': paymentMethodId,
      'discount': discount ?? 0,
      'paid_amount': paidAmount ?? 0,
      'products': products,
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Gagal menyimpan transaksi');
      }
    } else {
      print(response.body);
      throw Exception(
        'Gagal menyimpan transaksi. Status: ${response.statusCode}',
      );
    }
  }

  Future<Map<String, dynamic>> fetchTransactions({
    String? searchTerm,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1, // ✅ Tambah parameter halaman
  }) async {
    // 1. Siapkan query parameters
    final Map<String, String> queryParams = {'page': page.toString()};

    if (searchTerm != null && searchTerm.isNotEmpty) {
      queryParams['search'] = searchTerm;
    }

    if (startDate != null) {
      queryParams['startDate'] = DateFormat('yyyy-MM-dd').format(startDate);
    }

    if (endDate != null) {
      queryParams['endDate'] = DateFormat('yyyy-MM-dd').format(endDate);
    }

    // 2. Buat URL
    final uri = Uri.parse(
      '$baseUrl/transactions',
    ).replace(queryParameters: queryParams);

    // 3. Lakukan HTTP GET
    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      print('📦 Response paginate: $jsonResponse');

      // ✅ Ambil bagian utama
      final pageData = jsonResponse['data'];

      // ✅ Ambil daftar transaksi
      final List<dynamic> transactions = pageData['data'] ?? [];

      // ✅ Return dengan meta pagination
      return {
        'transactions': List<Map<String, dynamic>>.from(transactions),
        'current_page': pageData['current_page'],
        'last_page': pageData['last_page'],
        'next_page_url': pageData['next_page_url'],
        'prev_page_url': pageData['prev_page_url'],
      };
    } else {
      throw Exception(
        'Failed to load transactions (status: ${response.statusCode})',
      );
    }
  }
}
