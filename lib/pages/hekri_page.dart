import 'package:flutter/material.dart';
import '../theme/app_background.dart';

class HekriPage extends StatelessWidget {
  const HekriPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hekri')),
      body: const AppBackground(
        child: Center(
          child: Text('Përmbajtja e hekurt këtu'),
        ),
      ),
    );
  }
}
