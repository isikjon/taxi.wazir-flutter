import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class LogoWidget extends StatelessWidget {
  final double size;
  final bool showText;

  const LogoWidget({
    super.key,
    this.size = 100,
    this.showText = true,
  });

  // Создаем HttpClient с отключенной проверкой SSL
  static HttpClient? _httpClient;
  
  static HttpClient get httpClient {
    _httpClient ??= HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return _httpClient!;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size / 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size / 2),
            child: FutureBuilder<Widget>(
              future: _buildNetworkImage(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return snapshot.data!;
                }
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(size / 2),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // Текст "Wazir" удален по запросу
      ],
    );
  }

  Future<Widget> _buildNetworkImage() async {
    try {
      // Сначала пробуем загрузить локальный asset
      try {
        print('Trying to load local asset logo');
        
        // Проверяем что asset действительно существует
        await rootBundle.load('assets/images/logo.png');
        print('Successfully found local asset logo');
        
        final image = Image.asset(
          'assets/images/logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        );
        
        return image;
      } catch (e) {
        print('Failed to load local asset: $e, trying network URLs');
        return await _buildFromNetworkUrls();
      }
    } catch (e) {
      print('General error loading logo: $e');
      return _buildFallbackLogo();
    }
  }

  Future<Widget> _buildFromNetworkUrls() async {
    // Пробуем разные URL логотипа
    final List<String> logoUrls = [
      'https://wazir.kg/static/logo.png',
      'http://wazir.kg/static/logo.png', // Fallback на HTTP
      'https://via.placeholder.com/200x200/4CAF50/FFFFFF?text=W', // Placeholder
    ];

    for (String url in logoUrls) {
      try {
        print('Trying to load logo from: $url');
        
        final image = Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36',
            'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
            'Accept-Language': 'ru,en;q=0.9',
            'Cache-Control': 'no-cache',
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              print('Successfully loaded logo from: $url');
              return child;
            }
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(size / 2),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('Failed to load from $url: $error');
            return _buildFallbackLogo();
          },
        );

        return image;
      } catch (e) {
        print('Exception loading from $url: $e');
        continue;
      }
    }
    
    return _buildFallbackLogo();
  }

  Widget _buildFallbackLogo() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Text(
          'W',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
