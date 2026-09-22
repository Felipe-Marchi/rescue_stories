import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'custom_network_image.dart';

// Renderiza um componente interativo para seleção de imagens via câmera, galeria ou remoção.
class ImagePickerField extends StatefulWidget {
  final String? initialImageUrl;
  final Function(File?) onImageSelected;
  final VoidCallback? onImageRemoved;

  // Inicializa o componente exigindo a função de retorno para repassar o arquivo ou nulo.
  const ImagePickerField({
    super.key,
    this.initialImageUrl,
    required this.onImageSelected,
    this.onImageRemoved,
  });

  @override
  State<ImagePickerField> createState() => _ImagePickerFieldState();
}

class _ImagePickerFieldState extends State<ImagePickerField> {
  File? _selectedImage;
  bool _isImageRemoved = false;

  // Aciona a interface nativa do dispositivo para capturar ou selecionar uma imagem.
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      setState(() {
        _selectedImage = file;
        _isImageRemoved = false;
      });
      widget.onImageSelected(file);
    }
  }

  // Remove a seleção de imagem atual e aciona a notificação de remoção.
  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _isImageRemoved = true;
    });
    widget.onImageSelected(null);
    if (widget.onImageRemoved != null) {
      widget.onImageRemoved!();
    }
  }

  // Exibe um menu deslizante inferior para escolha ou remoção de imagem.
  void _showImageSourceOptions() {
    final hasImage = _selectedImage != null ||
        (!_isImageRemoved &&
            widget.initialImageUrl != null &&
            widget.initialImageUrl!.isNotEmpty);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.green),
                title: const Text('Tirar Foto'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('Escolher da Galeria'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (hasImage) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    'Remover Foto',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _removeImage();
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Image.file(
          _selectedImage!,
          fit: BoxFit.cover,
          width: double.infinity,
        ),
      );
    }

    if (!_isImageRemoved &&
        widget.initialImageUrl != null &&
        widget.initialImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: CustomNetworkImage(
          imageUrl: widget.initialImageUrl!,
          height: 200,
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo, size: 48, color: Colors.grey.shade400),
        const SizedBox(height: 8.0),
        Text(
          'Toque para adicionar uma foto',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showImageSourceOptions,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: _buildImagePreview(),
      ),
    );
  }
}