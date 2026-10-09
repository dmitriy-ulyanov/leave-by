# Prompt AI dan catatan pemeriksaan

Isi bagian "Yang saya periksa / perbaiki sendiri" dengan kata-katamu sendiri. Bagian ini yang dinilai.

## P3: Generate arsitektur dari dokumen P2

Alat AI yang dipakai: (isi)

Prompt:

```text
Read the attached specification (ARCHITECTURE.md) for the Flutter app "Leave By".
Generate the architecture for it with these parts:
1. Prototype: a description of each screen (Planner, Saved Trips list, Saved Trip form) as a mock UI.
2. Project structure: folders and files, following the structure in the specification.
3. Routing: how navigation between screens works and what app_routes.dart contains.
4. Reusable widgets: which widgets are shared and what each one does.
5. Models and repositories: fields and responsibilities.
Keep to the stack, code rules and entities in the specification. Do not add features that are not in it.
```

Hasil: (tempel ringkasan atau tautan ke file hasil)

Yang saya periksa / perbaiki sendiri:
- (isi)

## P4: State management (Planner dan Saved Trips)

Prompt yang dipakai: (isi)

Catatan untuk reviewer:
- Kode state management: `lib/features/planner/application/planner_notifier.dart` dan `lib/features/saved_trips/application/`
- Proses: widget memanggil method notifier, notifier mengubah state, widget rebuild lewat `ref.watch`
- Test: `test/features/`
- Screenshot atau video: `docs/screenshots/`

Yang saya periksa / perbaiki sendiri:
- (isi)

## P5: Local data dan persistence (Saved Trips)

Prompt yang dipakai: (isi)

Catatan untuk reviewer:
- Kode penyimpanan lokal: `lib/features/saved_trips/data/local_saved_trip_repository.dart`
- Model data: `lib/features/saved_trips/domain/saved_trip.dart`
- Persistence test: `test/features/saved_trips/data/`
- Demo CRUD dan data tetap ada setelah aplikasi dibuka ulang: (tautan atau file)

Yang saya periksa / perbaiki sendiri:
- (isi)
