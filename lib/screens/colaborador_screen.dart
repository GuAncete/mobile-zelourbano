import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/denuncia.dart';
import '../providers/auth_provider.dart';
import '../providers/report_provider.dart';
import '../utils/status_denuncia.dart';
import '../utils/type_helper.dart';
import '../utils/constants.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'route_screen.dart';

class ColaboradorScreen extends StatefulWidget {
  const ColaboradorScreen({super.key});

  @override
  State<ColaboradorScreen> createState() => _ColaboradorScreenState();
}

class _ColaboradorScreenState extends State<ColaboradorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetch();
    });
  }

  void _fetch() {
    final auth = context.read<AuthProvider>();
    if (auth.user != null) {
      context.read<ReportProvider>().fetchColaboradorDenuncias(auth.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Atribuições'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _fetch,
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
      body: Consumer<ReportProvider>(
        builder: (context, reportProvider, _) {
          if (reportProvider.isLoading && reportProvider.colaboradorDenuncias.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final denuncias = reportProvider.colaboradorDenuncias;

          if (denuncias.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_late_outlined, size: 72, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma denúncia atribuída a você.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Novas atribuições aparecerão aqui.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _fetch(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: denuncias.length,
              itemBuilder: (context, index) {
                final d = denuncias[index];
                return _DenunciaCard(
                  denuncia: d,
                  onTap: () => _showDetails(context, d),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showDetails(BuildContext context, Denuncia d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DenunciaDetailSheet(denuncia: d),
    );
  }
}

// ---------------------------------------------------------------------------
// Card da lista
// ---------------------------------------------------------------------------
class _DenunciaCard extends StatelessWidget {
  final Denuncia denuncia;
  final VoidCallback onTap;

  const _DenunciaCard({required this.denuncia, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = StatusDenuncia.getColor(denuncia.status);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Foto ou ícone
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: denuncia.imagens.isNotEmpty
                    ? Image.network(
                        '${Constants.storageUrl}/${denuncia.imagens.first}',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _iconBox(),
                      )
                    : _iconBox(),
              ),
              const SizedBox(width: 14),
              // Informações
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            denuncia.titulo,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (denuncia.prioridade != null)
                          _PriorityBadge(
                            label: denuncia.prioridade!.nome,
                            colorHex: denuncia.prioridade!.cor,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      TypeHelper.getText(denuncia.tipo).toUpperCase(),
                      style: TextStyle(fontSize: 11, color: Colors.grey[600], letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 8),
                    _StatusBadge(status: denuncia.status),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBox() => Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.report_problem_outlined, color: Colors.grey[400], size: 28),
      );
}

// ---------------------------------------------------------------------------
// Badge de status
// ---------------------------------------------------------------------------
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = StatusDenuncia.getColor(status);
    final text = StatusDenuncia.getNome(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Badge de Prioridade
// ---------------------------------------------------------------------------
class _PriorityBadge extends StatelessWidget {
  final String? label;
  final String? colorHex;

  const _PriorityBadge({this.label, this.colorHex});

  @override
  Widget build(BuildContext context) {
    if (label == null) return const SizedBox.shrink();

    final Color color = _parseColor(colorHex);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label!.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 9,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null || !hex.startsWith('#')) return Colors.grey;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet de detalhes + botão de rota + pré-finalizar
// ---------------------------------------------------------------------------
class _DenunciaDetailSheet extends StatefulWidget {
  final Denuncia denuncia;

  const _DenunciaDetailSheet({required this.denuncia});

  @override
  State<_DenunciaDetailSheet> createState() => _DenunciaDetailSheetState();
}

class _DenunciaDetailSheetState extends State<_DenunciaDetailSheet> {
  bool _isSubmitting = false;
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimerIfNeeded() {
    if (widget.denuncia.status == '2' && widget.denuncia.dataInicioAtendimento != null) {
      // O Laravel envia em UTC (Y-m-d H:i:s). Precisamos garantir que o Flutter entenda como UTC.
      String dateStr = widget.denuncia.dataInicioAtendimento!;
      if (!dateStr.contains('Z') && !dateStr.contains('+')) {
        dateStr = '${dateStr.replaceFirst(' ', 'T')}Z';
      }
      
      final startTime = DateTime.tryParse(dateStr);
      if (startTime != null) {
        final localStartTime = startTime.toLocal();
        // O tempo decorrido é o acumulado + a diferença do início desta sessão até agora
        final baseDuration = Duration(seconds: widget.denuncia.tempoAcumulado);
        _elapsed = baseDuration + DateTime.now().difference(localStartTime);
        
        _timer?.cancel();
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _elapsed = baseDuration + DateTime.now().difference(localStartTime);
            });
          }
        });
      }
    } else {
      // Se não está em andamento, mas tem tempo acumulado (ex: parado), mostra o acumulado
      if (widget.denuncia.tempoAcumulado > 0) {
        setState(() {
          _elapsed = Duration(seconds: widget.denuncia.tempoAcumulado);
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return "00:00:00";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  Future<void> _abrirRota(BuildContext context) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Serviço de localização desativado');
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permissão negada');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permissão negada permanentemente');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      final startPos = LatLng(position.latitude, position.longitude);

      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RouteScreen(
            startPos: startPos, 
            destination: widget.denuncia
          )
        )
      );

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao obter localização: $e')),
        );
      }
    }
  }

  /// Colaborador inicia o atendimento (Status 5 -> 2).
  Future<void> _iniciar(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Iniciar Atendimento'),
        content: const Text('Deseja iniciar o atendimento agora? O tempo começará a contar.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Não')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), foregroundColor: Colors.white),
            child: const Text('Sim, Iniciar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);
    try {
      await context.read<ReportProvider>().iniciarDenuncia(widget.denuncia.id, auth.user!.id);
      if (context.mounted) {
        Navigator.pop(context); // Fechar bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Atendimento iniciado! O tempo está contando.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao iniciar atendimento.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Colaborador interrompe o atendimento (Status 2 -> 5).
  Future<void> _parar(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Interromper Atendimento'),
        content: const Text('Deseja parar o atendimento agora? A denúncia voltará para o status "Atribuído" e o tempo será zerado.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Voltar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            child: const Text('Confirmar Interrupção'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);
    try {
      await context.read<ReportProvider>().pararDenuncia(widget.denuncia.id, auth.user!.id);
      if (context.mounted) {
        Navigator.pop(context); // Fechar bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Atendimento interrompido!'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao interromper atendimento.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Pré-finaliza a denúncia: colaborador envia relatório (Status 2 → 3).
  Future<void> _preFinalizar(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;
    
    final TextEditingController relatorioController = TextEditingController();
    final List<XFile> selecionadas = [];
    final ImagePicker picker = ImagePicker();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Enviar Relatório'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Descreva o que foi verificado/realizado no local e adicione fotos se necessário.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: relatorioController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Descreva o serviço realizado...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Fotos do Serviço:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    const SizedBox(height: 8),
                    if (selecionadas.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: selecionadas.asMap().entries.map((entry) {
                            final index = entry.key;
                            final foto = entry.value;
                            return Stack(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.grey.shade200, // Fundo cinza para caso a imagem não carregue
                                    image: DecorationImage(
                                      image: kIsWeb 
                                          ? NetworkImage(foto.path) as ImageProvider
                                          : FileImage(File(foto.path)),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0, right: 8,
                                  child: GestureDetector(
                                    onTap: () => setStateDialog(() => selecionadas.removeAt(index)),
                                    child: Container(
                                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final XFile? photo = await picker.pickImage(
                                source: ImageSource.camera,
                                imageQuality: 70, // Reduzir tamanho do arquivo
                              );
                              if (photo != null) setStateDialog(() => selecionadas.add(photo));
                            },
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Câmera'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final List<XFile> images = await picker.pickMultiImage(
                                imageQuality: 70,
                              );
                              if (images.isNotEmpty) setStateDialog(() => selecionadas.addAll(images));
                            },
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Galeria'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
                  child: const Text('Enviar'),
                ),
              ],
            );
          }
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);
    try {
      await context.read<ReportProvider>().preFinalizarDenuncia(
        widget.denuncia.id, 
        auth.user!.id,
        relatorio: relatorioController.text.trim(),
        fotos: selecionadas,
      );
      if (context.mounted) {
        Navigator.pop(context); // Fechar o BottomSheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Relatório e fotos enviados com sucesso!'), 
            backgroundColor: Color(0xFF3B82F6),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        // Mostramos o erro real para o usuário entender o que houve
        String msgErro = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msgErro), 
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título e badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.denuncia.prioridade != null) ...[
                                  _PriorityBadge(
                                    label: widget.denuncia.prioridade!.nome,
                                    colorHex: widget.denuncia.prioridade!.cor,
                                  ),
                                  const SizedBox(height: 4),
                                ],
                                Text(
                                  widget.denuncia.titulo,
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(status: widget.denuncia.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        TypeHelper.getText(widget.denuncia.tipo).toUpperCase(),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500], letterSpacing: 0.8),
                      ),

                      // Resumo de Finalização se estiver em Revisão (Status 3)
                      if (widget.denuncia.status == '3') ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'RESUMO DA FINALIZAÇÃO',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12, letterSpacing: 1),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('FINALIZADA EM', style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Text(
                                        widget.denuncia.dataFimAtendimento != null 
                                          ? _formatDateTime(widget.denuncia.dataFimAtendimento!) 
                                          : 'N/A',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('TEMPO TOTAL', style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatDuration(Duration(seconds: widget.denuncia.tempoAcumulado)),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Timer se estiver em andamento (Status 2)
                      if (widget.denuncia.status == '2') ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.timer_outlined, color: Color(0xFF3B82F6), size: 22),
                              const SizedBox(width: 12),
                              const Text(
                                'TEMPO DECORRIDO: ',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3B82F6), fontSize: 13, letterSpacing: 1),
                              ),
                              Text(
                                _formatDuration(_elapsed),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3B82F6),
                                  fontFamily: 'Courier', // Estilo relógio
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const Divider(height: 28),

                      // Fotos do Cidadão
                      if (widget.denuncia.fotosCidadao.isNotEmpty) ...[
                        const Text('Fotos da Denúncia (Cidadão)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 8),
                        _buildPhotoGallery(widget.denuncia.fotosCidadao),
                        const SizedBox(height: 16),
                      ],

                      // Relatório do Colaborador (se houver)
                      if (widget.denuncia.relatorioColaborador != null && widget.denuncia.relatorioColaborador!.isNotEmpty) ...[
                        const Text('Relatório de Serviço', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF3B82F6))),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                          ),
                          child: Text(widget.denuncia.relatorioColaborador!, style: const TextStyle(fontSize: 14, height: 1.5)),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Fotos do Colaborador (Execução)
                      if (widget.denuncia.fotosColaborador.isNotEmpty) ...[
                        const Text('Fotos do Serviço (Colaborador)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF3B82F6))),
                        const SizedBox(height: 8),
                        _buildPhotoGallery(widget.denuncia.fotosColaborador),
                        const SizedBox(height: 16),
                      ],

                      // Instruções
                      if (widget.denuncia.descricaoAdmin.isNotEmpty) ...[
                        const Text('Instruções', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange)),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: Text(widget.denuncia.descricaoAdmin, style: const TextStyle(fontSize: 14, height: 1.5)),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Descrição
                      const Text('Descrição', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(widget.denuncia.descricao, style: const TextStyle(fontSize: 14, height: 1.5)),
                      ),

                      const SizedBox(height: 16),

                      // Localização
                      _InfoRow(icon: Icons.location_on_outlined, label: 'Localização',
                        value: '${widget.denuncia.latitude.toStringAsFixed(6)}, ${widget.denuncia.longitude.toStringAsFixed(6)}'),
                      const SizedBox(height: 8),
                      _InfoRow(icon: Icons.calendar_today_outlined, label: 'Data',
                        value: widget.denuncia.data),
                      
                      if (widget.denuncia.dataFimAtendimento != null) ...[
                        const SizedBox(height: 8),
                        _InfoRow(
                          icon: Icons.check_circle_outline, 
                          label: 'Finalizada em', 
                          value: _formatDateTime(widget.denuncia.dataFimAtendimento!),
                        ),
                        if (widget.denuncia.tempoAcumulado > 0) ...[
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.hourglass_bottom_outlined, 
                            label: 'Tempo de Execução', 
                            value: _formatDuration(Duration(seconds: widget.denuncia.tempoAcumulado)),
                          ),
                        ],
                      ],

                      const SizedBox(height: 28),

                      // Botões de ação
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _abrirRota(context),
                              icon: const Icon(Icons.map_outlined),
                              label: const Text('Mapa Interno'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D9488),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          // Botão de INICIAR só aparece se status = Atribuído (5)
                          if (widget.denuncia.status == '5') ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isSubmitting ? null : () => _iniciar(context),
                                icon: _isSubmitting 
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                                  : const Icon(Icons.play_arrow_outlined),
                                label: Text(_isSubmitting ? 'Iniciando...' : 'Iniciar Serviço'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8B5CF6),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                          // Botão de PARAR só aparece se status = Em Andamento (2)
                          if (widget.denuncia.status == '2') ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isSubmitting ? null : () => _parar(context),
                                icon: _isSubmitting 
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                                  : const Icon(Icons.stop_circle_outlined),
                                label: Text(_isSubmitting ? 'Parando...' : 'Parar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                          // Botão de pré-finalizar só aparece se status = Em Andamento (2)
                          if (widget.denuncia.status == '2') ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isSubmitting ? null : () => _preFinalizar(context),
                                icon: _isSubmitting 
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                                  : const Icon(Icons.assignment_turned_in_outlined),
                                label: Text(_isSubmitting ? 'Finalizar' : 'Finalizar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3B82F6),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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

  Widget _buildPhotoGallery(List<String> fotos) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: fotos.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              '${Constants.storageUrl}/${fotos[index]}',
              height: 180,
              width: MediaQuery.of(context).size.width * 0.7,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 180,
                width: MediaQuery.of(context).size.width * 0.7,
                color: Colors.grey[200],
                child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDateTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString;
    }
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
        Icon(icon, size: 18, color: const Color(0xFF0D9488)),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Expanded(
          child: Text(value, style: TextStyle(fontSize: 13, color: Colors.grey[700]), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
