import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../data/services/firestore_service.dart';
import 'alert_detail_view_model.dart';

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
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          if (model.alertData == null) {
            return Scaffold(
              appBar: AppBar(),
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(height: 12),
                    Text('Alert not found',
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
            );
          }

          final alert = model.alertData!;
          final lat = alert['latitude'] as double? ?? 0.0;
          final lng = alert['longitude'] as double? ?? 0.0;
          final audioUrl = alert['audioUrl'] as String?;
          final senderName = alert['senderName'] as String? ?? 'Unknown';
          final status = alert['status'] as String? ?? 'unknown';
          final timestamp = alert['timestamp'] as Timestamp?;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Alert Details'),
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // -- Status Banner --
                    _StatusBanner(status: status),
                    const SizedBox(height: 20),

                    // -- Sender Info --
                    _SenderInfoCard(
                      senderName: senderName,
                      timestamp: timestamp,
                    ),
                    const SizedBox(height: 16),

                    // -- Map --
                    Text(
                      'Location',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        height: 280,
                        width: double.infinity,
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(lat, lng),
                            zoom: 15,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('sender'),
                              position: LatLng(lat, lng),
                              infoWindow: InfoWindow(title: senderName),
                            ),
                          },
                          zoomControlsEnabled: false,
                          myLocationButtonEnabled: false,
                          liteModeEnabled: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // -- Audio Proof --
                    Text(
                      'Audio Proof',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 10),
                    _AudioProofCard(
                      audioUrl: audioUrl,
                      model: model,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status Banner
// ---------------------------------------------------------------------------
class _StatusBanner extends StatelessWidget {
  final String status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'active';
    final color = isActive ? AppColors.danger : AppColors.success;
    final label = isActive ? 'SOS Active' : 'Resolved';
    final icon = isActive ? Icons.warning_amber_rounded : Icons.check_circle;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2)
                    ]
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sender Info Card
// ---------------------------------------------------------------------------
class _SenderInfoCard extends StatelessWidget {
  final String senderName;
  final Timestamp? timestamp;

  const _SenderInfoCard({required this.senderName, this.timestamp});

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return 'Just now';
    final dt = ts.toDate().toLocal();
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day.$month.$year at $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final initials =
        senderName.isNotEmpty ? senderName[0].toUpperCase() : '?';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.danger.withValues(alpha: 0.12),
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    senderName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimestamp(timestamp),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.emergency, color: AppColors.danger),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Audio Proof Card
// ---------------------------------------------------------------------------
class _AudioProofCard extends StatelessWidget {
  final String? audioUrl;
  final AlertDetailViewModel model;

  const _AudioProofCard({required this.audioUrl, required this.model});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Waiting state
    if (audioUrl == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: Column(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.danger.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Recording in progress...',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Audio proof will appear here once the recording is uploaded.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    // Audio player state
    final progressValue = model.duration.inMilliseconds > 0
        ? model.position.inMilliseconds / model.duration.inMilliseconds
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 16),
        child: Column(
          children: [
            Row(
              children: [
                // Play/Pause button
                _buildPlayButton(context),
                const SizedBox(width: 12),
                // Progress slider + time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 4,
                          thumbShape:
                              const RoundSliderThumbShape(enabledThumbRadius: 7),
                          overlayShape:
                              const RoundSliderOverlayShape(overlayRadius: 14),
                          activeTrackColor: AppColors.danger,
                          inactiveTrackColor:
                              colorScheme.onSurfaceVariant.withValues(alpha: 0.15),
                          thumbColor: AppColors.danger,
                          overlayColor: AppColors.danger.withValues(alpha: 0.12),
                        ),
                        child: Slider(
                          value: progressValue.clamp(0.0, 1.0),
                          onChanged: model.isAudioLoaded
                              ? (value) {
                                  final target = Duration(
                                    milliseconds:
                                        (value * model.duration.inMilliseconds)
                                            .round(),
                                  );
                                  model.seekTo(target);
                                }
                              : null,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              model.formatDuration(model.position),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontFeatures: [
                                      const FontFeature.tabularFigures()
                                    ],
                                  ),
                            ),
                            Text(
                              model.formatDuration(model.duration),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontFeatures: [
                                      const FontFeature.tabularFigures()
                                    ],
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!model.isAudioLoaded && !model.isAudioLoading)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Tap play to load audio proof',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayButton(BuildContext context) {
    if (model.isAudioLoading) {
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.danger.withValues(alpha: 0.1),
        ),
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.danger,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => model.loadAndPlayAudio(audioUrl!),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.danger,
          boxShadow: [
            BoxShadow(
              color: AppColors.danger.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          model.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
