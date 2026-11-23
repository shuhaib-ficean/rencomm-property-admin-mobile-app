import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/property/property_bloc.dart';
import '../../blocs/property/add_property_cubit.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/property_model.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../blocs/settings/settings_bloc.dart';

class AddPropertyPage extends StatelessWidget {
  final PropertyModel? property;
  const AddPropertyPage({super.key, this.property});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) {
        final cubit = AddPropertyCubit();
        final currentCountry = ctx.read<SettingsBloc>().state.country;
        cubit.updateCurrency(currentCountry.currency);
        if (property != null) {
          cubit.initFromProperty(property!);
        }
        return cubit;
      },
      child: AddPropertyView(property: property),
    );
  }
}

class AddPropertyView extends StatelessWidget {
  final PropertyModel? property;
  const AddPropertyView({super.key, this.property});

  void _saveProperty(BuildContext context, AddPropertyCubit cubit) {
    final isEditing = property != null;
    ConfirmationDialog.show(
      context: context,
      title: isEditing ? 'Confirm Update Property' : 'Confirm Create Property',
      content: isEditing ? 'Are you sure you want to update this property?' : 'Are you sure you want to create this property? All details will be saved.',
      confirmText: isEditing ? 'Update' : 'Create',
      cancelText: 'Cancel',
      onConfirm: () {
        final data = cubit.validateAndGetSubmissionData();
        if (data != null) {
          if (isEditing) {
            context.read<PropertyBloc>().add(UpdateProperty(property!.id, data));
          } else {
            context.read<PropertyBloc>().add(CreateProperty(data));
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PropertyBloc, PropertyState>(
      listener: (context, state) {
        if (state is PropertyOperationSuccess) {
          Navigator.pop(context);
        } else if (state is PropertyLoaded && state.operationSuccess != null) {
          Navigator.pop(context);
        } else if (state is PropertyLoaded && state.operationError != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.operationError!), backgroundColor: Colors.red));
        } else if (state is PropertyError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
        }
      },
      child: BlocConsumer<AddPropertyCubit, AddPropertyState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          final cubit = context.read<AddPropertyCubit>();
          String appBarTitle = 'Add Property';
          if (state.currentStep == 1) appBarTitle = 'Basic Details';
          if (state.currentStep == 2) appBarTitle = 'Structure & Units';
          if (state.currentStep == 3) appBarTitle = 'Expenses (Optional)';

          return Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
              title: Text(appBarTitle,
                  style: GoogleFonts.montserrat(
                      color: Colors.black87, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black87),
              actions: [
                if (state.currentStep == 3)
                  TextButton(
                    onPressed: () => _saveProperty(context, cubit),
                    child: Text(
                      'Skip',
                      style: GoogleFonts.montserrat(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.currentStep == 1)
                    _buildStep1(context, state)
                  else if (state.currentStep == 2)
                    _buildStep2(context, state)
                  else
                    _buildStep3(context, state),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStep1(BuildContext context, AddPropertyState state) {
    final cubit = context.read<AddPropertyCubit>();
    return Column(
      children: [
        _buildSectionTitle('Property Information'),
        _buildInputCard(
          children: [
            TextFormField(
              initialValue: state.name,
              decoration: const InputDecoration(labelText: 'Property Name', prefixIcon: Icon(Icons.business), border: OutlineInputBorder()),
              onChanged: (val) => cubit.updateBasicInfo(name: val, description: state.description),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: state.selectedType,
              decoration: const InputDecoration(labelText: 'Property Type', prefixIcon: Icon(Icons.category), border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: AppConstants.propertyTypeFlat, child: Text('Flat')),
                DropdownMenuItem(value: AppConstants.propertyTypeVilla, child: Text('Villa')),
              ],
              onChanged: (val) => cubit.updateType(val!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: state.description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description), border: OutlineInputBorder()),
              onChanged: (val) => cubit.updateBasicInfo(name: state.name, description: val),
            ),

            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => cubit.pickImages(), 
              icon: const Icon(Icons.image), 
              label: const Text('Select Images (Max 5)'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), minimumSize: const Size(double.infinity, 50)),
            ),
            if (state.images.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: state.images.asMap().entries.map((entry) {
                  final index = entry.key;
                  final file = entry.value;
                  return Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(File(file.path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: () => cubit.removeImage(index),
                          child: Container(
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                            child: const Icon(Icons.cancel, color: Colors.red, size: 20),
                          ),
                        ),
                      )
                    ],
                  );
                }).toList(),
              ),
            ]
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('Location (Google Maps Integration)'),
        _buildInputCard(
          children: [
            OutlinedButton.icon(
              onPressed: () {}, 
              icon: const Icon(Icons.map, color: Colors.blue), 
              label: const Text('Pick on Map'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), minimumSize: const Size(double.infinity, 50)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: state.address,
              decoration: const InputDecoration(labelText: 'Full Address', prefixIcon: Icon(Icons.location_on), border: OutlineInputBorder()),
              onChanged: (val) => cubit.updateLocationInfo(address: val, lat: state.lat, long: state.long, country: state.country, stateText: state.stateText, city: state.city, pincode: state.pincode),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextFormField(initialValue: state.lat, decoration: const InputDecoration(labelText: 'Latitude', border: OutlineInputBorder()), onChanged: (val) => cubit.updateLocationInfo(lat: val))),
                const SizedBox(width: 16),
                Expanded(child: TextFormField(initialValue: state.long, decoration: const InputDecoration(labelText: 'Longitude', border: OutlineInputBorder()), onChanged: (val) => cubit.updateLocationInfo(long: val))),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextFormField(initialValue: state.city, decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()), onChanged: (val) => cubit.updateLocationInfo(city: val))),
                const SizedBox(width: 16),
                Expanded(child: TextFormField(initialValue: state.country, decoration: const InputDecoration(labelText: 'Country', border: OutlineInputBorder()), onChanged: (val) => cubit.updateLocationInfo(country: val))),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('Amenities & Facilities'),
        _buildInputCard(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select amenities available at this property:',
                style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[700]),
              ),
            ),
            const SizedBox(height: 12),
            _buildAmenitiesSelector(context, state, cubit),
          ],
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => cubit.nextStep(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            minimumSize: const Size(double.infinity, 50),
          ),
          child: Text('Next: Structure & Units', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildAmenitiesSelector(
      BuildContext context, AddPropertyState state, AddPropertyCubit cubit) {
    const standardAmenities = [
      'High-Speed Wi-Fi',
      'Swimming Pool',
      'Gym / Fitness Center',
      'Reserved Parking',
      '24/7 Security & CCTV',
      'Elevator / Lift',
      'Central Air Conditioning',
      'Power Backup Generator',
      'Maintenance Service',
      'Laundry Facility',
      'Garden / Balcony',
      'Waste Management',
    ];

    final allAmenities = <String>[...standardAmenities];
    for (final item in state.amenities) {
      if (!allAmenities.contains(item)) {
        allAmenities.add(item);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...allAmenities.map((item) {
              final isSel = state.amenities.contains(item);
              return FilterChip(
                label: Text(item),
                selected: isSel,
                selectedColor: const Color(0xFFE0F2FE),
                checkmarkColor: const Color(0xFF0284C7),
                avatar: Icon(
                  _getAmenityIcon(item),
                  size: 16,
                  color: isSel ? const Color(0xFF0284C7) : Colors.grey,
                ),
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: isSel ? const Color(0xFF0369A1) : Colors.black87,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (_) => cubit.toggleAmenity(item),
              );
            }),
            ActionChip(
              avatar: const Icon(Icons.add, size: 16, color: Colors.blue),
              label: const Text(
                'Add Custom',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.blue.withValues(alpha: 0.08),
              onPressed: () => _showAddCustomAmenityDialog(context, cubit),
            ),
          ],
        ),
      ],
    );
  }

  void _showAddCustomAmenityDialog(
      BuildContext context, AddPropertyCubit cubit) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Custom Amenity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'e.g. Sauna, Squash Court, Rooftop Deck',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  cubit.addCustomAmenity(text);
                }
                Navigator.pop(dialogCtx);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  IconData _getAmenityIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('wifi') || lower.contains('internet')) {
      return Icons.wifi_rounded;
    } else if (lower.contains('pool')) {
      return Icons.pool_rounded;
    } else if (lower.contains('gym') || lower.contains('fitness')) {
      return Icons.fitness_center_rounded;
    } else if (lower.contains('park')) {
      return Icons.local_parking_rounded;
    } else if (lower.contains('secur') || lower.contains('cctv')) {
      return Icons.security_rounded;
    } else if (lower.contains('lift') || lower.contains('elevator')) {
      return Icons.elevator_rounded;
    } else if (lower.contains('ac') ||
        lower.contains('air') ||
        lower.contains('cool')) {
      return Icons.ac_unit_rounded;
    } else if (lower.contains('power') ||
        lower.contains('backup') ||
        lower.contains('generator')) {
      return Icons.bolt_rounded;
    } else if (lower.contains('clean') || lower.contains('maid')) {
      return Icons.cleaning_services_rounded;
    } else if (lower.contains('laundr') || lower.contains('wash')) {
      return Icons.local_laundry_service_rounded;
    } else if (lower.contains('balcon') ||
        lower.contains('terrace') ||
        lower.contains('garden')) {
      return Icons.balcony_outlined;
    } else if (lower.contains('waste') || lower.contains('trash')) {
      return Icons.delete_outline;
    }
    return Icons.check_circle_outline;
  }

  Widget _buildStep2(BuildContext context, AddPropertyState state) {
    final cubit = context.read<AddPropertyCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('Property Room Types'),
        const SizedBox(height: 6),
        Text(
          'Manage the room types for this property. Remove types not present in this property, or add custom ones.',
          style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...state.availableRoomTypes.map((type) => Chip(
                label: Text(type, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                backgroundColor: Colors.blue.withValues(alpha: 0.08),
                deleteIcon: const Icon(Icons.close, size: 14, color: Colors.redAccent),
                onDeleted: state.availableRoomTypes.length > 1
                    ? () => cubit.removeRoomType(type)
                    : null,
              )),
              ActionChip(
                avatar: const Icon(Icons.add, size: 16, color: Colors.blue),
                label: const Text('Add Type', style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                backgroundColor: Colors.blue.withValues(alpha: 0.1),
                onPressed: () => _showAddCustomTypeDialog(context, cubit),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Floors & Rooms'),
            ElevatedButton.icon(
              onPressed: () => _showAddFloorSheet(context, cubit),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Floor'),
            )
          ],
        ),
        const SizedBox(height: 16),
        if (state.buildingFloors.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No floors added yet. Click "Add Floor" to begin.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.buildingFloors.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, floorIndex) {
            final floor = state.buildingFloors[floorIndex];
            final rooms = floor['rooms'] as List<dynamic>;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${floor['name']} (${floor['number']})', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          IconButton(icon: const Icon(Icons.add_box, color: Colors.blue), onPressed: () => _showAddRoomSheet(context, cubit, floorIndex)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => cubit.removeFloor(floorIndex)),
                        ],
                      )
                    ],
                  ),
                  const Divider(),
                  if (rooms.isEmpty) const Text('No rooms added.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: rooms.asMap().entries.map((entry) {
                      final rIndex = entry.key;
                      final r = entry.value;
                      final rent = r['rent'] ?? r['defaultRent'] ?? r['rentAmount'];
                      final deposit = r['deposit'] ?? r['defaultDeposit'] ?? r['depositAmount'];

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${r['number']} - ${r['type']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                if ((rent != null && rent > 0) || (deposit != null && deposit > 0)) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Rent: ${state.currency} ${rent ?? 0} | Dep: ${state.currency} ${deposit ?? 0}',
                                    style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => cubit.removeUnitFromFloor(floorIndex, rIndex),
                              child: const Icon(Icons.close, size: 14, color: Colors.redAccent),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Column(
          children: [
            ElevatedButton(
              onPressed: () => _saveProperty(context, cubit),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(
                property != null ? 'Save & Update Property' : 'Save & Create Property',
                style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => cubit.prevStep(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: () => cubit.nextStep(),
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('Expenses (Optional)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue[800],
                      side: BorderSide(color: Colors.blue.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3(BuildContext context, AddPropertyState state) {
    final cubit = context.read<AddPropertyCubit>();
    final isPropertyLoading = context.select((PropertyBloc bloc) => bloc.state is PropertyLoading || (bloc.state is PropertyLoaded && (bloc.state as PropertyLoaded).isOperationLoading));

    final hasExpenses = state.propertyExpenses.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _buildSectionTitle('Property Expenses'),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Optional',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => _showAddExpenseSheet(context, cubit),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Expense'),
            )
          ],
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Recurring property expenses are optional. If you do not have any recurring expenses right now, you can skip this step and save your property directly.',
                  style: TextStyle(fontSize: 13, color: Colors.blue[900], height: 1.3),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (!hasExpenses)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                const Text(
                  'No Recurring Expenses Added',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  'You can add monthly utility or maintenance costs, or tap below to finish.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ...state.propertyExpenses.asMap().entries.map((e) => ListTile(
          title: Text(e.value['name']),
          subtitle: Text('${state.currency} ${e.value['amount']}'),
          trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => cubit.removePropertyExpense(e.key)),
        )),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isPropertyLoading ? null : () => cubit.prevStep(),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: BlocBuilder<PropertyBloc, PropertyState>(
                builder: (context, propertyState) {
                  final isPropertyLoading = propertyState is PropertyLoading || 
                      (propertyState is PropertyLoaded && propertyState.isOperationLoading);
                      
                  final String buttonText;
                  if (hasExpenses) {
                    buttonText = property != null ? 'Update Property' : 'Save Property';
                  } else {
                    buttonText = property != null ? 'Skip & Update' : 'Skip & Save Property';
                  }

                  return ElevatedButton(
                    onPressed: isPropertyLoading ? null : () => _saveProperty(context, cubit),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: isPropertyLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                        : Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showAddFloorSheet(BuildContext context, AddPropertyCubit cubit) {
    String fName = '';
    String fNumber = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Floor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(decoration: const InputDecoration(labelText: 'Floor Name (e.g. Ground Floor)'), onChanged: (v) => fName = v),
            const SizedBox(height: 16),
            TextField(decoration: const InputDecoration(labelText: 'Floor Number (e.g. 0)'), keyboardType: TextInputType.number, onChanged: (v) => fNumber = v),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (fName.isNotEmpty && fNumber.isNotEmpty) {
                  cubit.addFloor(fName, fNumber);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add Floor'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showAddCustomTypeDialog(BuildContext context, AddPropertyCubit cubit) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Room Type', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Room Type Name',
            hintText: 'e.g. 2 BHK, Duplex, Studio, Penthouse',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                cubit.addRoomType(text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddRoomSheet(BuildContext context, AddPropertyCubit cubit, int floorIndex) {
    String rName = '';
    String rNumber = '';
    String rRent = '';
    String rDeposit = '';
    
    final availableTypes = cubit.state.availableRoomTypes.isNotEmpty
        ? cubit.state.availableRoomTypes
        : ['1 BHK', '2 BHK', 'Standard'];
    String rType = availableTypes.first;
    bool isAddingCustomType = false;
    final customTypeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add Room / Unit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Room Number (Required, e.g. 101, Apt 4B)',
                  prefixIcon: Icon(Icons.tag),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => rNumber = v,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Room Name (Optional, e.g. Master Bedroom)',
                  prefixIcon: Icon(Icons.meeting_room_outlined),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => rName = v,
              ),
              const SizedBox(height: 12),
              if (!isAddingCustomType) ...[
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: availableTypes.contains(rType) ? rType : availableTypes.first,
                        decoration: const InputDecoration(
                          labelText: 'Room Type',
                          prefixIcon: Icon(Icons.category_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          ...availableTypes.map(
                            (type) => DropdownMenuItem(value: type, child: Text(type)),
                          ),
                          const DropdownMenuItem(
                            value: '__ADD_NEW__',
                            child: Row(
                              children: [
                                Icon(Icons.add_circle_outline, size: 16, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('+ Add Custom Type...', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val == '__ADD_NEW__') {
                            setSheetState(() {
                              isAddingCustomType = true;
                            });
                          } else if (val != null) {
                            setSheetState(() {
                              rType = val;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Add Custom Type',
                      icon: const Icon(Icons.add_circle, color: Colors.blue, size: 28),
                      onPressed: () {
                        setSheetState(() {
                          isAddingCustomType = true;
                        });
                      },
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: customTypeController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Enter Custom Room Type',
                          hintText: 'e.g. Duplex, Store Room, 4 BHK',
                          prefixIcon: Icon(Icons.edit_note),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                      ),
                      onPressed: () {
                        final newType = customTypeController.text.trim();
                        if (newType.isNotEmpty) {
                          cubit.addRoomType(newType);
                          setSheetState(() {
                            rType = newType;
                            isAddingCustomType = false;
                          });
                        }
                      },
                      child: const Text('Save'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.grey),
                      onPressed: () {
                        setSheetState(() {
                          isAddingCustomType = false;
                        });
                      },
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Default Rent (${cubit.state.currency})',
                        prefixIcon: const Icon(Icons.payments_outlined),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => rRent = v,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Default Deposit (${cubit.state.currency})',
                        prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => rDeposit = v,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  if (rNumber.trim().isNotEmpty) {
                    final selectedType = isAddingCustomType && customTypeController.text.trim().isNotEmpty
                        ? customTypeController.text.trim()
                        : rType;

                    cubit.addUnitToFloor(floorIndex, {
                      'name': rName.trim(),
                      'number': rNumber.trim(),
                      'type': selectedType,
                      'rent': double.tryParse(rRent) ?? 0.0,
                      'deposit': double.tryParse(rDeposit) ?? 0.0,
                      'defaultRent': double.tryParse(rRent) ?? 0.0,
                      'defaultDeposit': double.tryParse(rDeposit) ?? 0.0,
                    });
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Add Room', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddExpenseSheet(BuildContext context, AddPropertyCubit cubit) {
    String eName = '';
    String eAmount = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Property Expense', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(decoration: const InputDecoration(labelText: 'Expense Name (e.g. Maintenance)'), onChanged: (v) => eName = v),
            const SizedBox(height: 16),
            TextField(decoration: const InputDecoration(labelText: 'Amount (Monthly)'), keyboardType: TextInputType.number, onChanged: (v) => eAmount = v),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (eName.isNotEmpty && eAmount.isNotEmpty) {
                  cubit.addPropertyExpense(eName, double.tryParse(eAmount) ?? 0.0);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add Expense'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _buildInputCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }
}
