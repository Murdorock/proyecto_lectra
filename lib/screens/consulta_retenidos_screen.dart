import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../services/consulta_retenidos_metricas_service.dart';

class ConsultaRetenidosScreen extends StatefulWidget {
  const ConsultaRetenidosScreen({super.key});

  @override
  State<ConsultaRetenidosScreen> createState() => _ConsultaRetenidosScreenState();
}

class _ConsultaRetenidosScreenState extends State<ConsultaRetenidosScreen> {
  final _instalacionController = TextEditingController();
  final _contratoController = TextEditingController();

  String? _resultado;
  String? _mensaje;
  bool _buscando = false;
  late DateTime _horaApertura;

  @override
  void initState() {
    super.initState();
    _horaApertura = DateTime.now();
    ConsultaRetenidosMetricasService.registrarVistaAbierta();
  }

  @override
  void dispose() {
    final tiempoVista = DateTime.now().difference(_horaApertura).inSeconds;
    ConsultaRetenidosMetricasService.registrarTiempoVista(tiempoVista);
    _instalacionController.dispose();
    _contratoController.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    FocusScope.of(context).unfocus();

    final instalacion = _instalacionController.text.trim();
    final contrato = _contratoController.text.trim();

    if (instalacion.isEmpty && contrato.isEmpty) {
      await ConsultaRetenidosMetricasService.registrarIntentofallido(
        tipo: 'campos_vacios',
        mensaje: 'No se ingreso instalacion ni contrato',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes ingresar INSTALACION o CONTRATO'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (instalacion.isNotEmpty && contrato.isNotEmpty) {
      await ConsultaRetenidosMetricasService.registrarIntentofallido(
        tipo: 'multiples_campos',
        mensaje: 'Se ingresaron instalacion y contrato simultaneamente',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solo puedes buscar por INSTALACION o CONTRATO, no ambos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (instalacion.isNotEmpty && instalacion.length > 18) {
      await ConsultaRetenidosMetricasService.registrarIntentofallido(
        tipo: 'longitud_instalacion',
        mensaje: 'Ingreso ${instalacion.length} digitos, maximo 18',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('INSTALACION solo permite 18 digitos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _buscando = true;
      _resultado = null;
      _mensaje = null;
    });

    try {
      if (instalacion.isNotEmpty) {
        await ConsultaRetenidosMetricasService.registrarConsulta(
          criterio: 'instalacion',
          valor: instalacion,
        );
      } else {
        await ConsultaRetenidosMetricasService.registrarConsulta(
          criterio: 'contrato',
          valor: contrato,
        );
      }

      final query = supabase.from('consulta_retenidos').select('personalizado');
      final data = instalacion.isNotEmpty
          ? await query.eq('instalacion', instalacion).maybeSingle()
          : await query.eq('contrato', contrato).maybeSingle();

      if (data == null) {
        if (instalacion.isNotEmpty) {
          await ConsultaRetenidosMetricasService.registrarBusquedaSinResultados(
            criterio: 'instalacion',
            valor: instalacion,
          );
        } else {
          await ConsultaRetenidosMetricasService.registrarBusquedaSinResultados(
            criterio: 'contrato',
            valor: contrato,
          );
        }
        setState(() {
          _mensaje = 'No se encontraron coincidencias';
        });
        return;
      }

      final personalizado = data['personalizado'];
      setState(() {
        _resultado = personalizado != null ? personalizado.toString() : 'Sin dato';
      });
    } catch (e) {
      setState(() {
        _mensaje = 'Error al buscar: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _buscando = false;
        });
      }
    }
  }

  void _limpiar() {
    FocusScope.of(context).unfocus();
    setState(() {
      _instalacionController.clear();
      _contratoController.clear();
      _resultado = null;
      _mensaje = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CONSULTA RETENIDOS'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _instalacionController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(18),
              ],
              decoration: const InputDecoration(
                labelText: 'INSTALACION',
                prefixIcon: Icon(Icons.confirmation_number),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contratoController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'CONTRATO',
                prefixIcon: Icon(Icons.receipt_long),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _buscando ? null : _buscar,
                      icon: _buscando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.search),
                      label: Text(_buscando ? 'BUSCANDO...' : 'BUSCAR'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _buscando ? null : _limpiar,
                      icon: const Icon(Icons.clear),
                      label: const Text('LIMPIAR'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1A237E),
                        side: const BorderSide(color: Color(0xFF1A237E)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_resultado != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resultado',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _resultado ?? '',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              )
            else if (_mensaje != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _mensaje!,
                  style: TextStyle(color: Colors.orange.shade800),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
