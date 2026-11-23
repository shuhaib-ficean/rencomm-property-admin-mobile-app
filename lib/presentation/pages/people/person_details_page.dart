import 'package:admin_mobile_app/core/constants/app_constants.dart';
import 'package:admin_mobile_app/l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:admin_mobile_app/core/models/tenant_model.dart';
import 'package:admin_mobile_app/core/models/user_model.dart';
import 'package:admin_mobile_app/presentation/blocs/tenant/tenant_bloc.dart';
import 'package:admin_mobile_app/presentation/blocs/staff/staff_bloc.dart';
import 'package:admin_mobile_app/presentation/blocs/role/role_bloc.dart';
import 'package:admin_mobile_app/presentation/widgets/confirmation_dialog.dart';
import 'package:admin_mobile_app/presentation/widgets/assign_property_modal.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:admin_mobile_app/core/routes/app_routes.dart';
import 'package:admin_mobile_app/presentation/pages/people/add_person_page.dart';
import 'package:admin_mobile_app/presentation/widgets/change_password_modal.dart';
import 'package:admin_mobile_app/presentation/widgets/lease_history_modal.dart';
import 'package:admin_mobile_app/core/theme/app_theme.dart';
import '../../../data/repositories/payment_repository.dart';
import 'package:admin_mobile_app/core/di/injection_container.dart'; // To access service locator getIt
import 'package:admin_mobile_app/presentation/widgets/add_payment_modal.dart';
import 'package:admin_mobile_app/presentation/widgets/add_amenity_modal.dart';
import 'package:admin_mobile_app/core/utils/permission_helper.dart';

class PersonDetailsPage extends StatefulWidget {
  const PersonDetailsPage({super.key});

  @override
  State<PersonDetailsPage> createState() => _PersonDetailsPageState();
}

