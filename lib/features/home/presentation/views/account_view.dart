import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../location/providers/location_provider.dart';
import '../../../payment/providers/payment_provider.dart';
import '../../../profile/providers/profile_provider.dart';

class AccountView extends ConsumerWidget {
  const AccountView({super.key});

  // Helper to extract initials for profile avatar securely
  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'U';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1 && parts[1].isNotEmpty) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : 'U';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profileState = ref.watch(profileProvider);
    final locationState = ref.watch(locationProvider);
    final paymentState = ref.watch(paymentProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Account',
          style: AppTextStyles.heading2.copyWith(fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. PROFILE SECTION
            Container(
              margin: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 6,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Text(
                          _getInitials(profileState.name),
                          style: AppTextStyles.heading1.copyWith(
                            color: AppColors.primary,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () =>
                              _showEditProfileSheet(context, profileState),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profileState.name,
                          style: AppTextStyles.heading2.copyWith(fontSize: 18),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '+91 ${authState.phoneNumber.isNotEmpty ? authState.phoneNumber : '9876543210'}',
                          style: AppTextStyles.caption.copyWith(fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profileState.email,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.grey),
                    onPressed: () =>
                        _showEditProfileSheet(context, profileState),
                  ),
                ],
              ),
            ),

            // 2. SAVED ADDRESS SECTION
            _buildSectionCard(
              context: context,
              title: "Saved Addresses",
              icon: Icons.location_on_outlined,
              children: [
                if (locationState.savedAddresses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No saved addresses yet.',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  )
                else
                  ...locationState.savedAddresses.map((address) {
                    IconData addressIcon = Icons.location_city_outlined;
                    if (address.label.toLowerCase().contains('home')) {
                      addressIcon = Icons.home_outlined;
                    } else if (address.label.toLowerCase().contains('work')) {
                      addressIcon = Icons.work_outline;
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(addressIcon, color: AppColors.primary, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  address.label,
                                  style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  address.addressLine,
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Colors.grey,
                              size: 20,
                            ),
                            onPressed: () => _showAddressSheet(
                              context,
                              editingAddress: address,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            onPressed: () {
                              ref
                                  .read(locationProvider.notifier)
                                  .deleteAddress(address.label);
                              AppSnackbar.showSuccess(
                                context,
                                "Address deleted successfully",
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _showAddressSheet(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.add, color: AppColors.primary),
                  label: const Text(
                    'ADD NEW ADDRESS',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),

            // 3. PAYMENT METHOD SECTION
            _buildSectionCard(
              context: context,
              title: "Payment Methods",
              icon: Icons.payment_outlined,
              children: [
                if (paymentState.methods.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No payment methods added yet.',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  )
                else
                  ...paymentState.methods.map((method) {
                    IconData payIcon = Icons.payment;
                    if (method.type == PaymentType.upi) {
                      payIcon = Icons.account_balance_wallet_outlined;
                    } else if (method.type == PaymentType.cod) {
                      payIcon = Icons.money;
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: InkWell(
                        onTap: () => ref
                            .read(paymentProvider.notifier)
                            .setDefaultMethod(method.id),
                        child: Row(
                          children: [
                            Icon(payIcon, color: AppColors.primary, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        method.title,
                                        style: AppTextStyles.body.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (method.isDefault) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green[50],
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: Colors.green[200]!,
                                            ),
                                          ),
                                          child: Text(
                                            'DEFAULT',
                                            style: TextStyle(
                                              fontSize: 8,
                                              color: Colors.green[800],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    method.subtitle,
                                    style: AppTextStyles.caption.copyWith(
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (method.id != 'cod_default')
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                onPressed: () {
                                  ref
                                      .read(paymentProvider.notifier)
                                      .deletePaymentMethod(method.id);
                                  AppSnackbar.showSuccess(
                                    context,
                                    "Payment method removed",
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _showAddPaymentSheet(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.add, color: AppColors.primary),
                  label: const Text(
                    'ADD PAYMENT METHOD',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),

            // 4. HELP & SUPPORT SECTION
            _buildSectionCard(
              context: context,
              title: "Help & Support",
              icon: Icons.help_outline,
              children: [
                _buildSupportTile(
                  context,
                  title: "FAQs & Support",
                  subtitle: "Get help with your orders and queries",
                  onTap: () => _showHelpSheet(context),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: () => _showLogoutDialog(context, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red,
                  elevation: 0,
                  side: BorderSide(color: Colors.red[100]!),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: const Text(
                  'LOGOUT',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Center(
              child: Text(
                'FoodyShopy v1.0.0',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.grey[700],
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Visual card builder
  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey[700], size: 22),
              const SizedBox(width: 10),
              Text(
                title.toUpperCase(),
                style: AppTextStyles.heading2.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSupportTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.keyboard_arrow_right, color: Colors.grey),
        ],
      ),
    );
  }

  // Navigators for Bottom Sheets
  void _showEditProfileSheet(BuildContext context, dynamic profileState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _EditProfileSheet(profileState: profileState),
    );
  }

  void _showAddressSheet(BuildContext context, {dynamic editingAddress}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddressSheet(editingAddress: editingAddress),
    );
  }

  void _showAddPaymentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _AddPaymentSheet(),
    );
  }

  void _showHelpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Help & Support', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildFaqTile(
                    "How do I cancel my order?",
                    "Orders can be cancelled before the restaurant accepts them. Tapping 'Cancel Order' inside the tracking page initiates a refund.",
                  ),
                  _buildFaqTile(
                    "What are the payment options?",
                    "We support Cards, UPI platforms (Google Pay, PhonePe), and Cash on Delivery.",
                  ),
                  _buildFaqTile(
                    "How can I contact my delivery partner?",
                    "Once a rider is assigned to your order, their phone contact details are shown on the Order Status page.",
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      AppSnackbar.showSuccess(
                        context,
                        "Connecting to customer support agent...",
                      );
                    },
                    icon: const Icon(Icons.support_agent),
                    label: const Text("Chat with Support Agent"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqTile(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Colors.black87,
        ),
      ),
      childrenPadding: const EdgeInsets.all(12),
      expandedAlignment: Alignment.topLeft,
      children: [
        Text(
          answer,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout from FoodyShopy?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await ref.read(authProvider.notifier).logout();
            },
            child: const Text(
              'LOGOUT',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EXTRACTED STATEFUL WIDGETS FOR BOTTOM SHEETS (Prevents Memory Leaks)
// ============================================================================

class _EditProfileSheet extends ConsumerStatefulWidget {
  final dynamic profileState;
  const _EditProfileSheet({required this.profileState});

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController emailController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.profileState.name);
    emailController = TextEditingController(text: widget.profileState.email);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit Profile', style: AppTextStyles.heading2),
            const SizedBox(height: 20),
            CustomTextField(
              controller: nameController,
              labelText: 'Name',
              hintText: 'Enter your full name',
              validator: (val) => val == null || val.trim().isEmpty
                  ? 'Name cannot be empty'
                  : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: emailController,
              labelText: 'Email Address',
              hintText: 'Enter your email address',
              keyboardType: TextInputType.emailAddress,
              validator: (val) {
                if (val == null || val.trim().isEmpty)
                  return 'Email cannot be empty';
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(val.trim()))
                  return 'Enter a valid email address';
                return null;
              },
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Save Changes',
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  ref
                      .read(profileProvider.notifier)
                      .updateProfile(
                        name: nameController.text.trim(),
                        email: emailController.text.trim(),
                      );
                  Navigator.pop(context);
                  AppSnackbar.showSuccess(
                    context,
                    "Profile updated successfully",
                  );
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _AddressSheet extends ConsumerStatefulWidget {
  final dynamic editingAddress;
  const _AddressSheet({this.editingAddress});

  @override
  ConsumerState<_AddressSheet> createState() => _AddressSheetState();
}

class _AddressSheetState extends ConsumerState<_AddressSheet> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController labelController;
  late final TextEditingController addressController;

  @override
  void initState() {
    super.initState();
    labelController = TextEditingController(
      text: widget.editingAddress?.label ?? '',
    );
    addressController = TextEditingController(
      text: widget.editingAddress?.addressLine ?? '',
    );
  }

  @override
  void dispose() {
    labelController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.editingAddress != null
                  ? 'Edit Address'
                  : 'Add New Address',
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: labelController,
              labelText: 'Address Tag (e.g. Home, Work, Parents)',
              hintText: 'Enter label name',
              validator: (val) => val == null || val.trim().isEmpty
                  ? 'Label cannot be empty'
                  : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: addressController,
              labelText: 'Address Details',
              hintText: 'House/Flat No, Building, Street details',
              validator: (val) => val == null || val.trim().isEmpty
                  ? 'Address details cannot be empty'
                  : null,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: widget.editingAddress != null
                  ? 'Update Address'
                  : 'Save Address',
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final notifier = ref.read(locationProvider.notifier);

                  if (widget.editingAddress != null &&
                      widget.editingAddress.label !=
                          labelController.text.trim()) {
                    notifier.deleteAddress(widget.editingAddress.label);
                  }

                  notifier.saveAddress(
                    labelController.text.trim(),
                    addressController.text.trim(),
                    12.9716, // TODO: Replace with dynamic map coordinate
                    77.6408,
                  );
                  Navigator.pop(context);
                  AppSnackbar.showSuccess(
                    context,
                    widget.editingAddress != null
                        ? "Address updated successfully"
                        : "Address saved successfully",
                  );
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _AddPaymentSheet extends ConsumerStatefulWidget {
  const _AddPaymentSheet();

  @override
  ConsumerState<_AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends ConsumerState<_AddPaymentSheet> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController(text: 'UPI');
  final subtitleController = TextEditingController();
  PaymentType selectedType = PaymentType.upi;

  @override
  void dispose() {
    titleController.dispose();
    subtitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add Payment Method', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('UPI Handle'),
                    selected: selectedType == PaymentType.upi,
                    selectedColor: AppColors.primary.withOpacity(0.1),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          selectedType = PaymentType.upi;
                          titleController.text = 'UPI';
                          subtitleController.clear();
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Card'),
                    selected: selectedType == PaymentType.card,
                    selectedColor: AppColors.primary.withOpacity(0.1),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          selectedType = PaymentType.card;
                          titleController.text = 'Credit/Debit Card';
                          subtitleController.clear();
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (selectedType == PaymentType.upi) ...[
              CustomTextField(
                controller: subtitleController,
                labelText: 'UPI ID (e.g. name@okaxis)',
                hintText: 'Enter your UPI handle',
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'UPI handle cannot be empty';
                  if (!val.contains('@')) return 'Enter a valid UPI handle';
                  return null;
                },
              ),
            ] else ...[
              CustomTextField(
                controller: subtitleController,
                labelText: 'Card Number',
                hintText: 'xxxx xxxx xxxx 1234',
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'Card number cannot be empty';
                  if (val.trim().length < 12)
                    return 'Enter a valid card number';
                  return null;
                },
              ),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Save Payment Method',
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  String sub = subtitleController.text.trim();
                  String finalTitle = selectedType == PaymentType.upi
                      ? 'UPI'
                      : 'Credit/Debit Card';

                  if (selectedType == PaymentType.card) {
                    final cleaned = sub.replaceAll(RegExp(r'\s+'), '');
                    final lastFour = cleaned.substring(cleaned.length - 4);
                    sub = '•••• $lastFour';
                  }

                  ref
                      .read(paymentProvider.notifier)
                      .addPaymentMethod(
                        id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
                        type: selectedType,
                        title: finalTitle,
                        subtitle: sub,
                      );
                  Navigator.pop(context);
                  AppSnackbar.showSuccess(
                    context,
                    "Payment method saved successfully",
                  );
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
