
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl =
      'http://143.198.118.203:8100/ejemplos/';

  static const String _usuario = 'test';
  static const String _contrasena = 'test2023';

  static Map<String, String> get _headers {
    final credenciales = base64Encode(
      utf8.encode('$_usuario:$_contrasena'),
    );

    return {
      'Authorization': 'Basic $credenciales',
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=UTF-8',
    };
  }

  static Future<dynamic> get(String endpoint) async {
    final uri = Uri.parse('$_baseUrl$endpoint');

    final respuesta = await http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 20));

    return _procesarRespuesta(respuesta);
  }

  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> datos,
  ) async {
    final uri = Uri.parse('$_baseUrl$endpoint');

    final respuesta = await http
        .post(
          uri,
          headers: _headers,
          body: jsonEncode(datos),
        )
        .timeout(const Duration(seconds: 20));

    return _procesarRespuesta(respuesta);
  }

  static dynamic _procesarRespuesta(http.Response respuesta) {
    if (respuesta.statusCode < 200 ||
        respuesta.statusCode >= 300) {
      throw Exception(
        'Error HTTP ${respuesta.statusCode}: ${respuesta.body}',
      );
    }

    final cuerpo = utf8.decode(
      respuesta.bodyBytes,
      allowMalformed: true,
    );

    try {
      return jsonDecode(cuerpo);
    } on FormatException {
      return cuerpo;
    }
  }

  static Future<List<dynamic>> listarProductos() async {
    final resultado = await get('product_list_rest/');

    if (resultado is Map<String, dynamic> &&
        resultado['Listado'] is List) {
      return resultado['Listado'] as List<dynamic>;
    }

    throw Exception(
      'La API respondió, pero no se encontró la lista de productos.',
    );
  }
  
  static Future<dynamic> agregarProducto({
    required String nombre,
    required int precio,
    required String imagen,
  }) {
    return post('product_add_rest/', {
      'product_name': nombre,
      'product_price': precio,
      'product_image': imagen,
    });
  }

  static Future<dynamic> editarProducto({
    required int id,
    required String nombre,
    required int precio,
    required String imagen,
    required String estado,
  }) {
    return post('product_edit_rest/', {
      'product_id': id,
      'product_name': nombre,
      'product_price': precio,
      'product_image': imagen,
      'product_state': estado,
    });
  }

  static Future<dynamic> eliminarProducto(int id) {
    return post('product_del_rest/', {
      'product_id': id,
    });
  }
  
  
static Future<List<dynamic>> listarCategorias() async {
  final respuesta = await get('category_list_rest/');

  if (respuesta is List) {
    return respuesta;
  }

  if (respuesta is Map) {
    final listado = respuesta['Listado Categorias'] ??
        respuesta['Listado'] ??
        respuesta['listado'];

    if (listado is List) {
      return listado;
    }
  }

  throw Exception(
    'La respuesta de categorías no contiene una lista válida.',
  );
}

  
  static Future<dynamic> agregarCategoria({
    required String nombre,
  }) async {
    return await post('category_add_rest/', {
      'category_name': nombre,
    });
  }

  static Future<dynamic> editarCategoria({
    required int id,
    required String nombre,
    required String estado,
  }) async {
    return await post('category_edit_rest/', {
      'category_id': id,
      'category_name': nombre,
      'category_state': estado,
    });
  }

  static Future<dynamic> eliminarCategoria(int id) async {
    return await post('category_del_rest/', {
      'category_id': id,
    });
  }


  static Future<List<dynamic>> listarProveedores() async {
    final respuesta = await get('provider_list_rest/');

    if (respuesta is List) {
      return respuesta;
    }

    if (respuesta is Map) {
      final listado = respuesta['Proveedores Listado'] ??
          respuesta['Listado Proveedores'] ??
          respuesta['Listado'];

      if (listado is List) {
        return listado;
      }
    }

    throw Exception(
      'La respuesta de proveedores no contiene una lista válida.',
    );
  }

  static Future<dynamic> agregarProveedor({
    required String nombre,
    required String apellido,
    required String correo,
  }) {
    return post('provider_add_rest/', {
      'provider_name': nombre,
      'provider_last_name': apellido,
      'provider_mail': correo,
    });
  }

  static Future<dynamic> editarProveedor({
    required int id,
    required String nombre,
    required String apellido,
    required String correo,
    required String estado,
  }) {
    return post('provider_edit_rest/', {
      'provider_id': id,
      'provider_name': nombre,
      'provider_last_name': apellido,
      'provider_mail': correo,
      'provider_state': estado,
    });
  }

  static Future<dynamic> eliminarProveedor(int id) {
    return post('provider_del_rest/', {
      'provider_id': id,
    });
  }


}
