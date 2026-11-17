import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'database_helper.dart';
import 'models/laporan.dart';
import 'halaman_laporan.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  runApp(const SmartCityApp());
}


//class
class SmartCityApp extends StatelessWidget {
  const SmartCityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart City',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const HalamanInputLaporan(),
    );
  }
}


//hlaman 
class HalamanInputLaporan extends StatefulWidget {
  const HalamanInputLaporan({super.key});

  @override
  State<HalamanInputLaporan> createState() =>
      _HalamanInputLaporanState();
}

class _HalamanInputLaporanState extends State<HalamanInputLaporan> {
  final _formKey = GlobalKey<FormState>();

  final _judulController = TextEditingController();
  final _lokasiController = TextEditingController();
  final _tanggalController = TextEditingController();

  String? _kategori = 'Penerangan';
  int _urgensi = 1;
  DateTime? _tanggal;

  bool _isSaving = false;

  final List<String> _daftarKategori = [
    'Penerangan',
    'Jalan',
    'Drainase',
    'Sampah',
    'Lalu Lintas',
  ];

  // buka kalender untuk memilih tanggal laporan
  Future<void> _pilihTanggal() async {
    final tanggalDipilih = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (tanggalDipilih != null) {
      setState(() {
        _tanggal = tanggalDipilih;

        _tanggalController.text =
            '${tanggalDipilih.year}-'
            '${tanggalDipilih.month.toString().padLeft(2, '0')}-'
            '${tanggalDipilih.day.toString().padLeft(2, '0')}';
      });
    }
  }

  // simpan laporan ke database
  Future<void> _simpanLaporan() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final laporan = Laporan(
        judul: _judulController.text.trim(),
        kategori: _kategori!,
        lokasi: _lokasiController.text.trim(),
        urgensi: _urgensi,
        tanggal: _tanggalController.text,
      );

      await DatabaseHelper.instance.tambahLaporan(laporan);

      if (!mounted) return;


//bagian berhasil, gagal
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan berhasil disimpan'),
          backgroundColor: Colors.green,
        ),
      );

      _judulController.clear();
      _lokasiController.clear();
      _tanggalController.clear();

      setState(() {
        _kategori = 'Penerangan';
        _urgensi = 1;
        _tanggal = null;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan laporan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _judulController.dispose();
    _lokasiController.dispose();
    _tanggalController.dispose();
    super.dispose();
  }

//build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart City - Pelaporan'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            tooltip: 'Monitoring Laporan',
            icon: const Icon(Icons.dashboard),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HalamanLaporan(),
                ),
              );
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.location_city,
                size: 60,
                color: Colors.blue,
              ),

              const SizedBox(height: 12),

              const Text(
                'Form Pelaporan Fasilitas Publik',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              // Input judul laporan
              TextFormField(
                controller: _judulController,
                decoration: const InputDecoration(
                  labelText: 'Judul Laporan',
                  hintText: 'Contoh: Lampu jalan mati',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Judul laporan wajib diisi';
                  }

                  if (value.trim().length < 5) {
                    return 'Judul minimal 5 karakter';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // dropdown dn tanggal
              DropdownButtonFormField<String>(
                initialValue: _kategori,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _daftarKategori.map((kategori) {
                  return DropdownMenuItem(
                    value: kategori,
                    child: Text(kategori),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _kategori = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Kategori wajib dipilih';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Input lokasi laporan
              TextFormField(
                controller: _lokasiController,
                decoration: const InputDecoration(
                  labelText: 'Lokasi',
                  hintText: 'Contoh: Jalan Dipatiukur',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Lokasi wajib diisi';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Pilihan tingkat urgensi
              DropdownButtonFormField<int>(
                initialValue: _urgensi,
                decoration: const InputDecoration(
                  labelText: 'Tingkat Urgensi',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.warning_amber),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 1,
                    child: Text('1 - Normal'),
                  ),
                  DropdownMenuItem(
                    value: 2,
                    child: Text('2 - Mendesak'),
                  ),
                  DropdownMenuItem(
                    value: 3,
                    child: Text('3 - Darurat'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _urgensi = value!;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Pilihan tanggal laporan
              TextFormField(
                controller: _tanggalController,
                readOnly: true,
                onTap: _pilihTanggal,
                decoration: const InputDecoration(
                  labelText: 'Tanggal Laporan',
                  hintText: 'Pilih tanggal',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_month),
                ),
                validator: (value) {
                  if (_tanggal == null) {
                    return 'Tanggal laporan wajib dipilih';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Tombol simpan laporan
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _simpanLaporan,
                icon: const Icon(Icons.save),
                label: Text(
                  _isSaving ? 'Menyimpan...' : 'Simpan Laporan',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),

              const SizedBox(height: 12),

              // Tombol menuju halaman monitoring
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HalamanLaporan(),
                    ),
                  );
                },
                icon: const Icon(Icons.dashboard),
                label: const Text('Lihat Monitoring Laporan'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
