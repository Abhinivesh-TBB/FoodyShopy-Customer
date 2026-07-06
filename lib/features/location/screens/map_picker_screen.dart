import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/app_snackbar.dart';
import '../providers/location_provider.dart';

class MapPickerScreen extends ConsumerStatefulWidget {
  const MapPickerScreen({super.key});

  @override
  ConsumerState<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends ConsumerState<MapPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _draggedLatLng;
  String _resolvedAddress = '';
  bool _isResolving = false;
  String _selectedLabel = ''; // '', 'Home', 'Work', 'Other'

  @override
  void initState() {
    super.initState();
    final locationState = ref.read(locationProvider);
    _resolvedAddress = locationState.activeAddressLine;
    _draggedLatLng = LatLng(locationState.activeLatitude, locationState.activeLongitude);
  }

  Future<void> _resolveAddress(LatLng coords) async {
    setState(() => _isResolving = true);
    final address = await LocationService.reverseGeocode(coords.latitude, coords.longitude);
    if (mounted) {
      setState(() {
        _resolvedAddress = address;
        _isResolving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final notifier = ref.read(locationProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('Set Delivery Location', style: AppTextStyles.heading2.copyWith(fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(locationState.activeLatitude, locationState.activeLongitude),
              zoom: 15.5,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: (position) {
              _draggedLatLng = position.target;
            },
            onCameraIdle: () {
              if (_draggedLatLng != null) {
                _resolveAddress(_draggedLatLng!);
              }
            },
            myLocationEnabled: locationState.hasPermission,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // Central Pin overlay
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Order will deliver here',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.location_pin, color: AppColors.primary, size: 48),
                ],
              ),
            ),
          ),

          // GPS Location floating button
          Positioned(
            right: 16,
            bottom: 260,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              onPressed: () async {
                final success = await notifier.fetchDeviceLocation();
                if (success && _mapController != null) {
                  final activeState = ref.read(locationProvider);
                  _mapController!.animateCamera(
                    CameraUpdate.newLatLng(
                      LatLng(activeState.activeLatitude, activeState.activeLongitude),
                    ),
                  );
                }
              },
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),

      // Bottom address selector sheet
      bottomSheet: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Select Precise Location',
                  style: AppTextStyles.heading2.copyWith(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Address display card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: _isResolving
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      ),
                    )
                  : Text(
                      _resolvedAddress,
                      style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),

            const SizedBox(height: 16),

            // Label Selector (Pills)
            Text(
              'SAVE ADDRESS AS',
              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildLabelPill('Home 🏠'),
                const SizedBox(width: 10),
                _buildLabelPill('Work 💼'),
                const SizedBox(width: 10),
                _buildLabelPill('Other 📍'),
              ],
            ),

            const SizedBox(height: 20),

            // Confirm Button
            ElevatedButton(
              onPressed: _isResolving
                  ? null
                  : () {
                      if (_draggedLatLng == null) return;

                      // Set active address
                      notifier.selectActiveAddress(
                        _resolvedAddress,
                        _draggedLatLng!.latitude,
                        _draggedLatLng!.longitude,
                      );

                      // Save address if label selected
                      if (_selectedLabel.isNotEmpty) {
                        notifier.saveAddress(
                          _selectedLabel,
                          _resolvedAddress,
                          _draggedLatLng!.latitude,
                          _draggedLatLng!.longitude,
                        );
                      }

                      AppSnackbar.showSuccess(context, "Delivery location confirmed!");
                      context.go(AppRoutes.home);
                    },
              child: const Text('CONFIRM LOCATION'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelPill(String label) {
    final isSelected = _selectedLabel == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLabel = isSelected ? '' : label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
