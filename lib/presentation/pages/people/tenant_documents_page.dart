import 'dart:io';

import 'package:admin_mobile_app/core/constants/api_constants.dart';
import 'package:admin_mobile_app/core/models/tenant_model.dart';
import 'package:admin_mobile_app/l10n/app_localizations.dart';
import 'package:admin_mobile_app/presentation/blocs/tenant/tenant_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/image_picker_modal.dart';
import 'package:url_launcher/url_launcher.dart';

/// Page to view, add, and edit tenant documents: Passport (front/back), Qatar ID.
class TenantDocumentsPage extends StatefulWidget {
  const TenantDocumentsPage({super.key});

  @override
  State<TenantDocumentsPage> createState() => _TenantDocumentsPageState();
}

class _TenantDocumentsPageState extends State<TenantDocumentsPage> {
  TenantModel? _tenant;
  List<List<dynamic>>? _documentsByType;
  bool _saving = false;
  int? _lastOperationTimestamp;
  late final List<List<String>> _originalDocs;

  bool get _hasChanges {
    if (_tenant == null || _documentsByType == null) return false;

    // Check for any new files (File objects)
    for (var list in _documentsByType!) {
      if (list.any((item) => item is File)) return true;
    }

    // Check if any existing files (Strings) were removed
    for (int i = 0; i < 3; i++) {
      final currentStrings = _documentsByType![i].whereType<String>().toList();
      if (!_areListsEqual(_originalDocs[i], currentStrings)) return true;
    }

    return false;
  }

