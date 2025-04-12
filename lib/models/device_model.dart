class DeviceModel {
  final int id;
  final String name;
  final String? description;
  final int officeId;
  final int typeId;
  final String type;
  final String? subcategory;
  final String status;
  final String? serialNumber;
  final String? purchaseDate;
  final String? warrantyExpiration;
  final String? notes;
  final String? imageUrl;
  final String? createdAt;
  final String? updatedAt;
  final String? lastMaintenance;

  DeviceModel({
    required this.id,
    required this.name,
    this.description,
    required this.officeId,
    required this.typeId,
    required this.type,
    this.subcategory,
    required this.status,
    this.serialNumber,
    this.purchaseDate,
    this.warrantyExpiration,
    this.notes,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
    this.lastMaintenance,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      officeId: json['office_id'] as int,
      typeId: json['type_id'] as int,
      type: json['type'] as String,
      subcategory: json['subcategory'] as String?,
      status: json['status'] as String? ?? 'Available',
      serialNumber: json['serial_number'] as String?,
      purchaseDate: json['purchase_date'] as String?,
      warrantyExpiration: json['warranty_expiration'] as String?,
      notes: json['notes'] as String?,
      imageUrl: json['image_url'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      lastMaintenance: json['last_maintenance'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'office_id': officeId,
      'type_id': typeId,
      'type': type,
      'subcategory': subcategory,
      'status': status,
      'serial_number': serialNumber,
      'purchase_date': purchaseDate,
      'warranty_expiration': warrantyExpiration,
      'notes': notes,
      'image_url': imageUrl,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'last_maintenance': lastMaintenance,
    };
  }

  DeviceModel copyWith({
    int? id,
    String? name,
    String? description,
    int? officeId,
    int? typeId,
    String? type,
    String? subcategory,
    String? status,
    String? serialNumber,
    String? purchaseDate,
    String? warrantyExpiration,
    String? notes,
    String? imageUrl,
    String? createdAt,
    String? updatedAt,
    String? lastMaintenance,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      officeId: officeId ?? this.officeId,
      typeId: typeId ?? this.typeId,
      type: type ?? this.type,
      subcategory: subcategory ?? this.subcategory,
      status: status ?? this.status,
      serialNumber: serialNumber ?? this.serialNumber,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      warrantyExpiration: warrantyExpiration ?? this.warrantyExpiration,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMaintenance: lastMaintenance ?? this.lastMaintenance,
    );
  }
} 