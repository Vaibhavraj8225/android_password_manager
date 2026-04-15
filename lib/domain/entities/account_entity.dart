class AccountEntity {
  const AccountEntity({
    required this.id,
    required this.username,
    required this.passwordSalt,
    required this.passwordHash,
    required this.vaultKey,
    required this.recoveryKeySalt,
    required this.recoveryKeyHash,
    this.authToken,
    this.createdAt,
    this.lastUsedAt,
  });

  final String id;
  final String username;
  final String passwordSalt;
  final String passwordHash;
  final String vaultKey;
  final String recoveryKeySalt;
  final String recoveryKeyHash;
  final String? authToken;
  final DateTime? createdAt;
  final DateTime? lastUsedAt;

  AccountEntity copyWith({
    String? id,
    String? username,
    String? passwordSalt,
    String? passwordHash,
    String? vaultKey,
    String? recoveryKeySalt,
    String? recoveryKeyHash,
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
      recoveryKeySalt: recoveryKeySalt ?? this.recoveryKeySalt,
      recoveryKeyHash: recoveryKeyHash ?? this.recoveryKeyHash,
      authToken: authToken ?? this.authToken,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }
}

class RecoveryRequestEntity {
  const RecoveryRequestEntity({
    required this.attemptCount,
    this.requestedAt,
    this.availableAt,
    this.lockedUntil,
    this.authorizedAt,
    this.authorizationExpiresAt,
  });

  final DateTime? requestedAt;
  final DateTime? availableAt;
  final int attemptCount;
  final DateTime? lockedUntil;
  final DateTime? authorizedAt;
  final DateTime? authorizationExpiresAt;

  bool get hasPendingDelay => availableAt != null;

  bool isLocked(DateTime now) =>
      lockedUntil != null && lockedUntil!.isAfter(now);

  bool isAuthorized(DateTime now) {
    final expiresAt = authorizationExpiresAt;
    if (authorizedAt == null || expiresAt == null) {
      return false;
    }
    return !expiresAt.isBefore(now);
  }

  RecoveryRequestEntity copyWith({
    DateTime? requestedAt,
    DateTime? availableAt,
    int? attemptCount,
    DateTime? lockedUntil,
    DateTime? authorizedAt,
    DateTime? authorizationExpiresAt,
    bool clearRequestedAt = false,
    bool clearAvailableAt = false,
    bool clearLockedUntil = false,
    bool clearAuthorizedAt = false,
    bool clearAuthorizationExpiresAt = false,
  }) {
    return RecoveryRequestEntity(
      requestedAt: clearRequestedAt ? null : requestedAt ?? this.requestedAt,
      availableAt: clearAvailableAt ? null : availableAt ?? this.availableAt,
      attemptCount: attemptCount ?? this.attemptCount,
      lockedUntil: clearLockedUntil ? null : lockedUntil ?? this.lockedUntil,
      authorizedAt: clearAuthorizedAt
          ? null
          : authorizedAt ?? this.authorizedAt,
      authorizationExpiresAt: clearAuthorizationExpiresAt
          ? null
          : authorizationExpiresAt ?? this.authorizationExpiresAt,
    );
  }
}


