import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/models/repair_model.dart';
import '../../blocs/repair/repair_bloc.dart';
import '../../blocs/repair/repair_event.dart';
import '../../blocs/repair/repair_state.dart';
import '../../widgets/image_picker_modal.dart';

class StaffRepairDetailsPage extends StatefulWidget {
  final RepairModel repair;

  const StaffRepairDetailsPage({super.key, required this.repair});

  @override
  State<StaffRepairDetailsPage> createState() => _StaffRepairDetailsPageState();
}

class _StaffRepairDetailsPageState extends State<StaffRepairDetailsPage> {
  late RepairModel _repair;
  final TextEditingController _notesController = TextEditingController();
  final List<File> _proofFiles = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _repair = widget.repair;
    if (_repair.completionNotes != null) {
      _notesController.text = _repair.completionNotes!;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return const Color(0xFF10B981);
      case 'in progress':
        return const Color(0xFF2563EB);
      case 'rejected':
      case 'cancelled':
        return const Color(0xFFEF4444);
      case 'pending':
      default:
        return const Color(0xFFF59E0B);
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
      case 'urgent':
        return const Color(0xFFEF4444);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'low':
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  Future<void> _pickProofImages() async {
    final picked = await ImagePickerModal.show(context);
    if (picked != null && picked.isNotEmpty) {
      setState(() {
        _proofFiles.addAll(picked);
      });
    }
  }

  void _removeProofImage(int index) {
    setState(() {
      _proofFiles.removeAt(index);
    });
  }

  String _formatImageUrl(String url) {
    if (url.startsWith('data:image') || url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final cleanBase = ApiConstants.baseUrl.replaceAll('/api', '');
    return '$cleanBase${url.startsWith('/') ? '' : '/'}$url';
  }

  Widget _buildImage(String url, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    if (url.startsWith('data:image')) {
      try {
        final base64Data = url.split(',').last;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, size: 24, color: Colors.grey),
          ),
        );
      } catch (_) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, size: 24, color: Colors.grey),
        );
      }
    }

    return CachedNetworkImage(
      imageUrl: _formatImageUrl(url),
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, size: 24, color: Colors.grey),
      ),
    );
  }

  void _openFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              child: imageUrl.startsWith('data:image')
                  ? Image.memory(base64Decode(imageUrl.split(',').last))
                  : CachedNetworkImage(
                      imageUrl: _formatImageUrl(imageUrl),
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator(color: Colors.white)),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.broken_image, color: Colors.white, size: 48),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  void _submitResolution(BuildContext context) {
    if (_proofFiles.isEmpty && _notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload at least 1 proof photo or enter resolution notes.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Convert picked files into base64 or upload paths
    List<String> completionImages = [];
    for (var file in _proofFiles) {
      try {
        final bytes = file.readAsBytesSync();
        final ext = file.path.split('.').last.toLowerCase();
        final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
        final base64String = 'data:$mime;base64,${base64Encode(bytes)}';
        completionImages.add(base64String);
      } catch (_) {}
    }

    context.read<RepairBloc>().add(
          ResolveRepairRequest(
            _repair.id,
            status: 'Resolved',
            completionImages: completionImages.isNotEmpty ? completionImages : null,
            completionNotes: _notesController.text.trim().isNotEmpty
                ? _notesController.text.trim()
                : null,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(_repair.status);
    final priorityColor = _getPriorityColor(_repair.priority);

    return BlocListener<RepairBloc, RepairState>(
      listener: (context, state) {
        if (state is RepairLoaded) {
          if (state.operationSuccess != null) {
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.operationSuccess!),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          } else if (state.operationError != null) {
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.operationError!),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else if (state is RepairError) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Task: ${_repair.ticket}',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.4)),
              ),
              child: Text(
                _repair.status,
                style: GoogleFonts.montserrat(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ticket Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
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
                          child: Text(
                            _repair.category,
                            style: GoogleFonts.montserrat(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_repair.priority} Priority',
                            style: GoogleFonts.montserrat(
                              color: priorityColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Department: ${_repair.department}',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Property & Unit Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEBEBEB), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.apartment_rounded, color: Color(0xFF2F92D0), size: 26),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _repair.propertyName ?? 'Assigned Property',
                            style: GoogleFonts.montserrat(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _repair.roomNumber != null ? 'Unit / Room: ${_repair.roomNumber}' : 'General Area',
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tenant Contact Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEBEBEB), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_rounded, color: Color(0xFF10B981), size: 26),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _repair.customerName ?? 'Tenant',
                            style: GoogleFonts.montserrat(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _repair.customerPhone ?? 'No phone provided',
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_repair.customerPhone != null &&
                        _repair.customerPhone!.trim().isNotEmpty &&
                        _repair.customerPhone != 'N/A')
                      IconButton(
                        icon: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF10B981)),
                        onPressed: () => _makePhoneCall(_repair.customerPhone!),
                        tooltip: 'Call Tenant',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Issue Description & Initial Photos
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Issue Description',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _repair.description != null && _repair.description!.trim().isNotEmpty
                          ? _repair.description!
                          : 'No detailed description provided by tenant.',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: const Color(0xFF475569),
                        height: 1.4,
                      ),
                    ),
                    if (_repair.images.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Reported Photos (${_repair.images.length})',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 90,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _repair.images.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final imgUrl = _repair.images[index];
                            return GestureDetector(
                              onTap: () => _openFullScreenImage(context, imgUrl),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CachedNetworkImage(
                                  imageUrl: _formatImageUrl(imgUrl),
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    width: 90,
                                    height: 90,
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    width: 90,
                                    height: 90,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.broken_image, color: Colors.grey),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ================= SECTION: RESOLUTION / WORK PROOF =================
              if (_repair.status.toLowerCase() == 'resolved') ...[
                // Already Resolved View
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Task Completed',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      if (_repair.resolvedAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Resolved at: ${_repair.resolvedAt}',
                          style: GoogleFonts.montserrat(fontSize: 12, color: const Color(0xFF64748B)),
                        ),
                      ],
                      if (_repair.completionNotes != null &&
                          _repair.completionNotes!.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Technician Notes:',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _repair.completionNotes!,
                          style: GoogleFonts.montserrat(fontSize: 13, color: const Color(0xFF475569)),
                        ),
                      ],
                      if (_repair.completionImages.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          'Proof Photos (${_repair.completionImages.length}):',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 90,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _repair.completionImages.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final imgUrl = _repair.completionImages[index];
                              return GestureDetector(
                                onTap: () => _openFullScreenImage(context, imgUrl),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: _buildImage(imgUrl, width: 90, height: 90),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ] else if (_repair.status.toLowerCase() == 'pending') ...[
                // Pending: Button to Start Work
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<RepairBloc>().add(
                          UpdateRepairStatus(_repair.id, 'In Progress'),
                        );
                    setState(() {
                      _repair = RepairModel(
                        id: _repair.id,
                        ticket: _repair.ticket,
                        description: _repair.description,
                        department: _repair.department,
                        category: _repair.category,
                        priority: _repair.priority,
                        status: 'In Progress',
                        customerId: _repair.customerId,
                        propertyId: _repair.propertyId,
                        roomId: _repair.roomId,
                        staffId: _repair.staffId,
                        images: _repair.images,
                        completionImages: _repair.completionImages,
                        completionNotes: _repair.completionNotes,
                        resolvedAt: _repair.resolvedAt,
                        createdAt: _repair.createdAt,
                        propertyName: _repair.propertyName,
                        roomNumber: _repair.roomNumber,
                        customerName: _repair.customerName,
                        customerPhone: _repair.customerPhone,
                        staffName: _repair.staffName,
                      );
                    });
                  },
                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                  label: Text(
                    'Accept & Start Work',
                    style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ] else ...[
                // In Progress: Resolution & Proof Upload Form
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF10B981), size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Upload Proof of Resolution',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Take a photo of the completed repair so the property admin and tenant can inspect the solved work.',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Proof photos preview grid
                      if (_proofFiles.isNotEmpty) ...[
                        SizedBox(
                          height: 100,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _proofFiles.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      _proofFiles[index],
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeProofImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Add photos button
                      OutlinedButton.icon(
                        onPressed: _pickProofImages,
                        icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                        label: Text(
                          _proofFiles.isEmpty ? 'Take / Pick Proof Photo' : 'Add More Photos',
                          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          side: const BorderSide(color: Color(0xFF2563EB)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Completion Notes field
                      Text(
                        'Resolution Notes / Work Summary',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'e.g. Replaced leaking valve, tested water flow, all working properly.',
                          hintStyle: GoogleFonts.montserrat(fontSize: 13, color: const Color(0xFF94A3B8)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Submit Resolution Button
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : () => _submitResolution(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'Mark as Resolved & Submit Proof',
                                style: GoogleFonts.montserrat(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
