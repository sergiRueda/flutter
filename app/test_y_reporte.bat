@echo off
echo Ejecutando pruebas de integración en Chrome...

flutter drive --driver=test_driver/integration_test.dart --target=integration_test/login_test.dart -d chrome > integration_result.txt

echo Generando reporte HTML...
dart tools\generar_reporte.dart

echo Abriendo reporte...
start reporte_integracion.html
