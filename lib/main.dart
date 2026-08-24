import 'package:flutter/material.dart';
import 'package:gsheets/gsheets.dart';

// Constantes y Colores
const Color colorRojoCarmin = Color(0xFF990033);
const Color colorCarminHover = Color(0xFFBF0D40);
const Color colorBlancoPalido = Color(0xFFF8F9FA);
const String spreadsheetId = '1zzpaAQjjK4ZA-vABmIGyST3ejuLFTVlfF-Z0UNIBqII';

const String gsheetsCredentials = r'''
{
  "type": "service_account",
  "project_id": "inventario-sistema-490018",
  "private_key_id": "bca120282531fcb8ff59d314febab44ec4d81216",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvwIBADANBgkqhkiG9w0BAQEFAASCBKkwggSlAgEAAoIBAQDlutDuKo0FZVx6\nVLuFjvpkBpendqKcPRT0alJp/6Q2bs4v/0EiMOTUfgz5G6atCUHaGM7wl2/xrNKp\n6iFLm3OFSnKEK5hZVcu062TqVdhStP8JfWTYw8tH3Y0urMqZTWHYA1wmGjvl5K/L\n6bG/4+MTAAJv9bKI2ChNBuLGo/Rb35xBOZCfFYZZcvshIuaqjcYlH0WgSU9jI0VL\ntHRTUn5USNI1IG1uBwo0dTylC2LaYv14zH9yzQGjSiUZCLzZs8mlCB+LnYSNhrN8\nVxw2KB9bT4QaX3YbOndUoHS6XW9Au2qxOzsZv4j6yR/GqozoJD2OkAa/Z2FDlTgC\n+ZrzDlLpAgMBAAECggEAOftd0k7hCvSbU7DhJ4N/xRE446Z4wlBUYqAXLvO74ZUz\n6z9UlCmdB9jMs278MX49patPR8AhG/FPtl0GjEuu63xvzNYn/Jw/7ujerpp+H9nY\n6O9CLce1He1YPeiUtf6m7FtkvaUvawW+LQxNta3x2RDOjK2JoypTeaV8RUCKY0lh\nfKHkGhZXWrWjfsEr16SiZnq6tLUTvYdHRvbmRWe10ntc1b+DAf9+8Na2exIWat+5\n7DQfbN7sxfE0+RezSyi51LSt6w+6WdeWp/urTAuzgBctoRLCSPRl+dMjL0hmw6fS\nt+gGBqlVXnly5v/ISRStEL7hmOA1XY76k6t9fJm7tQKBgQD1ka2D/4YYBQ3Puz5F\n573TfKV1o8LfKNZjKIPWWYFFiVpKYHXnf1Q/6V7SXECEKm2jyvMabdHFYKNB78s0\n4RtZaqDFejp6lbI/SvXSMCiJEKj5k3pGnVPRBbBMVsI7M8Ql6uFCRJnrYsq6mebt\nx0RhzMKsxV3kZNetA6BpeG3TEwKBgQDvfObHHicceP9oNyCvDIFDgbBxOzl/LzAR\nmcj7Q7/uTOb1JBJYOMsDHlmMUimcUukItMQ+Y8VN+7UA3yiR2O4KRsb1CkHxgY7U\n/aLr5gn+k6i6SLwezABTmPIndDga9kiP2z+9dBJQ0RsFcc+A17d6O1tgM7y4OhAj\n1dLKjr5FkwKBgQC5jJRuK3G3zoHMF3ALQ/pTxVgEFnPVSLcM/3z2RnT+BLWbg10z\nSStwizYhfqEk/CYR3/RmYNpi6A0Tcku5remLW50U+bEcFOY1Gr+5TLgkMNlskvmO\nR6wgQMsgM2HZd9jayang95LRn7kM2+L4gVtzBlOGVi8Gtweb7CSV7PAWzwKBgQCY\nMRe3kkHopjwpTl9G3vuGmvQ2AR0Y5jP1+3TtuLBQEC71umauCel5od/mfJBU95uA\nHOBZha3tUPhGBYsSpHkhrrjhIBOoFl1enZDbuOTBE7U2LOLf72SFu7yntgOxnrGe\nOgbXrtu04C3718e2aWAAHZiEGlzj9oIrQ8chUnU4YQKBgQCM3u5aHbDdrK4yJrq1\nMlmnaZ1iPxZlkIXGoOji4298hjedqAHVsuFctqvN/xxEHRwKOUORMChC0PsPsaqG\n/VW/NeZSHhr+oGfRgaReaMbEqviDKSLMjLfoyTV2RALEBK+7hzTHp54eEKk+WjNj\niaYXkRpL90KK198iq4uOkcUVBA==\n-----END PRIVATE KEY-----\n",
  "client_email": "python-sheets-bot@inventario-sistema-490018.iam.gserviceaccount.com",
  "client_id": "113831630798125120243",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/python-sheets-bot%40inventario-sistema-490018.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}
''';

