class IuranPaymentModel {
  final String id;
  final String iuranId;
  final String siswaId;
  final String status; // 'lunas' | 'belum_lunas' | 'terlambat'
  final DateTime? paidAt;
  final String? confirmedBy;
  final String? notes;
  final String? paymentProofUrl;
  final DateTime createdAt;

  // Nested from iuran table
  final String? iuranTitle;
  final int? iuranAmount;
  final DateTime? iuranDueDate;

  // Nested from profiles table
  final String? siswaName;
  final String? siswaNis;

  const IuranPaymentModel({
    required this.id,
    required this.iuranId,
    required this.siswaId,
    required this.status,
    this.paidAt,
    this.confirmedBy,
    this.notes,
    this.paymentProofUrl,
    required this.createdAt,
    this.iuranTitle,
    this.iuranAmount,
    this.iuranDueDate,
    this.siswaName,
    this.siswaNis,
  });

  factory IuranPaymentModel.fromMap(Map<String, dynamic> map) {
    final iuranData = map['iuran'];
    final profileData = map['siswa'] ?? map['profiles'];
    return IuranPaymentModel(
      id: map['id'] as String,
      iuranId: map['iuran_id'] as String,
      siswaId: map['siswa_id'] as String,
      status: map['status'] as String? ?? 'belum_lunas',
      paidAt: map['paid_at'] != null
          ? DateTime.tryParse(map['paid_at'] as String)
          : null,
      confirmedBy: map['confirmed_by'] as String?,
      notes: map['notes'] as String?,
      paymentProofUrl: map['payment_proof_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      iuranTitle: iuranData != null ? iuranData['title'] as String? : null,
      iuranAmount:
          iuranData != null ? (iuranData['amount'] as num?)?.toInt() : null,
      iuranDueDate: iuranData != null && iuranData['due_date'] != null
          ? DateTime.tryParse(iuranData['due_date'] as String)
          : null,
      siswaName:
          profileData != null ? profileData['full_name'] as String? : null,
      siswaNis: profileData != null ? profileData['nis'] as String? : null,
    );
  }

  bool get isLunas => status == 'lunas';
  bool get isBelumLunas => status == 'belum_lunas';
  bool get isTerlambat => status == 'terlambat';
  bool get isMenungguKonfirmasi => notes == 'menunggu_konfirmasi';
}
