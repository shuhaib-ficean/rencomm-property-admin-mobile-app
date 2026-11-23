import 'package:admin_mobile_app/core/constants/app_constants.dart';
import 'package:admin_mobile_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/tenant/tenant_bloc.dart';
import '../../blocs/staff/staff_bloc.dart';
import '../../blocs/property/property_bloc.dart';
import 'package:admin_mobile_app/core/models/property_model.dart';
import '../../blocs/role/role_bloc.dart';

import 'package:admin_mobile_app/core/models/user_model.dart';
import 'package:admin_mobile_app/core/models/tenant_model.dart';
import 'package:admin_mobile_app/core/utils/validators.dart';
import '../../blocs/department/department_bloc.dart';
import '../../blocs/department/department_event.dart';
import '../../blocs/department/department_state.dart';
import '../../blocs/settings/settings_bloc.dart';
import '../../../core/models/country_config.dart';

class AddPersonPage extends StatefulWidget {
  final dynamic person; // TenantModel or UserModel for editing
  final String? initialRole;
  final String? initialPropertyId;
  final String? initialRoomId;

  const AddPersonPage({
    super.key,
    this.person,
    this.initialRole,
    this.initialPropertyId,
    this.initialRoomId,
  });

  @override
  State<AddPersonPage> createState() => _AddPersonPageState();
}

