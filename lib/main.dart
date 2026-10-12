import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shalomly_app/src/app.dart';
import 'package:shalomly_app/src/core/di/dependency_injection.dart';
import 'package:shalomly_app/src/core/theme/theme_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // 1. Configure all dependencies synchronously in GetIt
  configureDependencies();

  // 2. Pick the church's colors before the first frame. Until runApp draws,
  //    the native splash screen stays up, so a first launch waits there for
  //    at most about two seconds while the Theme is fetched.
  final churchTheme = await getIt<ThemeRepository>().themeForLaunch();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en', 'US'), Locale('ne', 'NP')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en', 'US'),
      child: ShalomlyApp(
        churchTheme: churchTheme,
      ),
    ),
  );
}
