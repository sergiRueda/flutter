import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              'Inicio',
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
        child: Column(
          children: [
            _buildBlueSection(
              context,
              title: 'AMBUSOS La mejor elección para tus emergencias',
              subtitle:
                  'AMBUSOS se encarga de llegar al lugar ideal en el momento indicado',
              description:
                  'En AMBUSOS, nos comprometemos a responder a tus emergencias con la mayor prontitud posible. Confía en nosotros para brindarte soluciones eficientes en cualquier situación. AMBUSOS, tu aliado de confianza en momentos críticos.',
              imagePath: 'assets/images/ambu.png',
              animate: true,
            ),
            _buildWhiteSection(
              context,
              title:
                  'EN AMBUSOS trabajamos para la mejor entidad médica del país',
              subtitle: 'AMBUSOS sabe lo que es mejor para ti',
              description:
                  'En AMBUSOS, nuestro compromiso es garantizarte un traslado rápido y seguro al mejor centro médico disponible en tu área. Confía en nuestra experiencia y dedicación para brindarte la atención médica que necesitas en situaciones de emergencia.',
              imagePath: 'assets/images/go.png',
              buttonText: '¿Para quién trabajamos?\nAmbusos!',
              route: '/eps',
              animate: true,
            ),
            _buildBlueSection(
              context,
              title: '¿¡Tienes una emergencia!?',
              subtitle: 'No des más vueltas, ',
              description:
                  'En Ambusos, no dudes en presionar este botón para recibir las rutas para llegar a la emergencia y dar la atención que se necesita de manera rápida y efectiva.',
              imagePath: 'assets/images/alarma.png',
              buttonText: 'Ambusos al rescate\nAmbusos!',
              route: '/conductor',
              animate: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlueSection(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String description,
    required String imagePath,
    String? buttonText,
    String? route,
    bool animate = false,
  }) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF007bff), Color(0xFF00d2ff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Column(
        children: [
          _buildText(title, 28, Colors.white, FontWeight.w600),
          const SizedBox(height: 15),
          _buildText(subtitle, 18, Colors.white),
          const SizedBox(height: 25),
          _buildText(description, 16, Colors.white),
          if (buttonText != null && route != null) ...[
            const SizedBox(height: 25),
            _buildButton(context, buttonText, route),
          ],
          const SizedBox(height: 30),
          animate
              ? _AnimatedFloatingImage(imagePath: imagePath)
              : Image.asset(
                  imagePath,
                  width: 120,
                  fit: BoxFit.contain,
                ),
        ],
      ),
    );
  }

  Widget _buildWhiteSection(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String description,
    required String imagePath,
    required String buttonText,
    required String route,
    bool animate = false,
  }) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Column(
        children: [
          _buildText(title, 26, Colors.black87, FontWeight.w600),
          const SizedBox(height: 15),
          _buildText(subtitle, 18, Colors.black87),
          const SizedBox(height: 25),
          _buildText(description, 16, Colors.black87),
          const SizedBox(height: 25),
          _buildButton(context, buttonText, route),
          const SizedBox(height: 30),
          animate
              ? _AnimatedFloatingImage(imagePath: imagePath)
              : Image.asset(
                  imagePath,
                  width: 120,
                  fit: BoxFit.contain,
                ),
        ],
      ),
    );
  }

  Widget _buildText(String text, double size, Color color,
      [FontWeight weight = FontWeight.normal]) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: size,
        color: color,
        fontWeight: weight,
        decoration: TextDecoration.none,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildButton(BuildContext context, String text, String route) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0056b3),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        shadowColor: Colors.black.withOpacity(0.2),
        elevation: 10,
      ),
      onPressed: () {
        Navigator.pushNamed(context, route);
      },
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 16,
          decoration: TextDecoration.none,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _AnimatedFloatingImage extends StatefulWidget {
  final String imagePath;

  const _AnimatedFloatingImage({required this.imagePath});

  @override
  State<_AnimatedFloatingImage> createState() => _AnimatedFloatingImageState();
}

class _AnimatedFloatingImageState extends State<_AnimatedFloatingImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  late final Animation<double> _animation = Tween<double>(begin: -8, end: 8)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _animation.value),
        child: child,
      ),
      child: Image.asset(
        widget.imagePath,
        width: 120,
        fit: BoxFit.contain,
      ),
    );
  }
}
