class Absensi {
  final String id;
  final String tanggal;
  final String? hari;
  final String? waktuMasuk;
  final String? waktuKeluar;
  final String status;
  final String? lokasiMasuk;
  final String? lokasiKeluar;
  final String? keterangan;

  Absensi({
    required this.id,
    required this.tanggal,
    this.hari,
    this.waktuMasuk,
    this.waktuKeluar,
    required this.status,
    this.lokasiMasuk,
    this.lokasiKeluar,
    this.keterangan,
  });

  factory Absensi.fromJson(Map<String, dynamic> json) {
    return Absensi(
      id: json['id'].toString(), // Convert to string to handle both String and int
      tanggal: json['tanggal'],
      hari: json['hari'],
      waktuMasuk: json['waktu_masuk'],
      waktuKeluar: json['waktu_keluar'],
      status: json['status'],
      lokasiMasuk: json['lokasi_masuk'],
      lokasiKeluar: json['lokasi_keluar'],
      keterangan: json['keterangan'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tanggal': tanggal,
      'hari': hari,
      'waktu_masuk': waktuMasuk,
      'waktu_keluar': waktuKeluar,
      'status': status,
      'lokasi_masuk': lokasiMasuk,
      'lokasi_keluar': lokasiKeluar,
      'keterangan': keterangan,
    };
  }
}

class AbsensiLaporan {
  final String periode;
  final int tahun;
  final int bulan;
  final int totalHariKerja;
  final int totalHadir;
  final int totalTerlambat;
  final int totalIzin;
  final int totalSakit;
  final int totalAlpha;
  final double persentaseKehadiran;
  final double persentaseKeterlambatan;
  final Map<String, dynamic>? karyawan;

  AbsensiLaporan({
    required this.periode,
    required this.tahun,
    required this.bulan,
    required this.totalHariKerja,
    required this.totalHadir,
    required this.totalTerlambat,
    required this.totalIzin,
    required this.totalSakit,
    required this.totalAlpha,
    required this.persentaseKehadiran,
    required this.persentaseKeterlambatan,
    this.karyawan,
  });

  factory AbsensiLaporan.fromJson(Map<String, dynamic> json) {
    return AbsensiLaporan(
      periode: json['periode'],
      tahun: int.tryParse(json['tahun'].toString()) ?? 0,
      bulan: int.tryParse(json['bulan'].toString()) ?? 0,
      totalHariKerja: int.tryParse(json['total_hari_kerja'].toString()) ?? 0,
      totalHadir: int.tryParse(json['total_hadir'].toString()) ?? 0,
      totalTerlambat: int.tryParse(json['total_terlambat'].toString()) ?? 0,
      totalIzin: int.tryParse(json['total_izin'].toString()) ?? 0,
      totalSakit: int.tryParse(json['total_sakit'].toString()) ?? 0,
      totalAlpha: int.tryParse(json['total_alpha'].toString()) ?? 0,
      persentaseKehadiran: double.tryParse(json['persentase_kehadiran'].toString()) ?? 0.0,
      persentaseKeterlambatan: double.tryParse(json['persentase_keterlambatan'].toString()) ?? 0.0,
      karyawan: json['karyawan'],
    );
  }
}