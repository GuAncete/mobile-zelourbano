import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';

class CreateReportScreen extends StatefulWidget {
  final LatLng initialLocation;
  
  const CreateReportScreen({super.key, required this.initialLocation});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  String _tipoDenuncia = 'buraco'; // default type
  
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  final List<String> _tipos = [
    'buraco',
    'iluminacao',
    'lixo',
    'saneamento',
    'arvore',
    'outro'
  ];

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70, // Compress slightly
    );
    
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _submitReport() async {
    if (_formKey.currentState!.validate()) {
      if (_imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, tire uma foto do problema.')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        // 1. Create the report
        final denunciaData = {
          'titulo_denuncia': _tituloController.text.trim(),
          'tipo_denuncia': _tipoDenuncia,
          'descricao_denuncia': _descricaoController.text.trim(),
          'latitude_denuncia': widget.initialLocation.latitude.toString(),
          'longitude_denuncia': widget.initialLocation.longitude.toString(),
          // Data gets added by Laravel automatically usually or we can rely on its timestamp
        };

        final createdDenuncia = await _apiService.createDenuncia(denunciaData);

        // 2. Upload the photo
        await _apiService.uploadFotoDenuncia(createdDenuncia.id, _imageFile!.path);

        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
               content: Text('Denúncia registrada com sucesso!'),
               backgroundColor: Colors.green,
             ),
           );
           Navigator.pop(context, true); // Return true to signal map refresh
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('Erro ao registrar denúncia: $e'),
               backgroundColor: Colors.redAccent,
             ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Denúncia'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Picker Area
                GestureDetector(
                  onTap: () => _pickImage(ImageSource.camera),
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                      image: _imageFile != null 
                         ? DecorationImage(
                             image: FileImage(_imageFile!),
                             fit: BoxFit.cover,
                           )
                         : null,
                    ),
                    child: _imageFile == null 
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              'Toque para tirar uma foto',
                              style: TextStyle(color: Colors.grey.shade600),
                            )
                          ],
                        )
                      : null,
                  ),
                ),
                
                if (_imageFile != null)
                   TextButton.icon(
                     onPressed: () => _pickImage(ImageSource.gallery),
                     icon: const Icon(Icons.photo_library),
                     label: const Text('Ou escolha da galeria'),
                   ),

                const SizedBox(height: 24),
                
                TextFormField(
                  controller: _tituloController,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    hintText: 'Ex: Buraco profundo na via',
                  ),
                  validator: (value) => 
                      value == null || value.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<String>(
                  value: _tipoDenuncia,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Problema',
                  ),
                  items: _tipos.map((tipo) {
                    return DropdownMenuItem(
                      value: tipo,
                      child: Text(tipo.toUpperCase()),
                     );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _tipoDenuncia = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _descricaoController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    hintText: 'Descreva os detalhes do problema...',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => 
                      value == null || value.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 32),
                
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('Enviar Denúncia'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
