# Leave By

Aplikasi mobile (Flutter) yang membantu orang menentukan **kapan harus berangkat** dan **moda apa yang dipakai** untuk mencapai bandara atau stasiun tepat waktu.

## 1. Deskripsi masalah

Orang yang harus tiba di bandara atau stasiun dengan waktu mepet sulit memutuskan kapan berangkat dan memakai moda apa. Setiap pilihan punya kelemahan:

- **TransJakarta**: murah, tetapi sering perlu beberapa kali transit sehingga waktu tempuhnya sulit diperkirakan.
- **KRL**: memungkinkan, tetapi perlu sambungan ke Kereta Bandara yang jadwalnya tetap dan tiketnya harus dipesan.
- **Taksi online**: fleksibel, tetapi waktu mendapat driver tidak pasti dan tarifnya mahal.

Akibatnya orang berangkat terlalu cepat (membuang waktu) atau terlalu lambat (tertinggal).

## 2. Profil target pengguna

Komuter atau pelancong di Jabodetabek yang punya batas waktu tiba (jadwal pesawat/kereta), tidak punya banyak pilihan moda, dan sedang repot sehingga butuh keputusan cepat, bukan sekadar peta rute.

## 3. Manfaat aplikasi

Pengguna memasukkan asal, tujuan, dan jam tiba yang dibutuhkan. Aplikasi menampilkan setiap opsi moda beserta **waktu berangkat paling lambat**, cadangan waktu, durasi, jumlah transit, dan biaya, lengkap dengan label tercepat, termurah, dan paling aman. Perjalanan yang sering dipakai bisa disimpan di perangkat.

## 4. Daftar fitur inti (realistis untuk 8 minggu)

1. Input asal, tujuan, dan jam tiba yang dibutuhkan (dengan validasi).
2. Daftar opsi rute per moda: durasi, jumlah transit, estimasi biaya.
3. Perhitungan waktu berangkat paling lambat per opsi, dengan buffer per moda dan pembulatan ke jadwal keberangkatan untuk moda berjadwal.
4. Label opsi: tercepat, termurah, paling aman.
5. Perjalanan Tersimpan: simpan, lihat, ubah, dan hapus perjalanan secara lokal di perangkat (data tetap ada setelah aplikasi ditutup).

## 5. Fitur yang tidak dikerjakan

- Pemesanan tiket atau taksi dari dalam aplikasi
- Data lalu lintas dan posisi kendaraan real-time
- Notifikasi pengingat otomatis
- Pembayaran
- Backend, akun pengguna, dan sinkronisasi antar perangkat
- Cakupan di luar Jabodetabek

## 6. Kriteria aplikasi dinyatakan berhasil

- Untuk set skenario uji (rute ke Bandara Soekarno-Hatta dan stasiun besar), aplikasi menghasilkan rekomendasi dengan waktu berangkat yang masuk akal.
- Opsi yang mustahil dikejar tidak ditampilkan, dan pengguna melihat pesan yang jelas bila tidak ada opsi.
- Pengguna dapat memutuskan moda dan waktu berangkat dalam waktu kurang dari satu menit.
- Perjalanan yang disimpan masih ada setelah aplikasi ditutup dan dibuka kembali, dan CRUD-nya berfungsi.
- Aplikasi berjalan di emulator/perangkat tanpa crash dan setiap state utama punya widget test.

## Rencana 8 minggu

| Minggu | Fokus |
|---|---|
| 1 | Setup Flutter, jalankan starter (F5), README (P1), konsultasi jadwal dengan dosen |
| 2 | Spesifikasi (P2), generate arsitektur dengan AI (P3), routing dan prototype layar |
| 3 | Planner stabil (`flutter analyze` dan `flutter test` bersih), ganti data contoh dengan data riset |
| 4 | Fitur Perjalanan Tersimpan dengan state management dan enam state (P4) |
| 5 | Penyimpanan lokal, CRUD, dan persistence test (P5) |
| 6 | Dokumentasi: screenshot/video, `docs/ai-prompts.md`, catatan reviewer |
| 7 | Tugas baru (P6 dan seterusnya) dan perapian |
| 8 | Cadangan waktu, perbaikan, demo akhir |

## Cara menjalankan

Nama paket Flutter harus `leave_by` karena test memakai import `package:leave_by/...`.

```bash
flutter create --project-name leave_by --platforms=android .
flutter pub add flutter_riverpod:^2.6.1
flutter pub add shared_preferences
flutter pub add http
```

