class ExpenseModel {
  final String id;
  final String title;
  final String category;
  final double amount;
  final String date;
  final String? receipt;
  final String? propertyId;
  final String createdAt;
  final String updatedAt;
  final String? createdById;

  ExpenseModel({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.receipt,
    this.propertyId,
    required this.createdAt,
    required this.updatedAt,
    this.createdById,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: json['date'] as String,
      receipt: json['receipt'] as String?,
      propertyId: json['propertyId'] as String?,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
      createdById: json['createdById'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'date': date,
      'receipt': receipt,
      'propertyId': propertyId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdById': createdById,
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? title,
    String? category,
    double? amount,
    String? date,
    String? receipt,
    String? propertyId,
    String? createdAt,
    String? updatedAt,
    String? createdById,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      receipt: receipt ?? this.receipt,
      propertyId: propertyId ?? this.propertyId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdById: createdById ?? this.createdById,
    );
  }
}
