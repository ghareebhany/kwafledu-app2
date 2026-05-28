import 'package:flutter/material.dart';

/// شعار "القوافل التعليمية" — يُستخدم في SplashScreen وLoginScreen وأي مكان آخر.
class AppLogo extends StatelessWidget {
  /// [size] = عرض الصورة بالـ dp (الارتفاع يُحسب تلقائياً بنسبة 663/600)
  final double size;
  final BoxFit fit;

  const AppLogo({super.key, this.size = 120, this.fit = BoxFit.contain});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size * (663 / 600), // النسبة الأصلية للصورة
      fit: fit,
      semanticLabel: 'شعار القوافل التعليمية',
    );
  }
}

/// نسخة مصغرة مناسبة للـ AppBar
class AppLogoSmall extends StatelessWidget {
  const AppLogoSmall({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      height: 36,
      fit: BoxFit.contain,
      semanticLabel: 'شعار القوافل التعليمية',
    );
  }
}
