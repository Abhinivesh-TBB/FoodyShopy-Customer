import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/utils/app_snackbar.dart';
import '../providers/location_provider.dart';

class SelectAddressScreen extends ConsumerStatefulWidget {
  const SelectAddressScreen({super.key});

  @override
  ConsumerState<SelectAddressScreen> createState() => _SelectAddressScreenState();
}

class _SelectAddressScreenState extends ConsumerState<SelectAddressScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    setState(() {
      _suggestions = ref.read(locationProvider.notifier).searchAddressSuggestions(val);
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final notifier = ref.read(locationProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('Select Delivery Location', style: AppTextStyles.heading2.copyWith(fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Search Input Box
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search for area, street name...',
                  hintStyle: AppTextStyles.caption.copyWith(fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _suggestions = []);
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          Expanded(
            child: _suggestions.isNotEmpty
                ? ListView.separated(
                    itemCount: _suggestions.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.divider),
                    itemBuilder: (context, index) {
                      final item = _suggestions[index];
                      return ListTile(
                        leading: const Icon(Icons.location_on, color: AppColors.textSecondary),
                        title: Text(item['name'] as String, style: const TextStyle(fontSize: 13)),
                        onTap: () {
                          notifier.selectActiveAddress(item['name'] as String, item['lat'] as double, item['lng'] as double);
                          AppSnackbar.showSuccess(context, "Location set to: ${item['name']}");
                          context.go(AppRoutes.home);
                        },
                      );
                    },
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // Current Location Trigger
                      ListTile(
                        leading: const Icon(Icons.gps_fixed, color: AppColors.primary),
                        title: const Text('Use Current Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(
                          locationState.isLoading ? 'Fetching coordinates...' : 'Using device GPS position',
                          style: AppTextStyles.caption,
                        ),
                        trailing: locationState.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                              )
                            : const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () async {
                          final success = await notifier.fetchDeviceLocation();
                          if (context.mounted) {
                            if (success) {
                              AppSnackbar.showSuccess(context, "Location set to GPS position!");
                              context.go(AppRoutes.home);
                            } else {
                              AppSnackbar.showError(context, "Failed to get location. Enable GPS or input address.");
                            }
                          }
                        },
                      ),
                      const Divider(color: AppColors.divider),

                      // Set Location on Map
                      ListTile(
                        leading: const Icon(Icons.map_outlined, color: AppColors.primary),
                        title: const Text('Locate on Map', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text('Drag pointer to pin exact house location', style: AppTextStyles.caption),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () {
                          context.push(AppRoutes.mapPicker);
                        },
                      ),
                      const Divider(color: AppColors.divider),

                      const SizedBox(height: 16),

                      // Saved Addresses
                      if (locationState.savedAddresses.isNotEmpty) ...[
                        Text(
                          'SAVED ADDRESSES',
                          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 10),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: locationState.savedAddresses.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final address = locationState.savedAddresses[index];
                            return Card(
                              elevation: 0,
                              color: AppColors.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: AppColors.divider.withOpacity(0.5)),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.primary.withOpacity(0.1),
                                  child: Icon(
                                    address.label.contains('Home')
                                        ? Icons.home_outlined
                                        : address.label.contains('Work')
                                            ? Icons.work_outline
                                            : Icons.location_on_outlined,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  address.label,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                subtitle: Text(
                                  address.addressLine,
                                  style: AppTextStyles.caption.copyWith(fontSize: 11),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                  onPressed: () {
                                    notifier.deleteAddress(address.label);
                                    AppSnackbar.showInfo(context, "Address deleted.");
                                  },
                                ),
                                onTap: () {
                                  notifier.selectActiveAddress(
                                    address.addressLine,
                                    address.latitude,
                                    address.longitude,
                                  );
                                  AppSnackbar.showSuccess(context, "Location set to: ${address.label}");
                                  context.go(AppRoutes.home);
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