  bool _areListsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_tenant != null) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! TenantModel) {
      _tenant = TenantModel(
        id: '',
        name: '',
        phone: '',
        rentAmount: 0,
        securityDeposit: 0,
        contractStartDate: DateTime.now(),
        contractEndDate: DateTime.now(),
        status: 'active',
      );
      _documentsByType = List.generate(3, (_) => []);
      _originalDocs = [[], [], []];
    } else {
      _tenant = args;
      _documentsByType = [
        List<dynamic>.from(_tenant!.passportFrontImages ?? []),
        List<dynamic>.from(_tenant!.passportBackImages ?? []),
        List<dynamic>.from(_tenant!.qatarIdImages ?? []),
      ];
      _originalDocs = [
        List<String>.from(_tenant!.passportFrontImages ?? []),
        List<String>.from(_tenant!.passportBackImages ?? []),
        List<String>.from(_tenant!.qatarIdImages ?? []),
      ];
    }
  }

  List<String> _getLabels(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.passportFront,
      l10n.passportBack,
      l10n.qatarId,
    ];
  }

  Future<void> _pickImages(int typeIndex) async {
    final pickedFiles = await ImagePickerModal.show(context);

    if (pickedFiles == null || pickedFiles.isEmpty || !mounted) return;

    setState(() {
      _documentsByType![typeIndex].addAll(pickedFiles);
    });
  }

  void _removeDocument(int typeIndex, int index) {
    setState(() {
      _documentsByType![typeIndex].removeAt(index);
    });
  }

  void _viewDocument(BuildContext context, dynamic item) async {
    if (item is String) {
      if (item.toLowerCase().endsWith('.pdf')) {
        final uri = Uri.parse(item);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text(AppLocalizations.of(context)!.couldNotLaunchPDF)),
            );
          }
        }
      } else {
        showDialog(
          context: context,
          builder: (ctx) => Dialog(
            child: InteractiveViewer(
              child: CachedNetworkImage(imageUrl: item, fit: BoxFit.contain),
            ),
          ),
        );
      }
    } else if (item is File) {
      if (item.path.toLowerCase().endsWith('.pdf')) {
        // Provide a way to view local PDF
        // For simplicity on mobile, we might not be able to "launch" a local file path easily
        // without a file provider or specialized viewer.
        // Using open_file would be better but let's try a basic dialog message or verify if we can generic launch.
        // Actually, let's just show a message for now or let user know.
        // A better approach is using `open_file` package but that requires another dependency.
        // For now I'll just show a snackbar saying "Cannot preview local PDF".
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Preview of local PDF not supported yet')),
        );
      } else {
        showDialog(
          context: context,
          builder: (ctx) => Dialog(
            child: InteractiveViewer(
              child: Image.file(item, fit: BoxFit.contain),
            ),
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    final tenant = _tenant;
    final docs = _documentsByType;
    if (tenant == null || docs == null) return;
    setState(() => _saving = true);
    context.read<TenantBloc>().add(UpdateTenantDocuments(
          tenantId: tenant.id,
          tenant: tenant,
          passportFrontImages: docs[0],
          passportBackImages: docs[1],
          qatarIdImages: docs[2],
        ));
  }

  @override
  Widget build(BuildContext context) {
    final tenant = _tenant;
    final documentsByType = _documentsByType;
    if (tenant == null || documentsByType == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final l10n = AppLocalizations.of(context)!;
    final labels = _getLabels(context);

    return BlocListener<TenantBloc, TenantState>(
      listener: (context, state) {
        if (state is TenantOperationSuccess) {
          setState(() => _saving = false);
          Navigator.of(context).pop(_tenant!);
        } else if (state is TenantError) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.documentsSaveFailed}: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is TenantLoaded) {
          if (state.operationSuccess != null &&
              state.operationTimestamp != _lastOperationTimestamp) {
            _lastOperationTimestamp = state.operationTimestamp;
            setState(() => _saving = false);
            Navigator.of(context).pop(_tenant!);
          } else if (state.operationError != null &&
              state.operationTimestamp != _lastOperationTimestamp) {
            _lastOperationTimestamp = state.operationTimestamp;
            setState(() => _saving = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.operationError!),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            l10n.tenantDocuments,
            style: GoogleFonts.montserrat(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
          actions: [
            TextButton(
              onPressed: (_saving || !_hasChanges) ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.save,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _hasChanges ? null : Colors.grey,
                      )),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < 3; i++) ...[
                Text(
                  labels[i],
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                _DocumentSection(
                  items: documentsByType[i],
                  onAdd: () => _pickImages(i),
                  onRemove: (index) => _removeDocument(i, index),
                  onView: (item) => _viewDocument(context, item),
                  addLabel: l10n.addImage,
                  noDocumentsLabel: l10n.noDocuments,
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentSection extends StatelessWidget {
  const _DocumentSection({
    required this.items,
    required this.onAdd,
    required this.onRemove,
    required this.onView,
    required this.addLabel,
    required this.noDocumentsLabel,
  });

  final List<dynamic> items;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final void Function(dynamic item) onView;
  final String addLabel;
  final String noDocumentsLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 100,
            child: items.isEmpty
                ? Center(
                    child: Text(
                      noDocumentsLabel,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final rawItem = items[index];
                      final item =
                          (rawItem is String && !rawItem.startsWith('http'))
                              ? ApiConstants.serverUrl + rawItem
                              : rawItem;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: () => onView(item),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: _buildThumbnail(item),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.white, size: 20),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black54,
                                  padding: const EdgeInsets.all(4),
                                  minimumSize: Size.zero,
                                ),
                                onPressed: () => onRemove(index),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: onAdd,
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(8),
              ),
              child: const Icon(Icons.add_photo_alternate_outlined, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(dynamic item) {
    if (item is String) {
      if (item.toLowerCase().endsWith('.pdf')) {
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
              SizedBox(height: 4),
              Text('PDF',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }
      return CachedNetworkImage(
        imageUrl: item,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: Colors.grey[200]),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      );
    } else if (item is File) {
      if (item.path.toLowerCase().endsWith('.pdf')) {
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
              SizedBox(height: 4),
              Text('PDF',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }
      return Image.file(
        item,
        fit: BoxFit.cover,
      );
    }
    return const SizedBox();
  }
}
