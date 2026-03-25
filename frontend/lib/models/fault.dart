class Fault {
  final String id;
  final String transformerId;
  final String transformerName;
  final String location;
  final String fuseId;
  final String faultType;
  final String status;
  final DateTime detectedAt;
  final DateTime? resolvedAt;

  Fault({
    required this.id,
    required this.transformerId,
    required this.transformerName,
    required this.location,
    required this.fuseId,
    required this.faultType,
    required this.status,
    required this.detectedAt,
    this.resolvedAt,
  });

  factory Fault.fromJson(Map<String, dynamic> json) {
    return Fault(
      id: json['_id'] ?? '',
      transformerId: json['transformerId']['_id'] ?? '',
      transformerName: json['transformerId']['transformerId'] ?? 'Unknown',
      location: json['transformerId']['location'] ?? 'Unknown location',
      fuseId: json['fuseId'] ?? '',
      faultType: json['faultType'] ?? '',
      status: json['status'] ?? 'Active',
      detectedAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
    );
  }
}
