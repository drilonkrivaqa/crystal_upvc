import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.tealAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/logo.png', width: 400),
                        const SizedBox(height: 0),
                        const SizedBox(height: 12),
                        const Text(
                          'Rr. Ilir Konushevci, Nr. 80, Kamenicë, Kosovë, 62000',
                          textAlign: TextAlign.center,
                        ),
                        const Text(
                          '+38344357639 | +38344268300',
                          textAlign: TextAlign.center,
                        ),
                        const Text(
                          'www.tonialpvc.com | tonialpvc@gmail.com',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                    child: const Text('Hyr'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}