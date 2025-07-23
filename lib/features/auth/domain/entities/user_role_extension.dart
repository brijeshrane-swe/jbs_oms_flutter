import 'package:order_management_system/features/auth/domain/entities/user_entity.dart';

extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.client:
        return 'client';
      case UserRole.user:
        return 'user';
    }
  }

  static UserRole fromString(String? value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      case 'client':
        return UserRole.client;
      case 'user':
      default:
        return UserRole.user;
    }
  }
}
