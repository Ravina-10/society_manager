class Flat {
  final String id;
  final String flatNumber;
  final String ownerName;
  final String ownerPhone;
  final String? tenantName;
  final String? tenantPhone;
  final bool isOccupied;

  Flat({
    required this.id,
    required this.flatNumber,
    required this.ownerName,
    required this.ownerPhone,
    this.tenantName,
    this.tenantPhone,
    this.isOccupied = true,
  });

  factory Flat.fromMap(Map<String, dynamic> map, String id) {
    return Flat(
      id: id,
      flatNumber: map['flatNumber'] ?? id,
      ownerName: map['ownerName'] ?? '',
      ownerPhone: map['ownerPhone'] ?? '',
      tenantName: map['tenantName'],
      tenantPhone: map['tenantPhone'],
      isOccupied: map['isOccupied'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'flatNumber': flatNumber,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'tenantName': tenantName,
      'tenantPhone': tenantPhone,
      'isOccupied': isOccupied,
    };
  }
}
