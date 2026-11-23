import 'dart:async';
import 'package:admin_mobile_app/core/theme/app_theme.dart';
import 'package:admin_mobile_app/l10n/app_localizations.dart';
import 'package:admin_mobile_app/presentation/blocs/tenant/tenant_payment_bloc.dart';
import 'package:admin_mobile_app/presentation/blocs/tenant/tenant_bloc.dart';
import 'package:admin_mobile_app/presentation/widgets/add_payment_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/permission_helper.dart';
import '../../blocs/payment/payment_bloc.dart' as global_payment;
import '../../../core/models/payment_model.dart';
import '../../../core/di/injection_container.dart'; // To access service locator getIt
import '../../../core/utils/excel_export_service.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/app_entity_action_menu.dart';
import '../../widgets/paginated_list_view.dart';

class TenantPaymentHistoryPage extends StatefulWidget {
  final String tenantId;
  final String tenantName;
  final String? leaseId;

  const TenantPaymentHistoryPage({
    super.key,
    required this.tenantId,
    required this.tenantName,
    this.leaseId,
  });

  @override
  State<TenantPaymentHistoryPage> createState() =>
      _TenantPaymentHistoryPageState();
}

class _TenantPaymentHistoryPageState extends State<TenantPaymentHistoryPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedLeaseId;

  @override
  void initState() {
    super.initState();
    _selectedLeaseId = widget.leaseId;
    _setDefaultDateRange();
    _loadPayments();
    context.read<TenantBloc>().add(GetTenantLeases(widget.tenantId));
  }

  void _setDefaultDateRange() {
    final now = DateTime.now();
    // Default to this month: 1st of month to end of month
    _startDate = DateTime(now.year, now.month, 1);
    // Next month's 1st day minus 1ms = end of this month
    _endDate = DateTime(now.year, now.month + 1, 1)
        .subtract(const Duration(milliseconds: 1));
  }

  void _loadPayments({
    bool isRefresh = false,
    bool isLoadMore = false,
    Completer<void>? completer,
  }) {
    context.read<TenantPaymentBloc>().add(
          LoadTenantPayments(
            tenantId: widget.tenantId,
            startDate: _startDate,
            endDate: _endDate,
            leaseId: _selectedLeaseId,
            isRefresh: isRefresh,
            isLoadMore: isLoadMore,
            completer: completer,
          ),
        );
  }

  void _resetFilters() {
    setState(() {
      _setDefaultDateRange();
      _selectedLeaseId = widget.leaseId;
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
    String? tempLeaseId = _selectedLeaseId;

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
                            tempLeaseId = widget.leaseId;
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
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _startDate = tempStart;
                        _endDate = tempEnd;
                        _selectedLeaseId = tempLeaseId;
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

  void _showAddPaymentDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddPaymentModal(tenantId: widget.tenantId),
    );

    if (result == true && mounted) {
      _loadPayments();
      // Also refresh the tenant details globally in the background
      context.read<TenantBloc>().add(GetTenantDetails(widget.tenantId));
      context.read<TenantBloc>().add(GetTenantLeases(widget.tenantId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.paymentHistory,
          style: GoogleFonts.montserrat(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          BlocBuilder<TenantPaymentBloc, TenantPaymentState>(
            builder: (context, state) {
              if (state is TenantPaymentsLoaded && state.payments.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.download_outlined,
                      color: Colors.black54),
                  tooltip: 'Export as Excel',
                  onPressed: () async {
                    try {
                      final headers = [
                        'Date',
                        'Amount',
                        'Payment Method',
                        'Recorded By',
                        'Transaction ID',
                        'Notes'
                      ];

                      final data = state.payments
                          .map((p) => [
                                DateFormat('yyyy-MM-dd').format(
                                    DateTime.parse(p['paymentDate']).toUtc()),
                                (p['amount'] as num? ?? 0).toDouble(),
                                (p['paymentMethod']?.toString() ?? 'cash')
                                    .toUpperCase(),
                                p['createdBy']?['name'] ?? 'Unknown',
                                p['transactionId'] ?? 'N/A',
                                p['notes'] ?? ''
                              ])
                          .toList();

                      await ExcelExportService.exportAndOpenFile(
                        fileName:
                            'Tenant_Payments_${widget.tenantName.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}',
                        sheetName: 'History',
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
              if (_startDate != null || _selectedLeaseId != null)
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
      body: BlocConsumer<TenantPaymentBloc, TenantPaymentState>(
        listener: (context, state) {
          if (state is TenantPaymentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return MultiBlocListener(
            listeners: [
              BlocListener<global_payment.PaymentBloc,
                  global_payment.PaymentState>(
                listener: (context, state) {
                  if (state is global_payment.PaymentLoaded) {
                    if (state.operationSuccess != null) {
                      _loadPayments();
                      context
                          .read<TenantBloc>()
                          .add(GetTenantDetails(widget.tenantId));
                    } else if (state.operationError != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.operationError!),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
            child: Builder(
              builder: (context) {
                if (state is TenantPaymentLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is TenantPaymentsLoaded) {
                  final payments = state.payments;

                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(32)),
                        ),
                        child: Column(
                          children: [
                            _buildTotalItem(
                              AppLocalizations.of(context)!.totalAmount,
                              state.totalAmount,
                              AppTheme.primaryBlue,
                              Icons.receipt_long_outlined,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child:
                                  Divider(height: 1, color: Color(0xFFF0F0F0)),
                            ),
                            _buildTotalItem(
                              AppLocalizations.of(context)!.remainingDue,
                              state.totalPending,
                              state.totalPending > 0
                                  ? Colors.redAccent
                                  : Colors.green,
                              Icons.pending_actions,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child:
                                  Divider(height: 1, color: Color(0xFFF0F0F0)),
                            ),
                            _buildTotalItem(
                              AppLocalizations.of(context)!.totalPaid,
                              state.totalPaid,
                              Colors.green,
                              Icons.check_circle_outline,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: PaginatedListView<dynamic>(
                          items: payments,
                          isLoadingInitial: false,
                          isLoadingMore: state.isLoadingMore,
                          hasReachedMax: state.hasReachedMax,
                          onRefresh: () async {
                            final completer = Completer<void>();
                            _loadPayments(
                                isRefresh: true, completer: completer);
                            return completer.future;
                          },
                          onLoadMore: () => _loadPayments(isLoadMore: true),
                          padding: const EdgeInsets.all(20),
                          emptyStateWidget: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history_outlined,
                                    size: 64, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text(
                                  AppLocalizations.of(context)!.noPaymentsFound,
                                  style: GoogleFonts.montserrat(
                                      color: Colors.grey[400],
                                      fontWeight: FontWeight.w500),
                                ),
                                if (_startDate != null ||
                                    _selectedLeaseId != null)
                                  TextButton(
                                    onPressed: _resetFilters,
                                    child: const Text('Clear Filters'),
                                  ),
                              ],
                            ),
                          ),
                          itemBuilder: (context, payment) {
                            return _buildPaymentCard(context, payment);
                          },
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox();
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPaymentDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(AppLocalizations.of(context)!.addPayment,
            style: GoogleFonts.montserrat(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryBlue,
        elevation: 4,
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, dynamic payment) {
    final amount = (payment['amount'] as num? ?? 0).toDouble();
    final date = DateTime.parse(payment['paymentDate']);
    final notes = payment['notes'] as String?;
    final createdBy = payment['createdBy']?['name'] ?? 'Unknown';
    final method = payment['paymentMethod']?.toString() ?? 'cash';
    final transactionId = payment['transactionId'] as String?;
    final isSecurityDeposit = method.toUpperCase() == 'SECURITY_DEPOSIT';

    final color = isSecurityDeposit ? Colors.indigo : AppTheme.primaryBlue;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isSecurityDeposit
            ? Border.all(
                color: Colors.indigo.withValues(alpha: 0.1), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSecurityDeposit) ...[
                      const Icon(Icons.shield_outlined,
                          size: 12, color: Colors.indigo),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      isSecurityDeposit
                          ? 'SECURITY DEPOSIT'
                          : method.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                NumberFormat.currency(symbol: 'QR ').format(amount),
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSecurityDeposit
                      ? Colors.indigo[700]
                      : Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 14, color: Colors.grey[400]),
              const SizedBox(width: 8),
              Text(
                DateFormat('MMM dd, yyyy').format(date.toUtc()),
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.history, size: 12, color: Colors.grey[400]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Recorded: ${DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.parse(payment['createdAt']).toLocal())}',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          if (transactionId != null && transactionId.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 14, color: Colors.blue[400]),
                const SizedBox(width: 8),
                Text(
                  'TXN: $transactionId',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ],
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              notes,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'By $createdBy',
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () async {
                      try {
                        final repo = getIt<PaymentRepository>();
                        final url = await repo.getReceiptUrl(payment['id']);
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
                                  content: Text('Could not open receipt')),
                            );
                          }
                        }
                      } catch (e) {
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
                    onEdit: PermissionHelper.hasPermission(
                            context, 'edit_payments')
                        ? () async {
                            final result = await showDialog<bool>(
                              context: context,
                              builder: (context) => AddPaymentModal(
                                payment: PaymentModel.fromJson(payment),
                              ),
                            );
                            if (result == true) {
                              _loadPayments();
                              if (!mounted) return;
                              context
                                  .read<TenantBloc>()
                                  .add(GetTenantDetails(widget.tenantId));
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
                                  'Are you sure you want to delete this payment (${payment['tenant']?['name'] ?? 'Payment'} - QR ${payment['amount']})?',
                              confirmText: AppLocalizations.of(context)!.delete,
                              cancelText: AppLocalizations.of(context)!.cancel,
                              isDestructive: true,
                              onConfirm: () {
                                context
                                    .read<global_payment.PaymentBloc>()
                                    .add(global_payment.DeletePayment(
                                        payment['id']));
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
        ],
      ),
    );
  }

  Widget _buildTotalItem(
      String label, double amount, Color color, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Text(
          NumberFormat.currency(symbol: 'QR ').format(amount),
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
