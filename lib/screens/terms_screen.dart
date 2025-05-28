import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Column(
        children: [
          // Topo com cor verde e logo
          SizedBox(
            height: height * 0.41,
            child: Stack(
              children: [
                Container(color: const Color(0xFF4CE5B1)),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Image.asset(
                    'assets/images/skytowers.png',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: height * 0.05),
                    child: Image.asset(
                      'assets/images/Safedrive.png',
                      height: 50,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Conteúdo dos Termos
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Termos e Condições',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Bem-vindo ao SAFEDRIVE. Ao utilizar este aplicativo, você concorda com os seguintes termos:\n\n'
                    '1. Uso responsável: Você concorda em utilizar o aplicativo de forma segura e ética.\n\n'
                    '2. Compartilhamento de dados: O app pode coletar informações para melhorar sua experiência e garantir segurança nas estradas.\n\n'
                    '3. Privacidade: Suas informações são tratadas com confidencialidade conforme nossa política de privacidade.\n\n'
                    '4. Alterações nos termos: Podemos modificar estes termos a qualquer momento. Notificaremos mudanças importantes.\n\n'
                    '5. Consentimento: Ao continuar usando o app, você confirma que leu e aceita os termos.\n\n'
                    'Obrigado por fazer parte da comunidade SAFEDRIVE!',
                    style: TextStyle(fontSize: 16, height: 1.5),
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
