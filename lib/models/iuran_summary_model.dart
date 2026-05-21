class IuranSummaryModel {
  final String id;
  final String title;
  final int amount;
  final DateTime dueDate;
  final int totalSiswa;
  final int sudahBayar;
  final int belumBayar;
  final int totalTerkumpul;

  const IuranSummaryModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.totalSiswa,
    required this.sudahBayar,
    required this.belumBayar,
    required this.totalTerkumpul,
  });

  factory IuranSummaryModel.fromMap(Map<String, dynamic> map) {
    return IuranSummaryModel(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toInt(),
      dueDate: DateTime.parse(map['due_date'] as String),
      totalSiswa: (map['total_siswa'] as num?)?.toInt() ?? 0,
      sudahBayar: (map['sudah_bayar'] as num?)?.toInt() ?? 0,
      belumBayar: (map['belum_bayar'] as num?)?.toInt() ?? 0,
      totalTerkumpul: (map['total_terkumpul'] as num?)?.toInt() ?? 0,
    );
  }

  double get progressPercent => totalSiswa == 0 ? 0 : sudahBayar / totalSiswa;
}
