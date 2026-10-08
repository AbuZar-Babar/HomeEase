import 'package:flutter/material.dart';

import '../theme/home_ease_theme.dart';
import 'home_ease_flow.dart';

class HomeEaseApp extends StatelessWidget {
  const HomeEaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HomeEase',
      debugShowCheckedModeBanner: false,
      theme: HomeEaseTheme.theme,
      darkTheme: HomeEaseTheme.darkTheme,
      themeMode: ThemeMode.light,
      builder: (context, child) {
        return MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.35,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const HomeEaseFlow(),
    );
  }
}
