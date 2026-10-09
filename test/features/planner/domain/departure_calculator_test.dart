import 'package:flutter_test/flutter_test.dart';
import 'package:leave_by/features/planner/domain/departure_advice.dart';
import 'package:leave_by/features/planner/domain/departure_calculator.dart';
import 'package:leave_by/features/planner/domain/route_option.dart';
import 'package:leave_by/features/planner/domain/transport_mode.dart';
import 'package:leave_by/features/planner/domain/trip_request.dart';

DateTime at(int hour, int minute) => DateTime(2026, 10, 3, hour, minute);

const taxi = RouteOption(
  id: 'taxi',
  mode: TransportMode.taksiOnline,
  label: 'Taksi online',
  travelMinutes: 60,
  transitCount: 0,
  costRupiah: 250000,
);

const train = RouteOption(
  id: 'train',
  mode: TransportMode.keretaBandara,
  label: 'KRL + Kereta Bandara',
  travelMinutes: 70,
  transitCount: 1,
  costRupiah: 70000,
  scheduleMinutes: [480, 540, 570, 600, 630],
);

const bus = RouteOption(
  id: 'bus',
  mode: TransportMode.transjakarta,
  label: 'TransJakarta',
  travelMinutes: 100,
  transitCount: 3,
  costRupiah: 10500,
);

void main() {
  final request = TripRequest(origin: 'Tebet', destination: 'Bandara Soekarno-Hatta', arriveBy: at(12, 0));
  const calculator = DepartureCalculator();

  DepartureAdvice byId(List<DepartureAdvice> list, String id) => list.firstWhere((a) => a.option.id == id);

  test('moda tanpa jadwal: berangkat = tiba - durasi - buffer', () {
    final result = calculator.calculate(request, [taxi]);
    expect(result.single.departAt, at(10, 40));
    expect(result.single.buffer, const Duration(minutes: 20));
  });

  test('moda berjadwal: pilih keberangkatan terakhir yang masih sempat', () {
    final result = calculator.calculate(request, [train]);
    expect(result.single.departAt, at(10, 30));
    expect(result.single.cushion, const Duration(minutes: 20));
  });

  test('buffer TransJakarta bertambah per transit', () {
    final result = calculator.calculate(request, [bus]);
    expect(result.single.buffer, const Duration(minutes: 31));
    expect(result.single.departAt, at(9, 49));
  });

  test('opsi berjadwal dibuang jika tidak ada jadwal yang sempat', () {
    const lateTrain = RouteOption(
      id: 'late',
      mode: TransportMode.keretaBandara,
      label: 'Kereta siang',
      travelMinutes: 70,
      transitCount: 1,
      costRupiah: 70000,
      scheduleMinutes: [660, 700],
    );
    expect(calculator.calculate(request, [lateTrain]), isEmpty);
  });

  test('opsi yang waktu berangkatnya sudah lewat dibuang', () {
    final result = calculator.calculate(request, [taxi, train, bus], now: at(10, 0));
    expect(result.map((a) => a.option.id), ['taxi', 'train']);
  });

  test('semua opsi lewat menghasilkan daftar kosong', () {
    expect(calculator.calculate(request, [taxi, train, bus], now: at(10, 45)), isEmpty);
  });

  test('label tercepat, termurah, dan paling aman', () {
    final result = calculator.calculate(request, [taxi, train, bus]);
    expect(byId(result, 'taxi').tags, {AdviceTag.fastest});
    expect(byId(result, 'bus').tags, {AdviceTag.cheapest, AdviceTag.safest});
    expect(byId(result, 'train').tags, isEmpty);
  });

  test('hasil diurutkan dari waktu berangkat paling lambat', () {
    final result = calculator.calculate(request, [bus, taxi, train]);
    expect(result.map((a) => a.option.id), ['taxi', 'train', 'bus']);
  });
}
