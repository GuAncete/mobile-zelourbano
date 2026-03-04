import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/denuncia.dart';
import '../services/api_service.dart';
import 'create_report_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final ApiService _apiService = ApiService();
  
  LatLng _currentLocation = const LatLng(-23.5505, -46.6333); // Defaults to Sao Paulo
  List<Denuncia> _denuncias = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  Future<void> _initMap() async {
    await _determinePosition();
    await _fetchDenuncias();
  }

  Future<void> _fetchDenuncias() async {
    try {
      final denuncias = await _apiService.getDenuncias();
      setState(() {
        _denuncias = denuncias;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Erro ao buscar denúncias: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
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

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _mapController.move(_currentLocation, 15.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zelo Urbano'),
        actions: [
          IconButton(
             icon: const Icon(Icons.refresh),
             onPressed: () {
               setState(() => _isLoading = true);
               _fetchDenuncias();
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
      body: _isLoading 
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
                markers: _buildMarkers(),
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
            setState(() => _isLoading = true);
            _fetchDenuncias();
          }
        },
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add_a_photo, color: Colors.white),
        label: const Text('Nova Denúncia', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  List<Marker> _buildMarkers() {
    return _denuncias.map((d) {
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
            color: _getMarkerColor(d.status),
            size: 40,
          ),
        ),
      );
    }).toList();
  }

  Color _getMarkerColor(String status) {
    switch (status.toLowerCase()) {
      case 'pendente': return Colors.red;
      case 'em_andamento': return Colors.orange;
      case 'concluido': return Colors.green;
      default: return Colors.blue;
    }
  }

  void _showReportDetails(Denuncia d) {
    showModalBottomSheet(
      context: context,
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
              Text(
                d.titulo,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _getMarkerColor(d.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  d.status.toUpperCase(),
                  style: TextStyle(
                    color: _getMarkerColor(d.status),
                    fontWeight: FontWeight.bold,
                    fontSize: 12
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Descrição:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(d.descricao),
              const SizedBox(height: 8),
              const Text('Tipo:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(d.tipo),
              const SizedBox(height: 16),
              // Could add photo viewing later here
              const SizedBox(height: 16),
            ],
          ),
        );
      }
    );
  }
}
