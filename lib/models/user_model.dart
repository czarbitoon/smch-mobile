class UserModel {
  final int? id;
  final String? name;
  final String? email;
  final String? profilePicture;
  final int? type;
  final int? officeId;
  final String? officeName;

  UserModel({
    this.id,
    this.name,
    this.email,
    this.profilePicture,
    this.type,
    this.officeId,
    this.officeName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      profilePicture: json['profile_picture'],
      type: json['type'],
      officeId: json['office_id'],
      officeName: json['office'] != null ? json['office']['name'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profile_picture': profilePicture,
      'type': type,
      'office_id': officeId,
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? profilePicture,
    int? type,
    int? officeId,
    String? officeName,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profilePicture: profilePicture ?? this.profilePicture,
      type: type ?? this.type,
      officeId: officeId ?? this.officeId,
      officeName: officeName ?? this.officeName,
    );
  }
}