class SheetsManager {
  static final SheetsManager _instance = SheetsManager._internal();
  factory SheetsManager() => _instance;
  SheetsManager._internal();

  final GSheets _gsheets = GSheets(gsheetsCredentials);
  Spreadsheet? _spreadsheet;
  Worksheet? _sheetInventario;
  Worksheet? _sheetMovimientos;
  Worksheet? _sheetPersonal;

  Future<bool> init() async {
    try {
      if (_spreadsheet != null) return true;
      _spreadsheet = await _gsheets.spreadsheet(spreadsheetId);
      
      final sheets = _spreadsheet!.sheets;
      for (var ws in sheets) {
        final title = ws.title.toLowerCase();
        if (title == 'hoja 8' || title == 'materiales' || title == 'sheet1') {
          _sheetInventario = ws;
        } else if (title == 'movimientos') {
          _sheetMovimientos = ws;
        } else if (title == 'personal') {
          _sheetPersonal = ws;
        }
      }
      _sheetInventario ??= _spreadsheet!.sheets.first;
      return true;
    } catch (e) {
      debugPrint('Error conectando a Sheets: $e');
      return false;
    }
  }

  Future<bool> agregarMaterial(String nombre, String desc, int req, int act, String img) async {
    if (!await init() || _sheetInventario == null) return false;
    final fecha = DateTime.now().toIso8601String().replaceAll('T', ' ').substring(0, 19);
    return await _sheetInventario!.values.appendRow([nombre, desc, req, act, img, fecha]);
  }

  Future<List<Map<String, String>>> obtenerInventario() async {
    if (!await init() || _sheetInventario == null) return [];
    final rows = await _sheetInventario!.values.allRows();
    if (rows.length <= 1) return [];
    
    return rows.sublist(1).where((r) => r.isNotEmpty).map((f) => {
      'Nombre': f.isNotEmpty ? f[0] : '',
      'Descripcion': f.length > 1 ? f[1] : '',
      'Cantidad_Requerida': f.length > 2 ? f[2] : '0',
      'Cantidad_Actual': f.length > 3 ? f[3] : '0',
      'Imagen': f.length > 4 ? f[4] : '',
    }).toList();
  }

  Future<bool> registrarMovimiento(String mat, String tipo, int cant, String persona, String obs, String foto) async {
    if (!await init() || _sheetMovimientos == null || _sheetInventario == null) return false;
    final fecha = DateTime.now().toIso8601String().replaceAll('T', ' ').substring(0, 19);
    final res = await _sheetMovimientos!.values.appendRow([fecha, mat, tipo, cant, persona, obs, foto]);

    if (res) {
      final rows = await _sheetInventario!.values.allRows();
      int rowIndex = -1;
      for (int i = 0; i < rows.length; i++) {
        if (rows[i].isNotEmpty && rows[i][0].toLowerCase() == mat.toLowerCase()) {
          rowIndex = i + 1;
          break;
        }
      }

      if (rowIndex != -1) {
        final val = await _sheetInventario!.values.value(column: 4, row: rowIndex);
        final prev = int.tryParse(val ?? '0') ?? 0;
        final nueva = tipo == 'INGRESO' ? prev + cant : prev - cant;
        await _sheetInventario!.values.insertValue(nueva, column: 4, row: rowIndex);
      }
    }
    return res;
  }