class _AddPersonPageState extends State<AddPersonPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _qatarIdController = TextEditingController();
  bool _isEditing = false;

  final _employeeIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  final _rentAmountController = TextEditingController();
  final _securityDepositController = TextEditingController();
  DateTime _contractStartDate = DateTime.now();

  bool _isRecurring = true;
  final _durationDaysController = TextEditingController();

  String _role = AppConstants.tenant;
  String? _assignedPropertyId;
  String? _assignedRoomId;
  List<RoomModel> _availableRooms = [];

  String? _selectedRoleId;
  String? _selectedDepartment;
  int? _lastOperationTimestamp;

  String _securityPaymentMethod = 'cash';
  final _securityTransactionIdController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.person == null && widget.initialRole != null) {
      _role = widget.initialRole!;
    }

    if (widget.person == null) {
      if (widget.initialPropertyId != null) {
        _assignedPropertyId = widget.initialPropertyId;
      }
      if (widget.initialRoomId != null) {
        _assignedRoomId = widget.initialRoomId;
      }
    }

    if (_role == AppConstants.tenant || widget.person is TenantModel) {
      context.read<PropertyBloc>().add(const LoadProperties());
    }
    context.read<RoleBloc>().add(const LoadRoles());
    context.read<DepartmentBloc>().add(LoadDepartments());

    if (widget.person != null) {
      _isEditing = true;
      final currentCountry = context.read<SettingsBloc>().state.country;
      if (widget.person is TenantModel) {
        _role = AppConstants.tenant;
        final tenant = widget.person as TenantModel;
        _nameController.text = tenant.name;
        _emailController.text = tenant.email ?? '';
        _phoneController.text = _stripCountryDialCode(tenant.phone, currentCountry);
        _qatarIdController.text = tenant.qatarId ?? '';
        _rentAmountController.text = tenant.rentAmount.toString();
        _securityDepositController.text = tenant.securityDeposit.toString();
        try {
          _contractStartDate = tenant.contractStartDate;
        } catch (_) {}

        if (tenant.leaseList != null && tenant.leaseList!.isNotEmpty) {
          final activeLease = tenant.leaseList!.first;
          _isRecurring = activeLease.isRecurring;
          if (!_isRecurring && activeLease.endDate != null) {
            final duration =
                activeLease.endDate!.difference(activeLease.startDate).inDays;
            _durationDaysController.text = duration.toString();
          }
        } else if (tenant.contractEndDate != null) {
          _isRecurring = false;
          _durationDaysController.text = tenant.contractEndDate!
              .difference(tenant.contractStartDate)
              .inDays
              .toString();
        }

        // Pre-fill property and room
        _assignedPropertyId = tenant.assignedPropertyId;
        _assignedRoomId = tenant.assignedRoomId;

        // If property is set, we need to load rooms for it eventually.
        // The PropertyBloc might be loading, so we can't get rooms immediately here easily
        // without properties loaded.
        // However, we set the IDs so that when the UI builds and properties are loaded,
        // it can try to show them.
        // We might need to manually trigger room population in build or listener.
      } else if (widget.person is UserModel) {
        _role = AppConstants.staff;
        final staff = widget.person as UserModel;
        _nameController.text = staff.name;
        _emailController.text = staff.email;
        _phoneController.text = _stripCountryDialCode(staff.phone, currentCountry);
        _employeeIdController.text = staff.employeeId ?? '';
        _selectedRoleId = staff
            .roleId; // This works if roles load quickly or checking ID correspondence
        _selectedDepartment = staff.department;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _qatarIdController.dispose();

    _amountControllerDispose();
    _securityDepositController.dispose();
    _durationDaysController.dispose();

    _employeeIdController.dispose();
    _passwordController.dispose();
    _securityTransactionIdController.dispose();
    super.dispose();
  }

  void _amountControllerDispose() {
    _rentAmountController.dispose();
  }

  List<RoomModel> _getRoomsForProperty(PropertyModel? property) {
    if (property == null) return [];
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
    final List<RoomModel> rooms = roomMap.values.toList();
    rooms.sort((a, b) => a.number.compareTo(b.number));
    return rooms;
  }

  PropertyModel? _findProperty(List<PropertyModel> properties, String? id) {
    if (id == null) return null;
    for (final p in properties) {
      if (p.id == id) return p;
    }
    return null;
  }

  RoomModel? _findRoom(List<RoomModel> rooms, String? id) {
    if (id == null) return null;
    for (final r in rooms) {
      if (r.id == id) return r;
    }
    return null;
  }

  Widget _buildCoTenantNotice(RoomModel? room) {
    if (room == null || room.tenants.isEmpty) {
      return const SizedBox.shrink();
    }
    final tenantNames = room.tenants.map((t) => t.name).join(', ');
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.group_outlined, size: 20, color: Color(0xFF2563EB)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Room ${room.number} has ${room.tenants.length} active tenant${room.tenants.length > 1 ? "s" : ""}:',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E40AF),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  tenantNames,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'This tenant will be added as a co-tenant in this unit.',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _stripCountryDialCode(String phone, CountryConfig country) {
    var p = phone.trim();
    if (p.startsWith(country.dialCode)) {
      return p.substring(country.dialCode.length).trim();
    }
    final digits = country.dialCode.replaceAll('+', '');
    if (p.startsWith('+$digits')) {
      return p.substring(digits.length + 1).trim();
    }
    if (p.startsWith(digits)) {
      return p.substring(digits.length).trim();
    }
    return p;
  }

  String _formatPhoneWithDialCode(String phone, CountryConfig country) {
    final clean = phone.trim();
    if (clean.isEmpty) return clean;
    if (clean.startsWith('+')) return clean;
    final digits = country.dialCode.replaceAll('+', '');
    if (clean.startsWith(digits)) {
      return '+$clean';
    }
    return '${country.dialCode}$clean';
  }

  void _savePerson() {
    if (_formKey.currentState!.validate()) {
      final currentCountry = context.read<SettingsBloc>().state.country;
      final formattedPhone = _formatPhoneWithDialCode(_phoneController.text, currentCountry);

      if (_role == AppConstants.tenant) {
        final tenantData = {
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': formattedPhone,
          'qatarId': _qatarIdController.text.trim(),
          'rentAmount': double.tryParse(_rentAmountController.text) ?? 0.0,
          'securityDeposit':
              double.tryParse(_securityDepositController.text) ?? 0.0,
          'contractStartDate': _contractStartDate.toIso8601String(),
          'isRecurring': _isRecurring,
          'durationDays':
              _isRecurring ? null : int.tryParse(_durationDaysController.text),
          'assignedPropertyId': _assignedPropertyId,
          'assignedRoomId': _assignedRoomId,
          'paymentMethod': _securityPaymentMethod,
          'transactionId': _securityTransactionIdController.text.isEmpty
              ? null
              : _securityTransactionIdController.text,
        };

        if (_isEditing) {
          context
              .read<TenantBloc>()
              .add(UpdateTenant((widget.person as TenantModel).id, tenantData));
        } else {
          context.read<TenantBloc>().add(CreateTenant(tenantData));
        }
      } else {
        final Map<String, dynamic> staffData = {
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': formattedPhone,
          'role': AppConstants.staff,
          'employeeId': _employeeIdController.text,
          'roleId': _selectedRoleId,
          'department': _selectedDepartment ?? '',
        };

        if (_selectedRoleId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.required),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        if (_passwordController.text.isNotEmpty) {
          staffData['password'] = _passwordController.text;
        } else if (!_isEditing) {
          // Remove auto-generated password if user wants explicit validation
          // staffData['password'] = 'password123';
        }

        if (_isEditing) {
          context
              .read<StaffBloc>()
              .add(UpdateStaff((widget.person as UserModel).id, staffData));
        } else {
          context.read<StaffBloc>().add(CreateStaff(staffData));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCountry = context.watch<SettingsBloc>().state.country;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
            _isEditing
                ? AppLocalizations.of(context)!.editPerson
                : AppLocalizations.of(context)!.addNewPerson,
            style: GoogleFonts.montserrat(
                color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInputCard(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.fullName,
                      prefixIcon: const Icon(Icons.person),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => Validators.required(context, value, fieldName: AppLocalizations.of(context)!.fullName),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.emailAddress,
                      prefixIcon: const Icon(Icons.email),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => Validators.email(context, value),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.phoneNumber,
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(currentCountry.flag, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 4),
                            Text(
                              currentCountry.dialCode,
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(width: 1, height: 20, color: Colors.grey.withValues(alpha: 0.3)),
                          ],
                        ),
                      ),
                      hintText: currentCountry.code == 'QA' ? '5512 3456' : 'Phone number',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (_role == AppConstants.tenant) {
                        return Validators.phone(context, value);
                      }
                      return null;
                    },
                  ),
                  if (_role == AppConstants.tenant) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _qatarIdController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        labelText: 'Qatar ID (QID)',
                        hintText: 'Enter 11-digit Qatar ID',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (_role == AppConstants.tenant) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Qatar ID is required';
                          }
                          if (value.trim().length < 6) {
                            return 'Please enter a valid Qatar ID';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    BlocBuilder<PropertyBloc, PropertyState>(
                      builder: (context, state) {
                        if (state is PropertyLoaded) {
                          final allProperties = state.properties;

                          // Pre-fill available rooms if property is already set
                          if (_availableRooms.isEmpty && _assignedPropertyId != null) {
                            final prop = _findProperty(allProperties, _assignedPropertyId);
                            if (prop != null) {
                              _availableRooms = _getRoomsForProperty(prop);
                              if (_assignedRoomId != null &&
                                  !_isEditing &&
                                  _rentAmountController.text.isEmpty) {
                                final selectedRoom =
                                    _findRoom(_availableRooms, _assignedRoomId);
                                if (selectedRoom != null) {
                                  if (selectedRoom.defaultRent != null &&
                                      selectedRoom.defaultRent! > 0) {
                                    final rent = selectedRoom.defaultRent!;
                                    _rentAmountController.text = (rent % 1 == 0)
                                        ? rent.toInt().toString()
                                        : rent.toString();
                                  }
                                  if (selectedRoom.defaultDeposit != null &&
                                      selectedRoom.defaultDeposit! > 0) {
                                    final dep = selectedRoom.defaultDeposit!;
                                    _securityDepositController.text = (dep % 1 == 0)
                                        ? dep.toInt().toString()
                                        : dep.toString();
                                  }
                                }
                              }
                            }
                          }

                          final selectedProperty = _findProperty(allProperties, _assignedPropertyId);
                          final currency = selectedProperty?.currency ?? currentCountry.currency;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                key: ValueKey('prop_${_assignedPropertyId ?? 'none'}'),
                                initialValue: allProperties.any((p) => p.id == _assignedPropertyId)
                                    ? _assignedPropertyId
                                    : null,
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(context)!.assignProperty,
                                  prefixIcon: const Icon(Icons.home_work_outlined),
                                  border: const OutlineInputBorder(),
                                ),
                                items: allProperties
                                    .map(
                                      (property) => DropdownMenuItem(
                                        value: property.id,
                                        child: Text(
                                          '${property.name} - ${property.type}',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _assignedPropertyId = value;
                                    _assignedRoomId = null;
                                    final property = _findProperty(allProperties, value);
                                    _availableRooms = _getRoomsForProperty(property);
                                    if (!_isEditing) {
                                      _rentAmountController.clear();
                                      _securityDepositController.clear();
                                    }
                                  });
                                },
                                validator: (value) {
                                  if (_role == AppConstants.tenant &&
                                      (value == null || value == 'None')) {
                                    return AppLocalizations.of(context)!.pleaseSelectAProperty;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                key: ValueKey('room_${_assignedPropertyId ?? 'none'}_${_availableRooms.length}_${_assignedRoomId ?? 'none'}'),
                                initialValue: _availableRooms.any((r) => r.id == _assignedRoomId)
                                    ? _assignedRoomId
                                    : null,
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(context)!.room,
                                  prefixIcon: const Icon(Icons.meeting_room_outlined),
                                  border: const OutlineInputBorder(),
                                ),
                                items: _availableRooms.map((room) {
                                  String pricingHint = '';
                                  if (room.defaultRent != null && room.defaultRent! > 0) {
                                    final rentFormatted = room.defaultRent! % 1 == 0
                                        ? room.defaultRent!.toInt().toString()
                                        : room.defaultRent.toString();
                                    pricingHint = ' ($currency $rentFormatted)';
                                  }

                                  String occupancyHint = '';
                                  if (room.tenants.length > 1) {
                                    occupancyHint = ' · Shared (${room.tenants.length} tenants)';
                                  } else if (room.tenants.length == 1) {
                                    occupancyHint = ' · 1 tenant (${room.tenants.first.name})';
                                  } else if (room.activeTenantsCount > 0) {
                                    occupancyHint = ' · Occupied (${room.activeTenantsCount})';
                                  } else {
                                    occupancyHint = ' · Vacant';
                                  }

                                  final floorHint = room.floorName != null ? ' - ${room.floorName}' : '';

                                  return DropdownMenuItem(
                                    value: room.id,
                                    child: Text(
                                      '${room.number} (${room.type})$pricingHint$occupancyHint$floorHint',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (_assignedPropertyId == null || _availableRooms.isEmpty)
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _assignedRoomId = value;
                                          if (value != null) {
                                            final selectedRoom = _findRoom(_availableRooms, value);
                                            if (selectedRoom != null) {
                                              if (selectedRoom.defaultRent != null &&
                                                  selectedRoom.defaultRent! > 0) {
                                                final rent = selectedRoom.defaultRent!;
                                                _rentAmountController.text = (rent % 1 == 0)
                                                    ? rent.toInt().toString()
                                                    : rent.toString();
                                              }
                                              if (selectedRoom.defaultDeposit != null &&
                                                  selectedRoom.defaultDeposit! > 0) {
                                                final dep = selectedRoom.defaultDeposit!;
                                                _securityDepositController.text = (dep % 1 == 0)
                                                    ? dep.toInt().toString()
                                                    : dep.toString();
                                              }
                                            }
                                          }
                                        });
                                      },
                                hint: Text(_assignedPropertyId == null
                                    ? AppLocalizations.of(context)!.selectPropertyFirst
                                    : (_availableRooms.isEmpty
                                        ? AppLocalizations.of(context)!.noRoomsAvailable
                                        : AppLocalizations.of(context)!.selectRoom)),
                                disabledHint: Text(_assignedPropertyId == null
                                    ? AppLocalizations.of(context)!.selectPropertyFirst
                                    : AppLocalizations.of(context)!.noRoomsAvailable),
                                validator: (value) {
                                  if (_role == AppConstants.tenant && value == null) {
                                    return AppLocalizations.of(context)!.pleaseSelectARoom;
                                  }
                                  return null;
                                },
                              ),
                              if (_assignedRoomId != null)
                                _buildCoTenantNotice(_findRoom(_availableRooms, _assignedRoomId)),
                            ],
                          );
                        } else if (state is PropertyLoading) {
                          return const Center(child: CircularProgressIndicator());
                        } else {
                          return Text(AppLocalizations.of(context)!.failedToLoadProperties);
                        }
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
                              labelText: AppLocalizations.of(context)!.rentAmount,
                              prefixIcon: const Icon(Icons.payments_outlined),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) => value!.isEmpty
                                ? AppLocalizations.of(context)!.required
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: Text(
                        'Recurring Monthly Rent',
                        style: GoogleFonts.montserrat(),
                      ),
                      value: _isRecurring,
                      onChanged: (value) {
                        setState(() {
                          _isRecurring = value;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (!_isRecurring) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _durationDaysController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Lease Duration (in days)',
                          prefixIcon: Icon(Icons.timer_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (!_isRecurring && (value == null || value.isEmpty)) {
                            return AppLocalizations.of(context)!.required;
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _securityDepositController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.securityDeposit,
                        prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                        border: const OutlineInputBorder(),
                      ),
                      validator: null,
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    if (!_isEditing &&
                        _securityDepositController.text.isNotEmpty &&
                        (double.tryParse(_securityDepositController.text) ?? 0) > 0) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _securityPaymentMethod,
                        decoration: const InputDecoration(
                          labelText: 'Security Payment Method',
                          prefixIcon: Icon(Icons.payment_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: ['cash', 'bank transfer']
                            .map((method) => DropdownMenuItem(
                                  value: method,
                                  child: Text(method.toUpperCase()),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _securityPaymentMethod = value!;
                          });
                        },
                      ),
                      if (_securityPaymentMethod == 'bank transfer') ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _securityTransactionIdController,
                          decoration: const InputDecoration(
                            labelText: 'Security Transaction ID',
                            prefixIcon: Icon(Icons.receipt_long_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (_securityPaymentMethod == 'bank transfer' &&
                                (value == null || value.isEmpty)) {
                              return AppLocalizations.of(context)!.required;
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ],
                ],
              ),
              if (_role == AppConstants.staff) ...[
                const SizedBox(height: 16),
                _buildInputCard(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.employmentDetails,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _employeeIdController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.employeeId,
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) => null,
                    ),
                    const SizedBox(height: 16),
                    BlocBuilder<RoleBloc, RoleState>(
                      builder: (context, state) {
                        return DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.appRole,
                            prefixIcon: const Icon(Icons.security),
                            border: const OutlineInputBorder(),
                          ),
                          items: state is RoleLoaded
                              ? state.roles.map((role) {
                                  return DropdownMenuItem(
                                    value: role.id,
                                    child: Text(
                                      role.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList()
                              : [],
                          initialValue: state is RoleLoaded &&
                                  state.roles
                                      .any((role) => role.id == _selectedRoleId)
                              ? _selectedRoleId
                              : null,
                          onChanged: (value) {
                            setState(() {
                              _selectedRoleId = value;
                            });
                          },
                          validator: (value) => value == null
                              ? AppLocalizations.of(context)!.required
                              : null,
                          hint: state is RoleLoading
                              ? Text(AppLocalizations.of(context)!.loadingRoles)
                              : Text(AppLocalizations.of(context)!.selectRole),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    BlocBuilder<DepartmentBloc, DepartmentState>(
                      builder: (context, state) {
                        final List<DropdownMenuItem<String?>> deptItems = [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('No Department (General)'),
                          ),
                        ];

                        if (state is DepartmentLoaded) {
                          for (final dept in state.departments) {
                            deptItems.add(
                              DropdownMenuItem<String?>(
                                value: dept.name,
                                child: Text(
                                  dept.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            );
                          }
                        }

                        final bool isKnownDept = state is DepartmentLoaded &&
                            state.departments
                                .any((d) => d.name == _selectedDepartment);

                        return DropdownButtonFormField<String?>(
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Department (Optional)',
                            prefixIcon: Icon(Icons.business_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: deptItems,
                          initialValue: isKnownDept ? _selectedDepartment : null,
                          onChanged: (val) {
                            setState(() {
                              _selectedDepartment = val;
                            });
                          },
                          hint: state is DepartmentLoading
                              ? const Text('Loading departments...')
                              : const Text('Select Department (Optional)'),
                        );
                      },
                    ),
                    if (!_isEditing) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.password,
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          helperText: '',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (!_isEditing && (value == null || value.isEmpty)) {
                            return AppLocalizations.of(context)!.required;
                          }
                          if (value != null &&
                              value.isNotEmpty &&
                              value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                    ],
                  ],
                ),
              ],
              const SizedBox(height: 24),
              if (_role == AppConstants.tenant)
                BlocConsumer<TenantBloc, TenantState>(
                  listener: (context, state) {
                    if (state is TenantOperationSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(context, true);
                    } else if (state is TenantError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } else if (state is TenantLoaded) {
                      if (state.operationSuccess != null &&
                          state.operationTimestamp != _lastOperationTimestamp) {
                        _lastOperationTimestamp = state.operationTimestamp;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.operationSuccess!),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pop(context, true);
                      } else if (state.operationError != null &&
                          state.operationTimestamp != _lastOperationTimestamp) {
                        _lastOperationTimestamp = state.operationTimestamp;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.operationError!),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  builder: (context, state) {
                    bool isLoading = false;
                    if (state is TenantLoading) {
                      isLoading = true;
                    } else if (state is TenantLoaded &&
                        state.isOperationLoading) {
                      isLoading = true;
                    }

                    return ElevatedButton(
                      onPressed: isLoading ? null : _savePerson,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isEditing
                                  ? AppLocalizations.of(context)!.updateTenant
                                  : AppLocalizations.of(context)!.saveTenant,
                              style: GoogleFonts.montserrat(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    );
                  },
                )
              else
                BlocConsumer<StaffBloc, StaffState>(
                  listener: (context, state) {
                    if (state is StaffOperationSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(context, true);
                    } else if (state is StaffError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } else if (state is StaffLoaded) {
                      if (state.operationSuccess != null &&
                          state.operationTimestamp != _lastOperationTimestamp) {
                        _lastOperationTimestamp = state.operationTimestamp;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.operationSuccess!),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pop(context, true);
                      } else if (state.operationError != null &&
                          state.operationTimestamp != _lastOperationTimestamp) {
                        _lastOperationTimestamp = state.operationTimestamp;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.operationError!),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  builder: (context, state) {
                    bool isLoading = false;
                    if (state is StaffLoading) {
                      isLoading = true;
                    } else if (state is StaffLoaded &&
                        state.isOperationLoading) {
                      isLoading = true;
                    }

                    return ElevatedButton(
                      onPressed: isLoading ? null : _savePerson,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isEditing
                                  ? AppLocalizations.of(context)!.updateStaff
                                  : AppLocalizations.of(context)!.saveStaff,
                              style: GoogleFonts.montserrat(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}
