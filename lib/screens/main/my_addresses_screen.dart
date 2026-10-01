import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_spacing.dart';
import '../../models/address_model.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../components/common/custom_header.dart';
import '../../components/common/custom_button.dart';
import '../../components/common/custom_input.dart';
import '../../components/common/card_container.dart';
import '../../components/common/themed_alert.dart';

class MyAddressesScreen extends StatefulWidget {
  const MyAddressesScreen({super.key});

  @override
  State<MyAddressesScreen> createState() => _MyAddressesScreenState();
}

class _MyAddressesScreenState extends State<MyAddressesScreen> {
  List<AddressModel> _addresses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _loading = true);
    final list = await ApiService.getAddresses();
    if (mounted) {
      setState(() {
        _addresses = list;
        _loading = false;
      });
    }
  }

  void _openAddEditModal({AddressModel? existing}) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final addressController = TextEditingController(text: existing?.address ?? '');
    double? lat = existing?.lat;
    double? lng = existing?.lng;
    bool isDetecting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: AppColors.white,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: AppSpacing.md,
              bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(existing == null ? 'Add Delivery Address' : 'Edit Address', style: AppTypography.h3),
                const SizedBox(height: AppSpacing.md),

                CustomInput(
                  label: 'Address Title (e.g. Home, Office, Apt)',
                  hint: 'Home',
                  controller: titleController,
                  prefixIcon: Icons.bookmark_border_rounded,
                ),
                const SizedBox(height: AppSpacing.md),

                CustomInput(
                  label: 'Full Street Address',
                  hint: 'House 12, Street 45, Sector F-7/2, Islamabad',
                  controller: addressController,
                  maxLines: 2,
                  prefixIcon: Icons.location_on_outlined,
                ),
                const SizedBox(height: AppSpacing.sm),

                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  icon: isDetecting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location_rounded, size: 18, color: AppColors.primary),
                  label: const Text('Auto-Detect Current GPS Location', style: TextStyle(color: AppColors.primary)),
                  onPressed: isDetecting
                      ? null
                      : () async {
                          setModalState(() => isDetecting = true);
                          final loc = await LocationService.getCurrentLocationWithAddress();
                          if (!mounted) return;
                          setModalState(() {
                            addressController.text = loc.address;
                            lat = loc.lat;
                            lng = loc.lng;
                            isDetecting = false;
                          });
                        },
                ),

                const SizedBox(height: AppSpacing.lg),

                CustomButton(
                  text: existing == null ? 'Save Address' : 'Update Address',
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final addr = addressController.text.trim();
                    if (title.isEmpty || addr.isEmpty) {
                      ThemedAlert.show(context, title: 'Incomplete Form', message: 'Please fill both title and address.', type: 'warning');
                      return;
                    }

                    Navigator.of(ctx).pop();

                    final newModel = AddressModel(
                      id: existing?.id ?? 'ADR-${DateTime.now().millisecondsSinceEpoch}',
                      title: title,
                      address: addr,
                      lat: lat,
                      lng: lng,
                    );

                    if (existing == null) {
                      await ApiService.addAddress(newModel);
                    } else {
                      await ApiService.updateAddress(existing.id, newModel.toMap());
                    }

                    _loadAddresses();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteAddress(String id) async {
    await ApiService.deleteAddress(id);
    _loadAddresses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomHeader(
        showBackButton: true,
        title: 'Saved Addresses',
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on_outlined, size: 48, color: AppColors.primary),
                      ),
                      const SizedBox(height: 16),
                      Text('No Saved Addresses', style: AppTypography.h3),
                      const SizedBox(height: 6),
                      Text('Save your home or office address for quicker checkout.', style: AppTypography.bodySmall),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: _addresses.length,
                  itemBuilder: (ctx, i) {
                    final a = _addresses[i];
                    return CardContainer(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.title, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(a.address, style: AppTypography.bodySmall),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textSecondary),
                            onPressed: () => _openAddEditModal(existing: a),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
                            onPressed: () => _deleteAddress(a.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text('Add Address'),
        onPressed: () => _openAddEditModal(),
      ),
    );
  }
}
