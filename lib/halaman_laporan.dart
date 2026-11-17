import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'models/laporan.dart';

//class dan variabel
class HalamanLaporan extends StatefulWidget {
  const HalamanLaporan({super.key});

  @override
  State<HalamanLaporan> createState() => _HalamanLaporanState();
}

class _HalamanLaporanState extends State<HalamanLaporan> {
  List<Laporan> _daftarLaporan = [];

  int _totalLaporan = 0;
  int _laporanAktif = 0;
  int _laporanSelesai = 0;

  bool _isLoading = true;

  String _keyword = '';
  String _filterStatus = 'Semua';



  final List<String> _daftarStatus = [
    'Semua',
    'Baru',
    'Diproses',
    'Selesai',
  ];

// proses ngambbil data dari database
  @override
  void initState() {
    super.initState();
    _muatData();
  }

  Future<void> _muatData() async {
    setState(() {
      _isLoading = true;
    });


    try {
      final hasil = await DatabaseHelper.instance.getLaporan(
        keyword: _keyword,
        status: _filterStatus,
      );

      final total = await DatabaseHelper.instance.getTotalLaporan();
      final aktif = await DatabaseHelper.instance.getLaporanAktif();
      final selesai = await DatabaseHelper.instance.getLaporanSelesai();

      if (!mounted) return;

      setState(() {
        _daftarLaporan = hasil;
        _totalLaporan = total;
        _laporanAktif = aktif;
        _laporanSelesai = selesai;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: $e')),
      );
    }
  }

  // ubah status laporan secara langsung
  Future<void> _ubahStatus(
    Laporan laporan,
    String statusBaru,
  ) async {
    final laporanUpdate = Laporan(
      id: laporan.id,
      judul: laporan.judul,
      kategori: laporan.kategori,
      lokasi: laporan.lokasi,
      urgensi: laporan.urgensi,
      tanggal: laporan.tanggal,
      status: statusBaru,
    );

    await DatabaseHelper.instance.updateLaporan(laporanUpdate);
    await _muatData();
  }

  // Mengedit judul dan lokasi laporan
  Future<void> _editLaporan(Laporan laporan) async {
    final judulController = TextEditingController(
      text: laporan.judul,
    );

    final lokasiController = TextEditingController(
      text: laporan.lokasi,
    );

    String status = laporan.status;

    final berhasil = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Laporan'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: judulController,
                      decoration: const InputDecoration(
                        labelText: 'Judul Laporan',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: lokasiController,
                      decoration: const InputDecoration(
                        labelText: 'Lokasi',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Baru',
                          child: Text('Baru'),
                        ),
                        DropdownMenuItem(
                          value: 'Diproses',
                          child: Text('Diproses'),
                        ),
                        DropdownMenuItem(
                          value: 'Selesai',
                          child: Text('Selesai'),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          status = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (judulController.text.trim().length < 5 ||
                        lokasiController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Judul minimal 5 karakter dan lokasi wajib diisi',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (berhasil == true) {
      final laporanUpdate = Laporan(
        id: laporan.id,
        judul: judulController.text.trim(),
        kategori: laporan.kategori,
        lokasi: lokasiController.text.trim(),
        urgensi: laporan.urgensi,
        tanggal: laporan.tanggal,
        status: status,
      );

      await DatabaseHelper.instance.updateLaporan(laporanUpdate);
      await _muatData();
    }

    judulController.dispose();
    lokasiController.dispose();
  }

  // hapus laporan setelah pengguna melakukan konfirmasi
  Future<void> _hapusLaporan(Laporan laporan) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Laporan'),
          content: Text(
            'Yakin ingin menghapus laporan "${laporan.judul}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (konfirmasi == true) {
      await DatabaseHelper.instance.hapusLaporan(laporan.id!);
      await _muatData();
    }
  }

  // Menentukan warna berdasarkan tingkat urgensi
  Color _warnaUrgensi(int urgensi) {
    if (urgensi == 3) return Colors.red;
    if (urgensi == 2) return Colors.orange;
    return Colors.blue;
  }

  // kartu statistik
  Widget _kartuStatistik(
    String judul,
    int jumlah,
    Color warna,
    IconData ikon,
  ) {
    return SizedBox(
      width: 105,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(ikon, color: warna, size: 28),
              const SizedBox(height: 8),
              Text(
                jumlah.toString(),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: warna,
                ),
              ),
              Text(
                judul,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Menampilkan satu kartu laporan
  Widget _itemLaporan(Laporan laporan) {
    final sudahSelesai = laporan.status == 'Selesai';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    laporan.judul,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      decoration: sudahSelesai
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: sudahSelesai ? Colors.grey : null,
                    ),
                  ),
                ),
                Icon(
                  Icons.circle,
                  size: 12,
                  color: _warnaUrgensi(laporan.urgensi),
                ),
                const SizedBox(width: 5),
                Text('Urgensi ${laporan.urgensi}'),
              ],
            ),

            const SizedBox(height: 8),

            Text('Kategori: ${laporan.kategori}'),
            Text('Lokasi: ${laporan.lokasi}'),
            Text('Tanggal: ${laporan.tanggal}'),

            const SizedBox(height: 8),

            Row(
              children: [
                const Text('Status: '),
                Expanded(
                  child: DropdownButton<String>(
                    value: laporan.status,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'Baru',
                        child: Text('Baru'),
                      ),
                      DropdownMenuItem(
                        value: 'Diproses',
                        child: Text('Diproses'),
                      ),
                      DropdownMenuItem(
                        value: 'Selesai',
                        child: Text('Selesai'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _ubahStatus(laporan, value);
                      }
                    },
                  ),
                ),
              ],
            ),

            const Divider(),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _editLaporan(laporan),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: () => _hapusLaporan(laporan),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text(
                    'Hapus',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

// build, pencarian, filter dn dftar laporan
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring Laporan'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            onPressed: _muatData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
          ),
        ],
      ),

      body: Column(
        children: [
          // Dashboard statistik
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              alignment: WrapAlignment.center,
              children: [
                _kartuStatistik(
                  'Total',
                  _totalLaporan,
                  Colors.blue,
                  Icons.assignment,
                ),
                _kartuStatistik(
                  'Aktif',
                  _laporanAktif,
                  Colors.orange,
                  Icons.pending_actions,
                ),
                _kartuStatistik(
                  'Selesai',
                  _laporanSelesai,
                  Colors.green,
                  Icons.check_circle,
                ),
              ],
            ),
          ),

          // Kolom pencarian
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Cari judul atau lokasi laporan...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _keyword = value;
                _muatData();
              },
            ),
          ),

          const SizedBox(height: 12),

          // Filter berdasarkan status
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: _daftarStatus.map((status) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(status),
                    selected: _filterStatus == status,
                    onSelected: (selected) {
                      setState(() {
                        _filterStatus = status;
                      });
                      _muatData();
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Daftar laporan
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _daftarLaporan.isEmpty
                    ? const Center(
                        child: Text('Belum ada laporan ditemukan'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _daftarLaporan.length,
                        itemBuilder: (context, index) {
                          return _itemLaporan(_daftarLaporan[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