class _PersonDetailsPageState extends State<PersonDetailsPage> {
  UserModel? _updatedStaff;
  int? _lastOperationTimestamp;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is UserModel) {
        context.read<StaffBloc>().add(GetStaffDetails(args.id));
      } else if (args is TenantModel) {
        context.read<TenantBloc>().add(GetTenantDetails(args.id));
      }
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Could not launch $launchUri';
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments;

    return BlocConsumer<StaffBloc, StaffState>(
      listener: (context, state) {
        if (state is StaffLoaded && state.currentStaffDetail != null) {
          setState(() {
            _updatedStaff = state.currentStaffDetail;
          });
        }
      },
      builder: (context, staffState) {
        return BlocBuilder<TenantBloc, TenantState>(
          builder: (context, tenantState) {
            return BlocBuilder<RoleBloc, RoleState>(
              builder: (context, roleState) {
                dynamic currentPerson = args;

                // Try to find updated tenant data if available
                if (args is TenantModel && tenantState is TenantLoaded) {
                  if (tenantState.currentTenantDetail != null &&
                      tenantState.currentTenantDetail!.id == args.id) {
                    currentPerson = tenantState.currentTenantDetail;
                  } else {
                    try {
                      final updatedTenant = tenantState.tenants.firstWhere(
                        (t) => t.id == args.id,
                        orElse: () => args,
                      );
                      currentPerson = updatedTenant;
                    } catch (_) {}
                  }
                }

                // Try to find updated staff data if available
                // Priority:
                // 1. _updatedStaff (fetched details)
                // 2. staffState (list update)
                // 3. args (initial param)
                if (_updatedStaff != null) {
                  currentPerson = _updatedStaff;
                } else if (args is UserModel && staffState is StaffLoaded) {
                  try {
                    final updatedStaff = staffState.staff.firstWhere(
                      (s) => s.id == args.id,
                      orElse: () => args,
                    );
                    currentPerson = updatedStaff;
                  } catch (_) {}
                }

                final String name;
                final String email;
                final String phone;
                String role;
                final String status;
                final String imageUrl;

                if (currentPerson is TenantModel) {
                  name = currentPerson.name;
                  email = currentPerson.email ?? '';
                  phone = currentPerson.phone;
                  role = AppConstants.tenant;
                  status = currentPerson.status;
                  imageUrl =
                      'https://www.gravatar.com/avatar/$email?d=https%3A%2F%2Fui-avatars.com%2Fapi%2F/$name/128';
                } else if (currentPerson is UserModel) {
                  name = currentPerson.name;
                  email = currentPerson.email;
                  phone = currentPerson.phone;
                  role = currentPerson.role;
                  if (currentPerson.roleId != null && roleState is RoleLoaded) {
                    try {
                      final found = roleState.roles.firstWhere(
                        (r) => r.id == currentPerson.roleId,
                      );
                      role = found.name;
                    } catch (_) {}
                  }
                  status = currentPerson.isActive
                      ? AppLocalizations.of(context)!.active
                      : AppLocalizations.of(context)!.inactive;
                  imageUrl =
                      'https://www.gravatar.com/avatar/$email?d=https%3A%2F%2Fui-avatars.com%2Fapi%2F/$name/128';
                } else {
                  return Scaffold(
                    appBar: AppBar(title: const Text('Error')),
                    body: const Center(child: Text('Invalid arguments')),
                  );
                }

                return MultiBlocListener(
                  listeners: [
                    BlocListener<TenantBloc, TenantState>(
                      listener: (context, state) {
                        if (state is TenantOperationSuccess) {
                          if (state.operation == TenantOperation.delete) {
                            Navigator.pop(context); // Go back after delete
                          }
                        } else if (state is TenantLoaded &&
                            state.operationSuccess != null) {
                          if (state.operationTimestamp !=
                              _lastOperationTimestamp) {
                            _lastOperationTimestamp = state.operationTimestamp;
                            if (state.lastOperation == TenantOperation.delete) {
                              Navigator.pop(context);
                            }
                          }
                        } else if (state is TenantLoaded &&
                            state.operationError != null) {
                          if (state.operationTimestamp !=
                              _lastOperationTimestamp) {
                            _lastOperationTimestamp = state.operationTimestamp;
                          }
                        } else if (state is TenantError) {
                          // Handled globally
                        }
                      },
                    ),
                    BlocListener<StaffBloc, StaffState>(
                      listener: (context, state) {
                        if (state is StaffOperationSuccess) {
                          if (state.type == StaffOperationType.delete) {
                            Navigator.pop(context); // Go back only after delete
                          }
                        } else if (state is StaffLoaded &&
                            state.operationSuccess != null) {
                          if (state.operationTimestamp !=
                              _lastOperationTimestamp) {
                            _lastOperationTimestamp = state.operationTimestamp;
                            if (state.lastOperationType ==
                                StaffOperationType.delete) {
                              Navigator.pop(context);
                            }
                          }
                        } else if (state is StaffLoaded &&
                            state.operationError != null) {
                          if (state.operationTimestamp !=
                              _lastOperationTimestamp) {
                            _lastOperationTimestamp = state.operationTimestamp;
                          }
                        } else if (state is StaffError) {
                          // Handled globally
                        }
                      },
                    ),
                  ],
                  child: Scaffold(
                    backgroundColor: Colors.grey[50],
                    appBar: AppBar(
                      title: Text(
                        currentPerson is UserModel
                            ? AppLocalizations.of(context)!.staffDetails
                            : AppLocalizations.of(context)!.tenantDetails,
                        style: GoogleFonts.montserrat(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: Colors.white,
                      elevation: 0,
                      iconTheme: const IconThemeData(color: Colors.black87),
                      actions: [
                        if (currentPerson is TenantModel) ...[
                          IconButton(
                            icon: const Icon(Icons.history),
                            tooltip: AppLocalizations.of(
                              context,
                            )!
                                .viewPaymentHistory,
                            onPressed: () async {
                              await Navigator.pushNamed(
                                context,
                                AppRoutes.tenantPaymentHistory,
                                arguments: {
                                  'tenantId': currentPerson.id,
                                  'tenantName': currentPerson.name,
                                },
                              );
                              if (context.mounted) {
                                context
                                    .read<TenantBloc>()
                                    .add(GetTenantDetails(currentPerson.id));
                                context
                                    .read<TenantBloc>()
                                    .add(GetTenantLeases(currentPerson.id));
                              }
                            },
                          ),
                        ],
                        if (currentPerson is TenantModel &&
                            PermissionHelper.hasPermission(
                                context, 'edit_tenants'))
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AddPersonPage(person: currentPerson),
                                ),
                              );
                            },
                          ),
                        if (currentPerson is UserModel &&
                            PermissionHelper.hasPermission(
                                context, 'edit_staffs'))
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AddPersonPage(person: currentPerson),
                                ),
                              );
                            },
                          ),
                        if (currentPerson is TenantModel &&
                            PermissionHelper.hasPermission(
                                context, 'delete_tenants'))
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              _showDeleteConfirmation(context, currentPerson);
                            },
                          ),
                        if (currentPerson is UserModel &&
                            PermissionHelper.hasPermission(
                                context, 'delete_staffs'))
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              _showDeleteConfirmation(context, currentPerson);
                            },
                          ),
                      ],
                    ),
                    body: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildHeader(context, name, role, status, imageUrl),
                          const SizedBox(height: 24),
                          _buildContactInfo(
                            context,
                            email,
                            phone,
                            qatarId: currentPerson is TenantModel ? currentPerson.qatarId : null,
                          ),
                          const SizedBox(height: 24),
                          if (currentPerson is TenantModel) ...[
                            _buildTenantSpecifics(context, currentPerson),
                            const SizedBox(height: 24),
                            _buildAmenitiesSection(context, currentPerson),
                            const SizedBox(height: 24),
                            _buildTenantDocumentsSection(
                              context,
                              currentPerson,
                            ),
                          ],
                          if (currentPerson is UserModel)
                            _buildStaffSpecifics(context, currentPerson),
                        ],
                      ),
                    ),
                    floatingActionButton: currentPerson is TenantModel
                        ? PermissionHelper.hasPermission(
                            context,
                            'add_payments',
                          )
                            ? FloatingActionButton.extended(
                                onPressed: () async {
                                  final result = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AddPaymentModal(
                                      tenantId: currentPerson.id,
                                    ),
                                  );

                                  if (result == true && context.mounted) {
                                    // Refresh tenant details and leases to reflect new payment/balance
                                    context.read<TenantBloc>().add(
                                        GetTenantDetails(currentPerson.id));
                                    context
                                        .read<TenantBloc>()
                                        .add(GetTenantLeases(currentPerson.id));
                                  }
                                },
                                icon: const Icon(Icons.payment,
                                    color: Colors.white),
                                label: Text(
                                  AppLocalizations.of(context)!.addPayment,
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                backgroundColor: AppTheme.primaryBlue,
                                elevation: 4,
                              )
                            : null
                        : null,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String name,
    String role,
    String status,
    String imageUrl,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
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
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(imageUrl),
            backgroundColor: Colors.grey[200],
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              role,
              style: GoogleFonts.montserrat(
                color: Colors.blue,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            status,
            style: GoogleFonts.montserrat(
              color:
                  status.toLowerCase() == 'active' ? Colors.green : Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(BuildContext context, String email, String phone, {String? qatarId}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.contactDetails,
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
          child: Column(
            children: [
              _buildInfoRow(Icons.email_outlined, 'Email', email),
              if (phone != 'N/A') ...[
                const Divider(height: 24),
                _buildInfoRow(
                  Icons.phone_outlined,
                  'Phone',
                  null,
                  customValueWidget: Row(
                    children: [
                      Expanded(
                        child: Text(
                          phone,
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (phone != 'N/A')
                        SizedBox(
                          height: 32,
                          width: 32,
                          child: IconButton(
                            icon: const Icon(Icons.phone, size: 20),
                            color: Colors.green,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _makePhoneCall(phone),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (qatarId != null && qatarId.isNotEmpty) ...[
                const Divider(height: 24),
                _buildInfoRow(Icons.badge_outlined, 'Qatar ID (QID)', qatarId),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTenantDocumentsSection(
    BuildContext context,
    TenantModel tenant,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.documents,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (PermissionHelper.hasPermission(context, 'edit_tenants'))
              OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.pushNamed(
                    context,
                    AppRoutes.tenantDocuments,
                    arguments: tenant,
                  );
                  if (context.mounted) {
                    context.read<TenantBloc>().add(const LoadTenants());
                  }
                },
                icon: const Icon(Icons.edit_document, size: 18),
                label: Text(l10n.updateDocuments),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDocumentCategory(
                context,
                l10n.passportFront,
                tenant.passportFrontImages,
              ),
              const Divider(height: 24),
              _buildDocumentCategory(
                context,
                l10n.passportBack,
                tenant.passportBackImages,
              ),
              const Divider(height: 24),
              _buildDocumentCategory(
                context,
                l10n.qatarId,
                tenant.qatarIdImages,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentCategory(
    BuildContext context,
    String title,
    List<String>? images,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (images == null || images.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.noDocuments,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final rawItem = images[index];
              final item = (!rawItem.startsWith('http')) ? rawItem : rawItem;
              return _buildDocumentThumbnail(context, item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentThumbnail(BuildContext context, String url) {
    return GestureDetector(
      onTap: () => _viewDocument(context, url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 80,
          height: 80,
          color: Colors.grey[100],
          child: _buildThumbnailImage(url),
        ),
      ),
    );
  }

  Widget _buildThumbnailImage(String url) {
    if (url.toLowerCase().endsWith('.pdf')) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.picture_as_pdf, color: Colors.red, size: 30),
            SizedBox(height: 4),
            Text(
              'PDF',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(color: Colors.grey[200]),
      errorWidget: (context, url, error) => const Icon(Icons.error),
    );
  }

  Future<void> _viewDocument(BuildContext context, String url) async {
    if (url.toLowerCase().endsWith('.pdf')) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.couldNotLaunchPDF),
            ),
          );
        }
      }
    } else {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          child: InteractiveViewer(
            child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
          ),
        ),
      );
    }
  }

  Widget _buildTenantSpecifics(BuildContext context, TenantModel tenant) {
    final bool isAssigned =
        tenant.property != null && tenant.assignedRoom != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.rentalDetails,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => LeaseHistoryModal(tenant: tenant),
                );
                if (context.mounted) {
                  context.read<TenantBloc>().add(GetTenantDetails(tenant.id));
                  context.read<TenantBloc>().add(GetTenantLeases(tenant.id));
                }
              },
              icon: const Icon(Icons.history, size: 20),
              label: Text(
                AppLocalizations.of(context)!.leaseHistory,
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
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
          child: Column(
            children: [
              if (!isAssigned) ...[
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Colors.orange[800],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.noActiveLease,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
              ],
              _buildInfoRow(
                Icons.home_work_outlined,
                AppLocalizations.of(context)!.property,
                null,
                customValueWidget: (PermissionHelper.hasPermission(
                        context, 'edit_tenants'))
                    ? isAssigned
                        ? Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${tenant.property?.name} - ${tenant.assignedRoom?.number}',
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                onPressed: () {
                                  ConfirmationDialog.show(
                                    context: context,
                                    title:
                                        AppLocalizations.of(context)!.unassign,
                                    content: AppLocalizations.of(
                                      context,
                                    )!
                                        .unassignConfirmation,
                                    confirmText: AppLocalizations.of(
                                      context,
                                    )!
                                        .unassign,
                                    cancelText: AppLocalizations.of(
                                      context,
                                    )!
                                        .cancel,
                                    isDestructive: true,
                                    onConfirm: () {
                                      context.read<TenantBloc>().add(
                                            UnassignRoom(
                                              tenant.id,
                                              tenant.assignedRoom!.id,
                                              tenant.property!.id,
                                            ),
                                          );
                                    },
                                  );
                                },
                              ),
                            ],
                          )
                        : OutlinedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) =>
                                    AssignPropertyModal(tenantId: tenant.id),
                              );
                            },
                            icon: const Icon(Icons.add_link, size: 18),
                            label: Text(AppLocalizations.of(context)!.assign),
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              side: BorderSide(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          )
                    : const SizedBox.shrink(),
              ),
              if (isAssigned) ...[
                const Divider(height: 24),
                _buildInfoRow(
                  Icons.date_range_outlined,
                  'Current Lease',
                  null,
                  customValueWidget: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${DateFormat('MMM d, yyyy').format(tenant.contractStartDate)} - ${tenant.contractEndDate != null ? DateFormat('MMM d, yyyy').format(tenant.contractEndDate!) : 'Ongoing'}',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Active',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  Icons.money,
                  AppLocalizations.of(context)!.rentAmount,
                  '${NumberFormat.currency(symbol: 'QR ').format(tenant.rentAmount)} / ${AppLocalizations.of(context)!.month}',
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  Icons.security,
                  AppLocalizations.of(context)!.securityDeposit,
                  NumberFormat.currency(symbol: 'QR ')
                      .format(tenant.securityDeposit),
                  customValueWidget: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        NumberFormat.currency(symbol: 'QR ')
                            .format(tenant.securityDeposit),
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      if (tenant.securityDepositPaymentId != null)
                        IconButton(
                          onPressed: () async {
                            try {
                              final repo = getIt<PaymentRepository>();
                              final url = await repo.getReceiptUrl(
                                  tenant.securityDepositPaymentId!);
                              final uri = Uri.parse(url);
                              if (await canLaunchUrl(uri)) {
                                try {
                                  await launchUrl(uri,
                                      mode: LaunchMode.externalApplication);
                                } catch (e) {
                                  await launchUrl(uri,
                                      mode: LaunchMode.inAppBrowserView);
                                }
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Could not open receipt'),
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Error generating receipt')),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.download,
                              size: 20, color: AppTheme.primaryBlue),
                          tooltip: 'Download Receipt',
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                ),
              ],
              if (tenant.financials != null) ...[
                const Divider(height: 24),
                _buildInfoRow(
                  Icons.receipt_long_outlined,
                  AppLocalizations.of(context)!.totalAmount,
                  NumberFormat.currency(symbol: 'QR ')
                      .format(tenant.totalAmount),
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  Icons.check_circle_outline,
                  AppLocalizations.of(context)!.totalPaid,
                  NumberFormat.currency(symbol: 'QR ').format(tenant.totalPaid),
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  Icons.pending_actions,
                  AppLocalizations.of(context)!.remainingDue,
                  NumberFormat.currency(symbol: 'QR ')
                      .format(tenant.totalPending),
                  customValueWidget: Text(
                    NumberFormat.currency(symbol: 'QR ')
                        .format(tenant.totalPending),
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      color: tenant.totalPending > 0
                          ? Colors.redAccent
                          : Colors.green,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmenitiesSection(BuildContext context, TenantModel tenant) {
    final amenities = tenant.amenities ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Amenities Log',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (PermissionHelper.hasPermission(context, 'add_amenities'))
              OutlinedButton.icon(
                onPressed: () {
                  final tenantBloc = context.read<TenantBloc>();
                  showDialog(
                    context: context,
                    builder: (_) => BlocProvider.value(
                      value: tenantBloc,
                      child: AddAmenityModal(tenant: tenant),
                    ),
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
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
          child: amenities.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No amenities logged',
                      style: GoogleFonts.montserrat(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: amenities.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final amenity = amenities[index];
                    final date =
                        DateTime.tryParse(amenity.providedAt.toString());
                    final formattedDate = date != null
                        ? DateFormat('dd MMM yyyy').format(date.toLocal())
                        : 'Unknown date';

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                amenity.description,
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Provided: $formattedDate',
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (PermissionHelper.hasPermission(
                                context, 'edit_amenities'))
                              IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    color: AppTheme.primaryBlue),
                                tooltip: 'Edit Amenity',
                                onPressed: () {
                                  final tenantBloc = context.read<TenantBloc>();
                                  showDialog(
                                    context: context,
                                    builder: (_) => BlocProvider.value(
                                      value: tenantBloc,
                                      child: AddAmenityModal(
                                        tenant: tenant,
                                        amenity: amenity,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            if (PermissionHelper.hasPermission(
                                context, 'delete_amenities'))
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                tooltip: 'Delete Amenity',
                                onPressed: () {
                                  ConfirmationDialog.show(
                                    context: context,
                                    title: 'Delete Amenity',
                                    content:
                                        'Are you sure you want to remove this amenity from the log?',
                                    confirmText: 'Delete',
                                    cancelText:
                                        AppLocalizations.of(context)!.cancel,
                                    isDestructive: true,
                                    onConfirm: () {
                                      context.read<TenantBloc>().add(
                                            DeleteTenantAmenity(
                                              tenantId: tenant.id,
                                              amenityId: amenity.id,
                                            ),
                                          );
                                    },
                                  );
                                },
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStaffSpecifics(BuildContext context, UserModel staff) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.employmentDetails,
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
          child: Column(
            children: [
              _buildInfoRow(
                Icons.badge_outlined,
                AppLocalizations.of(context)!.employeeId,
                staff.employeeId ?? 'N/A',
              ),
              const Divider(height: 24),
              if (PermissionHelper.hasPermission(context, 'change_password'))
                _buildInfoRow(
                  Icons.lock_outline,
                  AppLocalizations.of(context)!.password,
                  null,
                  customValueWidget: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _showChangePasswordDialog(context, staff.id),
                          icon: const Icon(Icons.lock_reset, size: 18),
                          label: Text(
                            AppLocalizations.of(context)!.changePassword,
                          ),
                          style: OutlinedButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            side: BorderSide(color: Colors.grey[300]!),
                            foregroundColor: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, dynamic person) {
    ConfirmationDialog.show(
      context: context,
      title: AppLocalizations.of(context)!.delete,
      content: AppLocalizations.of(context)!.deletePersonConfirmation,
      confirmText: AppLocalizations.of(context)!.delete,
      cancelText: AppLocalizations.of(context)!.cancel,
      isDestructive: true,
      onConfirm: () {
        if (person is TenantModel) {
          context.read<TenantBloc>().add(DeleteTenant(person.id));
        } else if (person is UserModel) {
          context.read<StaffBloc>().add(DeleteStaff(person.id));
        }
      },
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String? value, {
    Widget? customValueWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (customValueWidget != null)
                  customValueWidget
                else
                  Text(
                    value ?? '',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, String staffId) {
    showDialog(
      context: context,
      builder: (context) => ChangePasswordModal(staffId: staffId),
    );
  }
}
