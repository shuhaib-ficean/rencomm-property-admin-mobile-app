import 'dart:async';
import 'package:admin_mobile_app/core/utils/permission_helper.dart';
import 'package:admin_mobile_app/l10n/app_localizations.dart';
import 'package:admin_mobile_app/utils/debug_utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../widgets/searchable_dropdown.dart';
import 'package:intl/intl.dart';
import '../../blocs/payment/payment_bloc.dart';
import '../../blocs/property/property_bloc.dart';
import '../../blocs/tenant/tenant_bloc.dart';
import '../../blocs/staff/staff_bloc.dart';
import '../../../core/models/payment_model.dart';
import '../../../core/theme/app_theme.dart';
import 'package:admin_mobile_app/presentation/widgets/add_payment_modal.dart';
import '../../widgets/app_entity_action_menu.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/paginated_list_view.dart';
import '../../../data/repositories/payment_repository.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/di/injection_container.dart'; // To access service locator getIt
import '../../../core/utils/excel_export_service.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedPropertyId;
  String? _selectedTenantId;
  String? _selectedStaffId;
  String? _selectedLeaseId;
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _setDefaultDateRange();
    _loadPayments();
    context.read<PropertyBloc>().add(const LoadProperties());
    context.read<TenantBloc>().add(const LoadTenants(limit: 100));
    context.read<StaffBloc>().add(const LoadStaff(limit: 100));
  }

  void _setDefaultDateRange() {
    _startDate = null;
    _endDate = null;
  }

  void _loadPayments({
    bool isRefresh = false,
    bool isLoadMore = false,
    Completer<void>? completer,
  }) {
    context.read<PaymentBloc>().add(LoadPayments(
          isRefresh: isRefresh,
          isLoadMore: isLoadMore,
          startDate: _startDate?.toUtc().toIso8601String(),
          endDate: _endDate?.toUtc().toIso8601String(),
          propertyId: _selectedPropertyId,
          tenantId: _selectedTenantId,
          leaseId: _selectedLeaseId,
          receivedBy: _selectedStaffId,
          type: _selectedType,
          completer: completer,
        ));
  }

  void _resetFilters() {
    setState(() {
      _setDefaultDateRange();
      _selectedPropertyId = null;
      _selectedTenantId = null;
      _selectedStaffId = null;
      _selectedLeaseId = null;
      _selectedType = null;
    });
    _loadPayments();
  }

  Future<DateTimeRange?> _pickDateRange(DateTime? start, DateTime? end) async {
    return await showDateRangePicker(
      context: context,
      initialDateRange: start != null && end != null
          ? DateTimeRange(start: start, end: end)
          : null,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: AppTheme.lightTheme.copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryBlue,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  void _showFilterSheet() {
    DateTime? tempStart = _startDate;
    DateTime? tempEnd = _endDate;
    String? tempProp = _selectedPropertyId;
    String? tempTenant = _selectedTenantId;
    String? tempStaff = _selectedStaffId;
    String? tempType = _selectedType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (modalContext, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
              top: 12,
              left: 24,
              right: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filters',
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            final now = DateTime.now();
                            final daysSinceMonday = now.weekday - 1;
                            tempStart = DateTime(
                                now.year, now.month, now.day - daysSinceMonday);
                            final daysUntilSunday = 7 - now.weekday;
                            tempEnd = DateTime(now.year, now.month,
                                now.day + daysUntilSunday, 23, 59, 59, 999);
                            tempProp = null;
                            tempTenant = null;
                            tempStaff = null;
                            tempType = null;
                          });
                        },
                        child: Text(
                          'Reset All',
                          style: GoogleFonts.montserrat(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Date Range Picker
                  InkWell(
                    onTap: () async {
                      final picked = await _pickDateRange(tempStart, tempEnd);
                      if (picked != null) {
                        setModalState(() {
                          tempStart = picked.start;
                          tempEnd = picked.end;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 20, color: AppTheme.primaryBlue),
                          const SizedBox(width: 12),
                          Text(
                            tempStart != null && tempEnd != null
                                ? '${DateFormat('MMM dd').format(tempStart!)} - ${DateFormat('MMM dd, yyyy').format(tempEnd!)}'
                                : 'Select Date Range',
                            style: GoogleFonts.montserrat(
                              color: tempStart != null
                                  ? Colors.black87
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Property searchable dropdown
                  BlocBuilder<PropertyBloc, PropertyState>(
                    builder: (propContext, propState) {
                      final Map<String?, String> propertyItems = {
                        null: 'All Properties',
                      };
                      if (propState is PropertyLoaded) {
                        for (final p in propState.properties) {
                          propertyItems[p.id] = p.name;
                        }
                      }
                      return SearchableDropdown<String>(
                        value: tempProp,
                        label: 'Property',
                        hint: 'Select Property',
                        prefixIcon: Icons.business_outlined,
                        items: propertyItems,
                        onChanged: (value) {
                          setModalState(() {
                            tempProp = value;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Tenant searchable dropdown
                  BlocBuilder<TenantBloc, TenantState>(
                    builder: (tenantContext, tenantState) {
                      final Map<String?, String> tenantItems = {
                        null: 'All Tenants',
                      };
                      if (tenantState is TenantLoaded) {
                        for (final t in tenantState.tenants) {
                          tenantItems[t.id] = t.name;
                        }
                      }
                      return SearchableDropdown<String>(
                        value: tempTenant,
                        label: 'Tenant',
                        hint: 'Select Tenant',
                        prefixIcon: Icons.person_outline,
                        items: tenantItems,
                        onChanged: (value) {
                          setModalState(() {
                            tempTenant = value;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Staff searchable dropdown
                  BlocBuilder<StaffBloc, StaffState>(
                    builder: (staffContext, staffState) {
                      final Map<String?, String> staffItems = {
                        null: 'All Staff',
                      };
                      if (staffState is StaffLoaded) {
                        for (final s in staffState.staff) {
                          staffItems[s.id] = s.name;
                        }
                      }
                      return SearchableDropdown<String>(
                        value: tempStaff,
                        label: 'Received By (Staff)',
                        hint: 'Select Staff',
                        prefixIcon: Icons.badge_outlined,
                        items: staffItems,
                        onChanged: (value) {
                          setModalState(() {
                            tempStaff = value;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Payment Type Selector
                  SearchableDropdown<String>(
                    value: tempType,
                    label: 'Payment Category',
                    hint: 'All Payments',
                    prefixIcon: Icons.category_outlined,
                    items: const {
                      null: 'All Payments',
                      'rent': 'Rent Only',
                      'deposit': 'Security Deposit Only',
                    },
                    onChanged: (value) {
                      setModalState(() {
                        tempType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _startDate = tempStart;
                        _endDate = tempEnd;
                        _selectedPropertyId = tempProp;
                        _selectedTenantId = tempTenant;
                        _selectedStaffId = tempStaff;
                        _selectedLeaseId = null;
                        _selectedType = tempType;
                      });
                      _loadPayments();
                      Navigator.pop(modalContext);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Apply Filters',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.payments,
            style: GoogleFonts.montserrat(
                color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          BlocBuilder<PaymentBloc, PaymentState>(
            builder: (context, state) {
              if (state is PaymentLoaded && state.payments.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.download_outlined,
                      color: Colors.black54),
                  tooltip: 'Export as Excel',
                  onPressed: () async {
                    try {
                      final headers = [
                        'Date',
                        'Tenant Name',
                        'Property',
                        'Amount',
                        'Payment Method',
                        'Recorded By',
                        'Transaction ID',
                        'Notes'
                      ];

                      final data = state.payments
                          .map((p) => [
                                DateFormat('yyyy-MM-dd')
                                    .format(p.paymentDate.toUtc()),
                                p.tenantName ?? 'Unknown',
                                p.propertyName ?? 'N/A',
                                p.amount,
                                p.paymentMethod.toUpperCase(),
                                p.createdByName ?? 'Unknown',
                                p.transactionId ?? 'N/A',
                                p.notes ?? ''
                              ])
                          .toList();

                      await ExcelExportService.exportAndOpenFile(
                        fileName:
                            'Payments_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}',
                        sheetName: 'Payments',
                        headers: headers,
                        data: data,
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to export Excel: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list, color: Colors.black54),
                onPressed: _showFilterSheet,
              ),
              if (_startDate != null ||
                  _selectedPropertyId != null ||
                  _selectedTenantId != null ||
                  _selectedStaffId != null)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: BlocListener<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentLoaded) {
            if (state.operationError != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.operationError!),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state.operationSuccess != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.operationSuccess!)),
              );
            }
          } else if (state is PaymentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<PaymentBloc, PaymentState>(
          builder: (context, state) {
            if (state is PaymentLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is PaymentLoaded) {
              if (state.payments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payments_outlined,
                          size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.noPaymentsFound,
                        style: GoogleFonts.montserrat(
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                            fontSize: 14),
                      ),
                      if (_startDate != null ||
                          _selectedPropertyId != null ||
                          _selectedTenantId != null ||
                          _selectedStaffId != null)
                        TextButton(
                          onPressed: _resetFilters,
                          child: const Text('Clear Filters'),
                        ),
                    ],
                  ),
                );
              }
              return PaginatedListView<PaymentModel>(
                items: state.payments,
                isLoadingInitial: false,
                isLoadingMore: state.isLoadingMore,
                hasReachedMax: state.hasReachedMax,
                onRefresh: () async {
                  final completer = Completer<void>();
                  _loadPayments(isRefresh: true, completer: completer);
                  return completer.future;
                },
                onLoadMore: () => _loadPayments(isLoadMore: true),
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, payment) {
                  return _buildPaymentCard(context, payment);
                },
              );
            } else if (state is PaymentError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.redAccent, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        '${AppLocalizations.of(context)!.error}: ${state.message}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(color: Colors.black87),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPayments,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
      floatingActionButton:
          PermissionHelper.hasPermission(context, 'add_payments')
              ? FloatingActionButton(
                  onPressed: () async {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (context) => const AddPaymentModal(),
                    );
                    if (result == true) {
                      _loadPayments(isRefresh: true);
                    }
                  },
                  backgroundColor: AppTheme.primaryBlue,
                  elevation: 4,
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : const SizedBox.shrink(),
    );
  }

  Widget _buildPaymentCard(BuildContext context, PaymentModel payment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.tenantName ??
                          AppLocalizations.of(context)!.unknownTenant,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: AppTheme.primaryBlue),
                        const SizedBox(width: 4),
                        Text(
                          payment.propertyName ?? 'N/A',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  NumberFormat.currency(symbol: 'QR ').format(payment.amount),
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('MMM dd, yyyy')
                              .format(payment.paymentDate.toUtc()),
                          style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: Colors.black87,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.history, size: 13, color: Colors.grey[400]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Recorded: ${DateFormat('MMM dd, yyyy, hh:mm a').format(payment.createdAt.toLocal())}',
                            style: GoogleFonts.montserrat(
                                fontSize: 10,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    if (payment.createdByName != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 13, color: Colors.grey[400]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Collected by: ${payment.createdByName}',
                              style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (payment.transactionId != null &&
                        payment.transactionId!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 13, color: Colors.blue[400]),
                          const SizedBox(width: 6),
                          Text(
                            'TXN: ${payment.transactionId}',
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: payment.isSecurityDeposit
                          ? Colors.amber.withValues(alpha: 0.15)
                          : Colors.teal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          payment.isSecurityDeposit
                              ? Icons.security
                              : Icons.receipt_long,
                          size: 11,
                          color: payment.isSecurityDeposit
                              ? Colors.amber[900]
                              : Colors.teal[800],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          payment.isSecurityDeposit ? 'DEPOSIT' : 'RENT',
                          style: GoogleFonts.montserrat(
                            color: payment.isSecurityDeposit
                                ? Colors.amber[900]
                                : Colors.teal[800],
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      payment.paymentMethod.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        color: Colors.blue[700],
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () async {
                  try {
                    final repo = getIt<PaymentRepository>();
                    final url = await repo.getReceiptUrl(payment.id);
                    consoleLog(url);
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      try {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      } catch (e) {
                        // Fallback if no external PDF viewer exists
                        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Could not open receipt')),
                        );
                      }
                    }
                  } catch (e) {
                    consoleLog(e);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Error generating receipt')),
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
              AppEntityActionMenu(
                onEdit: PermissionHelper.hasPermission(context, 'edit_payments')
                    ? () async {
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (context) =>
                              AddPaymentModal(payment: payment),
                        );
                        if (result == true) {
                          _loadPayments();
                        }
                      }
                    : null,
                editLabel: AppLocalizations.of(context)!.edit,
                onDelete: PermissionHelper.hasPermission(
                        context, 'delete_payments')
                    ? () {
                        ConfirmationDialog.show(
                          context: context,
                          title: AppLocalizations.of(context)!.delete,
                          content:
                              'Are you sure you want to permanently delete this payment (${payment.tenantName ?? 'Payment'} - QR ${payment.amount})?',
                          confirmText: AppLocalizations.of(context)!.delete,
                          cancelText: AppLocalizations.of(context)!.cancel,
                          isDestructive: true,
                          onConfirm: () {
                            context
                                .read<PaymentBloc>()
                                .add(DeletePayment(payment.id));
                          },
                        );
                      }
                    : null,
                deleteLabel: AppLocalizations.of(context)!.delete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
