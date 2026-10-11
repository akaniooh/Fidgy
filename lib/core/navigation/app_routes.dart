import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../application/ui/views/splash_view.dart';

abstract class AppRoutes {
  static const dashboardRoute = 'DashboardView';
  static const loginRoute = 'LoginView';

  static Route<T> generateRoutes<T>(RouteSettings settings) {
    switch (settings.name) {
      default:
        return getPageRoute<T>(
          settings: settings,
          view: Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }

  static final routes = <String, WidgetBuilder>{
    '/': (_) => const SplashView(),
  };

  static Route<T> getPageRoute<T>({
    required RouteSettings settings,
    required Widget view,
  }) {
    if (settings.name == null) {
      settings = RouteSettings(
        name: view.runtimeType.toString(),
        arguments: settings.arguments,
      );
    }

    return defaultTargetPlatform == TargetPlatform.iOS
        ? CupertinoPageRoute<T>(settings: settings, builder: (_) => view)
        : MaterialPageRoute<T>(settings: settings, builder: (_) => view);
  }
}
