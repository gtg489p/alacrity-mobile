/// Disruption / alert data models.
///
/// Parsed from GET /disruption/

class Disruption {
  final int id;
  final String type; // "equipment", "material", "staff", "other"
  final String title;
  final String summary;
  final String severity; // "critical", "warning", "info"
  final int affectedJobsCount;
  final String status; // "open", "triaging", "resolved", "acknowledged"
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const Disruption({
    required this.id,
    required this.type,
    required this.title,
    required this.summary,
    required this.severity,
    required this.affectedJobsCount,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
  });

  factory Disruption.fromJson(Map<String, dynamic> json) => Disruption(
        id: json['id'] as int,
        type: json['type'] as String? ?? 'other',
        title: json['title'] as String? ?? 'Unknown Disruption',
        summary: json['summary'] as String? ?? '',
        severity: json['severity'] as String? ?? 'info',
        affectedJobsCount: json['affected_jobs_count'] as int? ?? 0,
        status: json['status'] as String? ?? 'open',
        createdAt: DateTime.parse(
            json['created_at'] as String? ?? DateTime.now().toIso8601String()),
        resolvedAt: json['resolved_at'] != null
            ? DateTime.parse(json['resolved_at'] as String)
            : null,
      );

  bool get isCritical => severity == 'critical';
  bool get isOpen => status == 'open' || status == 'triaging';
}
