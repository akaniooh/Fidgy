import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../application/domain/app_lock.dart';
import '../application/domain/app_settings.dart';
import '../application/ui/views/lock_screen.dart';
import '../common/presentation/presentation.dart';
import '../core/theming/app_theme.dart';
import '../utilities/constants/constants.dart';
import '../utilities/mixins/device_orientation_mixin.dart';

class ThisApplication extends StatefulWidget {
  const ThisApplication({super.key});

  @override
  State<ThisApplication> createState() => _ThisApplicationState();
}

class _ThisApplicationState extends State<ThisApplication>
    with DeviceOrientationMixin {
  @override
  void initState() {
    lockToLandscapeOrientation();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1440, 960),
      minTextAdapt: true,
      child: AppViewBuilder<AppSettings>(
        model: AppSettings.i,
        builder: (settings, _) => MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.themeMode,
          builder: (context, child) {
            final dark = Theme.of(context).brightness == Brightness.dark;
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: (dark
                      ? SystemUiOverlayStyle.light
                      : SystemUiOverlayStyle.dark)
                  .copyWith(statusBarColor: Colors.transparent),
              child: AppViewBuilder<AppLock>(
                model: AppLock.i,
                builder: (lock, _) => Stack(
                  fit: StackFit.expand,
                  children: [
                    child ?? const SizedBox.shrink(),
                    if (lock.locked) const LockScreen(),
                  ],
                ),
              ),
            );
          },
          debugShowCheckedModeBanner: false,
          title: Constants.appName,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('es'),
          ],
          initialRoute: '/',
          navigatorKey: AppNavigator.mainKey,
          routes: AppRoutes.routes,
          onGenerateRoute: AppRoutes.generateRoutes,
          navigatorObservers: [AppNavigatorObserver.instance],
        ),
      ),
    );
  }
}
