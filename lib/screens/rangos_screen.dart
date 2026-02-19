import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'resultados_rangos_screen.dart';

class RangosScreen extends StatefulWidget {
  const RangosScreen({super.key});

  @override
  State<RangosScreen> createState() => _RangosScreenState();
}

class _RangosScreenState extends State<RangosScreen> {
  final TextEditingController _cicloController = TextEditingController();
  final TextEditingController _correriaController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  
  String? _cicloSeleccionado; // Variable para el ciclo seleccionado en dropdown

  String? _errorMessage;

  @override
  void dispose() {
    _cicloController.dispose();
    _correriaController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  void _buscar() {
    setState(() {
      _errorMessage = null;
    });

    final ciclo = _cicloSeleccionado; // Usar el ciclo del dropdown
    final correria = _correriaController.text.trim();
    final direccion = _direccionController.text.trim().toUpperCase();

    // Validar combinaciones
    bool cicloLleno = ciclo != null && ciclo.isNotEmpty;
    bool correriaLleno = correria.isNotEmpty;
    bool direccionLleno = direccion.isNotEmpty;

    // Validar que al menos un campo esté lleno
    if (!cicloLleno && !correriaLleno && !direccionLleno) {
      setState(() {
        _errorMessage = 'Debe ingresar al menos un criterio de búsqueda';
      });
      return;
    }

    // Validar que CICLO no esté solo
    if (cicloLleno && !correriaLleno && !direccionLleno) {
      setState(() {
        _errorMessage = 'CICLO debe combinarse con CORRERIA o DIRECCIÓN';
      });
      return;
    }

    // Validar que CORRERIA no esté solo
    if (correriaLleno && !cicloLleno && !direccionLleno) {
      setState(() {
        _errorMessage = 'CORRERIA debe combinarse con CICLO o DIRECCIÓN';
      });
      return;
    }

    // Validar que CORRERIA tenga exactamente 4 dígitos si está lleno
    if (correriaLleno && correria.length != 4) {
      setState(() {
        _errorMessage = 'CORRERIA debe tener exactamente 4 dígitos';
      });
      return;
    }

    // Navegar a la pantalla de resultados
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultadosRangosScreen(
          ciclo: cicloLleno ? ciclo : null,
          correria: correriaLleno ? correria : null,
          direccion: direccionLleno ? direccion : null,
        ),
      ),
    );
  }

  void _limpiar() {
    setState(() {
      _cicloSeleccionado = null; // Limpiar el ciclo del dropdown
      _correriaController.clear();
      _direccionController.clear();
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rangos Lectura'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Mensaje informativo
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reglas de búsqueda:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildRegla('• DIRECCIÓN: puede buscarse sola'),
                  _buildRegla('• CICLO: debe combinarse con CORRERIA o DIRECCIÓN'),
                  _buildRegla('• CORRERIA: debe combinarse con CICLO o DIRECCIÓN'),
                ],
              ),
            ),

            // Campos de búsqueda
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Campo CICLO (Dropdown)
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 1),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('Seleccionar CICLO'),
                        value: _cicloSeleccionado,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.loop, color: Colors.grey),
                        items: List.generate(
                          20,
                          (index) => DropdownMenuItem(
                            value: (index + 1).toString(),
                            child: Text((index + 1).toString()),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _cicloSeleccionado = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Campo CORRERIA (máximo 4 dígitos)
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 1),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: TextField(
                        controller: _correriaController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'CORRERIA (4 dígitos)',
                          prefixIcon: Icon(Icons.route, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                          hintText: 'Ej: 8001, 8002',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Campo DIRECCIÓN
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 1),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: TextField(
                        controller: _direccionController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'DIRECCIÓN',
                          prefixIcon: Icon(Icons.location_on, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                          hintText: 'Ej: AVDA 10 DIAG 52',
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Mensaje de error
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red, width: 2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Botones
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _buscar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A237E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'BUSCAR',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _limpiar,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1A237E),
                              side: const BorderSide(color: Color(0xFF1A237E), width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'LIMPIAR',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegla(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black87,
        ),
      ),
    );
  }
}
