import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../blocs/department/department_bloc.dart';
import '../../blocs/department/department_event.dart';
import '../../blocs/department/department_state.dart';
import '../../blocs/staff/staff_bloc.dart';
import '../../../../core/models/department_model.dart';
import '../../../../core/models/user_model.dart';
import '../../widgets/app_entity_action_menu.dart';
import '../../widgets/confirmation_dialog.dart';

class DepartmentsPage extends StatefulWidget {
  const DepartmentsPage({super.key});

  @override
  State<DepartmentsPage> createState() => _DepartmentsPageState();
}

class _DepartmentsPageState extends State<DepartmentsPage> {
  late DepartmentBloc _departmentBloc;
  late StaffBloc _staffBloc;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _departmentBloc = context.read<DepartmentBloc>()..add(LoadDepartments());
    _staffBloc = context.read<StaffBloc>()..add(const LoadStaff());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getDepartmentIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('plumb')) return Icons.plumbing_rounded;
    if (lower.contains('electr')) return Icons.electrical_services_rounded;
    if (lower.contains('clean')) return Icons.cleaning_services_rounded;
    if (lower.contains('paint')) return Icons.format_paint_rounded;
    if (lower.contains('secur')) return Icons.security_rounded;
    if (lower.contains('hvac') || lower.contains('ac') || lower.contains('air')) {
      return Icons.ac_unit_rounded;
    }
    if (lower.contains('garden') || lower.contains('landscap')) {
      return Icons.yard_rounded;
    }
    return Icons.business_rounded;
  }

  void _showCreateEditDialog({DepartmentModel? dept, List<UserModel>? staffList}) {
    final nameController = TextEditingController(text: dept?.name);
    final descriptionController = TextEditingController(text: dept?.description);
    String? selectedStaffId;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            dept == null ? 'Create Department' : 'Edit Department',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Department Name',
                  prefixIcon: Icon(Icons.business_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  prefixIcon: Icon(Icons.description_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              if (staffList != null && staffList.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue: selectedStaffId,
                  decoration: const InputDecoration(
                    labelText: 'Assign Staff Member',
                    prefixIcon: Icon(Icons.person_add_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: staffList
                      .map((user) => DropdownMenuItem(
                            value: user.id,
                            child: Text(user.name),
                          ))
                      .toList(),
                  onChanged: (val) {
                    selectedStaffId = val;
                  },
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                final name = nameController.text.trim();
                final desc = descriptionController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Department name is required')),
                  );
                  return;
                }

                final data = {
                  'name': name,
                  'description': desc,
                };

                if (dept == null) {
                  _departmentBloc.add(CreateDepartment(data));
                } else {
                  _departmentBloc.add(UpdateDepartment(dept.id, data));
                }

                if (selectedStaffId != null) {
                  _staffBloc.add(
                      UpdateStaff(selectedStaffId!, {'department': name}));
                }

                Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            )
          ],
        );
      },
    );
  }

  void _confirmDelete(DepartmentModel dept) {
    ConfirmationDialog.show(
      context: context,
      title: 'Delete Department',
      content:
          'Are you sure you want to permanently delete the "${dept.name}" department?',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      isDestructive: true,
      onConfirm: () => _departmentBloc.add(DeleteDepartment(dept.id)),
    );
  }

  Widget _buildDepartmentCard(
      BuildContext context, DepartmentModel dept, List<UserModel>? staffList) {
    final iconData = _getDepartmentIcon(dept.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showCreateEditDialog(dept: dept, staffList: staffList),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Department Icon Container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFBFDBFE).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Icon(
                    iconData,
                    color: const Color(0xFF2563EB),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),

                // Department Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dept.name,
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      if (dept.description != null &&
                          dept.description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          dept.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            fontSize: 12.5,
                            color: const Color(0xFF64748B),
                            height: 1.3,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),

                      // Staff Count Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.people_alt_outlined,
                              size: 13,
                              color: Color(0xFF2563EB),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${dept.staffCount} Staff Members',
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E40AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Action Menu
                AppEntityActionMenu(
                  onEdit: () =>
                      _showCreateEditDialog(dept: dept, staffList: staffList),
                  editLabel: 'Edit Department',
                  onDelete: () => _confirmDelete(dept),
                  deleteLabel: 'Delete Department',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _departmentBloc),
        BlocProvider.value(value: _staffBloc),
      ],
      child: BlocConsumer<DepartmentBloc, DepartmentState>(
        listener: (context, state) {
          if (state is DepartmentLoaded && state.operationSuccess != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.operationSuccess!),
                backgroundColor: Colors.green,
              ),
            );
          }
          if (state is DepartmentLoaded && state.operationError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.operationError!),
                backgroundColor: Colors.red,
              ),
            );
          }
          if (state is DepartmentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          return BlocBuilder<StaffBloc, StaffState>(
            builder: (context, staffState) {
              List<UserModel>? staffList;
              if (staffState is StaffLoaded) {
                staffList = staffState.staff;
              }

              if (state is DepartmentLoading || state is DepartmentInitial) {
                return Scaffold(
                  backgroundColor: Colors.grey[50],
                  appBar: AppBar(
                    title: Text(
                      'Departments',
                      style: GoogleFonts.montserrat(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: Colors.white,
                    elevation: 0,
                    iconTheme: const IconThemeData(color: Colors.black87),
                  ),
                  body: const Center(child: CircularProgressIndicator()),
                );
              }

              if (state is DepartmentError) {
                return Scaffold(
                  backgroundColor: Colors.grey[50],
                  appBar: AppBar(
                    title: Text(
                      'Departments',
                      style: GoogleFonts.montserrat(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: Colors.white,
                    elevation: 0,
                    iconTheme: const IconThemeData(color: Colors.black87),
                  ),
                  body: Center(child: Text('Error: ${state.message}')),
                );
              }

              final departments = (state as DepartmentLoaded).departments;
              final filteredDepartments = departments.where((d) {
                if (_searchQuery.isEmpty) return true;
                final q = _searchQuery.toLowerCase();
                return d.name.toLowerCase().contains(q) ||
                    (d.description?.toLowerCase().contains(q) ?? false);
              }).toList();

              return Scaffold(
                backgroundColor: Colors.grey[50],
                appBar: AppBar(
                  title: Text(
                    'Departments',
                    style: GoogleFonts.montserrat(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Colors.white,
                  elevation: 0,
                  iconTheme: const IconThemeData(color: Colors.black87),
                ),
                floatingActionButton: FloatingActionButton(
                  onPressed: () => _showCreateEditDialog(staffList: staffList),
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
                body: Column(
                  children: [
                    // Top Search Bar
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search departments...',
                          hintStyle: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: Colors.grey[400],
                          ),
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.blue),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.blue),
                          ),
                        ),
                      ),
                    ),

                    // Header Count and Refresh
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'All Departments (${filteredDepartments.length})',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF334155),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 20),
                            tooltip: 'Refresh',
                            onPressed: () =>
                                _departmentBloc.add(LoadDepartments()),
                          ),
                        ],
                      ),
                    ),

                    // Cards List
                    Expanded(
                      child: filteredDepartments.isEmpty
                          ? RefreshIndicator(
                              onRefresh: () async {
                                _departmentBloc.add(LoadDepartments());
                              },
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.45,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.business_outlined,
                                          size: 56,
                                          color: Colors.grey[300],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No departments found',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () async {
                                _departmentBloc.add(LoadDepartments());
                              },
                              child: ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 80),
                                itemCount: filteredDepartments.length,
                                itemBuilder: (context, index) {
                                  return _buildDepartmentCard(
                                    context,
                                    filteredDepartments[index],
                                    staffList,
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
