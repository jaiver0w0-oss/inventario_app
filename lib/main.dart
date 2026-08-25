import 'package:flutter/material.dart';
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
    _tabController.addListener(() => setState(() {})); // Redibuja al cambiar de pestaña para actualizar los botones flotantes
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

  // Modal para agregar Nuevo Material
  void _mostrarFormularioMaterial() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FormularioMaterialModal(
        onGuardar: (nombre, desc, stockActual, stockReq) async {
          Navigator.pop(context);
          setState(() => _cargando = true);

          bool exito = await _sheetsService.registrarMaterial(
            nombre: nombre,
            descripcion: desc,
            cantidadActual: stockActual,
            cantidadRequerida: stockReq,
          );

          if (exito) {
            await _cargarDatosCompletos();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Material registrado correctamente')),
              );
            }
          }
        },
      ),
    );
  }
  // Muestra el historial filtrado de movimientos del material seleccionado
  void _mostrarMovimientosDelMaterial(String nombreMaterial) {
    // Filtrar la lista global de movimientos por el nombre exacto del material
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
          height: MediaQuery.of(context).size.height * 0.7, // 70% de la altura de pantalla
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
                    ? const Center(
                        child: Text('No hay movimientos registrados para este material.'),
                      )
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

  // Modal para agregar Nuevo Movimiento
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
        spacing: 12, // Separación entre botones
        children: [
          // Botón para Nuevo Material (Solo visible en Hoja 8)
          if (_tabController.index == 0)
            FloatingActionButton.extended(
              heroTag: 'btnMaterial',
              onPressed: _mostrarFormularioMaterial,
              backgroundColor: Colors.teal.shade900,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_box),
              label: const Text('Nuevo Material'),
            ),
          
          // Botón para Nuevo Movimiento
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

  Widget _buildListaMateriales() {
    if (_materiales.isEmpty) return const Center(child: Text('No hay materiales en Hoja 8'));

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _materiales.length,
      itemBuilder: (context, index) {
        final item = _materiales[index];
        final stock = int.tryParse(item['Cantidad_Actual'] ?? '0') ?? 0;
        final requerida = item['Cantidad_Requerida'] ?? '0';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            onTap: () => _mostrarMovimientosDelMaterial(item['Nombre'] ?? ''),
            leading: CircleAvatar(
              backgroundColor: stock <= 0 ? Colors.red.shade100 : Colors.green.shade100,
              child: Icon(
                stock <= 0 ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
                color: stock <= 0 ? Colors.red : Colors.green.shade800,
              ),
            ),
            title: Text(item['Nombre'] ?? 'Sin Nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(item['Descripcion'] ?? 'Sin descripción'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Stock: $stock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: stock <= 0 ? Colors.red : Colors.black)),
                Text('Requerido: $requerida', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
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

// ==========================================
// MODAL PARA NUEVO MATERIAL
// ==========================================
class FormularioMaterialModal extends StatefulWidget {
  final Function(String nombre, String descripcion, int stockActual, int stockRequerido) onGuardar;

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
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockActualCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Stock Inicial', border: OutlineInputBorder()),
                      validator: (v) => v == null || int.tryParse(v) == null ? ' Inválido' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _stockReqCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Cantidad Requerida', border: OutlineInputBorder()),
                      validator: (v) => v == null || int.tryParse(v) == null ? ' Inválido' : null,
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

// ==========================================
// MODAL PARA NUEVO MOVIMIENTO
// ==========================================
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