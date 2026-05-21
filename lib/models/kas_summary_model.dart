class KasSummaryModel {
  final int totalPemasukan;
  final int totalPengeluaran;
  final int saldo;

  const KasSummaryModel({
    required this.totalPemasukan,
    required this.totalPengeluaran,
    required this.saldo,
  });

  factory KasSummaryModel.fromMap(Map<String, dynamic> map) {
    return KasSummaryModel(
      totalPemasukan: (map['total_pemasukan'] as num?)?.toInt() ?? 0,
      totalPengeluaran: (map['total_pengeluaran'] as num?)?.toInt() ?? 0,
      saldo: (map['saldo'] as num?)?.toInt() ?? 0,
    );
  }
}
