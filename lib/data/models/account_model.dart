import '../../domain/entities/account_entity.dart';

class AccountModel extends AccountEntity {
  const AccountModel({
    required super.id,
    required super.username,
    required super.passwordSalt,
    required super.passwordHash,
    required super.vaultKey,
    required super.backupCodes,
    super.authToken,
    super.createdAt,
    super.lastUsedAt,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    final rawCodes = json['backup_codes'] as List<dynamic>? ?? <dynamic>[];

    return AccountModel(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      passwordSalt: json['password_salt'] as String? ?? '',
      passwordHash: json['password_hash'] as String? ?? '',
      vaultKey: json['vault_key'] as String? ?? '',
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
    );
  }

  factory AccountModel.fromEntity(AccountEntity entity) {
    return AccountModel(
      id: entity.id,
      username: entity.username,
      passwordSalt: entity.passwordSalt,
      passwordHash: entity.passwordHash,
      vaultKey: entity.vaultKey,
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
    );
  }

  Map<String, dynamic> toJson() => {
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

  static DateTime? _readDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }
}

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
    );
  }

  Map<String, dynamic> toJson() => {
        'salt': salt,
        'hash': hash,
        'is_used': isUsed,
      };
}
