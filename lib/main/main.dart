import 'dart:async';

import 'package:flutter/material.dart';

import '../application/data/csv_exporter.dart';
import '../application/domain/app_lock.dart';
import '../application/domain/app_settings.dart';
import '../application/domain/suggestions.dart';
import 'application.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      // Load saved settings first so the right theme shows from the first frame.
      await AppSettings.i.initialise();
      await AppLock.i.initialise();
      // Exported CSV files are plain text, so clear any left from last time.
      unawaited(CsvExporter.purge());
      unawaited(Suggestions.i.refresh());
      runApp(const ThisApplication());
    },
    (error, stack) {},
  );
}
