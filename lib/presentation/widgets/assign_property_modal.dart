import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin_mobile_app/presentation/blocs/property/property_bloc.dart';
import 'package:admin_mobile_app/presentation/blocs/tenant/tenant_bloc.dart';
import 'package:admin_mobile_app/core/models/property_model.dart';
import 'package:admin_mobile_app/l10n/app_localizations.dart';
import 'searchable_dropdown.dart';

class AssignPropertyModal extends StatefulWidget {
  final String tenantId;

  const AssignPropertyModal({super.key, required this.tenantId});

  @override
  State<AssignPropertyModal> createState() => _AssignPropertyModalState();
}

class _AssignPropertyModalState extends State<AssignPropertyModal> {
  String? _selectedPropertyId;
  String? _selectedRoomId;
  List<RoomModel> _availableRooms = [];

  final _formKey = GlobalKey<FormState>();
  final _rentAmountController = TextEditingController();
  final _securityDepositController = TextEditingController();
  final _durationDaysController = TextEditingController();
  final DateTime _startDate = DateTime.now();
  bool _isRecurring = true;

  @override
  void initState() {
    super.initState();
    context.read<PropertyBloc>().add(const LoadProperties());
  }

  @override
  void dispose() {
    _rentAmountController.dispose();
    _securityDepositController.dispose();
    _durationDaysController.dispose();
    super.dispose();
  }

  void _updateAvailableRooms(PropertyModel property) {
    setState(() {
      _selectedRoomId = null; // Reset room selection
      final Map<String, RoomModel> roomMap = {};
      if (property.rooms.isNotEmpty) {
        for (final r in property.rooms) {
          roomMap[r.id] = r;
        }
      }
      for (final floor in property.floors) {
        for (final r in floor.rooms) {
          roomMap[r.id] = r;
        }
      }
      _availableRooms = roomMap.values.toList();
      // Sort rooms by number
      _availableRooms.sort((a, b) => a.number.compareTo(b.number));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppLocalizations.of(context)!.assignProperty,
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              BlocBuilder<PropertyBloc, PropertyState>(
                builder: (context, state) {
                  if (state is PropertyLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is PropertyLoaded) {
                    final Map<String?, String> propertyItems = {
                      for (var p in state.properties)
                        p.id: '${p.name} - ${p.type}'
                    };
                    return SearchableDropdown<String>(
                      value: _selectedPropertyId,
                      label: AppLocalizations.of(context)!.property,
                      hint: AppLocalizations.of(context)!.property,
                      prefixIcon: Icons.home_work_outlined,
                      items: {
                        null: 'Select Property',
                        ...propertyItems,
                      },
                      onChanged: (value) {
                        setState(() {
                          _selectedPropertyId = value;
                        });
                        if (value != null) {
                          final property = state.properties.firstWhere(
                            (p) => p.id == value,
                          );
                          _updateAvailableRooms(property);
                        } else {
                          setState(() {
                            _availableRooms = [];
                            _selectedRoomId = null;
                          });
                        }
                      },
                    );
                  } else {
                    return Text(
                      AppLocalizations.of(context)!.failedToLoadProperties,
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              SearchableDropdown<String>(
                value: _selectedRoomId,
                label: AppLocalizations.of(context)!.room,
                hint: _selectedPropertyId == null
                    ? AppLocalizations.of(context)!.selectPropertyFirst
                    : (_availableRooms.isEmpty
                        ? AppLocalizations.of(context)!.noRoomsAvailable
                        : AppLocalizations.of(context)!.selectRoom),
                prefixIcon: Icons.door_front_door_outlined,
                items: {
                  null: 'Select Room',
                  for (var r in _availableRooms)
                    r.id:
                        '${r.number} (${r.type}) ${r.floorName != null ? "- ${r.floorName}" : ""}'
                },
                onChanged: _selectedPropertyId == null
                    ? null
                    : (value) {
                        setState(() {
                          _selectedRoomId = value;
                        });
                      },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _rentAmountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText:
                            '${AppLocalizations.of(context)!.rentAmount} *',
                        prefixIcon: const Icon(Icons.money),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? AppLocalizations.of(context)!.required
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _securityDepositController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText:
                      '${AppLocalizations.of(context)!.securityDeposit} (Optional)',
                  prefixIcon: const Icon(Icons.wallet),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(
                        AppLocalizations.of(context)!.recurringMonthlyRent,
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      value: _isRecurring,
                      onChanged: (bool value) {
                        setState(() {
                          _isRecurring = value;
                          if (value) {
                            _durationDaysController.clear();
                          }
                        });
                      },
                      activeThumbColor: Colors.blue,
                    ),
                    if (!_isRecurring) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.leaseDurationNotice,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _durationDaysController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText:
                                    '${AppLocalizations.of(context)!.leaseDurationDays} *',
                                prefixIcon: const Icon(Icons.timer),
                                border: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(12)),
                                ),
                              ),
                              validator: (value) {
                                if (!_isRecurring &&
                                    (value == null || value.isEmpty)) {
                                  return AppLocalizations.of(context)!.required;
                                }
                                if (!_isRecurring) {
                                  final days = int.tryParse(value!);
                                  if (days == null || days <= 0) {
                                    return 'Invalid duration';
                                  }
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.cancel),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _selectedRoomId == null
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              context.read<TenantBloc>().add(
                                    AssignRoom(
                                      widget.tenantId,
                                      _selectedRoomId!,
                                      rentAmount: double.tryParse(
                                            _rentAmountController.text,
                                          ) ??
                                          0.0,
                                      securityDeposit: double.tryParse(
                                            _securityDepositController.text,
                                          ) ??
                                          0.0,
                                      startDate: _startDate.toIso8601String(),
                                      isRecurring: _isRecurring,
                                      durationDays: _isRecurring
                                          ? null
                                          : int.tryParse(
                                              _durationDaysController.text,
                                            ),
                                    ),
                                  );
                              Navigator.pop(context);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.assign,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
