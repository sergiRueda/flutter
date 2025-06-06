import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class EpsAliadasScreen extends StatelessWidget {
  const EpsAliadasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo_2.png',
              width: 170,
              height: 170,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            const Text(
              'EPS Aliadas',
              style: TextStyle(fontSize: 22, color: Colors.white),
            ),
            const Spacer(),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.house),
              tooltip: 'Inicio',
              color: Colors.white,
              onPressed: () {
                Navigator.pushNamed(context, '/home');
              },
            ),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.rightToBracket),
              tooltip: 'Iniciar sesión',
              color: Colors.white,
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
            ),
          ],
        ),
        toolbarHeight: 90,
      ),
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              FadeInUp(
                duration: const Duration(milliseconds: 800),
                child: const _EpsCard(
                  title: 'Compensar EPS',
                  subtitle: 'Aliado clave en salud',
                  description:
                      'Compensar es una EPS de confianza que brinda servicios de salud integrales con alta calidad para el bienestar de los afiliados.',
                  imagePath: 'assets/images/Compensar.png',
                  bgColor: Color(0xFFE3F2FD),
                  textColor: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              FadeInUp(
                duration: const Duration(milliseconds: 1000),
                child: const _EpsCard(
                  title: 'Sura EPS',
                  subtitle: 'Cobertura nacional destacada',
                  description:
                      'SURA se reconoce por su excelencia médica y su cobertura en todo el país como una EPS comprometida con la salud.',
                  imagePath: 'assets/images/sura.png',
                  bgColor: Color(0xFFBBDEFB),
                  textColor: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              FadeInUp(
                duration: const Duration(milliseconds: 1200),
                child: const _EpsCard(
                  title: 'Cafam EPS',
                  subtitle: 'Atención y cercanía',
                  description:
                      'Cafam destaca por su cercanía con los usuarios, con servicios de salud confiables y una atención centrada en el paciente.',
                  imagePath: 'assets/images/Cafam.png',
                  bgColor: Color(0xFFB3E5FC),
                  textColor: Colors.black,
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _EpsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final String imagePath;
  final Color bgColor;
  final Color textColor;

  const _EpsCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imagePath,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          Image.asset(
            imagePath,
            height: 60,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: textColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
