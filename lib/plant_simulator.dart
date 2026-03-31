class Part {
  final String name;

  const Part(this.name);

  @override
  String toString() {
    return name;
  }
}

const generic_part = Part("part");

class Clock {
  Duration currentTime = Duration.zero;
  Duration interval = Duration(milliseconds: 500);

  static final Clock _singleton =
      Clock._internal();

  factory Clock() {
    return _singleton;
  }

  void resetClock() {
    currentTime = Duration.zero;
  }

  Clock._internal();
}

enum LogLevel { verbose, normal, none }

class Logger {
  LogLevel level = LogLevel.none;
  static final Logger _singleton =
      Logger._internal();

  factory Logger() {
    return _singleton;
  }

  Logger._internal();

  void log(
    String msg, [
    LogLevel level = LogLevel.normal,
  ]) {
    if (this.level == LogLevel.none) return;

    if (level == this.level) {
      print(msg);
    }
  }
}

abstract class Base {
  final String label;
  final Logger logger = Logger();
  final Clock clock = Clock();
  List<BaseProcessor> next = [];

  Base({required this.label});

  void pipe(List<BaseProcessor> e) {
    next = e;
  }

  void log(
    String action, [
    LogLevel level = LogLevel.normal,
  ]) {
    logger.log(
      "${clock.currentTime} $label $action",
      level,
    );
  }
}

abstract class BaseProcessor extends Base {
  final bool isEmpty = true;

  BaseProcessor({required super.label});

  void accept(Part part) {
    if (!canAcceptAnother(part)) {
      throw Exception(
        "$label can't accept another ${part.name}. Wait until it finished processing its current load before pushing any more work to it",
      );
    }

    log("accept");
  }

  bool canAcceptAnother(Part part) => true;

  void process() {
    log("process", LogLevel.verbose);
  }
}

class PlantSimulator {
  final List<Source> sources;
  final DateTime startDate;
  final Duration duration;
  final Clock clock = Clock();

  PlantSimulator({
    Source? source,
    List<Source> sources = const [],
    DateTime? startDate,
    this.duration = const Duration(days: 1),
  }) : startDate =
           startDate ??
           DateTime(2026, 1, 1, 6, 0, 0),
       sources = source != null
           ? [source]
           : sources;

  void start() {
    for (
      int i = 1;
      i <=
          duration.inMilliseconds /
              clock.interval.inMilliseconds;
      i++
    ) {
      clock.currentTime = Duration(
        milliseconds: i,
      );

      for (var source in sources) {
        source.emit();
      }
    }
  }
}

class Source extends Base {
  Part part;
  int exits = 0;
  Duration interval;
  Duration timeSinceLastEmission = Duration.zero;

  Source({
    super.label = "Source",
    this.part = generic_part,
    this.interval = Duration.zero,
  });

  void emit() {
    if (interval != Duration.zero) {
      timeSinceLastEmission += clock.interval;
    }

    for (var e in next) {
      if (timeSinceLastEmission == interval) {
        while (e.canAcceptAnother(part)) {
          e.accept(part);
          exits += 1;

          if (interval != Duration.zero) {
            break;
          }
        }
      }

      e.process();
    }
  }
}

class Destination extends BaseProcessor {
  int throughput = 0;

  Destination({super.label = "Destination"});

  @override
  void accept(Part part) {
    super.accept(part);
    throughput += 1;
  }
}

abstract class BaseStation extends BaseProcessor {
  Duration processingTime;
  Duration currentProcessTime = Duration.zero;

  BaseStation({
    super.label = "Station",
    Duration? processingTime,
  }) : processingTime =
           processingTime ??
           Duration(seconds: 10);

  @override
  void process() {
    super.process();

    if (shouldProcess) {
      if (currentProcessTime == Duration.zero) {
        log("start processing");
      }
      currentProcessTime += clock.interval;
    }

    if (finishedProcessing) {
      onProcessFinished();
    }

    for (var e in next) {
      e.process();
    }
  }

  void onProcessFinished() =>
      throw UnimplementedError();

  void resetCurrentProcessTime() {
    currentProcessTime = Duration.zero;
  }

  bool get finishedProcessing =>
      processingTime == currentProcessTime;

  bool get shouldProcess =>
      throw UnimplementedError();
}

class Station extends BaseStation {
  Part? part;

  Station({
    super.label = "Station",
    super.processingTime,
  });

  @override
  void accept(Part part) {
    super.accept(part);

    this.part = part;
  }

  @override
  onProcessFinished() {
    if (part != null) {
      log("process finished");
      for (var e in next) {
        if (e.canAcceptAnother(part!)) {
          e.accept(part!);

          part = null;
          resetCurrentProcessTime();
          break;
        }
      }
    }
  }

  @override
  bool get isEmpty => part == null;

  @override
  bool get shouldProcess =>
      !isEmpty && !finishedProcessing;

  @override
  bool canAcceptAnother(_) => part == null;
}

class ParallelStation extends BaseStation {
  int capacity;
  List<Part> parts = [];

  ParallelStation({
    super.label = "Station",
    super.processingTime,
    required this.capacity,
  });

  @override
  void accept(Part part) {
    super.accept(part);

    parts.add(part);
  }

  @override
  onProcessFinished() {
    for (var e in next) {
      // In case there would be lots of successors this could save some time (ig)
      if (parts.isEmpty) break;

      while (parts.isNotEmpty &&
          e.canAcceptAnother(parts.last)) {
        e.accept(parts.removeLast());
      }
    }

    if (isEmpty) {
      resetCurrentProcessTime();
    }
  }

  @override
  bool get shouldProcess =>
      capacity == parts.length &&
      !finishedProcessing;

  @override
  bool canAcceptAnother(_) =>
      parts.length < capacity &&
      currentProcessTime.inSeconds == 0;

  @override
  bool get isEmpty => parts.isEmpty;
}

class AssemblyStation extends BaseStation {
  Map<String, int> recipy = {};
  Map<String, int> parts = {};
  Part exitingPart;

  AssemblyStation({
    super.label = "Station",
    super.processingTime,
    required this.recipy,
    required this.exitingPart,
  }) {
    parts = clearParts();
  }

  @override
  void accept(Part part) {
    super.accept(part);

    parts.update(
      part.name,
      (prev) => prev + 1,
      ifAbsent: () => 1,
    );
  }

  Map<String, int> clearParts() {
    return Map.fromEntries(
      recipy.entries.map(
        (e) => MapEntry(e.key, 0),
      ),
    );
  }

  @override
  onProcessFinished() {
    for (var e in next) {
      if (e.canAcceptAnother(exitingPart)) {
        e.accept(exitingPart);

        parts = clearParts();
        resetCurrentProcessTime();
        break;
      }
    }
  }

  @override
  bool canAcceptAnother(part) {
    final cur = parts[part.name];
    final desired = recipy[part.name];

    if (cur == null || desired == null) {
      throw Exception(
        "[$label] can't accept a part which isn't defined in recipy. [$label] only accepts [${recipy.keys.join()}] tried to pass [${part.name}]",
      );
    }

    return cur < desired;
  }

  @override
  bool get isEmpty => throw UnimplementedError();

  bool get recipyCompleted => recipy.entries
      .every((e) => parts[e.key] == e.value);

  @override
  bool get shouldProcess =>
      recipyCompleted && !finishedProcessing;
}
