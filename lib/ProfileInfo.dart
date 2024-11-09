class ProfileInfo {
  final String userId;
  final String name;
  final String studentId;
  final String contactNumber;
  final String email;


  ProfileInfo({
    required this.userId,
    required this.name,
    required this.studentId,
    required this.contactNumber,
    required this.email,

  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'studentId': studentId,
      'contactNumber': contactNumber,
      'email': email,

    };
  }

  factory ProfileInfo.fromDocumentSnapshot(Map<String, dynamic> doc) {
    return ProfileInfo(
      userId: doc['userId'] ?? '',
      name: doc['name'] ?? '',
      studentId: doc['studentId'] ?? '',
      contactNumber: doc['contactNumber'] ?? '',
      email: doc['email'] ?? '',
    );
  }
}
