import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notificacao_provider.dart';
import 'map_screen.dart';
import 'my_reports_screen.dart';
import 'notificacoes_screen.dart';
import 'colaborador_screen.dart';
import 'colaborador_map_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Busca contagem de notificações não lidas ao entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user != null && auth.user!.tipo == '3') {
        // Cidadão: busca notificações
        context.read<NotificacaoProvider>().fetchNaoLidasCount();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isColaborador = auth.user?.isColaborador ?? false;

    if (isColaborador) {
      // Colaborador: Mapa + Lista de atribuições
      final colaboradorScreens = [
        const ColaboradorMapScreen(),
        const ColaboradorScreen(),
      ];

      return Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: colaboradorScreens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: const Color(0xFF0D9488),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Mapa',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: 'Atribuições',
            ),
          ],
        ),
      );
    }

    // Cidadãos veem: Mapa + Minhas Denúncias + Notificações
    final screens = [
      const MapScreen(),
      const MyReportsScreen(),
      const NotificacoesScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: Consumer<NotificacaoProvider>(
        builder: (context, notifProvider, _) {
          return BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() => _selectedIndex = index);
              // Atualiza contagem ao entrar na aba de notificações
              if (index == 2) {
                notifProvider.fetchNotificacoes();
              }
            },
            selectedItemColor: const Color(0xFF0D9488),
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.map_outlined),
                activeIcon: Icon(Icons.map),
                label: 'Mapa',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.assignment_outlined),
                activeIcon: Icon(Icons.assignment),
                label: 'Minhas Denúncias',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: notifProvider.naoLidasCount > 0,
                  label: Text(
                    notifProvider.naoLidasCount.toString(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  child: const Icon(Icons.notifications_outlined),
                ),
                activeIcon: Badge(
                  isLabelVisible: notifProvider.naoLidasCount > 0,
                  label: Text(
                    notifProvider.naoLidasCount.toString(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  child: const Icon(Icons.notifications),
                ),
                label: 'Notificações',
              ),
            ],
          );
        },
      ),
    );
  }
}
