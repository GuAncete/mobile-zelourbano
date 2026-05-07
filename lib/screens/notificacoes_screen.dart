import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/notificacao_provider.dart';
import '../providers/auth_provider.dart';
import '../models/notificacao.dart';

class NotificacoesScreen extends StatefulWidget {
  const NotificacoesScreen({super.key});

  @override
  State<NotificacoesScreen> createState() => _NotificacoesScreenState();
}

class _NotificacoesScreenState extends State<NotificacoesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificacaoProvider>().fetchNotificacoes();
    });
  }

  IconData _getIcon(String tipo) {
    switch (tipo) {
      case 'cancelamento':
        return Icons.cancel_outlined;
      case 'finalizado':
        return Icons.check_circle_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getColor(String tipo) {
    switch (tipo) {
      case 'cancelamento':
        return const Color(0xFF6B7280);
      case 'finalizado':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  String _getTypeLabel(String tipo) {
    switch (tipo) {
      case 'cancelamento':
        return 'CANCELADA';
      case 'finalizado':
        return 'FINALIZADA';
      default:
        return 'ATUALIZAÇÃO';
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 60) {
        return 'Há ${diff.inMinutes} min';
      } else if (diff.inHours < 24) {
        return 'Há ${diff.inHours}h';
      } else if (diff.inDays < 7) {
        return 'Há ${diff.inDays} dia${diff.inDays > 1 ? 's' : ''}';
      } else {
        return DateFormat('dd/MM/yyyy HH:mm').format(date);
      }
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          ),
          Consumer<NotificacaoProvider>(
            builder: (context, provider, _) {
              if (provider.naoLidasCount == 0) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () => provider.marcarTodasComoLidas(),
                icon: const Icon(Icons.done_all, size: 18),
                label: const Text('Ler todas', style: TextStyle(fontSize: 13)),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificacaoProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.notificacoes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.notificacoes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 72, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma notificação.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Você receberá notificações quando suas\ndenúncias forem atualizadas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchNotificacoes(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: provider.notificacoes.length,
              itemBuilder: (context, index) {
                final notif = provider.notificacoes[index];
                return _NotificacaoTile(
                  notificacao: notif,
                  icon: _getIcon(notif.tipo),
                  color: _getColor(notif.tipo),
                  typeLabel: _getTypeLabel(notif.tipo),
                  formattedDate: _formatDate(notif.createdAt),
                  onTap: () {
                    if (!notif.lida) {
                      provider.marcarComoLida(notif.id);
                    }
                    _showDetail(context, notif);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showDetail(BuildContext context, Notificacao notif) {
    final color = _getColor(notif.tipo);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getIcon(notif.tipo), color: color, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notif.titulo,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (notif.tituloDenuncia != null)
                        Text(
                          notif.tituloDenuncia!,
                          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Text(
                notif.mensagem,
                style: const TextStyle(fontSize: 15, height: 1.6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _formatDate(notif.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Tile individual da notificação ─────────────────

class _NotificacaoTile extends StatelessWidget {
  final Notificacao notificacao;
  final IconData icon;
  final Color color;
  final String typeLabel;
  final String formattedDate;
  final VoidCallback onTap;

  const _NotificacaoTile({
    required this.notificacao,
    required this.icon,
    required this.color,
    required this.typeLabel,
    required this.formattedDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: notificacao.lida ? Colors.white : color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notificacao.lida ? Colors.grey.shade200 : color.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notificacao.titulo,
                style: TextStyle(
                  fontWeight: notificacao.lida ? FontWeight.w500 : FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!notificacao.lida)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notificacao.mensagem,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  formattedDate,
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
              ],
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
