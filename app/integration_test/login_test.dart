import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Login como enfermero redirige correctamente a ReporteAccidenteScreen',
      (tester) async {
    // Inicializa valores mock de SharedPreferences
    SharedPreferences.setMockInitialValues({'logueado': false});

    // Ejecuta la app
    app.main();
    await tester.pumpAndSettle();

    // Completa el formulario de login
    await tester.enterText(find.byKey(const Key('nombre')), 'julian');
    await tester.enterText(
        find.byKey(const Key('contrasena')), '123'); // contraseña incorrecta

    // Toca el botón login
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pump();

    // Espera hasta que aparezca la pantalla de ReporteAccidenteScreen (o falle si no aparece)
    await tester
        .pumpUntilFound(find.byKey(const Key('reporteAccidenteScreen')));

    // Verifica que el widget esté presente
    expect(find.byKey(const Key('reporteAccidenteScreen')), findsOneWidget);
  });
}

// Extensión corregida: lanza error si no encuentra el widget
extension PumpUntil on WidgetTester {
  Future<void> pumpUntilFound(Finder finder,
      {Duration timeout = const Duration(seconds: 5)}) async {
    final endTime = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(endTime)) {
      await pump(const Duration(milliseconds: 100));
      if (any(finder)) return;
    }
    throw TestFailure('No se encontró el widget: ${finder.description}');
  }
}
