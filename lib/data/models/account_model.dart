import '../../domain/entities/account_entity.dart';

class AccountModel extends AccountEntity {
  const AccountModel({
    required super.id,
    required super.username,
    required super.passwordSalt,
    required super.passwordHash,
    required super.vaultKey,
<<<<<<< HEAD
    required super.recoveryKeySalt,
    required super.recoveryKeyHash,
=======
    required super.backupCodes,
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c
    super.authToken,
    super.createdAt,
    super.lastUsedAt,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
<<<<<<< HEAD
=======
    final rawCodes = json['backup_codes'] as List<dynamic>? ?? <dynamic>[];

>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c
    return AccountModel(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      passwordSalt: json['password_salt'] as String? ?? '',
      passwordHash: json['password_hash'] as String? ?? '',
      vaultKey: json['vault_key'] as String? ?? '',
<<<<<<< HEAD
      recoveryKeySalt: json['recovery_key_salt'] as String? ?? '',
      recoveryKeyHash: json['recovery_key_hash'] as String? ?? '',
      authToken: json['auth_token'] as String?,
      createdAt: _readDate(json['created_at'] as String?),
      lastUsedAt: _readDate(json['last_used_at'] as String?),
=======
      authToken: json['auth_token'] as String?,
      createdAt: _readDate(json['created_at'] as String?),
      lastUsedAt: _readDate(json['last_used_at'] as String?),
      backupCodes: rawCodes
          .map(
            (code) => BackupCodeModel.fromJson(
              Map<String, dynamic>.from(code as Map),
            ),
          )
          .toList(),
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c
    );
  }

  factory AccountModel.fromEntity(AccountEntity entity) {
    return AccountModel(
      id: entity.id,
      username: entity.username,
      passwordSalt: entity.passwordSalt,
      passwordHash: entity.passwordHash,
      vaultKey: entity.vaultKey,
<<<<<<< HEAD
      recoveryKeySalt: entity.recoveryKeySalt,
      recoveryKeyHash: entity.recoveryKeyHash,
      authToken: entity.authToken,
      createdAt: entity.createdAt,
      lastUsedAt: entity.lastUsedAt,
=======
      authToken: entity.authToken,
      createdAt: entity.createdAt,
      lastUsedAt: entity.lastUsedAt,
      backupCodes: entity.backupCodes
          .map(
            (code) => BackupCodeModel(
              salt: code.salt,
              hash: code.hash,
              isUsed: code.isUsed,
            ),
          )
          .toList(),
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c
    );
  }

  Map<String, dynamic> toJson() => {
<<<<<<< HEAD
    'id': id,
    'username': username,
    'password_salt': passwordSalt,
    'password_hash': passwordHash,
    'vault_key': vaultKey,
    'recovery_key_salt': recoveryKeySalt,
    'recovery_key_hash': recoveryKeyHash,
    'auth_token': authToken,
    'created_at': createdAt?.toIso8601String(),
    'last_used_at': lastUsedAt?.toIso8601String(),
  };
=======
        'id': id,
        'username': username,
        'password_salt': passwordSalt,
        'password_hash': passwordHash,
        'vault_key': vaultKey,
        'auth_token': authToken,
        'created_at': createdAt?.toIso8601String(),
        'last_used_at': lastUsedAt?.toIso8601String(),
        'backup_codes': backupCodes
            .map(
              (code) => BackupCodeModel(
                salt: code.salt,
                hash: code.hash,
                isUsed: code.isUsed,
              ).toJson(),
            )
            .toList(),
      };
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c

  static DateTime? _readDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }
}

<<<<<<< HEAD
class RecoveryRequestModel extends RecoveryRequestEntity {
  const RecoveryRequestModel({
    required super.attemptCount,
    super.requestedAt,
    super.availableAt,
    super.lockedUntil,
    super.authorizedAt,
    super.authorizationExpiresAt,
  });

  factory RecoveryRequestModel.fromJson(Map<String, dynamic> json) {
    return RecoveryRequestModel(
      attemptCount: json['attempt_count'] as int? ?? 0,
      requestedAt: AccountModel._readDate(json['requested_at'] as String?),
      availableAt: AccountModel._readDate(json['available_at'] as String?),
      lockedUntil: AccountModel._readDate(json['locked_until'] as String?),
      authorizedAt: AccountModel._readDate(json['authorized_at'] as String?),
      authorizationExpiresAt: AccountModel._readDate(
        json['authorization_expires_at'] as String?,
      ),
    );
  }

  factory RecoveryRequestModel.fromEntity(RecoveryRequestEntity entity) {
    return RecoveryRequestModel(
      attemptCount: entity.attemptCount,
      requestedAt: entity.requestedAt,
      availableAt: entity.availableAt,
      lockedUntil: entity.lockedUntil,
      authorizedAt: entity.authorizedAt,
      authorizationExpiresAt: entity.authorizationExpiresAt,
=======
class BackupCodeModel extends BackupCodeEntity {
  const BackupCodeModel({
    required super.salt,
    required super.hash,
    required super.isUsed,
  });

  factory BackupCodeModel.fromJson(Map<String, dynamic> json) {
    return BackupCodeModel(
      salt: json['salt'] as String? ?? '',
      hash: json['hash'] as String? ?? '',
      isUsed: json['is_used'] as bool? ?? false,
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c
    );
  }

  Map<String, dynamic> toJson() => {
<<<<<<< HEAD
    'attempt_count': attemptCount,
    'requested_at': requestedAt?.toIso8601String(),
    'available_at': availableAt?.toIso8601String(),
    'locked_until': lockedUntil?.toIso8601String(),
    'authorized_at': authorizedAt?.toIso8601String(),
    'authorization_expires_at': authorizationExpiresAt?.toIso8601String(),
  };
=======
        'salt': salt,
        'hash': hash,
        'is_used': isUsed,
      };
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c
}
