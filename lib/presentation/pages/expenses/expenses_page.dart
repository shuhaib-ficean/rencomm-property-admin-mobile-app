import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/expense/expense_bloc.dart';
import '../../blocs/expense/expense_event.dart';
import '../../blocs/expense/expense_state.dart';
import '../../../core/models/expense_model.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/permission_helper.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/app_entity_action_menu.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  final _formKey = GlobalKey<FormState>();

  void _showCreateEditDialog({ExpenseModel? expense}) {
    String title = expense?.title ?? '';
    String category = expense?.category ?? 'Repairs';
    String amount = expense?.amount.toString() ?? '';
    String date = expense?.date ?? DateFormat('yyyy-MM-dd').format(DateTime.now());

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(expense == null ? 'Add Expense' : 'Edit Expense',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        initialValue: title,
                        decoration: const InputDecoration(
                            labelText: 'Title', border: OutlineInputBorder()),
                        onChanged: (val) => title = val,
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                            labelText: 'Category', border: OutlineInputBorder()),
                        initialValue: category,
                        items: ['Repairs', 'Utility Bills', 'Salaries', 'Other']
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => category = val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: amount,
                        decoration: const InputDecoration(
                            labelText: 'Amount (QR)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        onChanged: (val) => amount = val,
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: date,
                        decoration: const InputDecoration(
                            labelText: 'Date (YYYY-MM-DD)', border: OutlineInputBorder()),
                        onChanged: (val) => date = val,
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                      ),
                      // Receipt upload can be added here later
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (expense == null) {
                        dialogContext.read<ExpenseBloc>().add(
                              CreateExpense(
                                title: title,
                                category: category,
                                amount: double.tryParse(amount) ?? 0.0,
                                date: date,
                              ),
                            );
                      } else {
                        dialogContext.read<ExpenseBloc>().add(
                              UpdateExpense(
                                id: expense.id,
                                title: title,
                                category: category,
                                amount: double.tryParse(amount) ?? 0.0,
                                date: date,
                              ),
                            );
                      }
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Save'),
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ExpenseBloc, ExpenseState>(
      listener: (context, state) {
        if (state is ExpenseLoaded) {
          if (state.operationError != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.operationError!),
                backgroundColor: Colors.red));
          } else if (state.operationSuccess != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.operationSuccess!),
                backgroundColor: Colors.green));
          }
        } else if (state is ExpenseError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message), backgroundColor: Colors.red));
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text('Expense Management',
              style: GoogleFonts.montserrat(
                  color: Colors.black87, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        floatingActionButton: PermissionHelper.hasPermission(context, 'manage_expenses')
            ? FloatingActionButton(
                onPressed: () => _showCreateEditDialog(),
                backgroundColor: Colors.redAccent,
                child: const Icon(Icons.add),
              )
            : null,
        body: RefreshIndicator(
          onRefresh: () async {
            context.read<ExpenseBloc>().add(const LoadExpenses(isRefresh: true));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSummaryCards(),
                const SizedBox(height: 24),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Recent Expenses',
                            style: GoogleFonts.montserrat(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        BlocBuilder<ExpenseBloc, ExpenseState>(
                          builder: (context, state) {
                            if (state is ExpenseLoading) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            } else if (state is ExpenseLoaded) {
                              if (state.expenses.isEmpty) {
                                return const Center(
                                    child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('No expenses found'),
                                ));
                              }
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                      Colors.grey[100]),
                                  columns: const [
                                    DataColumn(label: Text('Title')),
                                    DataColumn(label: Text('Category')),
                                    DataColumn(label: Text('Amount')),
                                    DataColumn(label: Text('Date')),
                                    DataColumn(label: Text('Receipt')),
                                    DataColumn(label: Text('Actions')),
                                  ],
                                  rows: state.expenses.map((exp) {
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(exp.title)),
                                        DataCell(Text(exp.category)),
                                        DataCell(Text(
                                            'QR ${exp.amount.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                                color: Colors.red,
                                                fontWeight: FontWeight.bold))),
                                        DataCell(Text(exp.date.split('T').first)),
                                        DataCell(
                                          Icon(
                                            exp.receipt != null
                                                ? Icons.check_circle
                                                : Icons.cancel,
                                            color: exp.receipt != null
                                                ? Colors.green
                                                : Colors.grey,
                                            size: 20,
                                          ),
                                        ),
                                        DataCell(
                                          AppEntityActionMenu(
                                            onEdit: PermissionHelper.hasPermission(context, 'manage_expenses')
                                                ? () => _showCreateEditDialog(expense: exp)
                                                : null,
                                            editLabel: 'Edit Expense',
                                            onDelete: PermissionHelper.hasPermission(context, 'manage_expenses')
                                                ? () {
                                                    ConfirmationDialog.show(
                                                      context: context,
                                                      title: 'Delete Expense',
                                                      content:
                                                          'Are you sure you want to permanently delete this expense (${exp.category} - QR ${exp.amount})?',
                                                      confirmText: 'Delete',
                                                      cancelText: 'Cancel',
                                                      isDestructive: true,
                                                      onConfirm: () {
                                                        context.read<ExpenseBloc>().add(DeleteExpense(exp.id));
                                                      },
                                                    );
                                                  }
                                                : null,
                                            deleteLabel: 'Delete Expense',
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              );
                            } else if (state is ExpenseError) {
                              return Center(
                                  child: Text('Error: ${state.message}'));
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return BlocBuilder<ExpenseBloc, ExpenseState>(
      builder: (context, state) {
        double currentMonthTotal = 0.0;
        double previousMonthTotal = 0.0;

        if (state is ExpenseLoaded) {
          final now = DateTime.now();
          for (var exp in state.expenses) {
            try {
              final expDate = DateTime.parse(exp.date);
              if (expDate.year == now.year && expDate.month == now.month) {
                currentMonthTotal += exp.amount;
              } else if (expDate.year == now.year &&
                  expDate.month == now.month - 1) {
                previousMonthTotal += exp.amount;
              } else if (expDate.year == now.year - 1 &&
                  now.month == 1 &&
                  expDate.month == 12) {
                previousMonthTotal += exp.amount;
              }
            } catch (e) {
              // ignore parse errors
            }
          }
        }

        return Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Month',
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(height: 8),
                    Text('QR ${currentMonthTotal.toStringAsFixed(2)}',
                        style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Previous Month',
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(height: 8),
                    Text('QR ${previousMonthTotal.toStringAsFixed(2)}',
                        style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800])),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
