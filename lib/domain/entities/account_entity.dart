class AccountEntity {
  const AccountEntity({
    required this.id,
    required this.username,
    required this.passwordSalt,
    required this.passwordHash,
    required this.vaultKey,
    required this.backupCodes,
    this.authToken,
    this.createdAt,
    this.lastUsedAt,
  });

  final String id;
  final String username;
  final String passwordSalt;
  final String passwordHash;
  final String vaultKey;
  final List<BackupCodeEntity> backupCodes;
  final String? authToken;
  final DateTime? createdAt;
  final DateTime? lastUsedAt;

  AccountEntity copyWith({
    String? id,
    String? username,
    String? passwordSalt,
    String? passwordHash,
    String? vaultKey,
    List<BackupCodeEntity>? backupCodes,
    String? authToken,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) {
    return AccountEntity(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordSalt: passwordSalt ?? this.passwordSalt,
      passwordHash: passwordHash ?? this.passwordHash,
      vaultKey: vaultKey ?? this.vaultKey,
      backupCodes: backupCodes ?? this.backupCodes,
      authToken: authToken ?? this.authToken,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }
}

class BackupCodeEntity {
  const BackupCodeEntity({
    required this.salt,
    required this.hash,
    required this.isUsed,
  });

  final String salt;
  final String hash;
  final bool isUsed;

  BackupCodeEntity copyWith({
    String? salt,
    String? hash,
    bool? isUsed,
  }) {
    return BackupCodeEntity(
      salt: salt ?? this.salt,
      hash: hash ?? this.hash,
      isUsed: isUsed ?? this.isUsed,
    );
  }
}
