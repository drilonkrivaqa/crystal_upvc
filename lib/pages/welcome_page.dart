import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_background.dart';

class WelcomePage extends StatefulWidget {
  final List<String> failedBoxes;
  const WelcomePage({super.key, this.failedBoxes = const []});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  void initState() {
    super.initState();
    if (widget.failedBoxes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final names = widget.failedBoxes.join(', ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Disa të dhëna nuk u ngarkuan: $names')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/logo.png', width: 220)
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.2),
                  const SizedBox(height: 24),
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
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/home'),
                    child: const Text('Hyr'),
                  ).animate().fadeIn(duration: 220.ms, delay: 100.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
