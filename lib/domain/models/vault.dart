class Vault {
  List<Map<String, dynamic>> entries;
  List<Map<String, dynamic>> notes;

  Vault({required this.entries, required this.notes});

  factory Vault.empty() {
    return Vault(entries: [], notes: []);
  }

  factory Vault.fromJson(Map<String, dynamic> json) {
    return Vault(
      entries: List.from(json['entries'] ?? []),
      notes: List.from(json['secure_notes'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {"entries": entries, "secure_notes": notes};
}