  Future<List<Map<String, String>>> obtenerMovimientos() async {
    if (!await init() || _sheetMovimientos == null) return [];
    final rows = await _sheetMovimientos!.values.allRows();
    if (rows.length <= 1) return [];

    return rows.sublist(1).where((r) => r.isNotEmpty).map((f) => {
      'Fecha': f.isNotEmpty ? f[0] : '',
      'Material': f.length > 1 ? f[1] : '',
      'Tipo': f.length > 2 ? f[2] : '',
      'Cantidad': f.length > 3 ? f[3] : '0',
      'Persona': f.length > 4 ? f[4] : '',
      'Observacion': f.length > 5 ? f[5] : '',
      'Foto': f.length > 6 ? f[6] : '',
    }).toList();
  }

  Future<bool> registrarPersonal(String cedula, String nombre, String cargo, String foto) async {
    if (!await init() || _sheetPersonal == null) return false;
    return await _sheetPersonal!.values.appendRow([cedula, nombre, cargo, foto]);
  }

  Future<List<Map<String, String>>> obtenerPersonal() async {
    if (!await init() || _sheetPersonal == null) return [];
    final rows = await _sheetPersonal!.values.allRows();
    if (rows.length <= 1) return [];

    return rows.sublist(1).where((r) => r.isNotEmpty).map((f) => {
      'Cedula': f.isNotEmpty ? f[0] : '',
      'Nombre': f.length > 1 ? f[1] : '',
      'Cargo': f.length > 2 ? f[2] : '',
      'Foto': f.length > 3 ? f[3] : '',
    }).toList();
  }
}

void main() {
  runApp(const InventarioApp());
}

class InventarioApp extends StatelessWidget {
  const InventarioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Inventario',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: colorBlancoPalido,
        primaryColor: colorRojoCarmin,
        appBarTheme: const AppBarTheme(
          backgroundColor: colorRojoCarmin,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      home: const MenuScreen(),
    );
  }
}

class SelectorImagenWidget extends StatefulWidget {
  final Function(String) onImagenSeleccionada;
  const SelectorImagenWidget({super.key, required this.onImagenSeleccionada});

  @override
  State<SelectorImagenWidget> createState() => _SelectorImagenWidgetState();
}

class _SelectorImagenWidgetState extends State<SelectorImagenWidget> {
  final _pathController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _pathController,
      decoration: const InputDecoration(
        labelText: 'Ruta o URL de la imagen',
        hintText: 'https://ejemplo.com/imagen.jpg',
      ),
      onChanged: (val) => widget.onImagenSeleccionada(val),
    );
  }
}

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SISTEMA DE INVENTARIO', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: ListView(
          children: [
            _buildMenuButton(context, '📦 Ver Materiales', colorRojoCarmin, const ListadoMaterialesScreen()),
            _buildMenuButton(context, '➕ Registrar Material', colorCarminHover, const RegistroMaterialScreen()),
            _buildMenuButton(context, '📋 Ver Movimientos', colorRojoCarmin, const ListadoMovimientosScreen()),
            _buildMenuButton(context, '🔄 Registrar Movimiento', colorCarminHover, const RegistroMovimientoScreen()),
            _buildMenuButton(context, '👤 Registrar Personal', Colors.grey.shade700, const RegistroPersonalScreen()),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String text, Color color, Widget screen) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class RegistroMaterialScreen extends StatefulWidget {
  const RegistroMaterialScreen({super.key});

  @override
  State<RegistroMaterialScreen> createState() => _RegistroMaterialScreenState();
}

class _RegistroMaterialScreenState extends State<RegistroMaterialScreen> {
  final _nom = TextEditingController();
  final _desc = TextEditingController();
  final _req = TextEditingController();
  final _act = TextEditingController();
  String _fotoRuta = '';
  String _mensaje = '';

