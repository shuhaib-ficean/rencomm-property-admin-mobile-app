class PaginatedResponse<T> {
  final List<T> data;
  final int currentPage;
  final int totalPages;
  final int totalCount;

  PaginatedResponse({
    required this.data,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT, {
    String dataKey = 'data',
  }) {
    final List<dynamic> dataList = json[dataKey] ?? [];

    // Fallback logic for existing APIs that return raw lists instead of nested pagination
    // e.g. return { tenants: [...] } with optional pagination fields at the root level

    return PaginatedResponse(
      data: dataList.map((item) => fromJsonT(item)).toList(),
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalCount: json['total'] ?? dataList.length,
    );
  }
}
