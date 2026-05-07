import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/report_provider.dart';
import '../models/denuncia.dart';
import '../utils/constants.dart';
import '../utils/status_denuncia.dart';
import '../utils/type_helper.dart';
import 'route_screen.dart';

class ColaboradorMapScreen extends StatefulWidget {
  const ColaboradorMapScreen({super.key});

  @override
  State<ColaboradorMapScreen> createState() => _ColaboradorMapScreenState();
}

class _ColaboradorMapScreenState extends State<ColaboradorMapScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStreamSubscription;
  LatLng _currentLocation = const LatLng(-20.41722, -49.97278);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initMap();
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initMap() async {
    await _startLocationTracking();
    if (mounted) {
      final auth = context.read<AuthProvider>();
      if (auth.user != null) {
        context.read<ReportProvider>().fetchColaboradorDenuncias(auth.user!.id);
      }
    }
  }

  Future<void> _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    // Posição inicial
    final initialPosition = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentLocation = LatLng(initialPosition.latitude, initialPosition.longitude);
      });
      _mapController.move(_currentLocation, 14.0);
    }

    // Stream de atualizações
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, reportProvider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Mapa de Atribuições'),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: 'Legenda',
                onPressed: () => _showLegendDialog(context),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Atualizar',
                onPressed: () {
                  final auth = context.read<AuthProvider>();
                  if (auth.user != null) {
                    reportProvider.fetchColaboradorDenuncias(auth.user!.id);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Sair',
                onPressed: () {
                  Provider.of<AuthProvider>(context, listen: false).logout();
                },
              ),
            ],
          ),
          body: reportProvider.isLoading && reportProvider.colaboradorDenuncias.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentLocation,
                        initialZoom: 14.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.zelo_urbano',
                        ),
                        MarkerLayer(
                          markers: _buildMarkers(reportProvider.colaboradorDenuncias),
                        ),
                      ],
                    ),
                    if (reportProvider.colaboradorDenuncias.isEmpty)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Text(
                            'Nenhuma denúncia atribuída',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      // Badge com contagem
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.assignment, size: 18, color: Color(0xFF0D9488)),
                              const SizedBox(width: 6),
                              Text(
                                '${reportProvider.colaboradorDenuncias.length} atribuição(ões)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF0D9488),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
          floatingActionButton: reportProvider.colaboradorDenuncias.isNotEmpty
              ? FloatingActionButton(
                  onPressed: () {
                    // Ajustar câmera para mostrar todos os marcadores
                    final denuncias = reportProvider.colaboradorDenuncias;
                    if (denuncias.length == 1) {
                      _mapController.move(
                        LatLng(denuncias.first.latitude, denuncias.first.longitude),
                        15.0,
                      );
                    } else {
                      final points = denuncias
                          .map((d) => LatLng(d.latitude, d.longitude))
                          .toList();
                      points.add(_currentLocation);
                      final bounds = LatLngBounds.fromPoints(points);
                      _mapController.fitCamera(
                        CameraFit.bounds(
                          bounds: bounds,
                          padding: const EdgeInsets.all(60),
                        ),
                      );
                    }
                  },
                  backgroundColor: const Color(0xFF0D9488),
                  child: const Icon(Icons.fit_screen, color: Colors.white),
                )
              : null,
        );
      },
    );
  }

  void _showLegendDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Legenda de Cores'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: StatusDenuncia.todos.map((s) => _buildLegendItem(s.cor, s.nome)).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Icon(Icons.location_on, color: color, size: 28),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  List<Marker> _buildMarkers(List<Denuncia> denuncias) {
    final markers = denuncias.map((d) {
      return Marker(
        point: LatLng(d.latitude, d.longitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _showReportDetails(d),
          child: Icon(
            Icons.location_on,
            color: StatusDenuncia.getColor(d.status),
            size: 40,
          ),
        ),
      );
    }).toList();

    // Marcador da posição atual
    markers.add(
      Marker(
        point: _currentLocation,
        width: 50,
        height: 50,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.my_location, color: Colors.blue, size: 30),
          ),
        ),
      ),
    );

    return markers;
  }

  void _showReportDetails(Denuncia d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ColaboradorMapDetailSheet(denuncia: d),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet de detalhes da denúncia (com rota e concluir)
// ---------------------------------------------------------------------------
class _ColaboradorMapDetailSheet extends StatefulWidget {
  final Denuncia denuncia;
  const _ColaboradorMapDetailSheet({required this.denuncia});

  @override
  State<_ColaboradorMapDetailSheet> createState() => _ColaboradorMapDetailSheetState();
}

class _ColaboradorMapDetailSheetState extends State<_ColaboradorMapDetailSheet> {
  bool _isConcluding = false;

  Future<void> _abrirRota(BuildContext context) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Serviço de localização desativado');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception('Permissão negada');
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permissão negada permanentemente');
      }

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final startPos = LatLng(position.latitude, position.longitude);

      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RouteScreen(startPos: startPos, destination: widget.denuncia),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao obter localização: $e')),
        );
      }
    }
  }

  Future<void> _preFinalizar(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;
    
    final TextEditingController relatorioController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Enviar Relatório'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Descreva o que foi verificado/realizado no local. '
                'O administrador irá revisar antes de finalizar.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: relatorioController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Ex: Buraco tapado com asfalto a frio...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (relatorioController.text.trim().length < 10) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('O relatório deve ter pelo menos 10 caracteres.')),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
              ),
              child: const Text('Enviar Relatório'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isConcluding = true);
    try {
      await context.read<ReportProvider>().preFinalizarDenuncia(
        widget.denuncia.id, 
        auth.user!.id,
        relatorio: relatorioController.text.trim(),
      );
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Relatório enviado com sucesso!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao concluir denúncia.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isConcluding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Handle decorativo
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabeçalho com ID e Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'PROTOCOLO #${widget.denuncia.id}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Colors.grey[400],
                              letterSpacing: 1.2,
                            ),
                          ),
                          _StatusBadge(status: widget.denuncia.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.denuncia.titulo,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.category_outlined, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            TypeHelper.getText(widget.denuncia.tipo).toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500],
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // SEÇÃO: Instruções do Administrador (Destaque)
                      if (widget.denuncia.descricaoAdmin.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFFEDD5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.assignment_ind, size: 18, color: Color(0xFFC2410C)),
                                  SizedBox(width: 8),
                                  Text(
                                    'ORIENTAÇÕES DA ADMINISTRAÇÃO',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFC2410C),
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                widget.denuncia.descricaoAdmin,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF7C2D12),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // SEÇÃO: Galeria de Fotos
                      if (widget.denuncia.imagens.isNotEmpty) ...[
                        const Text(
                          'EVIDÊNCIAS VISUAIS',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 180,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: widget.denuncia.imagens.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  '${Constants.storageUrl}/${widget.denuncia.imagens[index]}',
                                  width: MediaQuery.of(context).size.width * 0.7,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: MediaQuery.of(context).size.width * 0.7,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // SEÇÃO: Detalhes da Ocorrência
                      const Text(
                        'DETALHES DA OCORRÊNCIA',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.denuncia.descricao,
                              style: const TextStyle(fontSize: 15, color: Color(0xFF334155), height: 1.6),
                            ),
                            const Divider(height: 32),
                            _InfoRow(
                              icon: Icons.calendar_today_rounded,
                              label: 'Registrado em',
                              value: widget.denuncia.data,
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(
                              icon: Icons.location_on_rounded,
                              label: 'Coordenadas',
                              value: '${widget.denuncia.latitude.toStringAsFixed(5)}, ${widget.denuncia.longitude.toStringAsFixed(5)}',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // BOTÕES DE AÇÃO
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () => _abrirRota(context),
                              icon: const Icon(Icons.directions_rounded, size: 20),
                              label: const Text('TRAÇAR ROTA'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D9488),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 4,
                                shadowColor: const Color(0xFF0D9488).withOpacity(0.4),
                                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                              ),
                            ),
                          ),
                          if (widget.denuncia.status == '2') ...[
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: ElevatedButton.icon(
                                onPressed: _isConcluding ? null : () => _preFinalizar(context),
                                icon: _isConcluding
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.check_circle_rounded, size: 20),
                                label: Text(_isConcluding ? 'ENVIANDO...' : 'CONCLUIR TRABALHO'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3B82F6),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 4,
                                  shadowColor: const Color(0xFF3B82F6).withOpacity(0.4),
                                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF0D9488)),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[500])),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
          ],
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = StatusDenuncia.getColor(status);
    final text = StatusDenuncia.getNome(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