Tambahkan aset di `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/data/
```

Lalu:

```bash
flutter pub get
flutter run        # atau F5 di VS Code
flutter test
```

Riverpod sengaja dipin ke 2.x. Riverpod 3 mencoba ulang provider yang gagal secara otomatis, sehingga test error state memerlukan konfigurasi tambahan.

## Catatan data

`assets/data/routes.json` berisi **data contoh (placeholder)**: durasi, tarif, dan jadwal Kereta Bandara belum diambil dari sumber resmi. Ganti dengan data hasil riset sebelum dipakai untuk evaluasi, dan nyatakan sumbernya di laporan.

## Menjalankan backend (P6)

Backend ada di folder `backend/` (FastAPI, SQLite secara default). Pilih salah satu cara:

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate        # Windows PowerShell
pip install -r requirements.txt
uvicorn app.main:app --port 8000
```

atau dengan Docker:

```bash
cd backend
docker compose up --build
```

Cek: buka `http://localhost:8000/health` (harus `{"status":"ok"}`) dan `http://localhost:8000/docs` untuk dokumentasi interaktif. Test backend: `pip install -r requirements-dev.txt` lalu `python -m pytest`.

Menghubungkan aplikasi ke backend:

- **Windows desktop atau emulator/HP lewat USB:** jalankan `adb reverse tcp:8000 tcp:8000` (untuk perangkat Android), lalu `flutter run`. Alamat bawaan aplikasi adalah `http://localhost:8000`.
- **Alamat lain** (misalnya terowongan Cloudflare): `flutter run --dart-define=API_BASE_URL=https://alamat-kamu`.
- **Kembali ke penyimpanan lokal (demo P5):** `flutter run --dart-define=STORAGE=local`.

Untuk build rilis, pastikan `AndroidManifest.xml` utama memuat `<uses-permission android:name="android.permission.INTERNET"/>` (mode debug sudah memilikinya).

## Status pengerjaan

| Bagian | Status |
|---|---|
| `DepartureCalculator` + unit test | Ada, `flutter test` lulus |
| Planner (enam state UI) + widget test | Ada, `flutter test` lulus |
| Spesifikasi arsitektur (`ARCHITECTURE.md`, P2) | Ada |
| Perjalanan Tersimpan: CRUD, state management, penyimpanan lokal (P4, P5) | Ada, `flutter test` lulus, di-tag `p4-p5` |
| Backend FastAPI + 13 test backend (P6) | Ada, test backend lulus |
| `RemoteSavedTripRepository` + unit test API (P6) | Sudah ditulis, belum dijalankan |
| Autentikasi, lokasi, notifikasi (P7) | Belum |
| Layout adaptif, keyboard-safe, aksesibilitas, feedback aksi (P8) | Sebagian |
| Arsitektur hasil AI dan prototype layar (P3) | Belum |
| Data jadwal asli | Belum |
| Screenshot/video dokumentasi dan isi `docs/ai-prompts.md` | Kerangka ada, isi belum |

## Lokasi kode Local Data & Persistence (untuk reviewer P5)

- Model data: `lib/features/saved_trips/domain/saved_trip.dart`
- Penyimpanan lokal (`shared_preferences`, JSON): `lib/features/saved_trips/data/local_saved_trip_repository.dart`
- Pemetaan JSON: `lib/features/saved_trips/data/saved_trip_json.dart`
- Kontrak repository: `lib/features/saved_trips/data/saved_trip_repository.dart`
- Persistence test: `test/features/saved_trips/data/local_saved_trip_repository_test.dart` dan `test/features/saved_trips/presentation/persistence_flow_test.dart`

## Lokasi kode state management (untuk reviewer P4)

- `lib/features/planner/application/planner_notifier.dart`
- `lib/features/saved_trips/application/saved_trips_notifier.dart` dan `saved_trip_form_notifier.dart`
- Widget hanya memanggil method notifier dan membaca state lewat `ref.watch`.

## Lokasi kode integrasi API (untuk reviewer P6)

- Koneksi ke API: `lib/features/saved_trips/data/remote_saved_trip_repository.dart` (GET, PUT, DELETE ke `/api/trips`)
- Alamat server dan pilihan penyimpanan: `lib/core/config/api_config.dart`
- Penanganan kesalahan: `lib/core/network/api_exception.dart`
- Backend: `backend/app/main.py`
- Unit test API: `test/features/saved_trips/data/remote_saved_trip_repository_test.dart` dan `saved_trip_json_test.dart`
