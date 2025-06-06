import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MapaRutaScreen extends StatefulWidget {
  const MapaRutaScreen({super.key});

  @override
  State<MapaRutaScreen> createState() => _MapaRutaScreenState();
}

class _MapaRutaScreenState extends State<MapaRutaScreen> {
  final MapController mapController = MapController();
  LatLng? userLocation;
  LatLng? destino;
  List<LatLng> ruta = [];

  @override
  void initState() {
    super.initState();
    verificarSesion(); // Verifica si hay sesión activa
  }

  Future<void> verificarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final estaLogueado = prefs.getBool('logueado') ?? false;

    if (!estaLogueado && mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (Route<dynamic> route) => false,
      );
    } else {
      obtenerUbicacion();
    }
  }

  Future<void> obtenerUbicacion() async {
    final servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) return;

    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.deniedForever ||
          permiso == LocationPermission.denied) {
        return;
      }
    }

    final posicion = await Geolocator.getCurrentPosition();
    setState(() {
      userLocation = LatLng(posicion.latitude, posicion.longitude);
    });
  }

  Future<void> obtenerRuta() async {
    if (userLocation == null || destino == null) return;

    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${userLocation!.longitude},${userLocation!.latitude};'
      '${destino!.longitude},${destino!.latitude}?overview=full&geometries=geojson',
    );

    final respuesta = await http.get(url);
    final data = json.decode(respuesta.body);

    if (data['routes'] != null && data['routes'].isNotEmpty) {
      final puntos = data['routes'][0]['geometry']['coordinates'] as List;
      setState(() {
        ruta = puntos.map((p) => LatLng(p[1], p[0])).toList();
      });
    }
  }

  Future<void> _cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ruta hasta tu destino'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: userLocation == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: mapController,
              options: MapOptions(
                center: userLocation,
                zoom: 15,
                onTap: (tapPosition, point) async {
                  setState(() {
                    destino = point;
                    ruta = []; // Limpia ruta mientras carga
                  });
                  await obtenerRuta();
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: userLocation!,
                      width: 60,
                      height: 60,
                      child: const Icon(Icons.my_location,
                          color: Colors.blue, size: 35),
                    ),
                    if (destino != null)
                      Marker(
                        point: destino!,
                        width: 60,
                        height: 60,
                        child: const Icon(Icons.place,
                            color: Colors.red, size: 35),
                      ),
                  ],
                ),
                if (ruta.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: ruta,
                        strokeWidth: 5,
                        color: Colors.green,
                      )
                    ],
                  ),
              ],
            ),
    );
  }
}
