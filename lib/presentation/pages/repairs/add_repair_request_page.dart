import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/repair/repair_bloc.dart';
import '../../blocs/repair/repair_event.dart';
import '../../blocs/repair/repair_state.dart';
import '../../blocs/property/property_bloc.dart';
import '../../blocs/tenant/tenant_bloc.dart';
import '../../../../core/models/tenant_model.dart';
import '../../../../core/models/property_model.dart';

class AddRepairRequestPage extends StatefulWidget {
  final String? initialServiceType;
  const AddRepairRequestPage({super.key, this.initialServiceType});

  @override
  State<AddRepairRequestPage> createState() => _AddRepairRequestPageState();
}

class _AddRepairRequestPageState extends State<AddRepairRequestPage> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedPropertyId;
  String? _selectedRoomId;
  String? _selectedTenantId;
  late String _serviceType;
  late String _department;
  late String _category;
  String _priority = 'Medium';
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  List<RoomModel> _availableRooms = [];

  static const List<String> _repairDepartments = [
    'Plumbing',
    'Electrical',
    'HVAC / AC',
    'Carpentry & Doors',
    'Appliance',
    'Painting & Walls',
    'General Maintenance',
  ];

  static const List<String> _extraDepartments = [
    'House Cleaning',
    'Laundry Services',
    'Pest Control',
    'Waste Management',
    'Gas Refill / Utilities',
    'Car Wash',
    'Other Extra Services',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialServiceType == 'Extras') {
      _serviceType = 'Extras';
      _department = 'House Cleaning';
      _category = 'Deep Cleaning';
    } else {
      _serviceType = 'Repairs';
      _department = 'Plumbing';
      _category = 'Leakage';
    }
    _categoryController.text = _category;

    // Load properties if not already loaded
    final propertyState = context.read<PropertyBloc>().state;
    if (propertyState is! PropertyLoaded) {
      context.read<PropertyBloc>().add(const LoadProperties());
    }

    // Load tenants if not already loaded
    final tenantState = context.read<TenantBloc>().state;
    if (tenantState is! TenantLoaded) {
      context.read<TenantBloc>().add(const LoadTenants());
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _updateDefaultCategory(String dept) {
    switch (dept) {
      // Repairs
      case 'Plumbing':
        _category = 'Leakage / Pipe Issue';
        break;
      case 'Electrical':
        _category = 'Wiring / Switch / Socket';
        break;
      case 'HVAC / AC':
        _category = 'AC Cooling Issue';
        break;
      case 'Carpentry & Doors':
        _category = 'Door / Lock / Window Repair';
        break;
      case 'Appliance':
        _category = 'Appliance Breakdown';
        break;
      case 'Painting & Walls':
        _category = 'Wall Touch-up / Dampness';
        break;
      case 'General Maintenance':
        _category = 'General Maintenance';
        break;

      // Extras
      case 'House Cleaning':
        _category = 'Deep Cleaning';
        break;
      case 'Laundry Services':
        _category = 'Wash & Iron';
        break;
      case 'Pest Control':
        _category = 'Fumigation & Pest Control';
        break;
      case 'Waste Management':
        _category = 'Bulk Trash Removal';
        break;
      case 'Gas Refill / Utilities':
        _category = 'Cooking Gas Cylinder';
        break;
      case 'Car Wash':
        _category = 'Vehicle Cleaning';
        break;
      case 'Other Extra Services':
        _category = 'Extra Service Request';
        break;
      default:
        _category = 'General Request';
        break;
    }
    _categoryController.text = _category;
  }

  void _onPropertySelected(String? propId, List<PropertyModel> properties) {
    setState(() {
      _selectedPropertyId = propId;
      _selectedRoomId = null;
      _selectedTenantId = null;

      if (propId != null) {
        final prop = properties.firstWhere((p) => p.id == propId);
        _availableRooms = [];
        _availableRooms.addAll(prop.rooms);
        for (var floor in prop.floors) {
          _availableRooms.addAll(floor.rooms);
        }
      } else {
        _availableRooms = [];
      }
    });
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedPropertyId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a property'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final data = {
        'propertyId': _selectedPropertyId,
        if (_selectedRoomId != null) 'roomId': _selectedRoomId,
        if (_selectedTenantId != null) 'tenantId': _selectedTenantId,
        'department': _department,
        'category': _categoryController.text.trim().isNotEmpty
            ? _categoryController.text.trim()
            : _category,
        'priority': _priority,
        'description': _descController.text.trim(),
      };

      context.read<RepairBloc>().add(CreateRepair(data));
    }
  }

  Widget _buildServiceTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _serviceType = 'Repairs';
                  _department = _repairDepartments.first;
                  _updateDefaultCategory(_department);
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _serviceType == 'Repairs' ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _serviceType == 'Repairs'
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.handyman_outlined,
                      size: 16,
                      color: _serviceType == 'Repairs'
                          ? const Color(0xFF2F92D0)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Repairs',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: _serviceType == 'Repairs'
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: _serviceType == 'Repairs'
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _serviceType = 'Extras';
                  _department = _extraDepartments.first;
                  _updateDefaultCategory(_department);
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _serviceType == 'Extras' ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _serviceType == 'Extras'
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.room_service_outlined,
                      size: 16,
                      color: _serviceType == 'Extras'
                          ? const Color(0xFF2F92D0)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Extras',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: _serviceType == 'Extras'
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: _serviceType == 'Extras'
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentDepartments =
        _serviceType == 'Extras' ? _extraDepartments : _repairDepartments;

    return BlocListener<RepairBloc, RepairState>(
      listener: (context, state) {
        if (state is RepairLoaded && state.operationSuccess != null) {
          Navigator.pop(context); // Go back to list
        } else if (state is RepairError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        } else if (state is RepairLoaded && state.operationError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.operationError!),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            _serviceType == 'Extras' ? 'New Extra Service' : 'New Repair Request',
            style: GoogleFonts.montserrat(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
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
                _buildServiceTypeSelector(),
                const SizedBox(height: 16),
                _buildPropertySelector(),
                const SizedBox(height: 16),
                _buildRoomSelector(),
                const SizedBox(height: 16),
                _buildTenantSelector(),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey('$_serviceType-$_department'),
                  isExpanded: true,
                  initialValue: _department,
                  decoration: InputDecoration(
                    labelText: _serviceType == 'Extras' ? 'Service Category' : 'Repair Department',
                    prefixIcon: Icon(
                      _serviceType == 'Extras'
                          ? Icons.room_service_outlined
                          : Icons.handyman_outlined,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  items: currentDepartments
                      .map((d) => DropdownMenuItem(
                          value: d,
                          child: Text(d, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _department = val;
                        _updateDefaultCategory(val);
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _categoryController,
                  decoration: InputDecoration(
                    labelText: _serviceType == 'Extras'
                        ? 'Specific Service (e.g. Deep Cleaning, Wash & Iron)'
                        : 'Issue Summary (e.g. Leakage, AC Cooling)',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.label_outline),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _priority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Low', 'Medium', 'High', 'Critical']
                      .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (val) => setState(() => _priority = val!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description / Notes',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please describe the request'
                      : null,
                ),
                const SizedBox(height: 32),
                BlocBuilder<RepairBloc, RepairState>(
                  builder: (context, state) {
                    final isLoading = state is RepairLoading;
                    return ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F92D0),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Submit ${_serviceType == 'Extras' ? 'Extra Service' : 'Repair'} Request',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPropertySelector() {
    return BlocBuilder<PropertyBloc, PropertyState>(
      builder: (context, state) {
        if (state is PropertyLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is PropertyLoaded) {
          return DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _selectedPropertyId,
            decoration: const InputDecoration(
              labelText: 'Select Property',
              prefixIcon: Icon(Icons.home_work_outlined),
              border: OutlineInputBorder(),
            ),
            items: state.properties
                .map((p) => DropdownMenuItem(
                    value: p.id,
                    child: Text(p.name, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (val) => _onPropertySelected(val, state.properties),
            validator: (v) => v == null ? 'Property is required' : null,
          );
        }
        return const Text('Failed to load properties');
      },
    );
  }

  List<TenantModel> _getTenantsForSelectedRoom(List<TenantModel> allTenants) {
    final propertyTenants = allTenants.where((t) {
      if (_selectedPropertyId == null) return true;
      return t.assignedPropertyId == _selectedPropertyId ||
          (t.property != null && t.property!.id == _selectedPropertyId);
    }).toList();

    if (_selectedRoomId == null) {
      return propertyTenants;
    }

    final room = _availableRooms.firstWhere(
      (r) => r.id == _selectedRoomId,
      orElse: () => const RoomModel(id: '', number: '', type: '', propertyId: ''),
    );

    return propertyTenants.where((t) {
      final matchesAssignedRoom = t.assignedRoomId == _selectedRoomId ||
          (t.assignedRoom != null && t.assignedRoom!.id == _selectedRoomId);
      final matchesRoomTenant = room.tenants.any((rt) => rt.id == t.id);
      final matchesLease = t.leaseList != null &&
          t.leaseList!.any((l) => l.roomId == _selectedRoomId);
      return matchesAssignedRoom || matchesRoomTenant || matchesLease;
    }).toList();
  }

  Widget _buildRoomSelector() {
    return DropdownButtonFormField<String>(
      key: ValueKey('room-$_selectedPropertyId-$_selectedRoomId'),
      isExpanded: true,
      initialValue: _selectedRoomId,
      decoration: const InputDecoration(
        labelText: 'Select Room (Optional)',
        prefixIcon: Icon(Icons.door_front_door_outlined),
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text(
            'None (General Property Area)',
            style: TextStyle(color: Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ..._availableRooms.map((r) => DropdownMenuItem(
            value: r.id,
            child:
                Text('Unit ${r.number}', overflow: TextOverflow.ellipsis))),
      ],
      onChanged: (val) {
        setState(() {
          _selectedRoomId = val;
          // Filter tenants for this room and auto-select if single tenant
          final tenantState = context.read<TenantBloc>().state;
          if (tenantState is TenantLoaded) {
            final roomTenants = _getTenantsForSelectedRoom(tenantState.tenants);
            if (val != null) {
              if (roomTenants.length == 1) {
                _selectedTenantId = roomTenants.first.id;
              } else if (_selectedTenantId != null &&
                  !roomTenants.any((t) => t.id == _selectedTenantId)) {
                _selectedTenantId = null;
              }
            }
          }
        });
      },
      disabledHint: const Text('No rooms available or property not selected'),
    );
  }

  Widget _buildTenantSelector() {
    return BlocBuilder<TenantBloc, TenantState>(
      builder: (context, state) {
        if (state is TenantLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is TenantLoaded) {
          final availableTenants = _getTenantsForSelectedRoom(state.tenants);

          // Safeguard: Ensure _selectedTenantId exists in availableTenants, otherwise reset
          if (_selectedTenantId != null &&
              !availableTenants.any((t) => t.id == _selectedTenantId)) {
            _selectedTenantId = null;
          }

          return DropdownButtonFormField<String>(
            key: ValueKey('tenant-$_selectedPropertyId-$_selectedRoomId-$_selectedTenantId'),
            isExpanded: true,
            initialValue: _selectedTenantId,
            decoration: InputDecoration(
              labelText: _selectedRoomId != null
                  ? 'Unit Tenant'
                  : 'Select Tenant (Optional)',
              prefixIcon: const Icon(Icons.person_outline),
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text(
                  _selectedRoomId != null
                      ? (availableTenants.isEmpty
                          ? 'No tenant assigned to this unit (Vacant)'
                          : 'None (Unassigned / Vacant)')
                      : 'None (General Maintenance / Vacant)',
                  style: const TextStyle(color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ...availableTenants.map((t) => DropdownMenuItem<String>(
                    value: t.id,
                    child: Text(
                      '${t.name} (${t.phone})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
            ],
            onChanged: (val) {
              setState(() {
                _selectedTenantId = val;
                // If tenant is selected and room was not set, auto-select tenant's room
                if (val != null && _selectedRoomId == null) {
                  final t = availableTenants.firstWhere((x) => x.id == val);
                  final tenantRoomId = t.assignedRoomId ?? t.assignedRoom?.id;
                  if (tenantRoomId != null &&
                      _availableRooms.any((r) => r.id == tenantRoomId)) {
                    _selectedRoomId = tenantRoomId;
                  }
                }
              });
            },
          );
        }
        return DropdownButtonFormField<String>(
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Select Tenant (Optional)',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem<String>(
              value: null,
              child: Text('None (Optional)', overflow: TextOverflow.ellipsis),
            ),
          ],
          onChanged: null,
        );
      },
    );
  }
}