  void _guardar() async {
    if (_nom.text.isEmpty || _req.text.isEmpty || _act.text.isEmpty) {
      setState(() => _mensaje = 'Completa los campos requeridos');
      return;
    }
    setState(() => _mensaje = 'Guardando...');
    final ok = await SheetsManager().agregarMaterial(
      _nom.text, _desc.text, int.parse(_req.text), int.parse(_act.text), _fotoRuta,
    );
    setState(() {
      if (ok) {
        _mensaje = '¡Material guardado exitosamente!';
        _nom.clear(); _desc.clear(); _req.clear(); _act.clear();
      } else {
        _mensaje = 'Error al guardar.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Material')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _nom, decoration: const InputDecoration(labelText: 'Nombre del material')),
            TextField(controller: _desc, decoration: const InputDecoration(labelText: 'Descripción')),
            TextField(controller: _req, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cantidad Requerida')),
            TextField(controller: _act, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cantidad Actual')),
            const SizedBox(height: 15),
            SelectorImagenWidget(onImagenSeleccionada: (path) => _fotoRuta = path),
            const SizedBox(height: 10),
            Text(_mensaje, style: const TextStyle(color: colorRojoCarmin, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: colorRojoCarmin, foregroundColor: Colors.white),
              onPressed: _guardar,
              child: const Text('Guardar Material'),
            )
          ],
        ),
      ),
    );
  }
}

