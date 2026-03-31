import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import 'map_view_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng? _lastAnimatedTarget;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _mapSectionKey = GlobalKey();

  Future<void> _moveCamera(LatLng target) async {
    if (_mapController == null) return;

    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: target, zoom: 16)),
    );
  }

  void _tryMoveToUser(MapViewModel viewModel) {
    if (_mapController == null) return;
    if (!viewModel.isLocationPermissionGranted) return;
    if (!viewModel.isLocationServiceEnabled) return;

    final target = LatLng(viewModel.latitude, viewModel.longitude);

    if (_lastAnimatedTarget != null &&
        _lastAnimatedTarget!.latitude == target.latitude &&
        _lastAnimatedTarget!.longitude == target.longitude) {
      return;
    }

    _lastAnimatedTarget = target;
    _moveCamera(target);
  }

  Future<void> _scrollToMap() async {
    final mapContext = _mapSectionKey.currentContext;
    if (mapContext == null) return;

    await Scrollable.ensureVisible(
      mapContext,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.1,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MapViewModel>();
    final colorScheme = Theme.of(context).colorScheme;
    final currentLatLng = LatLng(viewModel.latitude, viewModel.longitude);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _tryMoveToUser(viewModel);
    });

    return Scaffold(
      appBar: AppBar(title: const Text('My Location')),
      body: SafeArea(
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Location Overview',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'View your current location and location access status.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),

            if (viewModel.errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colorScheme.outline),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.danger),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        viewModel.errorMessage!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (!viewModel.isLocationServiceEnabled)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colorScheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_off_outlined,
                          color: AppColors.danger,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Location services are disabled',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Enable location services on your device to fetch your real position.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),

            if (viewModel.isLocationServiceEnabled &&
                !viewModel.isLocationPermissionGranted)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colorScheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.gps_off_rounded,
                          color: AppColors.danger,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Location permission is not granted',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Grant permission so SOSecure can detect and share your position during emergencies.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final vm = context.read<MapViewModel>();
                          await vm.requestLocationAccess();
                          if (!mounted) return;
                          _tryMoveToUser(vm);
                          await _scrollToMap();
                        },
                        child: const Text('Grant Permission'),
                      ),
                    ),
                  ],
                ),
              ),

            if (!viewModel.isLocationPermissionGranted ||
                !viewModel.isLocationServiceEnabled)
              const SizedBox(height: 20),

            Container(
              key: _mapSectionKey,
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colorScheme.outline),
              ),
              clipBehavior: Clip.antiAlias,
              child: GoogleMap(
                onMapCreated: (controller) {
                  _mapController = controller;
                  _tryMoveToUser(viewModel);
                },
                initialCameraPosition: CameraPosition(
                  target: currentLatLng,
                  zoom: 15,
                ),
                myLocationEnabled: viewModel.isLocationPermissionGranted,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                scrollGesturesEnabled: true,
                zoomGesturesEnabled: true,
                rotateGesturesEnabled: true,
                tiltGesturesEnabled: true,
                compassEnabled: true,
                gestureRecognizers: {
                  Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
                markers: {
                  Marker(
                    markerId: const MarkerId('current_location'),
                    position: currentLatLng,
                  ),
                },
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    icon: Icons.gps_fixed,
                    title: 'Permission',
                    value: viewModel.isLocationPermissionGranted
                        ? 'Granted'
                        : 'Not granted',
                    valueColor: viewModel.isLocationPermissionGranted
                        ? AppColors.success
                        : AppColors.danger,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoCard(
                    icon: Icons.settings_input_antenna,
                    title: 'Service',
                    value: viewModel.isLocationServiceEnabled
                        ? 'Enabled'
                        : 'Disabled',
                    valueColor: viewModel.isLocationServiceEnabled
                        ? AppColors.success
                        : AppColors.danger,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Coordinates',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 14),
                    _CoordinateRow(
                      label: 'Latitude',
                      value: viewModel.latitude.toStringAsFixed(6),
                    ),
                    const SizedBox(height: 10),
                    Divider(color: colorScheme.outlineVariant),
                    const SizedBox(height: 10),
                    _CoordinateRow(
                      label: 'Longitude',
                      value: viewModel.longitude.toStringAsFixed(6),
                    ),
                    const SizedBox(height: 10),
                    Divider(color: colorScheme.outlineVariant),
                    const SizedBox(height: 10),
                    _CoordinateRow(
                      label: 'Label',
                      value: viewModel.locationLabel,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: viewModel.isLocationPermissionGranted
                    ? () async {
                        final vm = context.read<MapViewModel>();
                        await vm.centerOnUser();
                        if (!mounted) return;
                        _tryMoveToUser(vm);
                        await _scrollToMap();
                      }
                    : null,
                icon: viewModel.isLoadingLocation
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(
                  viewModel.isLoadingLocation
                      ? 'Refreshing location...'
                      : 'Center on me',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color valueColor;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoordinateRow extends StatelessWidget {
  final String label;
  final String value;

  const _CoordinateRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}
