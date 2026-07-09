import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class LoggerService {
  LoggerService._();

  static final Logger logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 100,
      colors: true,
      printEmojis: false,
      printTime: true,
    ),
    level: kDebugMode ? Level.trace : Level.warning,
  );
}
