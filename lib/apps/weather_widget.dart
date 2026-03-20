import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Wetter-Widget — nutzt wttr.in API (kein API-Key nötig)
class WeatherApp extends StatefulWidget {
  const WeatherApp({super.key});
  @override
  State<WeatherApp> createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  Map<String, dynamic>? _weather;
  bool _loading = true;
  String _location = '';

  @override
  void initState() { super.initState(); _loadWeather(); }

  Future<void> _loadWeather() async {
    setState(() => _loading = true);
    try {
      final response = await http.get(Uri.parse('https://wttr.in/?format=j1'));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = data['current_condition']?[0];
        final area = data['nearest_area']?[0];
        setState(() {
          _weather = {
            'temp': current?['temp_C'] ?? '?',
            'feels': current?['FeelsLikeC'] ?? '?',
            'humidity': current?['humidity'] ?? '?',
            'desc': current?['weatherDesc']?[0]?['value'] ?? '',
            'wind': current?['windspeedKmph'] ?? '?',
            'windDir': current?['winddir16Point'] ?? '',
            'icon': _weatherIcon(int.tryParse(current?['weatherCode'] ?? '0') ?? 0),
          };
          _location = area?['areaName']?[0]?['value'] ?? '';
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  IconData _weatherIcon(int code) {
    if (code == 113) return Icons.wb_sunny;
    if (code == 116) return Icons.cloud_queue;
    if (code <= 119) return Icons.cloud;
    if (code <= 182) return Icons.grain;
    if (code <= 302) return Icons.water_drop;
    if (code <= 395) return Icons.ac_unit;
    return Icons.cloud;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.all(16),
      child: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _weather == null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.cloud_off, color: Colors.white.withValues(alpha: 0.2), size: 40),
                  const SizedBox(height: 8),
                  Text('Wetter nicht verfuegbar', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
                  const SizedBox(height: 8),
                  GestureDetector(onTap: _loadWeather, child: const Text('Erneut versuchen', style: TextStyle(color: Colors.blueAccent, fontSize: 11))),
                ]))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ort
                    Text(_location, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
                    const SizedBox(height: 8),
                    // Temperatur + Icon
                    Row(children: [
                      Icon(_weather!['icon'] as IconData, color: Colors.white, size: 40),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${_weather!['temp']}°C', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w200)),
                        Text('Gefuehlt ${_weather!['feels']}°C', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                      ]),
                    ]),
                    const SizedBox(height: 12),
                    // Beschreibung
                    Text(_weather!['desc'] as String, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 12),
                    // Details
                    Row(children: [
                      _DetailChip(Icons.water_drop, '${_weather!['humidity']}%'),
                      const SizedBox(width: 12),
                      _DetailChip(Icons.air, '${_weather!['wind']} km/h ${_weather!['windDir']}'),
                    ]),
                    const Spacer(),
                    GestureDetector(
                      onTap: _loadWeather,
                      child: Text('Aktualisieren', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10)),
                    ),
                  ],
                ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DetailChip(this.icon, this.label);
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: Colors.white38, size: 14),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
    ]);
  }
}
