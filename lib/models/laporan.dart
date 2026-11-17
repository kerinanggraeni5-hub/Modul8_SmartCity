class Laporan {
  final int? id;
  final String judul;
  final String kategori;
  final String lokasi;
  final int urgensi;
  final String tanggal;
  final String status;

  Laporan({
    this.id,
    required this.judul,
    required this.kategori,
    required this.lokasi,
    required this.urgensi,
    required this.tanggal,
    this.status = 'Baru',
  });

  // Mengubah data dari SQLite menjadi objek Laporan
  factory Laporan.fromMap(Map<String, Object?> map) {
    return Laporan(
      id: map['id'] as int?,
      judul: map['judul'] as String,
      kategori: map['kategori'] as String,
      lokasi: map['lokasi'] as String,
      urgensi: map['urgensi'] as int,
      tanggal: map['tanggal'] as String,
      status: map['status'] as String,
    );
  }

  // Mengubah objek Laporan menjadi Map untuk disimpan ke SQLite
  Map<String, Object?> toMap() {
    return {
      'judul': judul,
      'kategori': kategori,
      'lokasi': lokasi,
      'urgensi': urgensi,
      'tanggal': tanggal,
      'status': status,
    };
  }
}
