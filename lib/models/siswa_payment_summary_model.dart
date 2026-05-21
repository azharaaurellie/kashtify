class SiswaPaymentSummaryModel {
  final String siswaId;
  final String fullName;
  final String? nis;
  final int totalTagihan;
  final int sudahLunas;
  final int belumLunas;
  final int totalTunggakan;

  const SiswaPaymentSummaryModel({
    required this.siswaId,
    required this.fullName,
    this.nis,
    required this.totalTagihan,
    required this.sudahLunas,
    required this.belumLunas,
    required this.totalTunggakan,
  });

  factory SiswaPaymentSummaryModel.fromMap(Map<String, dynamic> map) {
    return SiswaPaymentSummaryModel(
      siswaId: map['siswa_id'] as String,
      fullName: map['full_name'] as String? ?? '',
      nis: map['nis'] as String?,
      totalTagihan: (map['total_tagihan'] as num?)?.toInt() ?? 0,
      sudahLunas: (map['sudah_lunas'] as num?)?.toInt() ?? 0,
      belumLunas: (map['belum_lunas'] as num?)?.toInt() ?? 0,
      totalTunggakan: (map['total_tunggakan'] as num?)?.toInt() ?? 0,
    );
  }
}