class ListadoMaterialesScreen extends StatelessWidget {
  const ListadoMaterialesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Listado de Materiales')),
      body: FutureBuilder<List<Map<String, String>>>(
        future: SheetsManager().obtenerInventario(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) return const Center(child: Text('Sin materiales registrados.'));

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.inventory_2, color: colorRojoCarmin),
                  title: Text(item['Nombre'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${item['Descripcion']}\nRequerido: ${item['Cantidad_Requerida']} | Actual: ${item['Cantidad_Actual']}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Pantalla: Registrar Movimiento con Autocomplete / Buscador Estilo Google
class RegistroMovimientoScreen extends StatefulWidget {
  const RegistroMovimientoScreen({super.key});

  @override
  State<RegistroMovimientoScreen> createState() => _RegistroMovimientoScreenState();
}

class _RegistroMovimientoScreenState extends State<RegistroMovimientoScreen> {
  String _tipo = 'RETIRO';
  String _materialSeleccionado = '';
  String _personaSeleccionada = '';
  final _cant = TextEditingController();
  final _obs = TextEditingController();
  String _fotoRuta = '';
  String _mensaje = '';

  List<String> _listaMateriales = [];
  List<String> _listaPersonal = [];
  bool _cargandoDatos = true;

  @override
  void initState() {
    super.initState();
    _cargarSugerencias();
  }

  void _cargarSugerencias() async {
    final matList = await SheetsManager().obtenerInventario();
    final perList = await SheetsManager().obtenerPersonal();
    
    setState(() {
      _listaMateriales = matList.map((e) => e['Nombre'] ?? '').where((n) => n.isNotEmpty).toList();
      _listaPersonal = perList.map((e) => e['Nombre'] ?? '').where((n) => n.isNotEmpty).toList();
      _cargandoDatos = false;
    });
  }

  void _guardar() async {
    if (_materialSeleccionado.isEmpty || _cant.text.isEmpty) {
      setState(() => _mensaje = 'Selecciona un material y su cantidad');
      return;
    }
    final ok = await SheetsManager().registrarMovimiento(
      _materialSeleccionado, _tipo, int.parse(_cant.text), _personaSeleccionada, _obs.text, _fotoRuta,
    );
    setState(() {
      _mensaje = ok ? '¡Movimiento registrado con éxito!' : 'Error al registrar.';
      if (ok) {
        _cant.clear(); _obs.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Movimiento')),
      body: _cargandoDatos
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Buscador Predictivo de Materiales
                  const Text('Buscar Material:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                      return _listaMateriales.where((String option) {
                        return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (String selection) {
                      _materialSeleccionado = selection;
                    },
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        onEditingComplete: onEditingComplete,
                        onChanged: (val) => _materialSeleccionado = val,
                        decoration: const InputDecoration(
                          hintText: 'Escribe para buscar material...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 15),

                  DropdownButton<String>(
                    value: _tipo,
                    isExpanded: true,
                    items: ['RETIRO', 'INGRESO'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setState(() => _tipo = v!),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: _cant, 
                    keyboardType: TextInputType.number, 
                    decoration: const InputDecoration(labelText: 'Cantidad', border: OutlineInputBorder())
                  ),
                  const SizedBox(height: 15),

                  // Buscador Predictivo de Personal
                  const Text('Buscar Persona / Responsable:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                      return _listaPersonal.where((String option) {
                        return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (String selection) {
                      _personaSeleccionada = selection;
                    },
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        onEditingComplete: onEditingComplete,
                        onChanged: (val) => _personaSeleccionada = val,
                        decoration: const InputDecoration(
                          hintText: 'Escribe para buscar persona...',
                          prefixIcon: Icon(Icons.person_search),
                          border: OutlineInputBorder(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    controller: _obs, 
                    decoration: const InputDecoration(labelText: 'Observación', border: OutlineInputBorder())
                  ),
                  const SizedBox(height: 15),

                  SelectorImagenWidget(onImagenSeleccionada: (path) => _fotoRuta = path),
                  const SizedBox(height: 10),

                  Center(
                    child: Text(_mensaje, style: const TextStyle(color: colorRojoCarmin, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorRojoCarmin,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _guardar,
                      child: const Text('Registrar Transacción', style: TextStyle(fontSize: 16)),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}

class RegistroPersonalScreen extends StatefulWidget {
  const RegistroPersonalScreen({super.key});

  @override
  State<RegistroPersonalScreen> createState() => _RegistroPersonalScreenState();
}

class _RegistroPersonalScreenState extends State<RegistroPersonalScreen> {
  final _ced = TextEditingController();
  final _nom = TextEditingController();
  final _cargo = TextEditingController();
  String _fotoRuta = '';
  String _mensaje = '';

  void _guardar() async {
    if (_ced.text.isEmpty || _nom.text.isEmpty) return;
    final ok = await SheetsManager().registrarPersonal(_ced.text, _nom.text, _cargo.text, _fotoRuta);
    setState(() {
      _mensaje = ok ? 'Personal registrado.' : 'Error al guardar.';
      if (ok) { _ced.clear(); _nom.clear(); _cargo.clear(); }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Personal')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _ced, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cédula')),
            TextField(controller: _nom, decoration: const InputDecoration(labelText: 'Nombre y Apellido')),
            TextField(controller: _cargo, decoration: const InputDecoration(labelText: 'Cargo')),
            const SizedBox(height: 15),
            SelectorImagenWidget(onImagenSeleccionada: (path) => _fotoRuta = path),
            const SizedBox(height: 10),
            Text(_mensaje, style: const TextStyle(color: colorRojoCarmin, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: colorRojoCarmin, foregroundColor: Colors.white),
              onPressed: _guardar,
              child: const Text('Guardar Personal'),
            )
          ],
        ),
      ),
    );
  }
}

class ListadoMovimientosScreen extends StatelessWidget {
  const ListadoMovimientosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Movimientos')),
      body: FutureBuilder<List<Map<String, String>>>(
        future: SheetsManager().obtenerMovimientos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) return const Center(child: Text('Sin movimientos registrados.'));

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final esIngreso = item['Tipo'] == 'INGRESO';
              return Card(
                child: ListTile(
                  leading: Icon(
                    esIngreso ? Icons.arrow_downward : Icons.arrow_upward,
                    color: esIngreso ? Colors.green : colorRojoCarmin,
                  ),
                  title: Text('${item['Material']} (${item['Cantidad']} unid.)'),
                  subtitle: Text('[${item['Fecha']}] Tipo: ${item['Tipo']}\nPersona: ${item['Persona']}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}