import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:admin_mobile_app/core/models/tenant_model.dart';
import 'package:admin_mobile_app/core/models/tenant_amenity_model.dart';
import 'package:admin_mobile_app/presentation/blocs/tenant/tenant_bloc.dart';
import 'package:admin_mobile_app/l10n/app_localizations.dart';

class AddAmenityModal extends StatefulWidget {
  final TenantModel tenant;
  final TenantAmenityModel? amenity;

  const AddAmenityModal({super.key, required this.tenant, this.amenity});

  @override
  State<AddAmenityModal> createState() => _AddAmenityModalState();
}

class _AddAmenityModalState extends State<AddAmenityModal> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _descriptionController.text = widget.amenity?.description ?? '';
    _selectedDate =
        DateTime.tryParse(widget.amenity?.providedAt ?? '') ?? DateTime.now();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        widget.amenity == null ? 'Add Amenity' : 'Update Amenity',
        style: GoogleFonts.montserrat(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _descriptionController,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Date Provided',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              subtitle: Text(
                DateFormat('dd MMM yyyy').format(_selectedDate),
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = picked;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            AppLocalizations.of(context)!.cancel,
            style: GoogleFonts.montserrat(color: Colors.grey[600]),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final tenantBloc = context.read<TenantBloc>();
              if (widget.amenity == null) {
                tenantBloc.add(
                  AddTenantAmenity(
                    tenantId: widget.tenant.id,
                    description: _descriptionController.text.trim(),
                    providedAt: _selectedDate,
                  ),
                );
              } else {
                tenantBloc.add(
                  UpdateTenantAmenity(
                    tenantId: widget.tenant.id,
                    amenityId: widget.amenity!.id,
                    description: _descriptionController.text.trim(),
                    providedAt: _selectedDate,
                  ),
                );
              }
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            AppLocalizations.of(context)!.save,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
