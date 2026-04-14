class MasterAccount {
  final String username;
  final String passwordSalt;
  final String passwordHash;
  final String vaultKey;
  final List<BackupCodeRecord> backupCodes;

  const MasterAccount({
    required this.username,
    required this.passwordSalt,
    required this.passwordHash,
    required this.vaultKey,
    required this.backupCodes,
  });

  factory MasterAccount.fromJson(Map<String, dynamic> json) {
    final rawCodes = (json['backup_codes'] as List<dynamic>? ?? <dynamic>[]);

    return MasterAccount(
      username: json['username'] as String? ?? '',
      passwordSalt: json['password_salt'] as String? ?? '',
      passwordHash: json['password_hash'] as String? ?? '',
      vaultKey: json['vault_key'] as String? ?? '',
      backupCodes: rawCodes
          .map(
            (code) => BackupCodeRecord.fromJson(
              Map<String, dynamic>.from(code as Map),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'username': username,
        'password_salt': passwordSalt,
        'password_hash': passwordHash,
        'vault_key': vaultKey,
        'backup_codes': backupCodes.map((code) => code.toJson()).toList(),
      };

  MasterAccount copyWith({
    String? username,
    String? passwordSalt,
    String? passwordHash,
    String? vaultKey,
    List<BackupCodeRecord>? backupCodes,
  }) {
    return MasterAccount(
      username: username ?? this.username,
      passwordSalt: passwordSalt ?? this.passwordSalt,
      passwordHash: passwordHash ?? this.passwordHash,
      vaultKey: vaultKey ?? this.vaultKey,
      backupCodes: backupCodes ?? this.backupCodes,
    );
  }
}

class BackupCodeRecord {
  final String salt;
  final String hash;
  final bool isUsed;

  const BackupCodeRecord({
    required this.salt,
    required this.hash,
    required this.isUsed,
  });

  factory BackupCodeRecord.fromJson(Map<String, dynamic> json) {
    return BackupCodeRecord(
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

  BackupCodeRecord copyWith({
    String? salt,
    String? hash,
    bool? isUsed,
  }) {
    return BackupCodeRecord(
      salt: salt ?? this.salt,
      hash: hash ?? this.hash,
      isUsed: isUsed ?? this.isUsed,
    );
  }
}
