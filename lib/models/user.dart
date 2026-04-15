class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? avatar;
  final String? createdAt;
  final bool isSuspended;
  final bool verified;
  final String? businessName;
  final String? userId;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.avatar,
    this.createdAt,
    this.isSuspended = false,
    this.verified = false,
    this.businessName,
    this.userId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user_id']?.toString() ??
          json['id']?.toString() ??
          json['_id']?.toString() ??
          '',
      userId: json['user_id']?.toString(), // ← Ensure string
      name: json['full_name'] ?? json['name'] ?? json['fullName'] ?? 'Unknown',
      email: json['email'] ?? '',
      role: json['role']?.toString().toLowerCase() ?? 'tourist',
      phone: json['phone']?.toString(),
      avatar: json['avatar'] ?? json['profileImage'],
      createdAt: json['created_at'] ?? json['createdAt'],
      isSuspended: json['suspended'] == 1 || json['isSuspended'] == true,
      verified: json['verified'] == 1 || json['verified'] == true,
      businessName: json['business_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId ?? id,
      'full_name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'avatar': avatar,
      'created_at': createdAt,
      'suspended': isSuspended ? 1 : 0,
      'verified': verified ? 1 : 0,
      'business_name': businessName,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? phone,
    String? avatar,
    String? createdAt,
    bool? isSuspended,
    bool? verified,
    String? businessName,
    String? userId, // ← String? type
  }) {
    return User(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      isSuspended: isSuspended ?? this.isSuspended,
      verified: verified ?? this.verified,
      businessName: businessName ?? this.businessName,
    );
  }

  // Helper getters
  bool get isAdmin => role == 'admin';
  bool get isVendor => role == 'vendor';
  bool get isTourist => role == 'tourist';
  bool get isPendingVendor => isVendor && !verified;
}
