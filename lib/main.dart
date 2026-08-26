import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'sheets_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MiInventarioApp());
}

class MiInventarioApp extends StatelessWidget {
  const MiInventarioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sistema de Inventario',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        useMaterial3: true,
      ),
      home: const PantallaPrincipal(),
    );
  }
}

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> with SingleTickerProviderStateMixin {
  
  final TextEditingController _busquedaCtrl = TextEditingController(); // Controller del Buscador
  String _filtroBusqueda = '';

  @override
  void initState() {
    super.initState();
    _cargarDatosCompletos();
    
    // Escuchar cambios en la barra de búsqueda
    _busquedaCtrl.addListener(() {
      setState(() {
        _filtroBusqueda = _busquedaCtrl.text.toLowerCase().trim();
      });
    });
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  // Modificación del menú de opciones al tocar un material
  void _opcionesMaterial(Map<String, dynamic> material) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.teal),
              title: const Text('Editar Valores'),
              onTap: () {
                Navigator.pop(context);
                _mostrarFormularioEditarMaterial(material); // Abre formulario de edición
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.blue),
              title: const Text('Ver Movimientos'),
              onTap: () {
                Navigator.pop(context);
                // Tu función de ver movimientos existente
                _verMovimientosMaterial(material);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Función para desplegar la modal de edición
  void _mostrarFormularioEditarMaterial(Map<String, dynamic> material) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FormularioEditarMaterialModal(
        material: material,
        onGuardar: (nombre, desc, stockActual, stockReq, unidad) async {
          Navigator.pop(context);
          setState(() => _cargando = true);

          bool exito = await _sheetsService.editarMaterial(
            nombre: nombre,
            descripcion: desc,
            cantidadActual: stockActual,
            cantidadRequerida: stockReq,
            unidad: unidad,
          );

          if (exito) {
            await _cargarDatosCompletos();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Material actualizado correctamente')),
              );
            }
          } else {
            setState(() => _cargando = false);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error al actualizar el material')),
              );
            }
          }
        },
      ),
    );
  }

  // Vista actualizada de la lista de materiales con Buscador incorporado
  Widget _buildListaMateriales() {
    // Filtrar la lista según la búsqueda realizada por el usuario
    final materialesFiltrados = _materiales.where((item) {
      final nombre = (item['Nombre'] ?? '').toString().toLowerCase();
      final desc = (item['Descripcion'] ?? '').toString().toLowerCase();
      return nombre.contains(_filtroBusqueda) || desc.contains(_filtroBusqueda);
    }).toList();

    return Column(
      children: [
        // Buscador superior
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _busquedaCtrl,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o descripción...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _filtroBusqueda.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _busquedaCtrl.clear(),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            ),
          ),
        ),

        // Lista de materiales filtrada
        Expanded(
          child: materialesFiltrados.isEmpty
              ? const Center(child: Text('No se encontraron materiales.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: materialesFiltrados.length,
                  itemBuilder: (context, index) {
                    final item = materialesFiltrados[index];
                    final stock = int.tryParse(item['Cantidad_Actual'] ?? '0') ?? 0;
                    final requerida = item['Cantidad_Requerida'] ?? '0';
                    final unidad = item['Unidad'] ?? '';
                    final imagenUrl = item['Imagen_URL'] ?? '';

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: ListTile(
                        onTap: () => _opcionesMaterial(item),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imagenUrl.isNotEmpty
                              ? Image.network(
                                  imagenUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(stock),
                                )
                              : _buildAvatarFallback(stock),
                        ),
                        title: Text(item['Nombre'] ?? 'Sin Nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(item['Descripcion'] ?? 'Sin descripción'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Stock: $stock ${unidad.isNotEmpty ? unidad : ''}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: stock <= 0 ? Colors.red : Colors.black,
                              ),
                            ),
                            Text(
                              'Req: $requerida ${unidad.isNotEmpty ? unidad : ''}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAvatarFallback(int stock) {
    return CircleAvatar(
      backgroundColor: stock <= 0 ? Colors.red.shade100 : Colors.teal.shade100,
      child: Icon(
        Icons.inventory_2,
        color: stock <= 0 ? Colors.red : Colors.teal.shade800,
      ),
    );
  }

  late TabController _tabController;
  final SheetsService _sheetsService = SheetsService();

  List<Map<String, String>> _materiales = [];
  List<Map<String, String>> _movimientos = [];
  List<Map<String, String>> _personal = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _cargarDatosCompletos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosCompletos() async {
    setState(() => _cargando = true);
    try {
      final resultados = await Future.wait([
        _sheetsService.obtenerMateriales(),
        _sheetsService.obtenerMovimientos(),
        _sheetsService.obtenerPersonal(),
      ]);

      setState(() {
        _materiales = resultados[0];
        _movimientos = resultados[1].reversed.toList();
        _personal = resultados[2];
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  void _opcionesMaterial(Map<String, String> item) {
    final nombreMaterial = item['Nombre'] ?? '';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                nombreMaterial,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.teal),
                title: const Text('Cambiar / Tomar Foto'),
                onTap: () {
                  Navigator.pop(context);
                  _seleccionarYActualizarFoto(nombreMaterial);
                },
              ),
              ListTile(
                leading: const Icon(Icons.history, color: Colors.blue),
                title: const Text('Ver Historial de Movimientos'),
                onTap: () {
                  Navigator.pop(context);
                  _mostrarMovimientosDelMaterial(nombreMaterial);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _seleccionarYActualizarFoto(String nombreMaterial) async {
    final picker = ImagePicker();
    final ImageSource? origen = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar origen de foto'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Cámara'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: const Text('Galería'),
          ),
        ],
      ),
    );

    if (origen == null) return;

    final pickedFile = await picker.pickImage(source: origen, imageQuality: 70);

    if (pickedFile != null) {
      setState(() => _cargando = true);
      final bytes = await pickedFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      bool exito = await _sheetsService.actualizarFotoMaterial(
        nombre: nombreMaterial,
        imagenBase64: base64Image,
      );

      if (exito) {
        await _cargarDatosCompletos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto actualizada correctamente')),
          );
        }
      } else {
        setState(() => _cargando = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al actualizar la foto')),
          );
        }
      }
    }
  }

  // En _PantallaPrincipalState:

void _mostrarFormularioMaterial() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => FormularioMaterialModal(
      // Actualizamos la firma del callback agregando 'unidad'
      onGuardar: (nombre, desc, stockActual, stockReq, unidad, imagenBase64) async {
        Navigator.pop(context);
        setState(() => _cargando = true);

        bool exito = await _sheetsService.registrarMaterial(
          nombre: nombre,
          descripcion: desc,
          cantidadActual: stockActual,
          cantidadRequerida: stockReq,
          unidad: unidad, // <-- Pasar aquí la unidad al servicio
          imagenBase64: imagenBase64,
        );

        if (exito) {
          await _cargarDatosCompletos();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Material guardado correctamente')),
            );
          }
        }
      },
    ),
  );
}

  void _mostrarFormularioMovimiento() {
    if (_materiales.isEmpty || _personal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cargando listas de datos, intenta de nuevo...')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FormularioMovimientoModal(
        materiales: _materiales,
        personal: _personal,
        onGuardar: (material, tipo, cantidad, persona, obs) async {
          Navigator.pop(context);
          setState(() => _cargando = true);

          bool exito = await _sheetsService.registrarMovimiento(
            materialNombre: material,
            tipo: tipo,
            cantidad: cantidad,
            personaCedula: persona,
            observacion: obs,
          );

          if (exito) {
            await _cargarDatosCompletos();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Movimiento registrado y stock actualizado')),
              );
            }
          }
        },
      ),
    );
  }

  void _mostrarMovimientosDelMaterial(String nombreMaterial) {
    final historialFiltrado = _movimientos.where((mov) {
      final matNombre = mov['Material']?.toString().toLowerCase().trim() ?? '';
      return matNombre == nombreMaterial.toLowerCase().trim();
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Historial: $nombreMaterial',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const Divider(),
              Expanded(
                child: historialFiltrado.isEmpty
                    ? const Center(child: Text('No hay movimientos registrados para este material.'))
                    : ListView.builder(
                        itemCount: historialFiltrado.length,
                        itemBuilder: (context, index) {
                          final mov = historialFiltrado[index];
                          final esIngreso = mov['Tipo']?.toUpperCase() == 'INGRESO';

                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: esIngreso ? Colors.green.shade50 : Colors.red.shade50,
                                child: Icon(
                                  esIngreso ? Icons.arrow_downward : Icons.arrow_upward,
                                  color: esIngreso ? Colors.green : Colors.red,
                                ),
                              ),
                              title: Text(
                                '${mov['Tipo']} - Cantidad: ${mov['Cantidad']}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Fecha: ${mov['Fecha']}\nResp: ${mov['Persona_Cedula']}\nObs: ${mov['Observacion'] ?? '-'}',
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Inventario', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatosCompletos,
            tooltip: 'Actualizar Datos',
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2), text: 'Hoja 8'),
            Tab(icon: Icon(Icons.history), text: 'Movimientos'),
            Tab(icon: Icon(Icons.people), text: 'Personal'),
          ],
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildListaMateriales(),
                _buildListaMovimientos(),
                _buildListaPersonal(),
              ],
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Wrap(
        direction: Axis.vertical,
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: 12,
        children: [
          if (_tabController.index == 0)
            FloatingActionButton.extended(
              heroTag: 'btnMaterial',
              onPressed: _mostrarFormularioMaterial,
              backgroundColor: Colors.teal.shade900,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_box),
              label: const Text('Nuevo Material'),
            ),
          FloatingActionButton.extended(
            heroTag: 'btnMovimiento',
            onPressed: _mostrarFormularioMovimiento,
            backgroundColor: Colors.teal.shade600,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Nuevo Movimiento'),
          ),
        ],
      ),
    );
  }

  // En _buildListaMateriales():

  Widget _buildListaMateriales() {
    if (_materiales.isEmpty) return const Center(child: Text('No hay materiales registrados'));

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _materiales.length,
      itemBuilder: (context, index) {
        final item = _materiales[index];
        final stock = int.tryParse(item['Cantidad_Actual'] ?? '0') ?? 0;
        final requerida = item['Cantidad_Requerida'] ?? '0';
        final unidad = item['Unidad'] ?? ''; // <-- Obtener valor de la unidad
        final imagenUrl = item['Imagen_URL'] ?? '';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            onTap: () => _opcionesMaterial(item),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imagenUrl.isNotEmpty
                  ? Image.network(
                      imagenUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(stock),
                    )
                  : _buildAvatarFallback(stock),
            ),
            title: Text(item['Nombre'] ?? 'Sin Nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(item['Descripcion'] ?? 'Sin descripción'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Stock: $stock ${unidad.isNotEmpty ? unidad : ''}', // <-- Muestra la unidad junto al Stock
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: stock <= 0 ? Colors.red : Colors.black,
                  ),
                ),
                Text(
                  'Req: $requerida ${unidad.isNotEmpty ? unidad : ''}', // <-- Muestra la unidad junto al requerimiento
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatarFallback(int stock) {
    return CircleAvatar(
      backgroundColor: stock <= 0 ? Colors.red.shade100 : Colors.teal.shade100,
      child: Icon(
        Icons.inventory_2,
        color: stock <= 0 ? Colors.red : Colors.teal.shade800,
      ),
    );
  }

  Widget _buildListaMovimientos() {
    if (_movimientos.isEmpty) return const Center(child: Text('No hay registros de movimientos'));

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _movimientos.length,
      itemBuilder: (context, index) {
        final mov = _movimientos[index];
        final esIngreso = mov['Tipo']?.toUpperCase() == 'INGRESO';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: esIngreso ? Colors.green.shade50 : Colors.red.shade50,
              child: Icon(
                esIngreso ? Icons.arrow_downward : Icons.arrow_upward,
                color: esIngreso ? Colors.green : Colors.red,
              ),
            ),
            title: Text('${mov['Material']} (${mov['Tipo']})', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Fecha: ${mov['Fecha']}\nPersona: ${mov['Persona_Cedula']}\nObs: ${mov['Observacion'] ?? '-'}'),
            isThreeLine: true,
            trailing: Text(
              '${esIngreso ? "+" : "-"}${mov['Cantidad']}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: esIngreso ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildListaPersonal() {
    if (_personal.isEmpty) return const Center(child: Text('No hay personal registrado'));

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _personal.length,
      itemBuilder: (context, index) {
        final p = _personal[index];

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(p['Nombre'] ?? 'Sin Nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Cargo: ${p['Cargo'] ?? 'N/A'}'),
            trailing: Text('C.I: ${p['Cedula'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        );
      },
    );
  }
}

class FormularioMaterialModal extends StatefulWidget {
  // 1. Agregar 'String unidad' al callback onGuardar
  final Function(
    String nombre, 
    String descripcion, 
    int stockActual, 
    int stockRequerida, 
    String unidad, 
    String? imagenBase64
  ) onGuardar;

  const FormularioMaterialModal({super.key, required this.onGuardar});

  @override
  State<FormularioMaterialModal> createState() => _FormularioMaterialModalState();
}

class _FormularioMaterialModalState extends State<FormularioMaterialModal> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _stockActualCtrl = TextEditingController(text: '0');
  final _stockReqCtrl = TextEditingController(text: '0');

  // 2. Variable para almacenar la unidad seleccionada
  String _unidadSeleccionada = 'Unidades';

  // Lista de unidades comunes (puedes ajustar según tus necesidades)
  final List<String> _opcionesUnidad = [
    'Und',
    'Rollos',
    'Caja',
    'Pares',
    'Laminas',
    'Sacos',
    'Litros',
    'Galon',
    'Atados',
    'metros',
    'm2',
    'm3',
    'Serv',
    'Pza',
    'Bolsa',
  ];

  Uint8List? _imagenBytes;
  String? _imagenBase64;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    _stockActualCtrl.dispose();
    _stockReqCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen(ImageSource origen) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: origen, imageQuality: 70);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imagenBytes = bytes;
        _imagenBase64 = base64Encode(bytes);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Agregar Nuevo Material', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Center(
                child: Column(
                  children: [
                    _imagenBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(_imagenBytes!, height: 120, width: 120, fit: BoxFit.cover),
                          )
                        : Container(
                            height: 100,
                            width: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                            child: const Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                          ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _seleccionarImagen(ImageSource.camera),
                          icon: const Icon(Icons.camera),
                          label: const Text('Cámara'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () => _seleccionarImagen(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Galería'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre del Material', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese el nombre' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Descripción / Especificaciones', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),

              // 3. Dropdown para seleccionar la unidad de medida
              DropdownButtonFormField<String>(
                value: _unidadSeleccionada,
                decoration: const InputDecoration(
                  labelText: 'Unidad de Medida',
                  border: OutlineInputBorder(),
                ),
                items: _opcionesUnidad.map((u) {
                  return DropdownMenuItem(value: u, child: Text(u));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _unidadSeleccionada = val);
                },
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockActualCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Stock Inicial', border: OutlineInputBorder()),
                      validator: (v) => v == null || int.tryParse(v) == null ? 'Inválido' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _stockReqCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Cantidad Requerida', border: OutlineInputBorder()),
                      validator: (v) => v == null || int.tryParse(v) == null ? 'Inválido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onGuardar(
                      _nombreCtrl.text.trim(),
                      _descCtrl.text.trim(),
                      int.parse(_stockActualCtrl.text),
                      int.parse(_stockReqCtrl.text),
                      _unidadSeleccionada, // <-- Se pasa la unidad seleccionada
                      _imagenBase64,
                    );
                  }
                },
                child: const Text('Guardar Material', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FormularioMovimientoModal extends StatefulWidget {
  final List<Map<String, String>> materiales;
  final List<Map<String, String>> personal;
  final Function(String material, String tipo, int cantidad, String persona, String obs) onGuardar;

  const FormularioMovimientoModal({
    super.key,
    required this.materiales,
    required this.personal,
    required this.onGuardar,
  });

  @override
  State<FormularioMovimientoModal> createState() => _FormularioMovimientoModalState();
}

class _FormularioMovimientoModalState extends State<FormularioMovimientoModal> {
  final _formKey = GlobalKey<FormState>();

  String? _materialSeleccionado;
  String _tipoSeleccionado = 'RETIRO';
  String? _personaSeleccionada;
  final _cantidadController = TextEditingController();
  final _observacionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Registrar Movimiento', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Material', border: OutlineInputBorder()),
                items: widget.materiales.map((m) {
                  final nombre = m['Nombre'] ?? '';
                  return DropdownMenuItem(value: nombre, child: Text(nombre));
                }).toList(),
                onChanged: (val) => setState(() => _materialSeleccionado = val),
                validator: (val) => val == null ? 'Seleccione un material' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _tipoSeleccionado,
                decoration: const InputDecoration(labelText: 'Tipo de Movimiento', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'RETIRO', child: Text('RETIRO')),
                  DropdownMenuItem(value: 'INGRESO', child: Text('INGRESO')),
                ],
                onChanged: (val) => setState(() => _tipoSeleccionado = val!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cantidadController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cantidad', border: OutlineInputBorder()),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Ingrese la cantidad';
                  if (int.tryParse(val) == null || int.parse(val) <= 0) return 'Ingrese un número válido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Persona Responsable', border: OutlineInputBorder()),
                items: widget.personal.map((p) {
                  final formato = '${p['Nombre']} (${p['Cedula']})';
                  return DropdownMenuItem(value: formato, child: Text(formato));
                }).toList(),
                onChanged: (val) => setState(() => _personaSeleccionada = val),
                validator: (val) => val == null ? 'Seleccione la persona' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _observacionController,
                decoration: const InputDecoration(labelText: 'Observación', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onGuardar(
                      _materialSeleccionado!,
                      _tipoSeleccionado,
                      int.parse(_cantidadController.text),
                      _personaSeleccionada!,
                      _observacionController.text,
                    );
                  }
                },
                child: const Text('Guardar Registros', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// En lib/main.dart (al final del archivo):

class FormularioEditarMaterialModal extends StatefulWidget {
  final Map<String, dynamic> material;
  final Function(
    String nombre,
    String descripcion,
    int stockActual,
    int stockRequerida,
    String unidad,
  ) onGuardar;

  const FormularioEditarMaterialModal({
    super.key,
    required this.material,
    required this.onGuardar,
  });

  @override
  State<FormularioEditarMaterialModal> createState() => _FormularioEditarMaterialModalState();
}

class _FormularioEditarMaterialModalState extends State<FormularioEditarMaterialModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _stockActualCtrl;
  late TextEditingController _stockReqCtrl;
  late String _unidadSeleccionada;

  final List<String> _opcionesUnidad = [
    'Unidades',
    'Piezas',
    'Sacos',
    'Metros',
    'Kilos',
    'Cajas',
    'Litros',
  ];

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.material['Nombre'] ?? '');
    _descCtrl = TextEditingController(text: widget.material['Descripcion'] ?? '');
    _stockActualCtrl = TextEditingController(text: (widget.material['Cantidad_Actual'] ?? '0').toString());
    _stockReqCtrl = TextEditingController(text: (widget.material['Cantidad_Requerida'] ?? '0').toString());
    
    final unidadActual = widget.material['Unidad'] ?? 'Unidades';
    _unidadSeleccionada = _opcionesUnidad.contains(unidadActual) ? unidadActual : _opcionesUnidad.first;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    _stockActualCtrl.dispose();
    _stockReqCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Editar Material', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              
              // Campo Nombre (DESHABILITADO)
              TextFormField(
                controller: _nombreCtrl,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Material (No editable)',
                  border: OutlineInputBorder(),
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),

              // Campo Descripción
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Descripción / Especificaciones', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),

              // Dropdown Unidad
              DropdownButtonFormField<String>(
                value: _unidadSeleccionada,
                decoration: const InputDecoration(
                  labelText: 'Unidad de Medida',
                  border: OutlineInputBorder(),
                ),
                items: _opcionesUnidad.map((u) {
                  return DropdownMenuItem(value: u, child: Text(u));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _unidadSeleccionada = val);
                },
              ),
              const SizedBox(height: 12),

              // Campos de Stock
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockActualCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Stock Actual', border: OutlineInputBorder()),
                      validator: (v) => v == null || int.tryParse(v) == null ? 'Inválido' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _stockReqCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Cantidad Requerida', border: OutlineInputBorder()),
                      validator: (v) => v == null || int.tryParse(v) == null ? 'Inválido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onGuardar(
                      _nombreCtrl.text.trim(),
                      _descCtrl.text.trim(),
                      int.parse(_stockActualCtrl.text),
                      int.parse(_stockReqCtrl.text),
                      _unidadSeleccionada,
                    );
                  }
                },
                child: const Text('Actualizar Material', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}