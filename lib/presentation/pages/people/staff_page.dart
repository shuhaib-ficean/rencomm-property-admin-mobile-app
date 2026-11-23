import 'dart:async';
import 'package:admin_mobile_app/core/utils/permission_helper.dart';
import 'package:admin_mobile_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/staff/staff_bloc.dart';
import '../../../core/models/user_model.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/app_entity_action_menu.dart';
import '../../widgets/paginated_list_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'add_person_page.dart';

class StaffPage extends StatefulWidget {
  const StaffPage({super.key});

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Could not launch $launchUri';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StaffBloc, StaffState>(
      listener: (context, state) {
        if (state is StaffOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is StaffLoaded) {
          if (state.operationError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.operationError!),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state.operationSuccess != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.operationSuccess!),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else if (state is StaffError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text('Manage Staff',
              style: GoogleFonts.montserrat(
                  color: Colors.black87, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        _debounce?.cancel();
                        _debounce =
                            Timer(const Duration(milliseconds: 400), () {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                          context
                              .read<StaffBloc>()
                              .add(LoadStaff(search: value.trim()));
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search staff by name, email or phone...',
                        hintStyle: GoogleFonts.montserrat(
                            fontSize: 13, color: Colors.grey[400]),
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.blue),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon:
                                    const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                  context
                                      .read<StaffBloc>()
                                      .add(const LoadStaff(search: ''));
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildStaffList()),
          ],
        ),
        floatingActionButton:
            PermissionHelper.hasPermission(context, 'add_staffs')
                ? FloatingActionButton(
                    onPressed: () async {
                      await Navigator.pushNamed(context, '/add-person',
                          arguments: {'initialRole': AppConstants.staff});
                      if (context.mounted) {
                        context.read<StaffBloc>().add(const LoadStaff());
                      }
                    },
                    backgroundColor: Colors.blue,
                    child: const Icon(Icons.person_add),
                  )
                : null,
      ),
    );
  }

  Widget _buildStaffList() {
    return BlocBuilder<StaffBloc, StaffState>(
      builder: (context, state) {
        if (state is StaffLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is StaffLoaded) {
          return PaginatedListView<UserModel>(
            items: state.staff,
            isLoadingInitial: false,
            isLoadingMore: state.isLoadingMore,
            hasReachedMax: state.hasReachedMax,
            onRefresh: () async {
              context.read<StaffBloc>().add(LoadStaff(
                    isRefresh: true,
                    search: _searchController.text.trim(),
                  ));
            },
            onLoadMore: () {
              context.read<StaffBloc>().add(LoadStaff(
                    isLoadMore: true,
                    search: _searchController.text.trim(),
                  ));
            },
            emptyStateWidget: Center(
              child: Text(AppLocalizations.of(context)!.noStaffFound),
            ),
            itemBuilder: (context, staffMember) {
              return _buildPersonCard(
                context,
                name: staffMember.name,
                role: staffMember.roleName ?? staffMember.role,
                status: staffMember.isActive
                    ? AppLocalizations.of(context)!.active
                    : AppLocalizations.of(context)!.inactive,
                email: staffMember.email,
                phone: staffMember.phone,
                imageUrl:
                    'https://www.gravatar.com/avatar/${staffMember.email}?d=https%3A%2F%2Fui-avatars.com%2Fapi%2F/${staffMember.name}/128',
                isStaff: true,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.personDetails,
                    arguments: staffMember,
                  );
                },
                onEdit: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddPersonPage(person: staffMember),
                    ),
                  );
                  if (context.mounted) {
                    context.read<StaffBloc>().add(const LoadStaff());
                  }
                },
                onDelete: () {
                  _showDeleteConfirmation(context, staffMember);
                },
                onCall: () {
                  if (staffMember.phone.isNotEmpty) {
                    _makePhoneCall(staffMember.phone);
                  }
                },
                onToggleStatus: () {
                  ConfirmationDialog.show(
                    context: context,
                    title: staffMember.isActive ? 'Inactivate Staff' : 'Activate Staff',
                    content: 'Are you sure you want to ${staffMember.isActive ? 'inactivate' : 'activate'} this staff member?',
                    confirmText: staffMember.isActive ? 'Inactivate' : 'Activate',
                    cancelText: AppLocalizations.of(context)!.cancel,
                    isDestructive: staffMember.isActive,
                    onConfirm: () {
                      context.read<StaffBloc>().add(UpdateStaff(staffMember.id, {
                        'name': staffMember.name,
                        'email': staffMember.email,
                        'phone': staffMember.phone,
                        'role': staffMember.role,
                        'employeeId': staffMember.employeeId ?? '',
                        'department': staffMember.department ?? '',
                        'isActive': !staffMember.isActive,
                        'roleId': staffMember.roleId,
                      }));
                    },
                  );
                },
              );
            },
          );
        } else if (state is StaffError) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<StaffBloc>().add(const LoadStaff());
            },
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: Center(
                      child: Text(
                          '${AppLocalizations.of(context)!.error}: ${state.message}')),
                ),
              ),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, dynamic person) {
    ConfirmationDialog.show(
      context: context,
      title: AppLocalizations.of(context)!.delete,
      content:
          'Are you sure you want to delete this staff member?', // AppLocalizations.of(context)!.deletePersonConfirmation
      confirmText: AppLocalizations.of(context)!.delete,
      cancelText: AppLocalizations.of(context)!.cancel,
      isDestructive: true,
      onConfirm: () {
        context.read<StaffBloc>().add(DeleteStaff(person.id));
      },
    );
  }

  Widget _buildPersonCard(
    BuildContext context, {
    required String name,
    required String role,
    required String status,
    String? phone,
    String? email,
    required String imageUrl,
    VoidCallback? onTap,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    VoidCallback? onCall,
    VoidCallback? onToggleStatus,
    bool isStaff = false,
  }) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
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
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(imageUrl),
                backgroundColor: Colors.grey[200],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: isStaff ? Colors.blue : Colors.black54,
                        fontWeight:
                            isStaff ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                    if (isStaff) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Dept: General | ID: STF-${name.length * 100}',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    if (email != null && email.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.email_outlined,
                              size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              email,
                              style: GoogleFonts.montserrat(
                                  fontSize: 12, color: Colors.grey[600]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    if (phone != null && phone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              phone,
                              style: GoogleFonts.montserrat(
                                  fontSize: 12, color: Colors.grey[600]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: status.toLowerCase() == 'active'
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.montserrat(
                          color: status.toLowerCase() == 'active'
                              ? Colors.green
                              : Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (onCall != null)
                SizedBox(
                  height: 32,
                  width: 32,
                  child: IconButton(
                    icon: const Icon(Icons.phone, size: 20),
                    color: Colors.blue,
                    onPressed: onCall,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              AppEntityActionMenu(
                onView: onTap,
                onEdit: PermissionHelper.hasPermission(context, 'edit_staffs')
                    ? onEdit
                    : null,
                editLabel: AppLocalizations.of(context)!.edit,
                isActive: status.toLowerCase() == 'active' ||
                    status.toLowerCase() ==
                        AppLocalizations.of(context)!.active.toLowerCase(),
                onToggleStatus:
                    PermissionHelper.hasPermission(context, 'edit_staffs')
                        ? onToggleStatus
                        : null,
                onDelete:
                    PermissionHelper.hasPermission(context, 'delete_staffs')
                        ? onDelete
                        : null,
                deleteLabel: AppLocalizations.of(context)!.delete,
              ),
            ],
          ),
        ));
  }
}
