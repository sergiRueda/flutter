import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

void main() async {
  final archivo = File('integration_result.txt');
  if (!await archivo.exists()) {
    print('❌ No se encontró el archivo integration_result.txt');
    return;
  }

  final bytes = await archivo.readAsBytes();
  final content = const Utf16Decoder(Endian.little).convert(bytes);
  final lines = LineSplitter.split(content).toList();

  final testLines =
      lines.where((line) => line.trim().startsWith('00:')).toList();

  bool hayFallos = lines.any((line) =>
      line.contains('FAILED') ||
      line.contains('Exception') ||
      line.contains('Error') ||
      line.contains('TestFailure'));

  final now = DateTime.now();
  final buffer = StringBuffer();

  buffer.writeln('<!DOCTYPE html>');
  buffer.writeln('<html lang="es">');
  buffer
      .writeln('<head><meta charset="UTF-8"><title>Reporte de Pruebas</title>');
  buffer.writeln('<style>');
  buffer.writeln(
      'body { font-family: Arial; margin: 2em; background: #f9f9f9; }');
  buffer.writeln(
      '.ok { color: green; } .fail { color: red; } .warn { color: orange; }');
  buffer.writeln('li.passed { color: green; }');
  buffer.writeln('li.failed { color: red; }');
  buffer.writeln('</style></head><body>');

  buffer.writeln('<h2>🧪 Resultados de Pruebas</h2>');

  if (testLines.isEmpty) {
    buffer.writeln('<p class="warn">⚠️ No se encontraron pruebas.</p>');
  } else if (hayFallos) {
    buffer.writeln('<p class="fail">❌ Algunas pruebas fallaron.</p>');
  } else {
    buffer.writeln(
        '<p class="ok">✅ Todas las pruebas pasaron correctamente.</p>');
  }

  buffer.writeln('<ul>');
  for (var line in testLines) {
    final escapedLine = htmlEscape.convert(line);
    if (line.contains('FAILED') ||
        line.contains('Exception') ||
        line.contains('Error') ||
        line.contains('TestFailure')) {
      buffer.writeln('<li class="failed">$escapedLine</li>');
    } else if (line.contains('+')) {
      buffer.writeln('<li class="passed">$escapedLine</li>');
    } else {
      buffer.writeln('<li>$escapedLine</li>');
    }
  }
  buffer.writeln('</ul>');

  buffer.writeln('<p><em>Generado el ${now.toString()}</em></p>');
  buffer.writeln('</body></html>');

  final reporte = File('reporte_integracion.html');
  await reporte.writeAsString(buffer.toString(), encoding: utf8);

  print('✅ Reporte generado: reporte_integracion.html');
}

class Utf16Decoder extends Converter<List<int>, String> {
  final Endian endian;
  const Utf16Decoder(this.endian);

  @override
  String convert(List<int> input) {
    final byteData = ByteData.sublistView(Uint8List.fromList(input));
    final codeUnits = List<int>.generate(
      byteData.lengthInBytes ~/ 2,
      (i) => byteData.getUint16(i * 2, endian),
    );
    return String.fromCharCodes(codeUnits);
  }
}
