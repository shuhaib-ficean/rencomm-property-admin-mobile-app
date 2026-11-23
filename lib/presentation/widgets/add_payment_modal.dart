import 'package:admin_mobile_app/core/theme/app_theme.dart';
import 'package:admin_mobile_app/l10n/app_localizations.dart';
import 'package:admin_mobile_app/presentation/blocs/tenant/tenant_payment_bloc.dart';
import 'package:admin_mobile_app/presentation/blocs/tenant/tenant_bloc.dart';
import 'package:admin_mobile_app/presentation/blocs/property/property_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'searchable_dropdown.dart';
import 'package:intl/intl.dart';

import 'package:admin_mobile_app/core/models/payment_model.dart';
import 'package:admin_mobile_app/presentation/blocs/payment/payment_bloc.dart'
    as global_payment;
import 'package:admin_mobile_app/presentation/blocs/analytics/analytics_bloc.dart';

class AddPaymentModal extends StatefulWidget {
  final String? tenantId;
  final PaymentModel? payment;

  const AddPaymentModal({super.key, this.tenantId, this.payment});

  @override
  State<AddPaymentModal> createState() => _AddPaymentModalState();
}

class _AddPaymentModalState extends State<AddPaymentModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _transactionIdController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedTenantId;
  String? _selectedPropertyId;
  String _paymentMethod = 'Cash';
  bool _isSecurityDeposit = false;

  @override
  void initState() {
    super.initState();
    if (widget.payment != null) {
      _selectedTenantId = widget.payment!.tenantId;
      _amountController.text = widget.payment!.amount.toString();
      _notesController.text = widget.payment!.notes ?? '';
      _transactionIdController.text = widget.payment!.transactionId ?? '';
      _selectedDate = widget.payment!.paymentDate;
      _paymentMethod = widget.payment!.paymentMethod[0].toUpperCase() +
          widget.payment!.paymentMethod.substring(1).toLowerCase();
      // Check if it's already a bank transfer
      if (_paymentMethod.toLowerCase().contains('bank')) {
        _paymentMethod = 'Bank Transfer';
      } else {
        _paymentMethod = 'Cash';
      }
      _isSecurityDeposit = widget.payment!.isSecurityDeposit;
    } else {
      _selectedTenantId = widget.tenantId;
    }

    if (_selectedTenantId != null) {
      context.read<TenantBloc>().add(GetTenantLeases(_selectedTenantId!));
      context.read<TenantBloc>().add(GetTenantDetails(_selectedTenantId!));
    } else {
      // Load tenants (all) initially so list is ready
      context.read<TenantBloc>().add(const LoadTenants());
    }
    // Ensure properties are loaded for the picker
    context.read<PropertyBloc>().add(const LoadProperties());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _transactionIdController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: AppTheme.lightTheme.copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<TenantPaymentBloc, TenantPaymentState>(
          listener: (context, state) {
            // Only handle Add logic here if we are indeed adding (not editing)
            if (widget.payment == null &&
                state is TenantPaymentOperationSuccess) {
              // Refresh Dashboard
              context.read<AnalyticsBloc>().add(const LoadAnalyticsOverview());

              if (Navigator.canPop(context)) {
                Navigator.of(context).pop(true);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.green),
              );
            } else if (state is TenantPaymentError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(state.message), backgroundColor: Colors.red),
              );
            }
          },
        ),
        BlocListener<global_payment.PaymentBloc, global_payment.PaymentState>(
          listener: (context, state) {
            // Only handle Edit logic here if we are indeed editing
            if (widget.payment != null) {
              if (state is global_payment.PaymentOperationSuccess) {
                // Refresh Dashboard
                context
                    .read<AnalyticsBloc>()
                    .add(const LoadAnalyticsOverview());

                if (Navigator.canPop(context)) {
                  Navigator.of(context).pop(true);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.green),
                );
              } else if (state is global_payment.PaymentLoaded &&
                  state.operationSuccess != null) {
                // Refresh Dashboard
                context
                    .read<AnalyticsBloc>()
                    .add(const LoadAnalyticsOverview());

                if (Navigator.canPop(context)) {
                  Navigator.of(context).pop(true);
                }
              } else if (state is global_payment.PaymentError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red),
                );
              }
            }
          },
        ),
      ],
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.payment != null
                        ? AppLocalizations.of(context)!.edit
                        : AppLocalizations.of(context)!.addPayment,
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Property + Tenant Selectors (only if tenantId not pre-set)
                  if (widget.tenantId == null) ...[
                    // Step 1: Property selector
                    BlocBuilder<PropertyBloc, PropertyState>(
                      builder: (context, propertyState) {
                        final Map<String?, String> propertyItems = {
                          null: 'Select Property',
                        };
                        if (propertyState is PropertyLoaded) {
                          for (final p in propertyState.properties) {
                            propertyItems[p.id] = p.name;
                          }
                        }
                        return SearchableDropdown<String>(
                          value: _selectedPropertyId,
                          label: 'Property',
                          hint: 'Select Property',
                          prefixIcon: Icons.business_outlined,
                          items: propertyItems,
                          onChanged: (value) {
                            setState(() {
                              _selectedPropertyId = value;
                              _selectedTenantId = null; // reset tenant
                            });
                            // Re-load tenants filtered by this property
                            context.read<TenantBloc>().add(
                                  LoadTenants(propertyId: value),
                                );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Step 2: Tenant selector (only after property is chosen)
                    if (_selectedPropertyId != null)
                      BlocBuilder<TenantBloc, TenantState>(
                        builder: (context, state) {
                          final bool isLoading = state is TenantLoading;
                          return SearchableDropdown<String>(
                            value: _selectedTenantId,
                            label: AppLocalizations.of(context)!.tenant,
                            hint: isLoading
                                ? 'Loading tenants…'
                                : AppLocalizations.of(context)!.tenant,
                            prefixIcon: Icons.person_outline,
                            items: (state is TenantLoaded)
                                ? {
                                    null: state.tenants.isEmpty
                                        ? 'No tenants in this property'
                                        : 'Select Tenant',
                                    for (var t in state.tenants) t.id: t.name
                                  }
                                : {null: 'Loading…'},
                            onChanged: (value) {
                              setState(() {
                                _selectedTenantId = value;
                              });
                              if (value != null) {
                                context
                                    .read<TenantBloc>()
                                    .add(GetTenantLeases(value));
                                context
                                    .read<TenantBloc>()
                                    .add(GetTenantDetails(value));
                              }
                            },
                          );
                        },
                      ),
                    if (_selectedPropertyId != null) const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'Amount (QR)',
                      prefixIcon: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: AppTheme.primaryBlue),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.montserrat(
                        fontSize: 16, fontWeight: FontWeight.w600),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter amount';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  // Payment Method Selector
                  DropdownButtonFormField<String>(
                    initialValue: _paymentMethod,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Payment Method',
                      prefixIcon: const Icon(Icons.payment_outlined,
                          color: AppTheme.primaryBlue),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    items: [
                      'Cash',
                      'Bank Transfer',
                    ]
                        .map((method) => DropdownMenuItem(
                              value: method,
                              child:
                                  Text(method, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _paymentMethod = value!;
                      });
                    },
                  ),
                  if (_paymentMethod.toLowerCase() == 'bank transfer') ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _transactionIdController,
                      decoration: InputDecoration(
                        labelText: 'Transaction ID',
                        prefixIcon: const Icon(Icons.receipt_long_outlined,
                            color: AppTheme.primaryBlue),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      style: GoogleFonts.montserrat(fontSize: 14),
                      validator: (value) {
                        if (_paymentMethod.toLowerCase() == 'bank transfer' &&
                            (value == null || value.isEmpty)) {
                          return 'Please enter transaction ID';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Type',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _isSecurityDeposit = false;
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: !_isSecurityDeposit
                                        ? AppTheme.primaryBlue
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: !_isSecurityDeposit
                                          ? AppTheme.primaryBlue
                                          : Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.home_outlined,
                                        size: 15,
                                        color: !_isSecurityDeposit
                                            ? Colors.white
                                            : Colors.grey[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          'Rent Payment',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.montserrat(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: !_isSecurityDeposit
                                                ? Colors.white
                                                : Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _isSecurityDeposit = true;
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: _isSecurityDeposit
                                        ? Colors.amber[800]
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _isSecurityDeposit
                                          ? Colors.amber[800]!
                                          : Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.security,
                                        size: 15,
                                        color: _isSecurityDeposit
                                            ? Colors.white
                                            : Colors.grey[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          'Security Deposit',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.montserrat(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: _isSecurityDeposit
                                                ? Colors.white
                                                : Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Payment Date',
                        prefixIcon: const Icon(Icons.calendar_today_outlined,
                            color: AppTheme.primaryBlue),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      child: Text(
                        DateFormat('MMM dd, yyyy').format(_selectedDate),
                        style: GoogleFonts.montserrat(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.notesOptional,
                      prefixIcon: const Icon(Icons.note_alt_outlined,
                          color: AppTheme.primaryBlue),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    maxLines: 2,
                    style: GoogleFonts.montserrat(fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.cancel,
                            style: GoogleFonts.montserrat(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child:
                            BlocBuilder<TenantPaymentBloc, TenantPaymentState>(
                          builder: (context, state) {
                            final isLoading = state is TenantPaymentLoading;
                            return ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      if (_formKey.currentState!.validate() &&
                                          _selectedTenantId != null) {
                                        num? pendingAmount;
                                        final tenantState =
                                            context.read<TenantBloc>().state;
                                        if (tenantState is TenantLoaded &&
                                            tenantState.currentTenantDetail !=
                                                null) {
                                          pendingAmount = tenantState
                                              .currentTenantDetail!
                                              .totalPending;
                                        }

                                        final double amount = double.parse(
                                            _amountController.text);

                                        Future<void> proceedWithSave() async {
                                          final paymentData = {
                                            'tenantId': _selectedTenantId!,
                                            'amount': amount,
                                            'paymentDate':
                                                _selectedDate.toIso8601String(),
                                            'notes':
                                                _notesController.text.isEmpty
                                                    ? null
                                                    : _notesController.text,
                                            'paymentMethod':
                                                _paymentMethod.toLowerCase(),
                                            'transactionId': _paymentMethod
                                                        .toLowerCase() ==
                                                    'bank transfer'
                                                ? _transactionIdController.text
                                                : null,
                                            'isSecurityDeposit':
                                                _isSecurityDeposit,
                                          };

                                          if (widget.payment != null) {
                                            context
                                                .read<
                                                    global_payment
                                                    .PaymentBloc>()
                                                .add(global_payment
                                                    .UpdatePayment(
                                                  widget.payment!.id,
                                                  paymentData,
                                                ));
                                          } else {
                                            context
                                                .read<TenantPaymentBloc>()
                                                .add(AddTenantPayment(
                                                  tenantId: _selectedTenantId!,
                                                  amount: amount,
                                                  paymentDate: _selectedDate,
                                                  notes: _notesController
                                                          .text.isEmpty
                                                      ? null
                                                      : _notesController.text,
                                                  paymentMethod: _paymentMethod
                                                      .toLowerCase(),
                                                  transactionId: _paymentMethod
                                                              .toLowerCase() ==
                                                          'bank transfer'
                                                      ? _transactionIdController
                                                          .text
                                                      : null,
                                                  isSecurityDeposit:
                                                      _isSecurityDeposit,
                                                ));
                                          }
                                        }

                                        if (!_isSecurityDeposit &&
                                            pendingAmount != null &&
                                            amount > pendingAmount) {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text(
                                                'Overpayment Warning',
                                                style: GoogleFonts.montserrat(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              content: Text(
                                                'The entered amount (QR $amount) is more than the pending amount (QR ${pendingAmount?.toStringAsFixed(2)}). Do you want to proceed?',
                                                style: GoogleFonts.montserrat(),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    proceedWithSave();
                                                  },
                                                  child: const Text('Proceed'),
                                                ),
                                              ],
                                            ),
                                          );
                                        } else {
                                          proceedWithSave();
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
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
                                      AppLocalizations.of(context)!.save,
                                      style: GoogleFonts.montserrat(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
