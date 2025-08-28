import 'package:learnify_rewards/shared/domain/entities/user.dart';

class UserModel extends User {
  UserModel({
    required String uid,
    String? displayName,
    String? email,
    String? photoUrl,
    required UserRole role,
    required UserStatus status,
    required AgeGroup ageGroup,
    required VerificationStatus verificationStatus,
  }) : super(
          uid: uid,
          displayName: displayName,
          email: email,
          photoUrl: photoUrl,
          role: role,
          status: status,
          ageGroup: ageGroup,
          verificationStatus: verificationStatus,
        );

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'],
      displayName: json['displayName'],
      email: json['email'],
      photoUrl: json['photoUrl'],
      role: UserRole.values
          .firstWhere((e) => e.toString() == 'UserRole.${json['role']}'),
      status: UserStatus.values
          .firstWhere((e) => e.toString() == 'UserStatus.${json['status']}'),
      ageGroup: AgeGroup.values
          .firstWhere((e) => e.toString() == 'AgeGroup.${json['ageGroup']}'),
      verificationStatus: VerificationStatus.values.firstWhere((e) =>
          e.toString() == 'VerificationStatus.${json['verificationStatus']}'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'role': role.toString().split('.').last,
      'status': status.toString().split('.').last,
      'ageGroup': ageGroup.toString().split('.').last,
      'verificationStatus': verificationStatus.toString().split('.').last,
    };
  }
}
