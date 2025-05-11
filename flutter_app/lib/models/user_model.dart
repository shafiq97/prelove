class User {
  final int id;
  final String username;
  final String email;
  final String fullName;
  final String? phone;
  final String? address;
  final String? profileImageUrl;
  final String? role;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    this.phone,
    this.address,
    this.profileImageUrl,
    this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      username: json['username'],
      email: json['email'],
      fullName: json['full_name'], // Updated to match API response
      phone: json['phone'],
      address: json['address'],
      profileImageUrl: json['profile_image'], // Updated to match API response
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName, // Updated to match API response
      'phone': phone,
      'address': address,
      'profile_image': profileImageUrl, // Updated to match API response
      'role': role,
    };
  }

  // Helper for backward compatibility
  String? get profileImage => profileImageUrl;
}
