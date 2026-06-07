import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../models/denuncia.dart';

class RouteScreen extends StatefulWidget {
  final LatLng startPos;
  final Denuncia destination;

  const RouteScreen({
    super.key,
    required this.startPos,
    required this.destination,
  });

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    final start = widget.startPos;
    final dest = LatLng(widget.destination.latitude, widget.destination.longitude);
    
    final startUrlStr = '${start.longitude},${start.latitude}';
    final destUrlStr = '${dest.longitude},${dest.latitude}';

    final mapboxToken = dotenv.env['MAPBOX_TOKEN'] ?? '';
    
    final url = Uri.parse(
      'https://api.mapbox.com/directions/v5/mapbox/driving/$startUrlStr;$destUrlStr?geometries=geojson&access_token=$mapboxToken&overview=full'
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
          
          if (mounted) {
            setState(() {
              _routePoints = coordinates.map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble())).toList();
              _isLoading = false;
            });
            _fitMap();
          }
        } else {
          _handleRouteError('Nenhum caminho por estrada encontrado.');
        }
      } else {
        _handleRouteError('Erro na conexão com o serviço de mapas.');
      }
    } catch (e) {
      _handleRouteError('Erro ao calcular rota. Verifique sua conexão.');
    }
  }

  void _handleRouteError(String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
        _isLoading = false;
        // Fallback: Linha reta entre os pontos
        _routePoints = [
          widget.startPos,
          LatLng(widget.destination.latitude, widget.destination.longitude)
        ];
      });
      _fitMap();
    }
  }

  void _fitMap() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_routePoints.isNotEmpty) {
        final bounds = LatLngBounds.fromPoints(_routePoints);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(70.0),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dest = LatLng(widget.destination.latitude, widget.destination.longitude);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Traçado de Rota'),
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.startPos,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.zelourbano.app',
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5.0,
                      color: const Color(0xFF3B82F6),
                      borderColor: Colors.white,
                      borderStrokeWidth: 2.0,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.startPos,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
                      ),
                      child: const Icon(Icons.my_location, color: Color(0xFF3B82F6), size: 24),
                    ),
                  ),
                  Marker(
                    point: dest,
                    width: 45,
                    height: 45,
                    child: const Icon(Icons.location_on, color: Colors.red, size: 45),
                    alignment: Alignment.topCenter,
                  ),
                ],
              ),
            ],
          ),
          
          // Indicador de Carregamento
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: Center(
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF0D9488)),
                        SizedBox(height: 16),
                        Text('Calculando melhor caminho...', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Banner de Erro/Fallback
          if (_errorMessage.isNotEmpty)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade800,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8)],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$_errorMessage (Mostrando linha direta)',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
