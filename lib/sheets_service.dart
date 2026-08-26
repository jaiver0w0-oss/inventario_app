import 'dart:convert';
import 'package:http/http.dart' as http;

class SheetsService {
  static const String scriptUrl = 'https://script.google.com/macros/s/AKfycbxIBPis1nBMTfJ4KJrzKviVlRBzMZgFmdETdiLC_L8TxjVbiYJ17GSLDIDp24MpgHxw/exec';

  Future<List<Map<String, String>>> obtenerMateriales() async {
    try {
      final response = await http.get(Uri.parse('$scriptUrl?action=getMateriales'));
      if (response.statusCode == 200 || response.statusCode == 302) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Map<String, String>.from(item)).toList();
      }
    } catch (e) {
      print('Error al obtener materiales: $e');
    }
    return [];
  }

  Future<List<Map<String, String>>> obtenerMovimientos() async {
    try {
      final response = await http.get(Uri.parse('$scriptUrl?action=getMovimientos'));
      if (response.statusCode == 200 || response.statusCode == 302) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Map<String, String>.from(item)).toList();
      }
    } catch (e) {
      print('Error al obtener movimientos: $e');
    }
    return [];
  }

  Future<List<Map<String, String>>> obtenerPersonal() async {
    try {
      final response = await http.get(Uri.parse('$scriptUrl?action=getPersonal'));
      if (response.statusCode == 200 || response.statusCode == 302) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Map<String, String>.from(item)).toList();
      }
    } catch (e) {
      print('Error al obtener personal: $e');
    }
    return [];
  }

  Future<bool> registrarMaterial({
    required String nombre,
    required String descripcion,
    required int cantidadActual,
    required int cantidadRequerida,
    required String unidad, // <-- Parámetro agregado
    String? imagenBase64,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(scriptUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'addMaterial',
          'nombre': nombre,
          'descripcion': descripcion,
          'cantidadActual': cantidadActual,
          'cantidadRequerida': cantidadRequerida,
          'unidad': unidad,
          'imagenBase64': imagenBase64 ?? '',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        final res = json.decode(response.body);
        return res['status'] == 'success';
      }
    } catch (e) {
      print('Error al registrar material: $e');
    }
    return false;
  }

  Future<bool> actualizarFotoMaterial({
    required String nombre,
    required String imagenBase64,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(scriptUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'updateFotoMaterial',
          'nombre': nombre,
          'imagenBase64': imagenBase64,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        final res = json.decode(response.body);
        return res['status'] == 'success';
      }
    } catch (e) {
      print('Error al actualizar foto: $e');
    }
    return false;
  }

  // En lib/sheets_service.dart:

  Future<bool> editarMaterial({
    required String nombre,
    required String descripcion,
    required int cantidadActual,
    required int cantidadRequerida,
    required String unidad,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'editMaterial', // Acción que procesará Apps Script
          'nombre': nombre,
          'descripcion': descripcion,
          'cantidadActual': cantidadActual,
          'cantidadRequerida': cantidadRequerida,
          'unidad': unidad,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error al editar material: $e');
      return false;
    }
  }

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
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'addMovimiento',
          'materialNombre': materialNombre,
          'tipo': tipo,
          'cantidad': cantidad,
          'personaCedula': personaCedula,
          'observacion': observacion,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        final res = json.decode(response.body);
        return res['status'] == 'success';
      }
    } catch (e) {
      print('Error al registrar movimiento: $e');
    }
    return false;
  }
}