import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/settings/settings_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final saved = await SavedSettings.load();
  runApp(
    ProviderScope(
      overrides: [
        chosenFontScaleProvider.overrideWith((_) => saved.fontScale),
        themeModeProvider.overrideWith((_) => saved.themeMode),
        analyticsOptInProvider.overrideWith((_) => saved.analyticsOptIn),
      ],
      child: SosiegoApp(firstRun: !saved.onboardingDone),
    ),
  );
}
