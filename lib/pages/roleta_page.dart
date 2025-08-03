import 'package:flutter/material.dart';
import '../theme/app_background.dart';

class RoletaPage extends StatelessWidget {
  const RoletaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Roleta')),
      body: const AppBackground(
        child: Center(
          child: Text('Përmbajtja e roletës këtu'),
        ),
      ),
    );
  }
}
