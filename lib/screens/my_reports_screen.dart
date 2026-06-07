import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/denuncia.dart';
import '../providers/auth_provider.dart';
import '../providers/report_provider.dart';
import '../utils/constants.dart';
import '../utils/status_denuncia.dart';
import '../utils/type_helper.dart';
import 'package:intl/intl.dart';
import 'report_details_screen.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _fetch() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user != null) {
        context.read<ReportProvider>().fetchUserDenuncias(auth.user!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: StatusDenuncia.cidadaoTodos.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Minhas Denúncias'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sair',
              onPressed: () {
                Provider.of<AuthProvider>(context, listen: false).logout();
              },
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: StatusDenuncia.cidadaoTodos.map((s) => Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: s.cor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(s.nome),
                ],
              ),
            )).toList(),
          ),
        ),
        body: Consumer<ReportProvider>(
          builder: (context, reportProvider, _) {
            if (reportProvider.isLoading && reportProvider.userDenuncias.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return TabBarView(
              children: StatusDenuncia.cidadaoTodos.map((s) {
                final filtered = reportProvider.userDenuncias
                    .where((d) => StatusDenuncia.getCitizenStatusId(d.status) == s.id.toString())
                    .toList();
                return _ReportList(
                  denuncias: filtered,
                  onRefresh: () async => _fetch(),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}

class _ReportList extends StatelessWidget {
  final List<Denuncia> denuncias;
  final Future<void> Function() onRefresh;

  const _ReportList({required this.denuncias, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (denuncias.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nenhuma denúncia encontrada.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: denuncias.length,
        itemBuilder: (context, index) {
          final denuncia = denuncias[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              contentPadding: const EdgeInsets.all(8),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: denuncia.imagens.isNotEmpty
                    ? Image.network(
                        '${Constants.storageUrl}/${denuncia.imagens.first}',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported),
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image),
                      ),
              ),
              title: Text(
                denuncia.titulo,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(TypeHelper.getText(denuncia.tipo).toUpperCase()),
                  const SizedBox(height: 4),
                  Text(
                    'Data: ${denuncia.data}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  _StatusBadge(status: denuncia.status),

                  // Mostrar justificativa de cancelamento se cancelada
                  if (denuncia.status == '0' && denuncia.justificativaCancelamento.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B7280).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF6B7280).withOpacity(0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: Color(0xFF6B7280)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              denuncia.justificativaCancelamento,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Mostrar mensagem do admin se finalizada
                  if (denuncia.status == '4' && denuncia.mensagemCidadao.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.message_outlined, size: 16, color: Color(0xFF10B981)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              denuncia.mensagemCidadao,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF10B981)),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportDetailsScreen(denuncia: denuncia),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = StatusDenuncia.getCitizenColor(status);
    final text = StatusDenuncia.getCitizenNome(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}
