import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_router.dart';
import 'core/theme/app_theme.dart';
import 'domain/font_scale.dart';
import 'features/settings/settings_providers.dart';
import 'l10n/l10n.dart';

export 'features/settings/settings_providers.dart' show chosenFontScaleProvider;

class SosiegoApp extends ConsumerStatefulWidget {
  /// [firstRun] abre la bienvenida en lugar del feed (primer arranque).
  const SosiegoApp({super.key, this.firstRun = false});

  final bool firstRun;

  @override
  ConsumerState<SosiegoApp> createState() => _SosiegoAppState();
}

class _SosiegoAppState extends ConsumerState<SosiegoApp> {
  late final GoRouter _router = buildRouter(firstRun: widget.firstRun);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      // Español de Colombia; los textos propios caen en `es` (sin app_es_CO).
      locale: const Locale('es', 'CO'),
      supportedLocales: const [Locale('es', 'CO'), Locale('es')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final factor = effectiveFontFactor(
          chosen: ref.watch(chosenFontScaleProvider),
          system: mq.textScaler.scale(1),
        );
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(factor)),
          child: child!,
        );
      },
      routerConfig: _router,
    );
  }
}
