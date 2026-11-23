class DepartmentModel {
  final String id;
  final String name;
  final String? description;
  final int staffCount;
  final String createdAt;
  final String updatedAt;

  DepartmentModel({
    required this.id,
    required this.name,
    this.description,
    required this.staffCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      staffCount: json['staffCount'] ?? 0,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'staffCount': staffCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
