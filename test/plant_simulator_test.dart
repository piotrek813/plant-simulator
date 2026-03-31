import 'package:plant_simulator/plant_simulator.dart';
import 'package:test/test.dart';

void main() {
  test('Lab1 - 1', () {
    final source = Source();
    final dest = Destination();

    source.pipe([
      Station()..pipe([dest]),
    ]);

    PlantSimulator(source: source).start();

    expect(dest.throughput, 8640);
    expect(source.exits, 8640);
  });

  test('Lab1 - 2', () {
    final source = Source();
    final dest = Destination();

    source.pipe([
      ParallelStation(
        label: "Mycie",
        capacity: 4,
        processingTime: Duration(minutes: 3),
      )..pipe([
        Station(
          label: "Frezowanie 1",
          processingTime: Duration(seconds: 30),
        )..pipe([dest]),
        Station(
          label: "Frezowanie 2",
          processingTime: Duration(minutes: 2),
        )..pipe([dest]),
      ]),
    ]);

    PlantSimulator(source: source).start();

    expect(dest.throughput, 1438);
  });

  test('Lab1 - 3', () {
    final source = Source();
    final dest = Destination();

    source.pipe([
      Station(
        label: "Szlifowanie",
        processingTime: Duration(
          minutes: 1,
          seconds: 30,
        ),
      )..pipe([
        Station(
          label: "Wiercenie",
          processingTime: Duration(minutes: 2),
        )..pipe([
          Station(
            label: "Malowanie",
            processingTime: Duration(minutes: 1),
          )..pipe([
            ParallelStation(
              label: "Suszenie",
              capacity: 4,
              processingTime: Duration(
                minutes: 6,
                seconds: 30,
              ),
            )..pipe([dest]),
          ]),
        ]),
      ]),
    ]);

    PlantSimulator(
      source: source,
      duration: Duration(hours: 8),
    ).start();

    expect(dest.throughput, 164);
  });

  // test('Two sources', () {
  //   final walek = Part("Lozysko");
  //   final lozysko = Part("Lozysko");
  //
  //   final sourceWalek = Source(
  //     part: walek,
  //     interval: Duration(seconds: 50),
  //   );
  //   final sourceLozysko = Source(
  //     part: lozysko,
  //     interval: Duration(seconds: 40),
  //   );
  //   final dest = Destination();
  //
  //   final station = Station(
  //     label: "Łączenie",
  //     processingTime: Duration(seconds: 10),
  //   )..pipe([dest]);
  //
  //   sourceWalek.pipe([station]);
  //
  //   sourceLozysko.pipe([station]);
  //
  //   PlantSimulator(
  //     sources: [sourceWalek, sourceLozysko],
  //     duration: Duration(days: 1),
  //   ).start();
  //
  //   expect(dest.throughput, 164);
  // });

  test('Lab 3 - cw 3', () {
    final walek = Part("Wałek");
    final lozysko = Part("Łozysko");
    final walekZLozyskiem = Part(
      "Wałek z łożyskiem",
    );

    final dest = Destination();

    final sourceWalek = Source(part: walek);

    final sourceLozysko = Source(part: lozysko);

    final assembly = AssemblyStation(
      label: "Łączenie",
      recipy: {walek.name: 1, lozysko.name: 1},
      exitingPart: walekZLozyskiem,
      processingTime: Duration(seconds: 10),
    )..pipe([dest]);

    sourceLozysko.pipe([assembly]);

    final frezowanie = Station(
      label: "Frezowanie",
      processingTime: Duration(minutes: 2),
    )..pipe([assembly]);

    sourceWalek.pipe([frezowanie]);

    PlantSimulator(
      sources: [sourceWalek, sourceLozysko],
      duration: Duration(days: 1),
    ).start();

    expect(dest.throughput, 719);
  });

  // test('Lab 3 - cw 3', () {
  //   final walek = Part("Wałek");
  //   final paleta = Part("Paleta");
  //   final dest = Destination();
  //
  //   final converyor = Conveyor(
  //     lengthInMeters: 15,
  //     speedInMetersPerSecond: 2,
  //   );
  //
  //   final sourceWalek = Source(part: walek)
  //     ..pipe([converyor]);
  //
  //   AssemblyStation(
  //     label: "Pakowanie",
  //     recipy: {walek.name: 400},
  //     exitingPart: paleta,
  //     processingTime: Duration(seconds: 10),
  //   ).pipe([dest]);
  //
  //   PlantSimulator(
  //     sources: [sourceWalek],
  //     duration: Duration(days: 1),
  //   ).start();
  //
  //   expect(dest.throughput, 217);
  // });
}
