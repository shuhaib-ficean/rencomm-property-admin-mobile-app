import 'package:admin_mobile_app/core/models/lease_model.dart';
import 'package:admin_mobile_app/presentation/blocs/tenant/tenant_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:admin_mobile_app/core/models/tenant_model.dart';
import 'package:admin_mobile_app/core/theme/app_theme.dart';
import 'package:admin_mobile_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class LeaseHistoryModal extends StatefulWidget {
  final TenantModel tenant;

  const LeaseHistoryModal({super.key, required this.tenant});

  @override
  State<LeaseHistoryModal> createState() => _LeaseHistoryModalState();
}

class _LeaseHistoryModalState extends State<LeaseHistoryModal> {
  @override
  void initState() {
    super.initState();
    context.read<TenantBloc>().add(GetTenantLeases(widget.tenant.id));
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: BlocBuilder<TenantBloc, TenantState>(
        builder: (context, state) {
          var leases = (state is TenantLoaded)
              ? (state.currentTenantLeases ?? [])
              : (widget.tenant.leaseList ?? []);
          final isLoading = (state is TenantLoaded) && state.isLeasesLoading;

          // If server lease history is empty but tenant currently has active room/property assignment, show the current active lease
          if (leases.isEmpty &&
              widget.tenant.property != null &&
              widget.tenant.assignedRoom != null) {
            leases = [
              LeaseModel(
                id: 'current',
                tenantId: widget.tenant.id,
                propertyId: widget.tenant.assignedPropertyId ?? widget.tenant.property?.id,
                roomId: widget.tenant.assignedRoomId ?? widget.tenant.assignedRoom?.id,
                rentAmount: widget.tenant.rentAmount,
                securityDeposit: widget.tenant.securityDeposit,
                startDate: widget.tenant.contractStartDate,
                endDate: widget.tenant.contractEndDate,
                status: 'active',
                isRecurring: widget.tenant.contractEndDate == null,
                createdAt: widget.tenant.contractStartDate,
                updatedAt: DateTime.now(),
                propertyDetails: widget.tenant.property,
                roomDetails: widget.tenant.assignedRoom,
                totalDue: widget.tenant.financials?.totalAmount,
                totalPaid: widget.tenant.financials?.totalPaid,
                totalPending: widget.tenant.financials?.totalPending,
              ),
            ];
          }

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.leaseHistory,
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(),
              if (isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (leases.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.noLeaseHistory,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: leases.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 32),
                    itemBuilder: (context, index) {
                      final lease = leases[index];
                      final isActive = lease.status == 'active';
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isActive
                                ? AppTheme.primaryBlue.withValues(alpha: 0.3)
                                : Colors.grey[200]!,
                            width: isActive ? 2 : 1,
                          ),
                        ),
                        color: isActive
                            ? AppTheme.primaryBlue.withValues(alpha: 0.02)
                            : Colors.grey[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      lease.propertyDetails != null
                                          ? '${lease.propertyDetails?.name} - ${lease.roomDetails?.number ?? 'N/A'}'
                                          : (widget.tenant.property != null
                                              ? '${widget.tenant.property?.name} - ${widget.tenant.assignedRoom?.number ?? 'N/A'}'
                                              : 'Unknown Property'),
                                      style: GoogleFonts.montserrat(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isActive) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Current Lease',
                                            style: GoogleFonts.montserrat(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10,
                                              color: Colors.green[700],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: (lease.isRecurring
                                                  ? Colors.blue
                                                  : Colors.orange)
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          lease.isRecurring ? 'Recurring' : 'Fixed',
                                          style: GoogleFonts.montserrat(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 10,
                                            color: lease.isRecurring
                                                ? Colors.blue
                                                : Colors.orange,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMiniLeaseInfo(
                                      context,
                                      Icons.calendar_today_outlined,
                                      AppLocalizations.of(context)!.startDate,
                                      dateFormat.format(lease.startDate),
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildMiniLeaseInfo(
                                      context,
                                      Icons.event_available_outlined,
                                      AppLocalizations.of(context)!.endDate,
                                      lease.endDate != null
                                          ? dateFormat.format(lease.endDate!)
                                          : 'Present',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMiniLeaseInfo(
                                      context,
                                      Icons.money,
                                      AppLocalizations.of(context)!.rentAmount,
                                      'QR ${lease.rentAmount.toStringAsFixed(2)}',
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildMiniLeaseInfo(
                                      context,
                                      Icons.security,
                                      AppLocalizations.of(
                                        context,
                                      )!
                                          .securityDeposit,
                                      'QR ${lease.securityDeposit.toStringAsFixed(2)}',
                                    ),
                                  ),
                                ],
                              ),
                              if (!lease.isRecurring &&
                                  lease.endDate != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildMiniLeaseInfo(
                                        context,
                                        Icons.timer_outlined,
                                        AppLocalizations.of(context)!
                                            .leaseDurationDays,
                                        '${lease.endDate!.difference(lease.startDate).inDays} Days',
                                      ),
                                    ),
                                    const Expanded(child: SizedBox()), // spacer
                                  ],
                                ),
                              ],
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMiniLeaseInfo(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: AppTheme.primaryBlue.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 18),
          child: Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
