import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'alert_detail_view_model.dart';
import '../../data/services/firestore_service.dart';

class AlertDetailScreen extends StatelessWidget {
  const AlertDetailScreen({super.key, required this.alertId});

  final String alertId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AlertDetailViewModel(
        context.read<FirestoreService>(),
        alertId,
      ),
      child: Consumer<AlertDetailViewModel>(
        builder: (context, model, child) {
          if (model.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (model.alertData == null) {
            return const Scaffold(
              body: Center(child: Text('Alert not found')),
            );
          }

          final alert = model.alertData!;
          final lat = alert['latitude'] as double? ?? 0.0;
          final lng = alert['longitude'] as double? ?? 0.0;
          final audioUrl = alert['audioUrl'] as String?;

          return Scaffold(
            appBar: AppBar(
              title: Text('SOS: ${alert['senderName']}'),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            body: Column(
              children: [
                Expanded(
                  flex: 2,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(lat, lng),
                      zoom: 15,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('sender'),
                        position: LatLng(lat, lng),
                        infoWindow: InfoWindow(title: alert['senderName']),
                      ),
                    },
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'EMERGENCY STATUS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.amber),
                            const SizedBox(width: 10),
                            Text(
                              alert['status'] == 'active' ? 'SOS Active' : 'Status: ${alert['status']}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (audioUrl == null)
                          const Center(
                            child: Column(
                              children: [
                                CircularProgressIndicator(color: Colors.red),
                                SizedBox(height: 10),
                                Text('Waiting for Audio Proof...'),
                              ],
                            ),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: () => model.playAudio(audioUrl),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('LISTEN TO AUDIO PROOF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
