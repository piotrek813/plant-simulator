import 'dart:io';

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
}
