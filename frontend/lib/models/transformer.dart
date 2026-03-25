class Fuse {
  final String fuseId;
  final String status;
  final DateTime lastUpdated;

  Fuse({
    required this.fuseId,
    required this.status,
    required this.lastUpdated,
  });

  factory Fuse.fromJson(Map<String, dynamic> json) {
    return Fuse(
      fuseId: json['fuseId'] ?? '',
      status: json['status'] ?? 'Unknown',
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
    );
  }
}

class Transformer {
  final String id;
  final String transformerId;
  final String location;
  final double voltageThreshold;
  final double currentThreshold;
  final double currentVoltage;
  final double currentAmperage;
  final String status;
  final List<Fuse> fuses;

  Transformer({
    required this.id,
    required this.transformerId,
    required this.location,
    required this.voltageThreshold,
    required this.currentThreshold,
    required this.currentVoltage,
    required this.currentAmperage,
    required this.status,
    required this.fuses,
  });

  factory Transformer.fromJson(Map<String, dynamic> json) {
    var rawFuses = json['fuses'] as List? ?? [];
    List<Fuse> fuseList = rawFuses.map((f) => Fuse.fromJson(f)).toList();

    return Transformer(
      id: json['_id'] ?? '',
      transformerId: json['transformerId'] ?? '',
      location: json['location'] ?? '',
      voltageThreshold: (json['voltageThreshold'] ?? 0).toDouble(),
      currentThreshold: (json['currentThreshold'] ?? 0).toDouble(),
      currentVoltage: (json['currentVoltage'] ?? 0).toDouble(),
      currentAmperage: (json['currentAmperage'] ?? 0).toDouble(),
      status: json['status'] ?? 'Unknown',
      fuses: fuseList,
    );
  }
  
  // Helper to get number of blown fuses
  int get blownFusesCount => fuses.where((f) => f.status == 'Blown').length;
}
