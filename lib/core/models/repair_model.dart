class RepairModel {
  final String id;
  final String ticket;
  final String? description;
  final String department;
  final String category;
  final String priority;
  final String status;
  final String customerId;
  final String propertyId;
  final String? roomId;
  final String? staffId;
  
  // Images & Proof of Completion
  final List<String> images;
  final List<String> completionImages;
  final String? completionNotes;
  final String? resolvedAt;
  final String? createdAt;

  // Related data that backend populates
  final String? propertyName;
  final String? roomNumber;
  final String? customerName;
  final String? customerPhone;
  final String? staffName;

  RepairModel({
    required this.id,
    required this.ticket,
    this.description,
    required this.department,
    required this.category,
    required this.priority,
    required this.status,
    required this.customerId,
    required this.propertyId,
    this.roomId,
    this.staffId,
    this.images = const [],
    this.completionImages = const [],
    this.completionNotes,
    this.resolvedAt,
    this.createdAt,
    this.propertyName,
    this.roomNumber,
    this.customerName,
    this.customerPhone,
    this.staffName,
  });

  factory RepairModel.fromJson(Map<String, dynamic> json) {
    return RepairModel(
      id: json['id']?.toString() ?? '',
      ticket: json['ticket']?.toString() ?? '',
      description: json['description'],
      department: json['department']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'Medium',
      status: json['status']?.toString() ?? 'Pending',
      customerId: json['customerId']?.toString() ?? json['tenantId']?.toString() ?? '',
      propertyId: json['propertyId']?.toString() ?? '',
      roomId: json['roomId']?.toString(),
      staffId: json['staffId']?.toString(),
      images: json['images'] is List ? List<String>.from(json['images']) : [],
      completionImages: json['completionImages'] is List
          ? List<String>.from(json['completionImages'])
          : [],
      completionNotes: json['completionNotes']?.toString(),
      resolvedAt: json['resolvedAt']?.toString(),
      createdAt: json['createdAt']?.toString(),
      propertyName: json['propertyName'] ??
          (json['property'] is Map ? json['property']['name'] : null),
      roomNumber: json['roomNumber'] ??
          (json['room'] is Map ? json['room']['number']?.toString() : null),
      customerName: json['customerName'] ??
          (json['customer'] is Map
              ? json['customer']['name']
              : (json['tenant'] is Map ? json['tenant']['name'] : null)),
      customerPhone: json['customerPhone'] ??
          (json['customer'] is Map
              ? json['customer']['phone']
              : (json['tenant'] is Map ? json['tenant']['phone'] : null)),
      staffName: json['staffName'] ??
          (json['staff'] is Map ? json['staff']['name'] : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket': ticket,
      'description': description,
      'department': department,
      'category': category,
      'priority': priority,
      'status': status,
      'customerId': customerId,
      'propertyId': propertyId,
      'roomId': roomId,
      'staffId': staffId,
      'images': images,
      'completionImages': completionImages,
      'completionNotes': completionNotes,
      'resolvedAt': resolvedAt,
      'createdAt': createdAt,
    };
  }
}
