import 'package:flutter_test/flutter_test.dart';
import 'package:leave_by/features/saved_trips/data/local_saved_trip_repository.dart';
import 'package:leave_by/features/saved_trips/domain/saved_trip.dart';
import 'package:shared_preferences/shared_preferences.dart';

SavedTrip makeTrip(String id, {String title = 'Ke bandara', DateTime? departAt}) {
  return SavedTrip(
    id: id,
    title: title,
    origin: 'Tebet',
    destination: 'Bandara Soekarno-Hatta',
    arriveBy: DateTime(2026, 10, 3, 12, 0),
    createdAt: DateTime(2026, 10, 3, 8, 0),
    optionLabel: 'Taksi online',
    departAt: departAt,
    note: 'catatan',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Read: penyimpanan kosong menghasilkan daftar kosong', () async {
    expect(await LocalSavedTripRepository().getAll(), isEmpty);
  });

  test('Create: perjalanan baru disimpan di urutan teratas', () async {
    final repository = LocalSavedTripRepository();
    await repository.save(makeTrip('1'));
    await repository.save(makeTrip('2'));
    final trips = await repository.getAll();
    expect(trips.map((t) => t.id), ['2', '1']);
  });

  test('Update: id yang sama diganti tanpa mengubah perjalanan lain', () async {
    final repository = LocalSavedTripRepository();
    await repository.save(makeTrip('1'));
    await repository.save(makeTrip('2'));
    await repository.save(makeTrip('1', title: 'Judul baru'));
    final trips = await repository.getAll();
    expect(trips.length, 2);
    expect(trips.firstWhere((t) => t.id == '1').title, 'Judul baru');
    expect(trips.firstWhere((t) => t.id == '2').title, 'Ke bandara');
  });

  test('Delete: hanya perjalanan yang dipilih terhapus', () async {
    final repository = LocalSavedTripRepository();
    await repository.save(makeTrip('1'));
    await repository.save(makeTrip('2'));
    await repository.delete('1');
    final trips = await repository.getAll();
    expect(trips.map((t) => t.id), ['2']);
  });

  test('data tetap ada setelah aplikasi dibuka ulang', () async {
    final departAt = DateTime(2026, 10, 3, 10, 40);
    await LocalSavedTripRepository().save(makeTrip('1', departAt: departAt));
    await LocalSavedTripRepository().save(makeTrip('2'));

    final stored = (await SharedPreferences.getInstance()).getString(LocalSavedTripRepository.storageKey);
    expect(stored, isNotNull);
    SharedPreferences.setMockInitialValues({LocalSavedTripRepository.storageKey: stored!});

    final trips = await LocalSavedTripRepository().getAll();
    expect(trips.map((t) => t.id), ['2', '1']);
    final first = trips.firstWhere((t) => t.id == '1');
    expect(first.departAt, departAt);
    expect(first.arriveBy, DateTime(2026, 10, 3, 12, 0));
    expect(first.note, 'catatan');
    expect(trips.firstWhere((t) => t.id == '2').departAt, isNull);
  });

  test('data rusak menimbulkan error, bukan crash diam-diam', () async {
    SharedPreferences.setMockInitialValues({LocalSavedTripRepository.storageKey: 'bukan json'});
    expect(() => LocalSavedTripRepository().getAll(), throwsA(isA<FormatException>()));
  });
}
