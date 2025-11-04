import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'local_db_service.dart';

class SyncService {
  final LocalDBService _localDB = LocalDBService();
  String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8001/api';

  Future<void> syncDataFromServer() async {
    final response = await http.get(Uri.parse('$baseUrl/sync-data'));
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['success']) {
        await _localDB.saveSyncData(jsonData['data']);
      }
    }
  }

  Future<void> syncPendingTransactions() async {
    final pending = await _localDB.getPendingTransactions();

    for (var trx in pending) {
      final trxData = jsonDecode(trx['data']);
      final res = await http.post(
        Uri.parse('$baseUrl/transactions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(trxData),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        await _localDB.markTransactionSynced(trx['id']);
      }
    }
  }
}
