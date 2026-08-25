import 'dart:convert';
import 'package:http/http.dart' as http;

class SheetsService {
  // PEGA AQUÍ LA URL COMPLETA QUE COPIASTE DE GOOGLE APPS SCRIPT
  static const String scriptUrl = 'https://script.google.com/macros/s/AKfycbzqf--jtu2uBdZcKiRcmmNwICOJ46-L4MYfirL_RjICQMPE3NhKqV2F2aUZNY1G8Hf0RA/exec';

  // 1. Obtener lista de Materiales (Hoja 8)
  Future<List<Map<String, String>>> obtenerMateriales() async {
    try {
      final response = await http.get(Uri.parse('$scriptUrl?action=getMateriales'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Map<String, String>.from(item)).toList();
      }
    } catch (e) {
      print('Error al obtener materiales: $e');
    }
    return [];
  }

  // 2. Obtener lista de Movimientos
  Future<List<Map<String, String>>> obtenerMovimientos() async {
    try {
      final response = await http.get(Uri.parse('$scriptUrl?action=getMovimientos'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Map<String, String>.from(item)).toList();
      }
    } catch (e) {
      print('Error al obtener movimientos: $e');
    }
    return [];
  }

  // 3. Obtener lista de Personal
  Future<List<Map<String, String>>> obtenerPersonal() async {
    try {
      final response = await http.get(Uri.parse('$scriptUrl?action=getPersonal'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Map<String, String>.from(item)).toList();
      }
    } catch (e) {
      print('Error al obtener personal: $e');
    }
    return [];
  }

  // 4. Registrar Nuevo Movimiento y recalcular Stock
  Future<bool> registrarMovimiento({
    required String materialNombre,
    required String tipo,
    required int cantidad,
    required String personaCedula,
    required String observacion,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(scriptUrl),
        body: json.encode({
          'action': 'addMovimiento',
          'materialNombre': materialNombre,
          'tipo': tipo,
          'cantidad': cantidad,
          'personaCedula': personaCedula,
          'observacion': observacion,
        }),
      );

      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        return res['status'] == 'success';
      }
    } catch (e) {
      print('Error al registrar movimiento: $e');
    }
    return false;
  }
}