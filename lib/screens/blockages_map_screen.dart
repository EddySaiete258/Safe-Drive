import 'package:flutter/material.dart';

class BlockagesMapScreen extends StatelessWidget {
  const BlockagesMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Aqui entrará o mapa (por exemplo, Mapbox ou Google Maps)
          const Placeholder(), // substitua com o widget de mapa real futuramente

          // Overlay de UI (botões, painel, etc) pode ir aqui
        ],
      ),
    );
  }
}
