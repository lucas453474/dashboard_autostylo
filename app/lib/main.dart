import 'package:flutter/material.dart';

import 'atendimento.dart';
import 'cores.dart';
import 'tela_dashboard.dart';

void main() {
  runApp(const AppAutoStylo());
}

// O aplicativo: tema escuro igual ao BI
class AppAutoStylo extends StatelessWidget {
  const AppAutoStylo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dashboard Auto Stylo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: corFundo),
      home: Scaffold(body: TelaDashboard(atendimentosDeExemplo())),
    );
  }
}
