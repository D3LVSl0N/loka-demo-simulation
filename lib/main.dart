import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const LOKADemoApp());
}

class LOKADemoApp extends StatelessWidget {
  const LOKADemoApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LOKA Simulation',
      debugShowCheckedModeBanner: false,
      home: const MapScreen(),
    );
  }
}

class Cattle {
  final String id;
  String name;
  double lat;
  double lng;
  bool isInside;
  bool alertShown;

  Cattle({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    this.isInside = true,
    this.alertShown = false,
  });
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng farmCenter = LatLng(36.5700, 2.4500);
  static const double fenceRadius = 200;
  final Distance distance = const Distance();
  final Random random = Random();
  final MapController mapController = MapController();
  Timer? _timer;
  bool isPaused = false;
  double currentZoom = 15;
  int _cowCounter = 1;

  final List<String> alerts = [];
  final List<Cattle> cattles = [];

  @override
  void initState() {
    super.initState();
    for (int i = 1; i <= 15; i++) {
      _addCow('Vache $i');
    }
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (isPaused) return;
      setState(() {
        for (var cow in cattles) {
          cow.lat += (random.nextDouble() - 0.5) * 0.0003;
          cow.lng += (random.nextDouble() - 0.5) * 0.0003;
          final dist = distance(LatLng(cow.lat, cow.lng), farmCenter);
          final wasInside = cow.isInside;
          cow.isInside = dist <= fenceRadius;
          if (wasInside && !cow.isInside && !cow.alertShown) {
            cow.alertShown = true;
            alerts.insert(0, '🚨 ${cow.name} a quitté la zone!');
            _showAlert(cow.name);
          }
          if (cow.isInside) {
            cow.alertShown = false;
          }
        }
      });
    });
  }

  void _addCow(String name) {
    final r = Random();
    final double offsetLat = (r.nextDouble() - 0.5) * 0.002;
    final double offsetLng = (r.nextDouble() - 0.5) * 0.002;
    cattles.add(Cattle(
      id: 'COW$_cowCounter',
      name: name,
      lat: 36.5700 + offsetLat,
      lng: 2.4500 + offsetLng,
    ));
    _cowCounter++;
  }

  void _showAddCowDialog() {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Text('🐄 ', style: TextStyle(fontSize: 24)),
            Text('Ajouter un bovin',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nom du bovin',
            hintText: 'ex: Bella, Sultan, Nour...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.edit),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  _addCow(name);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Ajouter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showManagePanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            minChildSize: 0.4,
            builder: (_, scrollController) => Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '🐄 Gérer le troupeau (${cattles.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                        ),
                        icon: const Icon(Icons.add, color: Colors.white, size: 18),
                        label: const Text('Ajouter',
                            style: TextStyle(color: Colors.white)),
                        onPressed: () {
                          Navigator.pop(context);
                          _showAddCowDialog();
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: cattles.length,
                    itemBuilder: (_, i) {
                      final cow = cattles[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: cow.isInside
                              ? Colors.green[100]
                              : Colors.red[100],
                          child: const Text('🐄',
                              style: TextStyle(fontSize: 18)),
                        ),
                        title: Text(cow.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          cow.isInside ? '✅ Dans la zone' : '🚨 Hors zone',
                          style: TextStyle(
                            color: cow.isInside ? Colors.green : Colors.red,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Supprimer',
                          onPressed: () {
                            setState(() {
                              cattles.removeAt(i);
                            });
                            setModalState(() {});
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAlert(String cowName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.red[50],
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('ALERTE LOKA', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Text(
          '$cowName a quitté la zone de pâturage!\nElle est peut-être perdue ou volée.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCowInfo(Cattle cow) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            const Text('🐄 ', style: TextStyle(fontSize: 24)),
            Text(cow.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${cow.id}'),
            const SizedBox(height: 6),
            Text('Latitude: ${cow.lat.toStringAsFixed(5)}'),
            Text('Longitude: ${cow.lng.toStringAsFixed(5)}'),
            const SizedBox(height: 6),
            Row(
              children: [
                const Text('Statut: '),
                Text(
                  cow.isInside ? '✅ Dans la zone' : '🚨 Hors zone',
                  style: TextStyle(
                    color: cow.isInside ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _zoomIn() {
    currentZoom = (currentZoom + 1).clamp(1, 18);
    mapController.move(farmCenter, currentZoom);
  }

  void _zoomOut() {
    currentZoom = (currentZoom - 1).clamp(1, 18);
    mapController.move(farmCenter, currentZoom);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get insideCount => cattles.where((c) => c.isInside).length;
  int get outsideCount => cattles.where((c) => !c.isInside).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LOKA - Simulation Troupeau'),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'Gérer le troupeau',
            onPressed: _showManagePanel,
          ),
          IconButton(
            icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
            tooltip: isPaused ? 'Reprendre' : 'Pause',
            onPressed: () {
              setState(() {
                isPaused = !isPaused;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: const MapOptions(
              initialCenter: farmCenter,
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName:
                    'com.example.loka_demo_simulation',
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: farmCenter,
                    radius: fenceRadius,
                    color: Colors.green.withOpacity(0.2),
                    borderColor: Colors.green,
                    borderStrokeWidth: 2,
                    useRadiusInMeter: true,
                  ),
                ],
              ),
              MarkerLayer(
                markers: cattles.map((cow) {
                  return Marker(
                    point: LatLng(cow.lat, cow.lng),
                    width: 50,
                    height: 50,
                    child: GestureDetector(
                      onTap: () => _showCowInfo(cow),
                      child: Column(
                        children: [
                          Text(
                            '🐄',
                            style: TextStyle(
                                fontSize: cow.isInside ? 24 : 22),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 3, vertical: 1),
                            decoration: BoxDecoration(
                              color: cow.isInside
                                  ? Colors.green[700]
                                  : Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              cow.name.length > 8
                                  ? '${cow.name.substring(0, 6)}..'
                                  : cow.name,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Counter box top right
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(blurRadius: 4, color: Colors.black26)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🐄 Total: ${cattles.length}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('✅ Dans la zone: $insideCount',
                      style: const TextStyle(
                          color: Colors.green, fontSize: 14)),
                  Text('🚨 Hors zone: $outsideCount',
                      style: const TextStyle(
                          color: Colors.red, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(
                    isPaused ? '⏸ Simulation pausée' : '▶ Simulation active',
                    style: TextStyle(
                      fontSize: 11,
                      color: isPaused ? Colors.orange : Colors.green,
                    ),
                  ),
                ],
                              ),
            ),
          ),

          // Zoom buttons left side
          Positioned(
            bottom: alerts.isEmpty ? 20 : 140,
            left: 12,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoomIn',
                  backgroundColor: Colors.white,
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add, color: Colors.black),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoomOut',
                  backgroundColor: Colors.white,
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove, color: Colors.black),
                ),
              ],
            ),
          ),

          // Alert log bottom panel
          if (alerts.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.red[900],
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                height: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Alertes récentes:',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: ListView.builder(
                        itemCount: alerts.length,
                        itemBuilder: (_, i) => Text(
                          alerts[i],
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}