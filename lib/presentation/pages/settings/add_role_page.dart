import '../../../core/models/role_model.dart';
import 'package:admin_mobile_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../blocs/role/role_bloc.dart';
import '../../../core/extensions/string_extensions.dart';

class AddRolePage extends StatefulWidget {
  final RoleModel? role; // Role to edit, null if creating new
  const AddRolePage({super.key, this.role});

  @override
  State<AddRolePage> createState() => _AddRolePageState();
}

class _AddRolePageState extends State<AddRolePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  final List<String> _selectedPermissions = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.role?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.role?.description ?? '');
    if (widget.role != null) {
      _selectedPermissions.addAll(widget.role!.permissions);
    }
  }

  // Grouped permissions for better UI structure
  final Map<String, List<String>> _groupedPermissions = {
    'Dashboard & Analytics': ['view_analytics'],
    'Properties': [
      'view_properties',
      'add_properties',
      'edit_properties',
      'delete_properties',
    ],
    'Tenants': [
      'view_tenants',
      'add_tenants',
      'edit_tenants',
      'delete_tenants',
    ],
    'Staff': [
      'view_staffs',
      'add_staffs',
      'edit_staffs',
      'delete_staffs',
    ],
    'Payments': [
      'view_payments',
      'add_payments',
      'edit_payments',
      'delete_payments',
    ],
    'Settings': [
      'manage_roles',
      'change_password',
    ],
    'Amenities': [
      'view_amenities',
      'add_amenities',
      'edit_amenities',
      'delete_amenities',
    ],
  };

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Dashboard & Analytics':
        return Icons.dashboard;
      case 'Properties':
        return Icons.house;
      case 'Tenants':
        return Icons.person;
      case 'Staff':
        return Icons.badge;
      case 'Payments':
        return Icons.payment;
      case 'Settings':
        return Icons.settings;
      case 'Amenities':
        return Icons.handyman;
      default:
        return Icons.lock;
    }
  }

  String _formatPermissionName(String permission) {
    return permission.replaceAll('_', ' ').capitalize();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveRole() {
    if (_formKey.currentState!.validate()) {
      if (_selectedPermissions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .pleaseSelectAtLeastOnePermission)),
        );
        return;
      }

      final roleData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'permissions': _selectedPermissions,
      };

      if (widget.role != null) {
        context.read<RoleBloc>().add(UpdateRole(widget.role!.id, roleData));
      } else {
        context.read<RoleBloc>().add(CreateRole(roleData));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RoleBloc, RoleState>(
      listener: (context, state) {
        if (state is RoleOperationSuccess) {
          Navigator.pop(context);
        } else if (state is RoleError) {
          // Handled by parent RolesPage
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Text(
                widget.role != null
                    ? AppLocalizations.of(context)!.editRole
                    : AppLocalizations.of(context)!.addNewRole,
                style: GoogleFonts.montserrat(
                    color: Colors.black87, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black87),
            actions: [
              if (state is RoleLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.blue),
                  onPressed: _saveRole,
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
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
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.roleName,
                            hintText: 'e.g., Manager, Accountant',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.badge_outlined),
                          ),
                          validator: (value) => value!.isEmpty
                              ? AppLocalizations.of(context)!.roleNameIsRequired
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText:
                                AppLocalizations.of(context)!.description,
                            hintText: AppLocalizations.of(context)!.hintText,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.description_outlined),
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.permissions,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._groupedPermissions.entries.map((entry) {
                    final category = entry.key;
                    final permissions = entry.value;

                    // check if all permissions in this category are selected
                    final areAllSelected = permissions
                        .every((p) => _selectedPermissions.contains(p));

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
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
                      child: Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          title: Row(
                            children: [
                              Icon(_getCategoryIcon(category),
                                  color: Colors.blue),
                              const SizedBox(width: 12),
                              Text(
                                category,
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          trailing: Checkbox(
                            value: areAllSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedPermissions.addAll(permissions.where(
                                      (p) =>
                                          !_selectedPermissions.contains(p)));
                                } else {
                                  _selectedPermissions.removeWhere(
                                      (p) => permissions.contains(p));
                                }
                              });
                            },
                          ),
                          children: [
                            const Divider(height: 1),
                            ListView.separated(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: permissions.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final permission = permissions[index];
                                final isSelected =
                                    _selectedPermissions.contains(permission);
                                return CheckboxListTile(
                                  title: Text(
                                    _formatPermissionName(permission),
                                    style: GoogleFonts.montserrat(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  value: isSelected,
                                  activeColor: Colors.blue,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedPermissions.add(permission);
                                      } else {
                                        _selectedPermissions.remove(permission);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
