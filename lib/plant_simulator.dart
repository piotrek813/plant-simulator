class Part {
  const Part();
}

Duration currentTime = Duration.zero;
Duration interval = Duration(milliseconds: 100);

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
      "$currentTime $label $action",
      level,
    );
  }
}

abstract class BaseProcessor extends Base {
  final bool canAcceptAnother = true;
  final bool isEmpty = true;

  BaseProcessor({required super.label});

  void accept(Part part) {
    if (!canAcceptAnother) {
      throw Exception(
        "$label can't accept another part. Wait until it finished processing its current load before pushing any more work to it",
      );
    }

    log("accept");
  }

  void process() {
    log("process", LogLevel.verbose);
  }
}

class PlantSimulator {
  final Source source;
  final DateTime startDate;
  final Duration duration;

  PlantSimulator({
    required this.source,
    DateTime? startDate,
    Duration? duration,
  }) : startDate =
           startDate ??
           DateTime(2026, 1, 1, 6, 0, 0),
       duration =
           duration ?? const Duration(days: 1);

  void start() {
    for (
      int i = 1;
      i <=
          duration.inMilliseconds /
              interval.inMilliseconds;
      i++
    ) {
      currentTime = Duration(milliseconds: i);
      source.emit();
    }
  }
}

class Source extends Base {
  Part part;
  int exits = 0;
  Source({
    super.label = "Source",
    this.part = const Part(),
  });

  void emit() {
    for (var e in next) {
      while (e.canAcceptAnother) {
        e.accept(part);
        exits += 1;
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
  bool isFirst;
  Duration processingTime;
  Duration currentProcessTime = Duration.zero;

  bool get finishedProcessing =>
      processingTime == currentProcessTime;

  void resetCurrentProcessTime() {
    currentProcessTime = Duration.zero;
  }

  BaseStation({
    super.label = "Station",
    Duration? processingTime,
    this.isFirst = false,
  }) : processingTime =
           processingTime ??
           Duration(seconds: 10);
}

class Station extends BaseStation {
  Part? part;

  Station({
    super.label = "Station",
    super.processingTime,
    super.isFirst,
  });

  @override
  void accept(Part part) {
    super.accept(part);

    this.part = part;
  }

  @override
  process() {
    super.process();
    if (!isEmpty && !finishedProcessing) {
      if (currentProcessTime == Duration.zero) {
        log("start processing");
      }
      currentProcessTime += interval;
    }

    if (finishedProcessing && part != null) {
      log("process finished");
      for (var e in next) {
        if (e.canAcceptAnother) {
          e.accept(part!);

          part = null;
          resetCurrentProcessTime();
          break;
        }
      }
    }

    for (var e in next) {
      e.process();
    }
  }

  @override
  bool get canAcceptAnother => part == null;

  @override
  bool get isEmpty => part == null;
}

class ParallelStation extends BaseStation {
  int capacity;
  List<Part> parts = [];

  ParallelStation({
    super.label = "Station",
    super.processingTime,
    required this.capacity,
    super.isFirst,
  });

  @override
  void accept(Part part) {
    super.accept(part);

    parts.add(part);
  }

  @override
  process() {
    super.process();
    if (capacity == parts.length &&
        !finishedProcessing) {
      currentProcessTime += interval;
    }

    if (finishedProcessing) {
      for (var e in next) {
        while (e.canAcceptAnother) {
          try {
            e.accept(parts.removeLast());
          } on RangeError {
            break;
          }
        }
      }

      if (isEmpty) {
        resetCurrentProcessTime();
      }
    }

    for (var e in next) {
      e.process();
    }
  }

  @override
  bool get canAcceptAnother =>
      parts.length < capacity &&
      currentProcessTime.inSeconds == 0;

  @override
  bool get isEmpty => parts.isEmpty;
}
