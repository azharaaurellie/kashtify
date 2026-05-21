String normalizeRole(String? role) {
  switch (role) {
    case 'admin':
      return 'bendahara';
    case 'bendahara':
    case 'siswa':
      return role!;
    default:
      return 'siswa';
  }
}

bool isTreasurerRole(String? role) => normalizeRole(role) == 'bendahara';
