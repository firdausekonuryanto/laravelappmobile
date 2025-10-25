import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class TransactionService {
  // ⚠️ Kalau pakai emulator Android, ganti ke 10.0.2.2
  final String baseUrl = 'http://10.0.2.2:8001/api';

  Future<Map<String, dynamic>> fetchCreateData() async {
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

  // Fetch transactions (index)
  Future<List<Map<String, dynamic>>> fetchTransactions({
    String? searchTerm,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // 1. Siapkan query parameters
    final Map<String, String> queryParams = {};

    if (searchTerm != null && searchTerm.isNotEmpty) {
      queryParams['search'] = searchTerm;
    }

    if (startDate != null) {
      // Format tanggal ke YYYY-MM-DD
      queryParams['startDate'] = DateFormat('yyyy-MM-dd').format(startDate);
    }

    if (endDate != null) {
      // Format tanggal ke YYYY-MM-DD
      queryParams['endDate'] = DateFormat('yyyy-MM-dd').format(endDate);
    }

    // 2. Gabungkan base URL dan query parameters
    final uri = Uri.parse(
      '$baseUrl/transactions',
    ).replace(queryParameters: queryParams);

    // 3. Lakukan HTTP GET request dengan Headers
    final response = await http.get(
      uri,
      // ✅ MENAMBAHKAN HEADERS SEPERTI PERMINTAAN ANDA
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);

      // ✅ MENYARING DATA SEPERTI PERMINTAAN ANDA
      // Asumsi API mengembalikan {'success': true, 'data': [...]}
      final List<dynamic>? dataList = jsonResponse['data'];

      if (dataList != null) {
        return List<Map<String, dynamic>>.from(dataList);
      } else {
        // Jika 'data' null atau tidak ditemukan
        return [];
      }
    } else {
      throw Exception(
        'Failed to load transactions. Status code: ${response.statusCode}',
      );
    }
  }
}
