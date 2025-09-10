import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../styles/app_colors.dart';

class LogoWidget extends StatelessWidget {
  final double size;
  final bool showText;

  const LogoWidget({
    super.key,
    this.size = 150,
    this.showText = true,
  });

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
            child: CachedNetworkImage(
              imageUrl: 'https://wazir.kg/static/logo.png',
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(size / 2),
                ),
                child: Center(
                  child: Text(
                    'h.',
                    style: TextStyle(
                      color: AppColors.surface,
                      fontSize: size * 0.4,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(size / 2),
                ),
                child: Center(
                  child: Text(
                    'h.',
                    style: TextStyle(
                      color: AppColors.surface,
                      fontSize: size * 0.4,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Текст "Wazir" удален по запросу
      ],
    );
  }
}
