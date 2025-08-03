import 'package:flutter/material.dart';
import '../theme/app_background.dart';

class XhamiPage extends StatelessWidget {
  const XhamiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xhami')),
      body: const AppBackground(
        child: Center(
          child: Text('Përmbajtja e xhamit këtu'),
        ),
      ),
    );
  }
}
