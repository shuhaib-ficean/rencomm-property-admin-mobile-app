// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/lease/lease_bloc.dart';
import '../../blocs/lease/lease_event.dart';
import '../../blocs/lease/lease_state.dart';
import '../../blocs/tenant/tenant_bloc.dart';
import '../../blocs/property/property_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/property_model.dart';
import '../../../core/routes/app_routes.dart';

class CreateLeasePage extends StatefulWidget {
  const CreateLeasePage({super.key});

  @override
  State<CreateLeasePage> createState() => _CreateLeasePageState();
}

class _CreateLeasePageState extends State<CreateLeasePage> {
  final _formKey = GlobalKey<FormState>();
  
  bool _isRecurring = true;
  String? _selectedTenantId;
  String? _selectedPropertyId;
  String? _selectedRoomId;
  
  final TextEditingController _rentController = TextEditingController();
  final TextEditingController _depositController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController(
    text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
  );
  final TextEditingController _durationController = TextEditingController();
  
  bool _initializedArgs = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedArgs) {
      _initializedArgs = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        if (args['tenantId'] != null) _selectedTenantId = args['tenantId'];
        if (args['propertyId'] != null) _selectedPropertyId = args['propertyId'];
        if (args['roomId'] != null) _selectedRoomId = args['roomId'];
        if (args['rentAmount'] != null) _rentController.text = args['rentAmount'].toString();
        if (args['securityDeposit'] != null) _depositController.text = args['securityDeposit'].toString();
        if (args['startDate'] != null) _startDateController.text = args['startDate'].toString();
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return BlocListener<LeaseBloc, LeaseState>(
      listener: (context, state) {
        if (state is LeaseSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green));
          Navigator.pop(context);
        } else if (state is LeaseError) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red));
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text('Create New Lease',
              style: GoogleFonts.montserrat(color: Colors.black87, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle('Tenant Information'),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFEBEBEB), width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        BlocBuilder<TenantBloc, TenantState>(
                          builder: (context, state) {
                            if (state is TenantLoading) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            } else if (state is TenantLoaded) {
                              return DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Select Tenant',
                                  prefixIcon: Icon(Icons.person_outline),
                                  border: OutlineInputBorder(),
                                ),
                                value: _selectedTenantId,
                                items: state.tenants.map((t) => DropdownMenuItem(
                                  value: t.id, 
                                  child: Text('${t.name} (${t.email})'),
                                )).toList(),
                                onChanged: (val) => setState(() => _selectedTenantId = val),
                                validator: (val) => val == null ? 'Required' : null,
                              );
                            }
                            return const Text('Failed to load tenants');
                          },
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton.icon(
                            onPressed: () async {
                              await Navigator.pushNamed(
                                context,
                                AppRoutes.addPerson,
                                arguments: {'initialRole': AppConstants.tenant},
                              );
                              if (context.mounted) {
                                context.read<TenantBloc>().add(const LoadTenants());
                              }
                            },
                            icon: const Icon(
                              Icons.person_add_alt_1_outlined,
                              size: 16,
                              color: Color(0xFF2F92D0),
                            ),
                            label: RichText(
                              text: TextSpan(
                                style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  color: const Color(0xFF64748B),
                                ),
                                children: [
                                  const TextSpan(text: 'New tenant? '),
                                  TextSpan(
                                    text: 'Register tenant first',
                                    style: GoogleFonts.montserrat(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2F92D0),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Property & Room'),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFEBEBEB), width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        BlocBuilder<PropertyBloc, PropertyState>(
                          builder: (context, state) {
                            if (state is PropertyLoading) {
                              return const CircularProgressIndicator();
                            } else if (state is PropertyLoaded) {
                              final property = _selectedPropertyId != null 
                                ? state.properties.cast<PropertyModel?>().firstWhere((p) => p?.id == _selectedPropertyId, orElse: () => null)
                                : null;
                                
                              return Column(
                                children: [
                                  DropdownButtonFormField<String>(
                                    decoration: const InputDecoration(labelText: 'Select Property', border: OutlineInputBorder()),
                                    value: _selectedPropertyId,
                                    items: state.properties.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedPropertyId = val;
                                        _selectedRoomId = null;
                                      });
                                    },
                                    validator: (val) => val == null ? 'Required' : null,
                                  ),
                                  const SizedBox(height: 12),
                                  if (property != null)
                                    DropdownButtonFormField<String>(
                                      decoration: const InputDecoration(labelText: 'Select Room', border: OutlineInputBorder()),
                                      value: _selectedRoomId,
                                      items: property.floors.expand((f) => f.rooms).map((r) {
                                        return DropdownMenuItem<String>(value: r.id, child: Text('Room ${r.number}'));
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedRoomId = val;
                                          final room = property.floors.expand((f) => f.rooms).firstWhere((r) => r.id == val);
                                          _rentController.text = (room.defaultRent ?? 0).toString();
                                          _depositController.text = (room.defaultDeposit ?? ((room.defaultRent ?? 0) / 2)).toString();
                                        });
                                      },
                                      validator: (val) => val == null ? 'Required' : null,
                                    ),
                                ],
                              );
                            }
                            return const Text('Failed to load properties');
                          }
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: TextFormField(controller: _rentController, decoration: const InputDecoration(labelText: 'Rent Amount', border: OutlineInputBorder(), prefixText: 'QR '), keyboardType: TextInputType.number, validator: (val) => val == null || val.isEmpty ? 'Required' : null)),
                            const SizedBox(width: 12),
                            Expanded(child: TextFormField(controller: _depositController, decoration: const InputDecoration(labelText: 'Security Deposit', border: OutlineInputBorder(), prefixText: 'QR '), keyboardType: TextInputType.number, validator: (val) => val == null || val.isEmpty ? 'Required' : null)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Lease Terms'),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFEBEBEB), width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _startDateController,
                          readOnly: true,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.tryParse(_startDateController.text) ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              _startDateController.text = DateFormat('yyyy-MM-dd').format(picked);
                            }
                          },
                          decoration: const InputDecoration(
                            labelText: 'Start Date (YYYY-MM-DD)',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          title: const Text('Is Recurring?'),
                          value: _isRecurring,
                          onChanged: (val) => setState(() => _isRecurring = val),
                        ),
                        if (!_isRecurring)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: TextFormField(
                              controller: _durationController,
                              decoration: const InputDecoration(labelText: 'Duration (Days)', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                BlocBuilder<LeaseBloc, LeaseState>(
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed: state is LeaseLoading 
                        ? null 
                        : () {
                          if (_formKey.currentState!.validate()) {
                            context.read<LeaseBloc>().add(CreateLease(
                              tenantId: _selectedTenantId!,
                              roomId: _selectedRoomId!,
                              rentAmount: double.parse(_rentController.text),
                              securityDeposit: double.parse(_depositController.text),
                              startDate: _startDateController.text,
                              isRecurring: _isRecurring,
                              durationDays: _durationController.text.isNotEmpty ? int.parse(_durationController.text) : null,
                            ));
                          }
                        },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: const Color(0xFF2F92D0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: state is LeaseLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('Create Lease', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16)),
                    );
                  }
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(title, style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}
