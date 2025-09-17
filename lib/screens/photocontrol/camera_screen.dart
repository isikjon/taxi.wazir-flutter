import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';

class CameraScreen extends StatefulWidget {
  final String photoType;
  final Function(File) onPhotoTaken;

  const CameraScreen({
    super.key,
    required this.photoType,
    required this.onPhotoTaken,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showErrorDialog('Камера не найдена');
        return;
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      _showErrorDialog('Ошибка инициализации камеры: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildCameraPreview(),
          _buildMaskOverlay(),
          _buildHeader(),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Positioned.fill(
      child: AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: CameraPreview(_controller!),
      ),
    );
  }

  Widget _buildMaskOverlay() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _getMaskPainter(),
      ),
    );
  }

  CustomPainter _getMaskPainter() {
    switch (widget.photoType) {
      case 'front':
        return DocumentMaskPainter(title: 'Водительское удостоверение: лицевая сторона 1/3');
      case 'back':
        return DocumentMaskPainter(title: 'Водительское удостоверение: обратная сторона 2/3');
      case 'selfie':
        return SelfieMaskPainter(title: 'Водительское удостоверение: обратная сторона 3/3');
      default:
        return DocumentMaskPainter(title: 'Документ');
    }
  }

  Widget _buildHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              Expanded(
                child: Text(
                  _getTitle(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                onPressed: _toggleFlash,
                icon: const Icon(
                  Icons.flash_off,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 60),
              GestureDetector(
                onTap: _isLoading ? null : _takePicture,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                  ),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Container(
                          margin: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTitle() {
    switch (widget.photoType) {
      case 'front':
        return 'Водительское удостоверение: лицевая сторона 1/3';
      case 'back':
        return 'Водительское удостоверение: обратная сторона 2/3';
      case 'selfie':
        return 'Водительское удостоверение: обратная сторона 3/3';
      default:
        return 'Фотография документа';
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final XFile picture = await _controller!.takePicture();
      final File photoFile = File(picture.path);
      
      widget.onPhotoTaken(photoFile);
      Navigator.of(context).pop();
    } catch (e) {
      _showErrorDialog('Ошибка при съемке: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleFlash() async {
    if (_controller == null) return;
    
    try {
      final currentFlashMode = _controller!.value.flashMode;
      final newFlashMode = currentFlashMode == FlashMode.off 
          ? FlashMode.auto 
          : FlashMode.off;
      
      await _controller!.setFlashMode(newFlashMode);
    } catch (e) {
      _showErrorDialog('Ошибка управления вспышкой: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

}

class DocumentMaskPainter extends CustomPainter {
  final String title;

  DocumentMaskPainter({required this.title});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint darkPaint = Paint()
      ..color = Colors.black.withOpacity(0.7);

    final Paint clearPaint = Paint()
      ..color = Colors.transparent
      ..blendMode = BlendMode.clear;

    // Заливаем весь экран темным цветом
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), darkPaint);

    // Вычисляем размер и позицию прямоугольника для документа
    const double aspectRatio = 1.6; // Примерное соотношение сторон ВУ
    const double margin = 40;
    
    final double rectWidth = size.width - (margin * 2);
    final double rectHeight = rectWidth / aspectRatio;
    final double rectLeft = margin;
    final double rectTop = (size.height - rectHeight) / 2;

    final Rect documentRect = Rect.fromLTWH(rectLeft, rectTop, rectWidth, rectHeight);

    // Вырезаем прозрачную область для документа
    canvas.drawRRect(
      RRect.fromRectAndRadius(documentRect, const Radius.circular(12)),
      clearPaint,
    );

    // Рисуем белую рамку вокруг области документа
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(documentRect, const Radius.circular(12)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SelfieMaskPainter extends CustomPainter {
  final String title;

  SelfieMaskPainter({required this.title});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint darkPaint = Paint()
      ..color = Colors.black.withOpacity(0.7);

    final Paint clearPaint = Paint()
      ..color = Colors.transparent
      ..blendMode = BlendMode.clear;

    // Заливаем весь экран темным цветом
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), darkPaint);

    // Область для документа (слева)
    const double margin = 30;
    final double docWidth = (size.width - margin * 3) * 0.5;
    final double docHeight = docWidth / 1.6;
    final double docLeft = margin;
    final double docTop = size.height * 0.6;

    final Rect documentRect = Rect.fromLTWH(docLeft, docTop, docWidth, docHeight);

    // Область для лица (справа)
    final double faceRadius = docWidth * 0.7;
    final double faceLeft = docLeft + docWidth + margin + faceRadius;
    final double faceTop = docTop + (docHeight / 2);

    // Вырезаем прозрачную область для документа
    canvas.drawRRect(
      RRect.fromRectAndRadius(documentRect, const Radius.circular(8)),
      clearPaint,
    );

    // Вырезаем прозрачную область для лица
    canvas.drawCircle(
      Offset(faceLeft, faceTop),
      faceRadius,
      clearPaint,
    );

    // Рисуем белые рамки
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Рамка документа
    canvas.drawRRect(
      RRect.fromRectAndRadius(documentRect, const Radius.circular(8)),
      borderPaint,
    );

    // Рамка лица
    canvas.drawCircle(
      Offset(faceLeft, faceTop),
      faceRadius,
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
