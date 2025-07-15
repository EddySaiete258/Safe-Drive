import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:safedrive/model/Road_block.dart';

class BloqueioDetalheCard extends StatelessWidget {
  final RoadBlock roadBlock;

  const BloqueioDetalheCard({super.key, required this.roadBlock});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título com imagem do tipo
            Row(
              children: [
                Image.asset(
                  _getTipoImage(roadBlock.type ?? ''),
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Bloqueio na ${roadBlock.location}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              roadBlock.type ?? '',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.blueGrey),
                const SizedBox(width: 4),
                Text("Previsão: ${roadBlock.duration ?? ''}"),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              roadBlock.description ?? '',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),

            // Galeria de imagens
            if (roadBlock.images != null && roadBlock.images!.isNotEmpty)
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: roadBlock.images!.length,
                  itemBuilder:
                      (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: roadBlock.images![i],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                ),
              ),

            const SizedBox(height: 12),
            Text(
              "Postado há 12 min por @Carlos_M",
              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
            const SizedBox(height: 12),

            // Reações
            Row(
              children: [
                const Icon(Icons.thumb_up_alt_outlined, color: Colors.blue),
                const SizedBox(width: 4),
                const Text("14"),
                const SizedBox(width: 16),
                const Icon(Icons.thumb_down_alt_outlined, color: Colors.orange),
                const SizedBox(width: 4),
                const Text("0"),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    // Lógica de denúncia
                  },
                  child: Row(
                    children: const [
                      Icon(Icons.campaign_outlined, color: Colors.black),
                      SizedBox(width: 4),
                      Text("Denunciar", style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTipoImage(String tipo) {
    switch (tipo) {
      case 'Acidente':
        return 'assets/images/blocks/acidente.png';
      case 'Obra':
        return 'assets/images/blocks/obras.png';
      case 'Manifestação':
        return 'assets/images/blocks/manifestacao.png';
      case 'Inundação':
        return 'assets/images/blocks/condicoesclimaticas.png';
      case 'Outro':
        return 'assets/images/blocks/outros.png';
      default:
        return 'assets/images/roadblock.png';
    }
  }
}
