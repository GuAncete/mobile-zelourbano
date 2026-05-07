import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/report_provider.dart';
import '../models/denuncia.dart';
import 'create_report_screen.dart';
import '../utils/type_helper.dart';
import '../utils/constants.dart';
import '../utils/status_denuncia.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStreamSubscription;
  
  LatLng _currentLocation = const LatLng(-20.41722, -49.97278); // Defaults to Votuporanga

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
        context.read<ReportProvider>().fetchUserDenuncias(auth.user!.id);
      }
    }
  }

  Future<void> _startLocationTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return;
    } 

    // Pega a posição inicial rapidamente
    final initialPosition = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentLocation = LatLng(initialPosition.latitude, initialPosition.longitude);
      });
      _mapController.move(_currentLocation, 15.0);
    }

    // Inicia o stream para atualizações em tempo real
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Atualiza a cada 10 metros
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
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Consumer<ReportProvider>(
      builder: (context, reportProvider, _) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showLegendDialog(context),
            ),
            title: const Text('Zelo Urbano'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  final auth = context.read<AuthProvider>();
                  if (auth.user != null) {
                    reportProvider.fetchUserDenuncias(auth.user!.id);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  Provider.of<AuthProvider>(context, listen: false).logout();
                },
              )
            ],
          ),
          body: reportProvider.isLoading && reportProvider.userDenuncias.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLocation,
                    initialZoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.zelo_urbano',
                    ),
                    MarkerLayer(
                      markers: _buildMarkers(reportProvider.userDenuncias),
                    ),
                  ],
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateReportScreen(initialLocation: _currentLocation),
                ),
              );

              if (result == true) {
                // Provider will call fetchAllDenuncias internally or we can do it here
                final auth = context.read<AuthProvider>();
                reportProvider.refreshAll(auth.user?.id);
              }
            },
            backgroundColor: primaryColor,
            icon: const Icon(Icons.add_a_photo, color: Colors.white),
            label: const Text('Nova Denúncia',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
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
          onTap: () {
            _showReportDetails(d);
          },
          child: Icon(
            Icons.location_on,
            color: StatusDenuncia.getColor(d.status),
            size: 40,
          ),
        ),
      );
    }).toList();

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
            child: Icon(
              Icons.my_location,
              color: Colors.blue,
              size: 30,
            ),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (d.imagens.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      '${Constants.storageUrl}/${d.imagens.first}',
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              Text(
                d.titulo,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _StatusBadge(status: d.status),
              const SizedBox(height: 16),
              const Text('Descrição:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(d.descricao),
              const SizedBox(height: 8),
              const Text('Tipo:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(TypeHelper.getText(d.tipo).toUpperCase()),
              const SizedBox(height: 16),
              Text(
                'Cadastrado em: ${d.data}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }
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
