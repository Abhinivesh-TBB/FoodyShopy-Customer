import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/utils/app_snackbar.dart';
import '../providers/location_provider.dart';

class LocationPermissionScreen extends ConsumerWidget {
  const LocationPermissionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Image Illustration
              Center(
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.map_outlined,
                    size: 90,
                    color: AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              Text(
                'Enable Location Services',
                style: AppTextStyles.heading1.copyWith(fontSize: 24),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                'FoodyShopy requires your location permission to discover popular restaurants nearby and estimate precise delivery times.',
                style: AppTextStyles.caption.copyWith(fontSize: 14),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Grant button
              ElevatedButton(
                onPressed: locationState.isLoading
                    ? null
                    : () async {
                        final success = await ref
                            .read(locationProvider.notifier)
                            .fetchDeviceLocation();
                        if (context.mounted) {
                          if (success) {
                            AppSnackbar.showSuccess(context, "Location updated successfully!");
                            context.go(AppRoutes.home);
                          } else {
                            AppSnackbar.showError(
                              context,
                              "Permission denied. Please grant location access in Settings or enter manually."
                            );
                          }
                        }
                      },
                child: locationState.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('ALLOW LOCATION ACCESS'),
              ),

              const SizedBox(height: 16),

              // Manual Address Trigger
              TextButton(
                onPressed: () {
                  context.push(AppRoutes.selectAddress);
                },
                child: Text(
                  'ENTER ADDRESS MANUALLY',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
